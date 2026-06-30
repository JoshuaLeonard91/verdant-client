import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../shared/verdant_input_sanitizer.dart';
import '../auth/auth_diagnostics.dart';
import '../auth/auth_models.dart';
import 'direct_messages_workspace/direct_messages_models.dart';
import 'direct_messages_workspace/direct_messages_preferences.dart';
import 'direct_messages_workspace/direct_messages_service.dart';
import 'direct_messages_workspace/direct_messages_store.dart';
import 'server_settings_workspace/server_settings_models.dart';
import 'server_settings_workspace/server_settings_service.dart';
import 'shared/message_reaction_projection.dart';
import 'shared/member_profile_projection.dart';
import 'shared/server_message_projection.dart';
import 'shared/workspace_message_mutation_repository.dart';
import 'workspace_local_id.dart';
import 'workspace_seed.dart';
import 'workspace_state.dart';
part 'workspace_controller_helpers.dart';

typedef _LoadedServerWorkspace = ({
  ServerSettingsData settings,
  VerdantUser currentUser,
  ServerSettingsCurrentUserMedia? currentUserMedia,
  String source,
});

typedef _CachedServerWorkspace = ({
  ServerSettingsData settings,
  VerdantUser currentUser,
  ServerSettingsCurrentUserMedia? currentUserMedia,
  String? activeChannelId,
  List<MessageSeed> messages,
  ({bool available, List<MemberSeed> members}) activity,
});

typedef WorkspaceServerAccessFilter = Future<Set<String>?> Function();
typedef WorkspaceDelay = Future<void> Function(Duration duration);

Future<void> _defaultWorkspaceDelay(Duration duration) {
  return Future<void>.delayed(duration);
}

final class WorkspaceController extends ChangeNotifier {
  static const _typingStartThrottle = Duration(seconds: 4);
  static const _initialMessageHydrationRetryDelay = Duration(milliseconds: 250);
  static const _initialMessageHydrationAttempts = 4;
  static const _messagePageSize = 50;

  WorkspaceController({
    required this.session,
    required this.repository,
    this.initialServerId,
    this.directMessagesRepository,
    DirectMessagesPreferences? directMessagesPreferences,
    this.serverAccessFilter,
    AuthDiagnostics? diagnostics,
    this.serverSelectionMinimumDwell = Duration.zero,
    WorkspaceDelay? serverSelectionDelay,
  }) : directMessagesPreferences =
           directMessagesPreferences ?? DirectMessagesPreferences(),
       _pendingInitialServerId = initialServerId,
       _serverSelectionDelay = serverSelectionDelay ?? _defaultWorkspaceDelay,
       diagnostics = RedactingAuthDiagnostics(
         diagnostics ?? const SilentAuthDiagnostics(),
       );

  final AuthSession session;
  final ServerSettingsRepository repository;
  final String? initialServerId;
  final DirectMessagesRepository? directMessagesRepository;
  final DirectMessagesPreferences directMessagesPreferences;
  final WorkspaceServerAccessFilter? serverAccessFilter;
  final AuthDiagnostics diagnostics;
  final Duration serverSelectionMinimumDwell;
  final WorkspaceDelay _serverSelectionDelay;
  final _directMessagesStore = DirectMessagesStore();
  final _serverTypingExpiryTimers = <String, Timer>{};
  final _lastServerTypingStartedAtByChannel = <String, DateTime>{};
  final _serverWorkspaceByServerId = <String, _LoadedServerWorkspace>{};
  final _cachedServerWorkspaceByServerId = <String, _CachedServerWorkspace>{};
  final _serverMessagesByChannel = <String, List<MessageSeed>>{};
  final _channelActivityByChannel =
      <String, ({bool available, List<MemberSeed> members})>{};
  var _hiddenDmPreferencesRestored = false;
  Future<bool>? _hiddenDmPreferencesRestoreFuture;
  Future<void> _hiddenDmPreferencesSaveTail = Future<void>.value();
  var _pendingHiddenDmPreferenceSaves = 0;
  var _hiddenDmPreferenceMutationEpoch = 0;
  StreamSubscription<DirectMessagesRealtimeEvent>? _directMessagesRealtime;
  String? _pendingInitialServerId;
  var _serverSelectionGeneration = 0;
  String? _pendingServerSelectionId;
  Future<void>? _pendingServerSelectionFuture;

  WorkspaceState _state = const WorkspaceState();

  WorkspaceState get state => _state;
  VerdantUser get _currentUser => _state.currentUser ?? session.user;

  Future<void> load() async {
    final loadWatch = Stopwatch()..start();
    _clearServerChannelCaches();
    _setState(
      _state.copyWith(isLoading: true, error: null, isAuthExpired: false),
    );
    diagnostics.record('workspace.load.start', {
      'networkId': session.networkId,
      'initialServerId': initialServerId,
    });
    try {
      final listedServers = await repository.listServers();
      final servers = await _filterServersForAccess(
        listedServers,
        source: 'load',
      );
      diagnostics.record('workspace.load.servers.ready', {
        'networkId': session.networkId,
        'ms': loadWatch.elapsedMilliseconds,
        'serverCount': servers.length,
        'listedServerCount': listedServers.length,
        'initialServerId': initialServerId,
        'listedServerIds': _serverIdPreview(
          listedServers.map((server) => server.id),
        ),
        'serverIds': _serverIdPreview(servers.map((server) => server.id)),
      });
      if (servers.isEmpty) {
        _setState(
          WorkspaceState(
            isLoading: false,
            servers: const [],
            error: 'No servers are available for this account',
            isAuthExpired: false,
          ),
        );
        return;
      }

      final activeServer = _initialOrFirstServer(servers);
      final loaded = await _loadServerSettingsWithCurrentUserMedia(
        repository,
        activeServer,
        mode: 'startup',
      );
      final settings = loaded.settings;
      final currentUser = loaded.currentUser;
      final activeChannelId = _defaultTextChannelId(settings);
      final serverMessagesResult = await _loadInitialServerMessages(
        activeChannelId,
        currentUserId: currentUser.id,
      );
      if (serverMessagesResult.isAuthExpired) {
        throw ServerSettingsException(
          serverMessagesResult.error ?? 'Sign in again to continue',
          isAuthExpired: true,
        );
      }
      final serverMessages = serverMessagesResult.messages;
      final activityFuture = _loadChannelActivityForSettings(
        activeChannelId,
        settings,
      );
      if (serverMessagesResult.error == null && activeChannelId != null) {
        _serverMessagesByChannel[activeChannelId] = serverMessages;
      }
      _cacheServerWorkspace(activeServer.id, loaded);
      final directMessages = _directMessagesStore.replaceSnapshot(
        _emptyDirectMessages(
          currentUser: currentUser,
          hasHydrated: directMessagesRepository == null,
        ),
      );
      _setState(
        WorkspaceState(
          isLoading: false,
          servers: servers,
          activeServer: activeServer,
          settings: settings,
          currentUser: currentUser,
          currentUserMedia: loaded.currentUserMedia,
          activeChannelId: activeChannelId,
          activeChannelMembers: const [],
          hasChannelActivityData: false,
          serverMessages: serverMessages,
          hasMoreServerMessages: _hasMoreMessagePage(serverMessages),
          serverMessagesError: serverMessagesResult.error,
          isChannelActivityLoading: activeChannelId != null,
          directMessages: directMessages,
          entitlements: settings.entitlements,
          isAuthExpired: false,
        ),
      );
      diagnostics.record('workspace.load.result', {
        'networkId': session.networkId,
        'status': 'ok',
        'ms': loadWatch.elapsedMilliseconds,
        'serverCount': servers.length,
        'activeServer': _diagnosticFingerprint(activeServer.id),
        'hasChannel': activeChannelId != null,
        'messageCount': serverMessages.length,
        'messageStatus': serverMessagesResult.error == null ? 'ok' : 'error',
      });
      _connectDirectMessagesRealtime();
      _syncRealtimeFocus();
      unawaited(
        _applyChannelActivityWhenReady(
          mode: 'startup',
          channelId: activeChannelId,
          messages: serverMessages,
          settings: settings,
          serverId: activeServer.id,
          currentUser: currentUser,
          currentUserMedia: loaded.currentUserMedia,
          activityFuture: activityFuture,
          serverSelectionGeneration: _serverSelectionGeneration,
        ),
      );
    } on ServerSettingsException catch (error) {
      diagnostics.record('workspace.load.result', {
        'networkId': session.networkId,
        'status': 'server_settings_exception',
        'ms': loadWatch.elapsedMilliseconds,
        'message': error.message,
        'isAuthExpired': error.isAuthExpired,
      });
      if (!error.isAuthExpired &&
          await _reconcileActiveServerMembershipAfterAccessDenied(
            error.message,
            source: 'load',
          )) {
        return;
      }
      _disconnectDirectMessagesRealtime();
      _setState(
        _state.copyWith(
          isLoading: false,
          error: error.message,
          isAuthExpired: error.isAuthExpired,
        ),
      );
    } catch (error) {
      diagnostics.record('workspace.load.result', {
        'networkId': session.networkId,
        'status': 'unexpected_exception',
        'ms': loadWatch.elapsedMilliseconds,
        'errorType': error.runtimeType.toString(),
        'message': error.toString(),
      });
      _disconnectDirectMessagesRealtime();
      _setState(
        _state.copyWith(
          isLoading: false,
          error: 'Could not load server workspace',
          isAuthExpired: false,
        ),
      );
    }
  }

  Future<void> refresh() => load();

  Future<List<ServerSettingsServer>> _filterServersForAccess(
    List<ServerSettingsServer> servers, {
    required String source,
  }) async {
    final filter = serverAccessFilter;
    if (filter == null) {
      return servers;
    }
    try {
      final allowedServerIds = await filter();
      if (allowedServerIds == null) {
        diagnostics.record('workspace.servers.access_filter.skip', {
          'networkId': session.networkId,
          'source': source,
          'serverCount': servers.length,
          'reason': 'not_applicable',
          'serverIds': _serverIdPreview(servers.map((server) => server.id)),
        });
        return servers;
      }
      final filteredServers = [
        for (final server in servers)
          if (allowedServerIds.contains(server.id)) server,
      ];
      diagnostics.record('workspace.servers.access_filter.result', {
        'networkId': session.networkId,
        'source': source,
        'listedServerCount': servers.length,
        'allowedServerCount': allowedServerIds.length,
        'filteredServerCount': filteredServers.length,
        'listedServerIds': _serverIdPreview(servers.map((server) => server.id)),
        'allowedServerIds': _serverIdPreview(allowedServerIds),
        'filteredServerIds': _serverIdPreview(
          filteredServers.map((server) => server.id),
        ),
      });
      return filteredServers;
    } catch (error) {
      diagnostics.record('workspace.servers.access_filter.error', {
        'networkId': session.networkId,
        'source': source,
        'listedServerCount': servers.length,
        'errorType': error.runtimeType.toString(),
        'listedServerIds': _serverIdPreview(servers.map((server) => server.id)),
      });
      return const <ServerSettingsServer>[];
    }
  }

  Future<void> refreshCurrentUserProfile() async {
    final settings = _state.settings;
    if (settings == null) {
      await refresh();
      return;
    }
    final rawCurrentUserMedia = await _loadCurrentUserMediaOrNull(repository);
    final preferredStatus = await _loadPreferredCurrentUserStatus(
      rawCurrentUserMedia,
    );
    final currentUser = _effectiveCurrentUser(
      rawCurrentUserMedia,
      preferredStatus: preferredStatus,
    );
    final currentUserMedia = _effectiveCurrentUserMedia(
      rawCurrentUserMedia,
      currentUser.status,
    );
    final nextSettings = _withCurrentUserMedia(settings, currentUserMedia);
    final localUserId = _safeLocalUserId(currentUser.id) ?? currentUser.id;
    final scopedUserId = _safeScopedUserId(session.networkId, localUserId);
    final presence = _applyServerRealtimePresence(
      localUserId: localUserId,
      status: currentUser.status,
      settingsOverride: nextSettings,
      activeChannelMembersOverride: scopedUserId == null
          ? _state.activeChannelMembers
          : _memberProfileProjection.applyRealtimeUpdateToMembers(
              _state.activeChannelMembers,
              scopedUserId: scopedUserId,
              localUserId: localUserId,
              profile: rawCurrentUserMedia,
            ),
      activeTypingMembersOverride: scopedUserId == null
          ? _state.activeTypingMembers
          : _memberProfileProjection.applyRealtimeUpdateToMembers(
              _state.activeTypingMembers,
              scopedUserId: scopedUserId,
              localUserId: localUserId,
              profile: rawCurrentUserMedia,
            ),
    );
    _setState(
      _state.copyWith(
        currentUser: currentUser,
        currentUserMedia: currentUserMedia,
        settings: presence.settings,
        activeChannelMembers: presence.activeChannelMembers,
        activeTypingMembers: presence.activeTypingMembers,
        directMessages: _state.directMessages?.copyWith(
          currentUserStatus: _normalizeRealtimePresenceStatus(
            currentUser.status,
          ),
        ),
      ),
    );
  }

  ServerSettingsServer _initialOrFirstServer(
    List<ServerSettingsServer> servers,
  ) {
    final requestedServerId = _pendingInitialServerId;
    _pendingInitialServerId = null;
    if (requestedServerId != null) {
      for (final server in servers) {
        if (server.id == requestedServerId) {
          return server;
        }
      }
    }
    return servers.first;
  }

  Future<void> refreshDirectMessages() async {
    final preferencesAlreadyRestored = _hiddenDmPreferencesRestored;
    if (preferencesAlreadyRestored) {
      final existing = _state.directMessages ?? _emptyDirectMessages();
      _setState(
        _state.copyWith(
          directMessages: _directMessagesStore.markRefreshing(existing),
        ),
      );
    } else {
      final pending = _directMessagesStore.replaceSnapshot(
        _emptyDirectMessages(currentUser: _currentUser, hasHydrated: false),
      );
      _setState(
        _state.copyWith(
          directMessages: pending.copyWith(isRefreshing: true, error: null),
        ),
      );
    }
    final directMessages =
        await _loadDirectMessagesWithAuthoritativeHiddenState(_currentUser);
    _setState(
      _state.copyWith(
        directMessages: directMessages,
        entitlements: directMessages.entitlements.mergeCapabilityFallback(
          _state.entitlements,
        ),
      ),
    );
    _connectDirectMessagesRealtime();
    _syncRealtimeFocus();
  }

  Future<void> sendFriendRequest(String username) async {
    final repository = directMessagesRepository;
    if (repository == null) {
      throw const DirectMessagesException('Direct messages are unavailable');
    }
    await repository.sendFriendRequest(username: username);
    await refreshDirectMessages();
  }

  Future<void> acceptFriendRequest(String localUserId) async {
    final repository = directMessagesRepository;
    if (repository == null) {
      throw const DirectMessagesException('Direct messages are unavailable');
    }
    await repository.acceptFriendRequest(localUserId: localUserId);
    await refreshDirectMessages();
  }

  Future<void> removeRelationship(String localUserId) async {
    final repository = directMessagesRepository;
    if (repository == null) {
      throw const DirectMessagesException('Direct messages are unavailable');
    }
    await repository.removeRelationship(localUserId: localUserId);
    await refreshDirectMessages();
  }

  Future<void> openDirectMessage(String localUserId) async {
    final repository = directMessagesRepository;
    if (repository == null) {
      throw const DirectMessagesException('Direct messages are unavailable');
    }
    final conversation = await repository.openDirectMessage(
      localUserId: localUserId,
      currentUserId: _currentUser.id,
    );
    final scopedConversation = _dmConversationForSession(conversation);
    if (scopedConversation == null) {
      throw const DirectMessagesException('Direct message route is invalid');
    }
    final wasHidden = _directMessagesStore.hiddenChannelIds.contains(
      scopedConversation.channelId,
    );
    _setState(
      _state.copyWith(
        directMessages: _directMessagesStore.unhideConversation(
          scopedConversation,
        ),
      ),
    );
    if (wasHidden) {
      _markHiddenDmPreferencesMutated();
    }
    unawaited(_saveHiddenDmPreferences());
    await openDirectMessageConversation(scopedConversation);
  }

  Future<void> openDirectMessageConversation(
    DmConversationPreviewSeed conversation,
  ) async {
    final repository = directMessagesRepository;
    if (repository == null) {
      throw const DirectMessagesException('Direct messages are unavailable');
    }
    final scopedConversation = _dmConversationForSession(conversation);
    if (scopedConversation == null) {
      throw const DirectMessagesException('Direct message route is invalid');
    }
    final wasHidden = _directMessagesStore.hiddenChannelIds.contains(
      scopedConversation.channelId,
    );
    final directMessages = _directMessagesStore.unhideConversation(
      scopedConversation,
    );
    if (wasHidden) {
      _markHiddenDmPreferencesMutated();
      unawaited(_saveHiddenDmPreferences());
    }
    final cached = _directMessagesStore.messagesFor(
      scopedConversation.channelId,
    );
    _setState(
      _state.copyWith(
        directMessages: directMessages,
        activeDmConversation: scopedConversation,
        dmMessages: cached,
        isDmMessagesLoading: cached == null,
        hasMoreDmMessages: cached == null
            ? _state.hasMoreDmMessages
            : _hasMoreMessagePage(cached.messages),
        dmMessagesError: null,
      ),
    );
    await _loadActiveDmMessages(scopedConversation, repository);
  }

  Future<void> refreshActiveDirectMessage() async {
    final conversation = _state.activeDmConversation;
    final repository = directMessagesRepository;
    if (conversation == null || repository == null) {
      return;
    }
    await _loadActiveDmMessages(conversation, repository);
  }

  Future<void> loadOlderDirectMessages() async {
    final conversation = _state.activeDmConversation;
    final repository = directMessagesRepository;
    final existing = _state.dmMessages;
    if (conversation == null ||
        repository == null ||
        existing == null ||
        existing.messages.isEmpty ||
        _state.isLoadingOlderDmMessages ||
        !_state.hasMoreDmMessages) {
      return;
    }
    final before = existing.messages.first.id;
    _setState(_state.copyWith(isLoadingOlderDmMessages: true));
    try {
      final older = await repository.loadConversationMessages(
        conversation: conversation,
        currentUserId: _currentUser.id,
        beforeMessageId: before,
      );
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      final merged = DmConversationMessages(
        channelId: conversation.channelId,
        messages: _mergeMessagePages(older.messages, existing.messages),
      );
      final directMessages = _directMessagesStore.applyConversationMessages(
        conversation,
        merged,
      );
      _setState(
        _state.copyWith(
          directMessages: directMessages,
          activeDmConversation:
              _directMessagesStore.conversationFor(conversation.channelId) ??
              conversationWithMessages(conversation, merged),
          dmMessages: _directMessagesStore.messagesFor(conversation.channelId),
          isLoadingOlderDmMessages: false,
          hasMoreDmMessages: _hasMoreMessagePage(older.messages),
          dmMessagesError: null,
        ),
      );
    } on DirectMessagesException catch (error) {
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      _setState(
        _state.copyWith(
          isLoadingOlderDmMessages: false,
          dmMessagesError: error.message,
        ),
      );
    } catch (_) {
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      _setState(
        _state.copyWith(
          isLoadingOlderDmMessages: false,
          dmMessagesError: 'Could not load older messages',
        ),
      );
    }
  }

  Future<void> _loadActiveDmMessages(
    DmConversationPreviewSeed conversation,
    DirectMessagesRepository repository,
  ) async {
    try {
      final messages = await repository.loadConversationMessages(
        conversation: conversation,
        currentUserId: _currentUser.id,
      );
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      final directMessages = _directMessagesStore.applyConversationMessages(
        conversation,
        messages,
      );
      final mergedMessages =
          _directMessagesStore.messagesFor(conversation.channelId) ?? messages;
      final updatedConversation = conversationWithMessages(
        conversation,
        mergedMessages,
      );
      _setState(
        _state.copyWith(
          directMessages: directMessages,
          activeDmConversation: updatedConversation,
          dmMessages: mergedMessages,
          isDmMessagesLoading: false,
          hasMoreDmMessages: _hasMoreMessagePage(messages.messages),
          dmMessagesError: null,
        ),
      );
    } on DirectMessagesException catch (error) {
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      _setState(
        _state.copyWith(
          activeDmConversation: conversation,
          isDmMessagesLoading: false,
          dmMessagesError: error.message,
        ),
      );
    } catch (_) {
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      _setState(
        _state.copyWith(
          activeDmConversation: conversation,
          isDmMessagesLoading: false,
          dmMessagesError: 'Could not load messages',
        ),
      );
    }
  }

  void showDirectMessageFriends() {
    _setState(
      _state.copyWith(
        activeDmConversation: null,
        dmMessages: null,
        isDmMessagesLoading: false,
        isLoadingOlderDmMessages: false,
        hasMoreDmMessages: false,
        dmMessagesError: null,
      ),
    );
  }

  Future<void> closeDirectMessageConversation(
    DmConversationPreviewSeed conversation,
  ) async {
    final scopedConversation = _dmConversationForSession(conversation);
    if (scopedConversation == null) {
      return;
    }
    final wasHidden = _directMessagesStore.hiddenChannelIds.contains(
      scopedConversation.channelId,
    );
    _setState(
      _state.copyWith(
        directMessages: _directMessagesStore.hideConversation(
          scopedConversation.channelId,
        ),
        activeDmConversation:
            _state.activeDmConversation?.channelId ==
                scopedConversation.channelId
            ? null
            : _state.activeDmConversation,
        dmMessages:
            _state.activeDmConversation?.channelId ==
                scopedConversation.channelId
            ? null
            : _state.dmMessages,
        isDmMessagesLoading:
            _state.activeDmConversation?.channelId ==
                scopedConversation.channelId
            ? false
            : _state.isDmMessagesLoading,
        isLoadingOlderDmMessages:
            _state.activeDmConversation?.channelId ==
                scopedConversation.channelId
            ? false
            : _state.isLoadingOlderDmMessages,
        hasMoreDmMessages:
            _state.activeDmConversation?.channelId ==
                scopedConversation.channelId
            ? false
            : _state.hasMoreDmMessages,
        dmMessagesError:
            _state.activeDmConversation?.channelId ==
                scopedConversation.channelId
            ? null
            : _state.dmMessagesError,
      ),
    );
    if (!wasHidden) {
      _markHiddenDmPreferencesMutated();
    }
    await _saveHiddenDmPreferences();
  }

  Future<void> selectServer(ServerSettingsServer server) async {
    if (_state.activeServer?.id == server.id && _state.settings != null) {
      _serverSelectionGeneration += 1;
      _pendingServerSelectionId = null;
      _pendingServerSelectionFuture = null;
      if (_state.isChannelTransitionLoading ||
          _state.isServerMessagesLoading ||
          _state.isChannelActivityLoading ||
          _state.serverMessagesError != null) {
        _clearServerTypingIndicators();
        _setState(
          _state.copyWith(
            isChannelTransitionLoading: false,
            isServerMessagesLoading: false,
            isChannelActivityLoading: false,
            serverMessagesError: null,
          ),
        );
      }
      return;
    }

    final pendingFuture = _pendingServerSelectionFuture;
    final pendingServerId = _pendingServerSelectionId;
    if (pendingFuture != null && pendingServerId != null) {
      diagnostics.record('workspace.server.select.busy_ignore', {
        'networkId': session.networkId,
        'serverId': server.id,
        'pendingServerId': pendingServerId,
        'reason': pendingServerId == server.id
            ? 'pending_same_server'
            : 'pending_selection',
      });
      return;
    }

    final selectionFuture = _selectServer(server);
    _pendingServerSelectionId = server.id;
    _pendingServerSelectionFuture = selectionFuture;
    try {
      await selectionFuture;
    } finally {
      if (identical(_pendingServerSelectionFuture, selectionFuture)) {
        _pendingServerSelectionId = null;
        _pendingServerSelectionFuture = null;
      }
    }
  }

  Future<void> _selectServer(ServerSettingsServer server) async {
    final selectionWatch = Stopwatch()..start();
    final selectionGeneration = ++_serverSelectionGeneration;
    final cachedWorkspace = _cachedServerWorkspaceFor(server);
    if (cachedWorkspace != null) {
      diagnostics.record('workspace.server.select.cache_hit', {
        'networkId': session.networkId,
        'serverId': server.id,
        'hasChannel': cachedWorkspace.activeChannelId != null,
        'messageCount': cachedWorkspace.messages.length,
      });
      _applyCachedServerWorkspace(server, cachedWorkspace);
      diagnostics.record('workspace.server.select.result', {
        'networkId': session.networkId,
        'serverId': server.id,
        'status': 'ok',
        'source': 'cache',
        'keepLoadedWorkspace': false,
        'settingsMs': 0,
        'messagesMs': 0,
        'dwellMs': 0,
        'totalMs': selectionWatch.elapsedMilliseconds,
        'activeChannel': cachedWorkspace.activeChannelId != null,
        'messageCount': cachedWorkspace.messages.length,
        'messageStatus': 'ok',
        'activityDeferred': false,
        'activityAvailable': cachedWorkspace.activity.available,
      });
      return;
    }
    final keepLoadedWorkspace =
        !_state.isLoading &&
        _state.settings != null &&
        _state.currentUser != null;
    final dwellFuture = _waitForServerSelectionDwell();
    diagnostics.record('workspace.server.select.start', {
      'networkId': session.networkId,
      'serverId': server.id,
      'keepLoadedWorkspace': keepLoadedWorkspace,
      'minimumDwellMs': serverSelectionMinimumDwell.inMilliseconds,
    });
    _setState(
      _state.copyWith(
        isLoading: keepLoadedWorkspace ? false : true,
        error: null,
        isAuthExpired: false,
        activeServer: keepLoadedWorkspace ? _state.activeServer : server,
        pendingChannelId: null,
        isChannelTransitionLoading: keepLoadedWorkspace,
        isServerMessagesLoading: keepLoadedWorkspace,
        isChannelActivityLoading: keepLoadedWorkspace,
        serverMessagesError: null,
        activeTypingMembers: const [],
      ),
    );
    _clearServerTypingIndicators();
    try {
      final settingsWatch = Stopwatch()..start();
      final loaded = await _loadServerSettingsWithCurrentUserMedia(
        repository,
        server,
        mode: 'server_select',
      );
      final settingsMs = settingsWatch.elapsedMilliseconds;
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      final settings = loaded.settings;
      final currentUser = loaded.currentUser;
      final activeChannelId = _defaultTextChannelId(settings);
      if (loaded.source != 'batch') {
        _clearServerChannelDataCaches();
      }
      final messagesWatch = Stopwatch()..start();
      final serverMessagesResult = await _loadInitialServerMessages(
        activeChannelId,
        currentUserId: currentUser.id,
        mode: 'server_select',
      );
      final messagesMs = messagesWatch.elapsedMilliseconds;
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      if (serverMessagesResult.isAuthExpired) {
        throw ServerSettingsException(
          serverMessagesResult.error ?? 'Sign in again to continue',
          isAuthExpired: true,
        );
      }
      final serverMessages = serverMessagesResult.messages;
      final activityFuture = _loadChannelActivityForSettings(
        activeChannelId,
        settings,
      );
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      if (serverMessagesResult.error == null && activeChannelId != null) {
        _serverMessagesByChannel[activeChannelId] = serverMessages;
      }
      _cacheServerWorkspace(server.id, loaded);
      final dwellWatch = Stopwatch()..start();
      await dwellFuture;
      final dwellMs = dwellWatch.elapsedMilliseconds;
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      _setState(
        _state.copyWith(
          isLoading: false,
          activeServer: server,
          settings: settings,
          currentUser: currentUser,
          currentUserMedia: loaded.currentUserMedia,
          activeChannelId: activeChannelId,
          pendingChannelId: null,
          isChannelTransitionLoading: false,
          isServerMessagesLoading: false,
          isChannelActivityLoading: activeChannelId != null,
          activeChannelMembers: const [],
          hasChannelActivityData: false,
          serverMessages: serverMessages,
          hasMoreServerMessages: _hasMoreMessagePage(serverMessages),
          serverMessagesError: serverMessagesResult.error,
          isAuthExpired: false,
        ),
      );
      _syncRealtimeFocus();
      diagnostics.record('workspace.server.select.result', {
        'networkId': session.networkId,
        'serverId': server.id,
        'status': 'ok',
        'source': loaded.source,
        'keepLoadedWorkspace': keepLoadedWorkspace,
        'settingsMs': settingsMs,
        'messagesMs': messagesMs,
        'dwellMs': dwellMs,
        'totalMs': selectionWatch.elapsedMilliseconds,
        'activeChannel': activeChannelId != null,
        'messageCount': serverMessages.length,
        'messageStatus': serverMessagesResult.error == null ? 'ok' : 'error',
        'activityDeferred': activeChannelId != null,
        'channelCount': settings.channels.length,
        'roleCount': settings.roles.length,
        'memberCount': settings.members.length,
        'emojiCount': settings.emojis.length,
        'stickerCount': settings.stickers.length,
      });
      unawaited(
        _applyChannelActivityWhenReady(
          mode: 'server_select',
          channelId: activeChannelId,
          messages: serverMessages,
          settings: settings,
          serverId: server.id,
          currentUser: currentUser,
          currentUserMedia: loaded.currentUserMedia,
          activityFuture: activityFuture,
          serverSelectionGeneration: selectionGeneration,
        ),
      );
    } on ServerSettingsException catch (error) {
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      await dwellFuture;
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      if (!error.isAuthExpired && _isHiddenChannelAccessError(error.message)) {
        diagnostics.record('workspace.server.select.access_denied', {
          'networkId': session.networkId,
          'server': _diagnosticFingerprint(server.id),
          'keepLoadedWorkspace': keepLoadedWorkspace,
          'errorKind': _messageLoadErrorKind(
            error.message,
            isAuthExpired: error.isAuthExpired,
          ),
        });
        await _removeServerFromRealtime(
          server.id,
          errorMessage: 'You no longer have access to this server',
        );
        return;
      }
      diagnostics.record('workspace.server.select.result', {
        'networkId': session.networkId,
        'status': 'failed',
        'serverId': server.id,
        'keepLoadedWorkspace': keepLoadedWorkspace,
        'errorKind': _messageLoadErrorKind(
          error.message,
          isAuthExpired: error.isAuthExpired,
        ),
        'isAuthExpired': error.isAuthExpired,
        'totalMs': selectionWatch.elapsedMilliseconds,
      });
      _setState(
        keepLoadedWorkspace && !error.isAuthExpired
            ? _state.copyWith(
                isLoading: false,
                isChannelTransitionLoading: false,
                isServerMessagesLoading: false,
                isChannelActivityLoading: false,
                serverMessagesError: error.message,
                isAuthExpired: false,
              )
            : _state.copyWith(
                isLoading: false,
                error: error.message,
                isAuthExpired: error.isAuthExpired,
                isChannelTransitionLoading: false,
                isServerMessagesLoading: false,
                isChannelActivityLoading: false,
              ),
      );
    } catch (error) {
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      await dwellFuture;
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      diagnostics.record('workspace.server.select.result', {
        'networkId': session.networkId,
        'status': 'unexpected_exception',
        'serverId': server.id,
        'keepLoadedWorkspace': keepLoadedWorkspace,
        'errorType': error.runtimeType.toString(),
        'message': error.toString(),
      });
      _setState(
        keepLoadedWorkspace
            ? _state.copyWith(
                isLoading: false,
                isChannelTransitionLoading: false,
                isServerMessagesLoading: false,
                isChannelActivityLoading: false,
                serverMessagesError: 'Could not load server workspace',
                isAuthExpired: false,
              )
            : _state.copyWith(
                isLoading: false,
                error: 'Could not load server workspace',
                isAuthExpired: false,
                isChannelTransitionLoading: false,
                isServerMessagesLoading: false,
                isChannelActivityLoading: false,
              ),
      );
    }
  }

  Future<void> _waitForServerSelectionDwell() {
    if (serverSelectionMinimumDwell <= Duration.zero) {
      return Future<void>.value();
    }
    return _serverSelectionDelay(serverSelectionMinimumDwell);
  }

  bool _isCurrentServerSelection(int generation) {
    return generation == _serverSelectionGeneration;
  }

  Future<void> selectTextChannel(String channelId) async {
    if (_state.activeChannelId == channelId &&
        _state.serverMessages.isNotEmpty) {
      diagnostics.record('workspace.channel.select.skip', {
        'reason': 'already_active',
        'messageCount': _state.serverMessages.length,
      });
      return;
    }
    if (_state.pendingChannelId == channelId) {
      diagnostics.record('workspace.channel.select.skip', {
        'reason': 'already_pending',
      });
      return;
    }
    final switchWatch = Stopwatch()..start();
    _setState(
      _state.copyWith(
        activeFeedId: null,
        pendingChannelId: channelId,
        isChannelTransitionLoading: true,
        serverMessagesError: null,
        activeTypingMembers: const [],
      ),
    );
    _clearServerTypingIndicators();
    _focusRealtimeChannel(channelId);
    final cachedMessages = _serverMessagesByChannel[channelId];
    final cachedActivity = _channelActivityByChannel[channelId];
    diagnostics.record('workspace.channel.select.start', {
      'hasCachedMessages': cachedMessages != null,
      'hasCachedActivity': cachedActivity != null,
      'previousMessageCount': _state.serverMessages.length,
    });
    if (cachedMessages != null && cachedActivity != null) {
      final enrichWatch = Stopwatch()..start();
      final members = _enrichChannelActivityMembersWithMessages(
        cachedActivity.members,
        cachedMessages,
        _state.settings,
      );
      enrichWatch.stop();
      _setState(
        _state.copyWith(
          activeChannelId: channelId,
          activeFeedId: null,
          pendingChannelId: null,
          activeChannelMembers: members,
          hasChannelActivityData: cachedActivity.available,
          serverMessages: cachedMessages,
          hasMoreServerMessages: _hasMoreMessagePage(cachedMessages),
          isChannelTransitionLoading: false,
          isChannelActivityLoading: false,
          isServerMessagesLoading: false,
          serverMessagesError: null,
        ),
      );
      switchWatch.stop();
      diagnostics.record('workspace.channel.select.result', {
        'source': 'cache',
        'status': 'ok',
        'ms': switchWatch.elapsedMilliseconds,
        'enrichMs': enrichWatch.elapsedMilliseconds,
        'messageCount': cachedMessages.length,
        'activityAvailable': cachedActivity.available,
        'memberCount': cachedActivity.members.length,
      });
      return;
    }
    diagnostics.record('workspace.channel.select.fetch.start', {
      'hasCachedMessages': cachedMessages != null,
      'hasCachedActivity': cachedActivity != null,
    });
    final activityFuture = _loadChannelActivityForSettings(
      channelId,
      _state.settings,
    );
    try {
      final messageResult = await _loadServerMessages(
        channelId,
        currentUserId: _currentUser.id,
        mode: 'channel_switch',
        attempt: 1,
      );
      if (messageResult.error != null) {
        throw ServerSettingsException(
          messageResult.error!,
          isAuthExpired: messageResult.isAuthExpired,
        );
      }
      final messages = messageResult.messages;
      diagnostics.record('workspace.channel.select.messages.ready', {
        'ms': switchWatch.elapsedMilliseconds,
        'messageCount': messages.length,
      });
      if (_state.pendingChannelId != channelId) {
        diagnostics.record('workspace.channel.select.stale', {
          'phase': 'messages_ready',
          'ms': switchWatch.elapsedMilliseconds,
        });
        return;
      }
      _serverMessagesByChannel[channelId] = messages;
      _setState(
        _state.copyWith(
          activeChannelId: channelId,
          activeFeedId: null,
          pendingChannelId: null,
          activeChannelMembers: const [],
          hasChannelActivityData: false,
          serverMessages: messages,
          hasMoreServerMessages: _hasMoreMessagePage(messages),
          isChannelTransitionLoading: false,
          isChannelActivityLoading: true,
          isServerMessagesLoading: false,
          serverMessagesError: null,
        ),
      );
      switchWatch.stop();
      diagnostics.record('workspace.channel.select.result', {
        'source': 'network',
        'status': 'ok',
        'ms': switchWatch.elapsedMilliseconds,
        'activityPending': true,
        'messageCount': messages.length,
      });
      unawaited(
        _applyChannelActivityWhenReady(
          mode: 'channel_switch',
          channelId: channelId,
          messages: messages,
          settings: _state.settings,
          activityFuture: activityFuture,
        ),
      );
    } on ServerSettingsException catch (error) {
      if (_state.pendingChannelId != channelId) {
        diagnostics.record('workspace.channel.select.stale', {
          'phase': 'server_exception',
          'ms': switchWatch.elapsedMilliseconds,
        });
        return;
      }
      unawaited(activityFuture);
      if (error.isAuthExpired) {
        _disconnectDirectMessagesRealtime();
        _setState(
          _state.copyWith(
            pendingChannelId: null,
            isChannelTransitionLoading: false,
            isChannelActivityLoading: false,
            isServerMessagesLoading: false,
            error: error.message,
            isAuthExpired: true,
            serverMessagesError: error.message,
          ),
        );
        switchWatch.stop();
        diagnostics.record('workspace.channel.select.result', {
          'source': 'network',
          'status': 'failed',
          'ms': switchWatch.elapsedMilliseconds,
          'errorKind': 'auth_expired',
        });
        return;
      }
      _setState(
        _state.copyWith(
          pendingChannelId: null,
          isChannelTransitionLoading: false,
          isChannelActivityLoading: false,
          isServerMessagesLoading: false,
          serverMessagesError: error.message,
        ),
      );
      if (await _reconcileActiveServerMembershipAfterAccessDenied(
        error.message,
        source: 'channel_select',
      )) {
        switchWatch.stop();
        return;
      }
      switchWatch.stop();
      diagnostics.record('workspace.channel.select.result', {
        'source': 'network',
        'status': 'failed',
        'ms': switchWatch.elapsedMilliseconds,
        'errorKind': _messageLoadErrorKind(
          error.message,
          isAuthExpired: error.isAuthExpired,
        ),
      });
    } catch (_) {
      if (_state.pendingChannelId != channelId) {
        diagnostics.record('workspace.channel.select.stale', {
          'phase': 'transport_exception',
          'ms': switchWatch.elapsedMilliseconds,
        });
        return;
      }
      unawaited(activityFuture);
      _setState(
        _state.copyWith(
          pendingChannelId: null,
          isChannelTransitionLoading: false,
          isChannelActivityLoading: false,
          isServerMessagesLoading: false,
          serverMessagesError: 'Could not load messages',
        ),
      );
      switchWatch.stop();
      diagnostics.record('workspace.channel.select.result', {
        'source': 'network',
        'status': 'failed',
        'ms': switchWatch.elapsedMilliseconds,
        'errorKind': 'transport',
      });
    }
  }

  void selectAnnouncementFeed(String feedId) {
    if (_state.activeFeedId == feedId) {
      diagnostics.record('workspace.feed.select.skip', {
        'reason': 'already_active',
      });
      return;
    }
    diagnostics.record('workspace.feed.select', {
      'hadActiveChannel': _state.activeChannelId != null,
    });
    _clearServerTypingIndicators();
    _setState(
      _state.copyWith(
        activeFeedId: feedId,
        activeChannelId: null,
        pendingChannelId: null,
        isChannelTransitionLoading: false,
        isServerMessagesLoading: false,
        isChannelActivityLoading: false,
        activeChannelMembers: const [],
        activeTypingMembers: const [],
        hasChannelActivityData: false,
        serverMessages: const [],
        hasMoreServerMessages: false,
        serverMessagesError: null,
      ),
    );
  }

  void updateCachedChannel(ServerSettingsChannelSeed channel) {
    final settings = _state.settings;
    if (settings == null) {
      return;
    }
    var replaced = false;
    final channels = [
      for (final existing in settings.channels)
        if (existing.id == channel.id) ...[
          channel.copyWith(
            unread: existing.unread,
            mentionCount: existing.mentionCount,
          ),
        ] else
          existing,
    ];
    replaced = settings.channels.any((existing) => existing.id == channel.id);
    if (!replaced) {
      channels.add(channel);
    }
    _setState(_state.copyWith(settings: settings.copyWith(channels: channels)));
  }

  void updateCachedEmojis(List<ServerSettingsListItemSeed> emojis) {
    _updateCachedServerSettings(
      (settings) => settings.copyWith(emojis: emojis),
    );
  }

  void updateCachedStickers(List<ServerSettingsListItemSeed> stickers) {
    _updateCachedServerSettings(
      (settings) => settings.copyWith(stickers: stickers),
    );
  }

  void _updateCachedServerSettings(
    ServerSettingsData Function(ServerSettingsData settings) update,
  ) {
    final settings = _state.settings;
    if (settings == null) {
      return;
    }
    final updated = update(settings);
    final serverId = _state.activeServer?.id ?? updated.server.id;
    final loaded = _serverWorkspaceByServerId[serverId];
    if (loaded != null) {
      _serverWorkspaceByServerId[serverId] = (
        settings: updated,
        currentUser: loaded.currentUser,
        currentUserMedia: loaded.currentUserMedia,
        source: loaded.source,
      );
    }
    final cached = _cachedServerWorkspaceByServerId[serverId];
    if (cached != null) {
      _cachedServerWorkspaceByServerId[serverId] = (
        settings: updated,
        currentUser: cached.currentUser,
        currentUserMedia: cached.currentUserMedia,
        activeChannelId: cached.activeChannelId,
        messages: cached.messages,
        activity: cached.activity,
      );
    }
    _setState(_state.copyWith(settings: updated));
  }

  Future<MemberSeed> prepareMemberProfile(MemberSeed member) async {
    if (repository is! ServerSettingsUserMediaRepository) {
      return member;
    }
    final memberId = member.id;
    final settings = _state.settings;
    if (memberId == null ||
        settings == null ||
        !_scopedIdBelongsToNetwork(memberId, settings.networkId)) {
      return member;
    }
    final localId = _safeLocalUserId(memberId);
    if (localId == null) {
      return member;
    }
    try {
      final profile = await (repository as ServerSettingsUserMediaRepository)
          .loadUserMedia(localUserId: localId);
      final hydrated = _memberProfileProjection.applyProfileToMember(
        member,
        profile,
      );
      _replaceActiveChannelMember(hydrated);
      return hydrated;
    } catch (_) {
      return member;
    }
  }

  Future<void> sendServerMessage(String rawContent) async {
    final activeChannelId = _state.activeChannelId;
    final commandSink = directMessagesRepository is WorkspaceRealtimeCommandSink
        ? directMessagesRepository as WorkspaceRealtimeCommandSink
        : null;
    if (activeChannelId == null || commandSink == null) {
      diagnostics.record('workspace.message.send.unavailable', {
        'networkId': session.networkId,
        'hasActiveChannel': activeChannelId != null,
        'hasRealtimeCommandSink': commandSink != null,
      });
      _setState(
        _state.copyWith(serverMessagesError: 'Message sending is unavailable'),
      );
      return;
    }
    final content = sanitizeSearchInput(rawContent, maxLength: 4000);
    if (content.isEmpty) {
      return;
    }
    try {
      diagnostics.record('workspace.message.send.start', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(activeChannelId),
        'contentLength': content.length,
      });
      await _sendRealtimeCommandWithRetry(
        (sink) => sink.sendChannelMessage(
          channelId: activeChannelId,
          content: content,
        ),
      );
      diagnostics.record('workspace.message.send.result', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(activeChannelId),
        'status': 'ok',
      });
      _setState(_state.copyWith(serverMessagesError: null));
    } on DirectMessagesException catch (error) {
      diagnostics.record('workspace.message.send.result', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(activeChannelId),
        'status': 'failed',
        'errorKind': _messageLoadErrorKind(error.message, isAuthExpired: false),
      });
      if (await _reconcileActiveServerMembershipAfterAccessDenied(
        error.message,
        source: 'message_send',
      )) {
        return;
      }
      _setState(_state.copyWith(serverMessagesError: error.message));
    } catch (_) {
      diagnostics.record('workspace.message.send.result', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(activeChannelId),
        'status': 'failed',
        'errorKind': 'transport',
      });
      _setState(_state.copyWith(serverMessagesError: 'Could not send message'));
    }
  }

  Future<void> deleteServerMessage(MessageSeed message) async {
    final activeChannelId = _state.activeChannelId;
    final mutationRepository = repository is WorkspaceMessageMutationRepository
        ? repository as WorkspaceMessageMutationRepository
        : null;
    if (activeChannelId == null || mutationRepository == null) {
      _setState(
        _state.copyWith(serverMessagesError: 'Message deletion is unavailable'),
      );
      return;
    }
    try {
      await mutationRepository.deleteChannelMessage(
        channelId: activeChannelId,
        messageId: message.id,
      );
      if (_state.activeChannelId != activeChannelId) {
        return;
      }
      final messages = removeServerMessage(_state.serverMessages, message.id);
      _cacheActiveServerMessages(messages);
      _setState(
        _state.copyWith(serverMessages: messages, serverMessagesError: null),
      );
    } on ServerSettingsException catch (error) {
      if (_state.activeChannelId == activeChannelId) {
        _setState(_state.copyWith(serverMessagesError: error.message));
      }
    } catch (_) {
      if (_state.activeChannelId == activeChannelId) {
        _setState(
          _state.copyWith(serverMessagesError: 'Could not delete message'),
        );
      }
    }
  }

  Future<void> loadOlderServerMessages() async {
    final channelId = _state.activeChannelId;
    final currentUser = _state.currentUser ?? session.user;
    if (channelId == null ||
        _state.serverMessages.isEmpty ||
        _state.isLoadingOlderServerMessages ||
        !_state.hasMoreServerMessages) {
      return;
    }
    final before = _state.serverMessages.first.id;
    _setState(_state.copyWith(isLoadingOlderServerMessages: true));
    try {
      final older = await repository.loadChannelMessages(
        channelId: channelId,
        currentUserId: currentUser.id,
        beforeMessageId: before,
      );
      if (_state.activeChannelId != channelId) {
        return;
      }
      final merged = _mergeMessagePages(older, _state.serverMessages);
      _cacheActiveServerMessages(merged);
      _setState(
        _state.copyWith(
          serverMessages: merged,
          isLoadingOlderServerMessages: false,
          hasMoreServerMessages: _hasMoreMessagePage(older),
          serverMessagesError: null,
        ),
      );
    } on ServerSettingsException catch (error) {
      if (_state.activeChannelId != channelId) {
        return;
      }
      _setState(
        _state.copyWith(
          isLoadingOlderServerMessages: false,
          serverMessagesError: error.message,
        ),
      );
    } catch (_) {
      if (_state.activeChannelId != channelId) {
        return;
      }
      _setState(
        _state.copyWith(
          isLoadingOlderServerMessages: false,
          serverMessagesError: 'Could not load older messages',
        ),
      );
    }
  }

  Future<void> sendDirectMessage(String rawContent) async {
    final conversation = _state.activeDmConversation;
    final commandSink = _realtimeCommandSink;
    if (conversation == null || commandSink == null) {
      _setState(
        _state.copyWith(dmMessagesError: 'Message sending is unavailable'),
      );
      return;
    }
    final content = sanitizeSearchInput(rawContent, maxLength: 4000);
    if (content.isEmpty) {
      return;
    }
    diagnostics.record('workspace.dm.message.send.start', {
      'networkId': session.networkId,
      'channel': _diagnosticFingerprint(conversation.channelId),
      'activeChannel': _diagnosticFingerprint(
        _state.activeDmConversation?.channelId,
      ),
      'contentLength': content.length,
      'hasRepository': directMessagesRepository != null,
    });
    try {
      await _sendRealtimeCommandWithRetry(
        (sink) => sink.sendChannelMessage(
          channelId: conversation.channelId,
          content: content,
        ),
      );
      diagnostics.record('workspace.dm.message.send.result', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(conversation.channelId),
        'status': 'sent',
      });
      _setState(_state.copyWith(dmMessagesError: null));
      final repository = directMessagesRepository;
      if (repository != null) {
        await _refreshActiveDmMessagesAfterSend(conversation, repository);
      }
    } on DirectMessagesException catch (error) {
      diagnostics.record('workspace.dm.message.send.result', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(conversation.channelId),
        'status': 'error',
        'reason': error.message,
      });
      _setState(_state.copyWith(dmMessagesError: error.message));
    } catch (_) {
      diagnostics.record('workspace.dm.message.send.result', {
        'networkId': session.networkId,
        'channel': _diagnosticFingerprint(conversation.channelId),
        'status': 'error',
        'reason': 'unexpected',
      });
      _setState(_state.copyWith(dmMessagesError: 'Could not send message'));
    }
  }

  Future<void> _refreshActiveDmMessagesAfterSend(
    DmConversationPreviewSeed conversation,
    DirectMessagesRepository repository,
  ) async {
    final activeChannelId = _state.activeDmConversation?.channelId;
    final stillActive =
        activeChannelId != null &&
        sameScopedWorkspaceId(activeChannelId, conversation.channelId);
    diagnostics.record('workspace.dm.message.send.refresh.start', {
      'networkId': session.networkId,
      'channel': _diagnosticFingerprint(conversation.channelId),
      'activeChannel': _diagnosticFingerprint(activeChannelId),
      'stillActive': stillActive,
    });
    if (!stillActive) {
      return;
    }
    final beforeCount = _state.dmMessages?.messages.length ?? 0;
    await _loadActiveDmMessages(conversation, repository);
    final afterCount = _state.dmMessages?.messages.length ?? 0;
    final error = _state.dmMessagesError;
    final fields = <String, Object?>{
      'networkId': session.networkId,
      'channel': _diagnosticFingerprint(conversation.channelId),
      'status': error == null ? 'ok' : 'error',
      'beforeCount': beforeCount,
      'afterCount': afterCount,
    };
    if (error != null) {
      fields['reason'] = error;
    }
    diagnostics.record('workspace.dm.message.send.refresh.result', fields);
  }

  Future<void> deleteDirectMessage(MessageSeed message) async {
    final conversation = _state.activeDmConversation;
    final mutationRepository =
        directMessagesRepository is WorkspaceMessageMutationRepository
        ? directMessagesRepository as WorkspaceMessageMutationRepository
        : null;
    if (conversation == null || mutationRepository == null) {
      _setState(
        _state.copyWith(dmMessagesError: 'Message deletion is unavailable'),
      );
      return;
    }
    try {
      await mutationRepository.deleteChannelMessage(
        channelId: conversation.channelId,
        messageId: message.id,
      );
      if (_state.activeDmConversation?.channelId != conversation.channelId) {
        return;
      }
      final directMessages = _directMessagesStore.applyRealtimeMessageDelete(
        channelId: conversation.channelId,
        messageId: message.id,
      );
      _setState(
        _state.copyWith(
          directMessages: directMessages,
          activeDmConversation:
              _directMessagesStore.conversationFor(conversation.channelId) ??
              conversation,
          dmMessages: _directMessagesStore.messagesFor(conversation.channelId),
          dmMessagesError: null,
        ),
      );
    } on DirectMessagesException catch (error) {
      if (_state.activeDmConversation?.channelId == conversation.channelId) {
        _setState(_state.copyWith(dmMessagesError: error.message));
      }
    } catch (_) {
      if (_state.activeDmConversation?.channelId == conversation.channelId) {
        _setState(_state.copyWith(dmMessagesError: 'Could not delete message'));
      }
    }
  }

  Future<void> sendServerTypingStart() async {
    final activeChannelId = _state.activeChannelId;
    final commandSink = _realtimeCommandSink;
    if (activeChannelId == null || commandSink == null) {
      return;
    }
    final now = DateTime.now();
    final lastSent = _lastServerTypingStartedAtByChannel[activeChannelId];
    if (lastSent != null && now.difference(lastSent) < _typingStartThrottle) {
      return;
    }
    _lastServerTypingStartedAtByChannel[activeChannelId] = now;
    try {
      await _sendRealtimeCommandWithRetry(
        (sink) => sink.sendTypingStart(channelId: activeChannelId),
      );
    } catch (_) {
      _lastServerTypingStartedAtByChannel.remove(activeChannelId);
      // Typing is ephemeral UI state. Message sending remains authoritative and
      // reports user-visible errors separately.
    }
  }

  Future<void> updateCurrentUserStatus(String status) async {
    final canonical = _canonicalRealtimePresenceStatus(status) ?? 'offline';
    final commandSink = _realtimeCommandSink;
    _applyCurrentUserStatus(canonical);
    await _saveCurrentUserStatusPreference(canonical);
    if (commandSink == null) {
      return;
    }
    try {
      await _sendRealtimeCommandWithRetry(
        (sink) => sink.updatePresenceStatus(status: canonical, afk: false),
      );
    } on DirectMessagesException catch (error) {
      if (!_isRetryableStatusTransportError(error)) {
        rethrow;
      }
      _recordDirectMessagesRealtimeDiagnostic('status_deferred', {
        'networkId': session.networkId,
        'reason': error.message,
      });
    }
  }

  void _applyCurrentUserStatus(String status) {
    final canonical = _canonicalRealtimePresenceStatus(status) ?? 'offline';
    final normalized = _normalizeRealtimePresenceStatus(canonical);
    final currentUser = _currentUser.copyWith(status: canonical);
    final currentUserMedia = _state.currentUserMedia?.copyWith(
      status: canonical,
    );
    final directMessages = _state.directMessages?.copyWith(
      currentUserStatus: normalized,
    );
    final localUserId = _safeLocalUserId(currentUser.id) ?? currentUser.id;
    final presence = _applyServerRealtimePresence(
      localUserId: localUserId,
      status: normalized,
    );
    _setState(
      _state.copyWith(
        currentUser: currentUser,
        currentUserMedia: currentUserMedia,
        directMessages: directMessages,
        settings: presence.settings,
        activeChannelMembers: presence.activeChannelMembers,
        activeTypingMembers: presence.activeTypingMembers,
      ),
    );
  }

  Future<void> _saveCurrentUserStatusPreference(String status) {
    return directMessagesPreferences.saveCurrentUserStatus(
      networkId: session.networkId,
      userId: _currentUser.id,
      status: status,
    );
  }

  bool _isRetryableStatusTransportError(DirectMessagesException error) {
    return error.message == 'Realtime commands are unavailable' ||
        _isRetryableRealtimeSetupError(error);
  }

  Future<void> setServerReaction({
    required String messageId,
    required String emoji,
    String? emojiId,
    required bool selected,
  }) async {
    final activeChannelId = _state.activeChannelId;
    final commandSink = directMessagesRepository is WorkspaceRealtimeCommandSink
        ? directMessagesRepository as WorkspaceRealtimeCommandSink
        : null;
    if (activeChannelId == null || commandSink == null) {
      _setState(
        _state.copyWith(serverMessagesError: 'Reaction sending is unavailable'),
      );
      return;
    }
    try {
      if (selected) {
        await _sendRealtimeCommandWithRetry(
          (sink) => sink.addReaction(
            channelId: activeChannelId,
            messageId: messageId,
            emoji: emoji,
            emojiId: emojiId,
          ),
        );
      } else {
        await _sendRealtimeCommandWithRetry(
          (sink) => sink.removeReaction(
            channelId: activeChannelId,
            messageId: messageId,
            emoji: emoji,
          ),
        );
      }
      _setState(_state.copyWith(serverMessagesError: null));
    } on DirectMessagesException catch (error) {
      _setState(_state.copyWith(serverMessagesError: error.message));
    } catch (_) {
      _setState(
        _state.copyWith(serverMessagesError: 'Could not update reaction'),
      );
    }
  }

  Future<void> _sendRealtimeCommandWithRetry(
    Future<void> Function(WorkspaceRealtimeCommandSink sink) command,
  ) async {
    final commandSink = _realtimeCommandSink;
    if (commandSink == null) {
      throw const DirectMessagesException('Realtime commands are unavailable');
    }
    if (_directMessagesRealtime == null) {
      _connectDirectMessagesRealtime();
    }
    DirectMessagesException? lastRetryableError;
    for (var attempt = 0; attempt < 5; attempt += 1) {
      try {
        await command(commandSink);
        return;
      } on DirectMessagesException catch (error) {
        if (!_isRetryableRealtimeSetupError(error)) {
          rethrow;
        }
        lastRetryableError = error;
        _recordDirectMessagesRealtimeDiagnostic('retry_command', {
          'networkId': session.networkId,
          'reason': error.message,
          'attempt': attempt + 1,
        });
        _connectDirectMessagesRealtime(force: true);
        await Future<void>.delayed(
          Duration(milliseconds: attempt == 0 ? 0 : 120),
        );
      }
    }
    throw DirectMessagesException(
      lastRetryableError == null
          ? 'Realtime is reconnecting'
          : 'Realtime is reconnecting',
    );
  }

  bool _isRetryableRealtimeSetupError(DirectMessagesException error) {
    return switch (error.message) {
      'Realtime session closed before READY' ||
      'Realtime session is not ready' ||
      'Realtime is reconnecting' ||
      'Realtime connection timed out' ||
      'Realtime session timed out' => true,
      _ => false,
    };
  }

  Future<ServerCreationResult> createServer(
    ServerCreationRequest request, {
    ServerSettingsRepository? targetRepository,
  }) async {
    final repository = targetRepository ?? this.repository;
    var created = await repository.createServer(
      name: sanitizeDisplayNameInput(request.name),
    );
    final warnings = <String>[];

    final iconUpload = request.iconUpload;
    if (iconUpload != null) {
      try {
        created = await repository.uploadServerIcon(
          serverId: created.id,
          upload: iconUpload,
        );
      } catch (_) {
        warnings.add('icon upload failed');
      }
    }

    final bannerUpload = request.bannerUpload;
    if (bannerUpload != null) {
      try {
        final uploaded = await repository.uploadServerBanner(
          serverId: created.id,
          upload: bannerUpload,
        );
        final crop = request.bannerCrop;
        created = crop == null
            ? uploaded
            : await repository.updateBannerCrop(
                serverId: uploaded.id,
                crop: crop,
              );
      } catch (_) {
        warnings.add('banner upload failed');
      }
    }

    final selected = await _reloadAndSelectServer(
      created,
      targetRepository: repository,
    );
    return ServerCreationResult(
      server: selected,
      warning: warnings.isEmpty
          ? null
          : 'Server created, but ${warnings.join(' and ')}.',
    );
  }

  Future<ServerInvitePreview> previewServerInvite(String code) {
    return repository.previewInvite(code: code);
  }

  Future<ServerSettingsListItemSeed> createServerInvite(
    ServerSettingsServer server,
  ) {
    return repository.createInvite(serverId: server.id);
  }

  Future<ServerSettingsServer> acceptServerInvite(String code) async {
    final watch = Stopwatch()..start();
    diagnostics.record('workspace.invite.accept.start', {
      'networkId': session.networkId,
    });
    final joined = await repository.acceptInvite(code: code);
    diagnostics.record('workspace.invite.accept.accepted', {
      'networkId': session.networkId,
      'ms': watch.elapsedMilliseconds,
      'server': _diagnosticFingerprint(joined.id),
    });
    final selected = await _reloadAndSelectServer(
      joined,
      mode: 'invite_accept',
    );
    diagnostics.record('workspace.invite.accept.result', {
      'networkId': session.networkId,
      'status': 'ok',
      'ms': watch.elapsedMilliseconds,
      'server': _diagnosticFingerprint(selected.id),
    });
    return selected;
  }

  Future<void> leaveServer(ServerSettingsServer server) async {
    await repository.leaveServer(serverId: server.id);
    _clearServerChannelCaches();
    final servers = await repository.listServers();
    if (servers.isEmpty) {
      _disconnectDirectMessagesRealtime();
      _setState(
        _state.copyWith(
          servers: const [],
          activeServer: null,
          settings: null,
          activeChannelId: null,
          activeFeedId: null,
          serverMessages: const [],
          serverMessagesError: null,
          error: 'No servers are available for this account',
          isAuthExpired: false,
        ),
      );
      return;
    }
    final fallback = servers.firstWhere(
      (candidate) => candidate.id != server.id,
      orElse: () => servers.first,
    );
    await _reloadAndSelectServer(fallback);
  }

  Future<ServerSettingsServer> _reloadAndSelectServer(
    ServerSettingsServer target, {
    ServerSettingsRepository? targetRepository,
    String mode = 'server_reload',
  }) async {
    final selectionGeneration = ++_serverSelectionGeneration;
    final reloadWatch = Stopwatch()..start();
    final repository = targetRepository ?? this.repository;
    diagnostics.record('workspace.server.reload.start', {
      'networkId': session.networkId,
      'mode': mode,
      'targetServer': _diagnosticFingerprint(target.id),
      'generation': selectionGeneration,
    });
    final servers = await repository.listServers();
    if (!_isCurrentServerSelection(selectionGeneration)) {
      diagnostics.record('workspace.server.reload.stale', {
        'networkId': session.networkId,
        'mode': mode,
        'phase': 'servers',
        'generation': selectionGeneration,
        'ms': reloadWatch.elapsedMilliseconds,
      });
      return target;
    }
    diagnostics.record('workspace.server.reload.servers.ready', {
      'networkId': session.networkId,
      'mode': mode,
      'generation': selectionGeneration,
      'ms': reloadWatch.elapsedMilliseconds,
      'serverCount': servers.length,
      'targetFound': servers.any((server) => server.id == target.id),
    });
    final selected = servers.firstWhere(
      (server) => server.id == target.id,
      orElse: () => target,
    );
    final loaded = await _loadServerSettingsWithCurrentUserMedia(
      repository,
      selected,
      mode: mode,
    );
    if (!_isCurrentServerSelection(selectionGeneration)) {
      diagnostics.record('workspace.server.reload.stale', {
        'networkId': session.networkId,
        'mode': mode,
        'phase': 'settings',
        'generation': selectionGeneration,
        'ms': reloadWatch.elapsedMilliseconds,
      });
      return selected;
    }
    diagnostics.record('workspace.server.reload.settings.ready', {
      'networkId': session.networkId,
      'mode': mode,
      'generation': selectionGeneration,
      'ms': reloadWatch.elapsedMilliseconds,
      'server': _diagnosticFingerprint(selected.id),
      'channelCount': loaded.settings.channels.length,
    });
    final settings = loaded.settings;
    final currentUser = loaded.currentUser;
    final activeChannelId = _defaultTextChannelId(settings);
    if (loaded.source != 'batch') {
      _clearServerChannelDataCaches();
    }
    final serverMessagesResult = await _loadServerMessages(
      activeChannelId,
      currentUserId: currentUser.id,
      mode: mode,
      attempt: 1,
    );
    if (!_isCurrentServerSelection(selectionGeneration)) {
      diagnostics.record('workspace.server.reload.stale', {
        'networkId': session.networkId,
        'mode': mode,
        'phase': 'messages',
        'generation': selectionGeneration,
        'ms': reloadWatch.elapsedMilliseconds,
      });
      return selected;
    }
    final serverMessages = serverMessagesResult.messages;
    diagnostics.record('workspace.server.reload.messages.ready', {
      'networkId': session.networkId,
      'mode': mode,
      'generation': selectionGeneration,
      'ms': reloadWatch.elapsedMilliseconds,
      'server': _diagnosticFingerprint(selected.id),
      'hasChannel': activeChannelId != null,
      'messageCount': serverMessages.length,
      'messageStatus': serverMessagesResult.error == null ? 'ok' : 'error',
    });
    final activityFuture = _loadChannelActivityForSettings(
      activeChannelId,
      settings,
    );
    if (serverMessagesResult.error == null && activeChannelId != null) {
      _serverMessagesByChannel[activeChannelId] = serverMessages;
    }
    _setState(
      _state.copyWith(
        isLoading: false,
        error: null,
        servers: servers.any((server) => server.id == selected.id)
            ? servers
            : [...servers, selected],
        activeServer: selected,
        settings: settings,
        currentUser: currentUser,
        currentUserMedia: loaded.currentUserMedia,
        activeChannelId: activeChannelId,
        activeFeedId: null,
        pendingChannelId: null,
        isChannelTransitionLoading: false,
        isServerMessagesLoading: false,
        isChannelActivityLoading: activeChannelId != null,
        activeChannelMembers: const [],
        activeTypingMembers: const [],
        hasChannelActivityData: false,
        serverMessages: serverMessages,
        hasMoreServerMessages: _hasMoreMessagePage(serverMessages),
        serverMessagesError: serverMessagesResult.error,
        isAuthExpired: false,
      ),
    );
    _syncRealtimeFocus();
    diagnostics.record('workspace.server.reload.commit', {
      'networkId': session.networkId,
      'mode': mode,
      'ms': reloadWatch.elapsedMilliseconds,
      'server': _diagnosticFingerprint(selected.id),
      'hasChannel': activeChannelId != null,
      'messageCount': serverMessages.length,
      'activityDeferred': activeChannelId != null,
    });
    unawaited(
      _applyChannelActivityWhenReady(
        mode: mode,
        channelId: activeChannelId,
        messages: serverMessages,
        settings: settings,
        serverId: selected.id,
        currentUser: currentUser,
        currentUserMedia: loaded.currentUserMedia,
        activityFuture: activityFuture,
        serverSelectionGeneration: selectionGeneration,
      ),
    );
    return selected;
  }

  Future<({List<MessageSeed> messages, String? error, bool isAuthExpired})>
  _loadServerMessages(
    String? channelId, {
    required String currentUserId,
    required String mode,
    required int attempt,
    String? beforeMessageId,
  }) async {
    if (channelId == null) {
      return (
        messages: const <MessageSeed>[],
        error: null,
        isAuthExpired: false,
      );
    }
    final watch = Stopwatch()..start();
    diagnostics.record('workspace.messages.load.start', {
      'hasChannel': true,
      'mode': mode,
      'attempt': attempt,
      'hasBefore': beforeMessageId != null,
    });
    if (beforeMessageId == null) {
      final cached = _serverMessagesByChannel[channelId];
      if (cached != null) {
        diagnostics.record('workspace.messages.load.result', {
          'hasChannel': true,
          'mode': mode,
          'attempt': attempt,
          'status': 'ok',
          'source': 'cache',
          'ms': watch.elapsedMilliseconds,
          'count': cached.length,
          'hasBefore': false,
        });
        return (messages: cached, error: null, isAuthExpired: false);
      }
    }
    try {
      final messages = await repository.loadChannelMessages(
        channelId: channelId,
        currentUserId: currentUserId,
        beforeMessageId: beforeMessageId,
      );
      diagnostics.record('workspace.messages.load.result', {
        'hasChannel': true,
        'mode': mode,
        'attempt': attempt,
        'status': 'ok',
        'ms': watch.elapsedMilliseconds,
        'count': messages.length,
        'hasBefore': beforeMessageId != null,
      });
      return (messages: messages, error: null, isAuthExpired: false);
    } on ServerSettingsException catch (error) {
      diagnostics.record('workspace.messages.load.result', {
        'hasChannel': true,
        'mode': mode,
        'attempt': attempt,
        'status': 'failed',
        'ms': watch.elapsedMilliseconds,
        'errorKind': _messageLoadErrorKind(
          error.message,
          isAuthExpired: error.isAuthExpired,
        ),
      });
      return (
        messages: const <MessageSeed>[],
        error: error.message,
        isAuthExpired: error.isAuthExpired,
      );
    } catch (_) {
      diagnostics.record('workspace.messages.load.result', {
        'hasChannel': true,
        'mode': mode,
        'attempt': attempt,
        'status': 'failed',
        'ms': watch.elapsedMilliseconds,
        'errorKind': 'transport',
      });
      return (
        messages: const <MessageSeed>[],
        error: 'Could not load messages',
        isAuthExpired: false,
      );
    }
  }

  Future<({List<MessageSeed> messages, String? error, bool isAuthExpired})>
  _loadInitialServerMessages(
    String? channelId, {
    required String currentUserId,
    String mode = 'startup',
  }) async {
    if (channelId == null) {
      return (
        messages: const <MessageSeed>[],
        error: null,
        isAuthExpired: false,
      );
    }
    String? lastError;
    var lastAuthExpired = false;
    for (
      var attempt = 0;
      attempt < _initialMessageHydrationAttempts;
      attempt += 1
    ) {
      final result = await _loadServerMessages(
        channelId,
        currentUserId: currentUserId,
        mode: mode,
        attempt: attempt + 1,
      );
      if (result.error == null) {
        return result;
      }
      if (result.error != null) {
        lastError = result.error;
        lastAuthExpired = result.isAuthExpired;
      }
      if (result.isAuthExpired) {
        return result;
      }
      if (result.messages.isNotEmpty) {
        return result;
      }
      if (attempt == _initialMessageHydrationAttempts - 1) {
        return (
          messages: result.messages,
          error: result.error ?? lastError,
          isAuthExpired: result.isAuthExpired || lastAuthExpired,
        );
      }
      await Future<void>.delayed(_initialMessageHydrationRetryDelay);
    }
    return (
      messages: const <MessageSeed>[],
      error: lastError,
      isAuthExpired: lastAuthExpired,
    );
  }

  void _cacheServerChannelData(
    String? channelId, {
    required List<MessageSeed> messages,
    required ({bool available, List<MemberSeed> members}) activity,
  }) {
    if (channelId == null) {
      return;
    }
    _serverMessagesByChannel[channelId] = messages;
    _channelActivityByChannel[channelId] = activity;
  }

  void _cacheServerWorkspace(
    String serverId,
    _LoadedServerWorkspace workspace,
  ) {
    _serverWorkspaceByServerId[serverId] = workspace;
  }

  _CachedServerWorkspace? _cachedServerWorkspaceFor(
    ServerSettingsServer server,
  ) {
    final serverCachedWorkspace = _cachedServerWorkspaceByServerId[server.id];
    if (serverCachedWorkspace != null) {
      return serverCachedWorkspace;
    }
    final loaded = _serverWorkspaceByServerId[server.id];
    if (loaded == null) {
      return null;
    }
    final activeChannelId = _defaultTextChannelId(loaded.settings);
    if (activeChannelId == null) {
      return (
        settings: loaded.settings,
        currentUser: loaded.currentUser,
        currentUserMedia: loaded.currentUserMedia,
        activeChannelId: null,
        messages: const <MessageSeed>[],
        activity: (available: true, members: const <MemberSeed>[]),
      );
    }
    final messages = _serverMessagesByChannel[activeChannelId];
    final activity = _channelActivityByChannel[activeChannelId];
    if (messages == null || activity == null) {
      return null;
    }
    return (
      settings: loaded.settings,
      currentUser: loaded.currentUser,
      currentUserMedia: loaded.currentUserMedia,
      activeChannelId: activeChannelId,
      messages: messages,
      activity: activity,
    );
  }

  void _applyCachedServerWorkspace(
    ServerSettingsServer server,
    _CachedServerWorkspace cached,
  ) {
    _clearServerTypingIndicators();
    _setState(
      _state.copyWith(
        isLoading: false,
        error: null,
        activeServer: server,
        settings: cached.settings,
        currentUser: cached.currentUser,
        currentUserMedia: cached.currentUserMedia,
        activeChannelId: cached.activeChannelId,
        activeFeedId: null,
        pendingChannelId: null,
        isChannelTransitionLoading: false,
        isServerMessagesLoading: false,
        isChannelActivityLoading: false,
        activeChannelMembers: _enrichChannelActivityMembersWithMessages(
          cached.activity.members,
          cached.messages,
          cached.settings,
        ),
        activeTypingMembers: const [],
        hasChannelActivityData: cached.activity.available,
        serverMessages: cached.messages,
        hasMoreServerMessages: _hasMoreMessagePage(cached.messages),
        serverMessagesError: null,
        isLoadingOlderServerMessages: false,
        isAuthExpired: false,
        entitlements: cached.settings.entitlements,
      ),
    );
    _syncRealtimeFocus();
  }

  Future<void> _applyChannelActivityWhenReady({
    required String mode,
    required String? channelId,
    required List<MessageSeed> messages,
    required ServerSettingsData? settings,
    required Future<({bool available, List<MemberSeed> members})>
    activityFuture,
    String? serverId,
    VerdantUser? currentUser,
    ServerSettingsCurrentUserMedia? currentUserMedia,
    int? serverSelectionGeneration,
  }) async {
    if (channelId == null) {
      return;
    }
    final watch = Stopwatch()..start();
    final activity = await activityFuture;
    if (serverSelectionGeneration != null &&
        !_isCurrentServerSelection(serverSelectionGeneration)) {
      diagnostics.record('workspace.activity.apply.result', {
        'mode': mode,
        'status': 'stale',
        'phase': 'server_generation',
        'ms': watch.elapsedMilliseconds,
      });
      return;
    }
    if (_state.activeChannelId != channelId ||
        _state.pendingChannelId != null) {
      diagnostics.record('workspace.activity.apply.result', {
        'mode': mode,
        'status': 'stale',
        'phase': 'channel_changed',
        'ms': watch.elapsedMilliseconds,
      });
      return;
    }
    final resolvedServerId = serverId ?? _state.activeServer?.id;
    final latestSettings = _freshServerSettingsForSnapshot(
      serverId: resolvedServerId,
      fallback: settings ?? _state.settings,
    );
    _cacheServerChannelData(channelId, messages: messages, activity: activity);
    _cacheServerWorkspaceSnapshot(
      serverId: resolvedServerId,
      settings: latestSettings,
      currentUser: currentUser ?? _state.currentUser,
      currentUserMedia: currentUserMedia ?? _state.currentUserMedia,
      activeChannelId: channelId,
      messages: messages,
      activity: activity,
    );
    final enrichWatch = Stopwatch()..start();
    final members = _enrichChannelActivityMembersWithMessages(
      activity.members,
      messages,
      latestSettings,
    );
    enrichWatch.stop();
    _setState(
      _state.copyWith(
        activeChannelMembers: members,
        hasChannelActivityData: activity.available,
        isChannelActivityLoading: false,
      ),
    );
    diagnostics.record('workspace.activity.apply.result', {
      'mode': mode,
      'status': 'ok',
      'ms': watch.elapsedMilliseconds,
      'enrichMs': enrichWatch.elapsedMilliseconds,
      'activityAvailable': activity.available,
      'memberCount': activity.members.length,
    });
  }

  ServerSettingsData? _freshServerSettingsForSnapshot({
    required String? serverId,
    required ServerSettingsData? fallback,
  }) {
    if (serverId == null) {
      return fallback;
    }
    final activeSettings = _state.settings;
    if (_state.activeServer?.id == serverId &&
        activeSettings?.server.id == serverId) {
      return activeSettings;
    }
    final snapshotSettings =
        _cachedServerWorkspaceByServerId[serverId]?.settings;
    if (snapshotSettings != null) {
      return snapshotSettings;
    }
    return _serverWorkspaceByServerId[serverId]?.settings ?? fallback;
  }

  void _cacheActiveServerMessages(List<MessageSeed> messages) {
    final channelId = _state.activeChannelId;
    if (channelId == null) {
      return;
    }
    _serverMessagesByChannel[channelId] = messages;
    final activeServerId = _state.activeServer?.id;
    if (activeServerId == null) {
      return;
    }
    final cached = _cachedServerWorkspaceByServerId[activeServerId];
    if (cached != null && cached.activeChannelId == channelId) {
      _cachedServerWorkspaceByServerId[activeServerId] = (
        settings: cached.settings,
        currentUser: cached.currentUser,
        currentUserMedia: cached.currentUserMedia,
        activeChannelId: cached.activeChannelId,
        messages: messages,
        activity: cached.activity,
      );
    }
  }

  void _cacheServerWorkspaceSnapshot({
    required String? serverId,
    required ServerSettingsData? settings,
    required VerdantUser? currentUser,
    required ServerSettingsCurrentUserMedia? currentUserMedia,
    required String activeChannelId,
    required List<MessageSeed> messages,
    required ({bool available, List<MemberSeed> members}) activity,
  }) {
    if (serverId == null || settings == null || currentUser == null) {
      return;
    }
    _cachedServerWorkspaceByServerId[serverId] = (
      settings: settings,
      currentUser: currentUser,
      currentUserMedia: currentUserMedia,
      activeChannelId: activeChannelId,
      messages: messages,
      activity: activity,
    );
  }

  bool _hasMoreMessagePage(List<MessageSeed> messages) {
    return messages.length >= _messagePageSize;
  }

  List<MessageSeed> _mergeMessagePages(
    List<MessageSeed> older,
    List<MessageSeed> newer,
  ) {
    final byId = <String, MessageSeed>{};
    for (final message in older) {
      byId[message.id] = message;
    }
    for (final message in newer) {
      byId[message.id] = message;
    }
    return byId.values.toList(growable: false);
  }

  void _clearServerChannelCaches() {
    _serverWorkspaceByServerId.clear();
    _cachedServerWorkspaceByServerId.clear();
    _clearServerChannelDataCaches();
  }

  void _clearServerChannelDataCaches() {
    _serverMessagesByChannel.clear();
    _channelActivityByChannel.clear();
  }

  Future<({bool available, List<MemberSeed> members})> _loadChannelActivity(
    String? channelId,
  ) async {
    if (channelId == null ||
        repository is! ServerSettingsChannelActivityRepository) {
      diagnostics.record('workspace.activity.load.result', {
        'status': 'unavailable',
        'reason': channelId == null ? 'no_channel' : 'unsupported_repository',
        'ms': 0,
        'memberCount': 0,
      });
      return (available: false, members: const <MemberSeed>[]);
    }
    final cached = _channelActivityByChannel[channelId];
    if (cached != null) {
      diagnostics.record('workspace.activity.load.result', {
        'networkId': session.networkId,
        'status': 'ok',
        'source': 'cache',
        'ms': 0,
        'memberCount': cached.members.length,
      });
      return cached;
    }
    final activityRepository =
        repository as ServerSettingsChannelActivityRepository;
    final watch = Stopwatch()..start();
    diagnostics.record('workspace.activity.load.start', {
      'networkId': session.networkId,
    });
    try {
      final members = await activityRepository.loadChannelActivity(
        channelId: channelId,
      );
      diagnostics.record('workspace.activity.load.result', {
        'networkId': session.networkId,
        'status': 'ok',
        'ms': watch.elapsedMilliseconds,
        'memberCount': members.length,
      });
      return (available: true, members: members);
    } catch (_) {
      diagnostics.record('workspace.activity.load.result', {
        'networkId': session.networkId,
        'status': 'failed',
        'ms': watch.elapsedMilliseconds,
        'memberCount': 0,
      });
      return (available: true, members: const <MemberSeed>[]);
    }
  }

  Future<({bool available, List<MemberSeed> members})>
  _loadChannelActivityForSettings(
    String? channelId,
    ServerSettingsData? settings,
  ) async {
    final watch = Stopwatch()..start();
    final activity = await _loadChannelActivity(channelId);
    if (!activity.available || settings == null || activity.members.isEmpty) {
      diagnostics.record('workspace.activity.enrich.result', {
        'networkId': settings?.networkId ?? session.networkId,
        'status': activity.available ? 'skipped' : 'unavailable',
        'ms': watch.elapsedMilliseconds,
        'memberCount': activity.members.length,
        'reason': settings == null
            ? 'no_settings'
            : activity.members.isEmpty
            ? 'no_members'
            : 'activity_unavailable',
      });
      return activity;
    }
    final localEnrichWatch = Stopwatch()..start();
    final enriched = _enrichChannelActivityMembers(activity.members, settings);
    localEnrichWatch.stop();
    diagnostics.record('workspace.activity.enrich.result', {
      'networkId': settings.networkId,
      'status': 'ok',
      'ms': watch.elapsedMilliseconds,
      'localEnrichMs': localEnrichWatch.elapsedMilliseconds,
      'memberCount': activity.members.length,
      'hydratedMemberCount': enriched.length,
    });
    return (available: true, members: enriched);
  }

  List<MemberSeed> _enrichChannelActivityMembers(
    List<MemberSeed> activityMembers,
    ServerSettingsData settings,
  ) {
    final knownMembersByLocalId = <String, ServerSettingsListItemSeed>{};
    for (final member in settings.members) {
      final userId = member.userId;
      if (userId == null) {
        continue;
      }
      final localId = _safeLocalUserId(userId);
      if (localId != null) {
        knownMembersByLocalId[localId] = member;
      }
    }
    if (knownMembersByLocalId.isEmpty) {
      return activityMembers;
    }
    var matchCount = 0;
    var mediaCount = 0;
    return [
      for (final member in activityMembers)
        () {
          final memberLocalId = _localIdForNetworkMember(
            member.id,
            settings.networkId,
          );
          final knownMember = memberLocalId == null
              ? null
              : knownMembersByLocalId[memberLocalId];
          if (knownMember != null) {
            matchCount += 1;
            if (knownMember.avatarUrl != null ||
                knownMember.bannerUrl != null ||
                knownMember.memberListBannerUrl != null) {
              mediaCount += 1;
            }
          }
          final next = _enrichChannelActivityMember(
            member,
            knownMember,
            settings,
          );
          if (member == activityMembers.last) {
            diagnostics.record('workspace.activity.known_media.result', {
              'networkId': settings.networkId,
              'memberCount': activityMembers.length,
              'knownMemberCount': knownMembersByLocalId.length,
              'matchCount': matchCount,
              'mediaCount': mediaCount,
            });
          }
          return next;
        }(),
    ];
  }

  MemberSeed _enrichChannelActivityMember(
    MemberSeed member,
    ServerSettingsListItemSeed? knownMember,
    ServerSettingsData settings,
  ) {
    final currentUserScopedId = _safeScopedUserId(
      session.networkId,
      _currentUser.id,
    );
    final currentUserLocalId = _safeLocalUserId(_currentUser.id);
    final memberLocalId = _localIdForNetworkMember(
      member.id,
      settings.networkId,
    );
    final isCurrentUser =
        currentUserScopedId != null &&
        currentUserLocalId != null &&
        memberLocalId == currentUserLocalId &&
        (member.id == null ||
            !member.id!.contains('/') ||
            sameScopedWorkspaceId(member.id!, currentUserScopedId));
    if (knownMember == null && !isCurrentUser) {
      return member;
    }
    final roleIds = member.roleIds.isNotEmpty
        ? member.roleIds
        : knownMember?.roleIds ?? const <String>[];
    return member.copyWith(
      role: _roleLabelForIds(roleIds, settings.roles, fallback: member.role),
      roleIds: roleIds,
      displayColor:
          member.displayColor ??
          knownMember?.accent ??
          _roleAccentForIds(roleIds, settings.roles),
      nameColorName: _nameColorRoleForIds(roleIds, settings.roles)?.title,
      avatarUrl:
          member.avatarUrl ??
          knownMember?.avatarUrl ??
          (isCurrentUser ? _currentUser.avatarUrl : null),
      bannerUrl:
          member.bannerUrl ??
          knownMember?.bannerUrl ??
          (isCurrentUser ? _currentUser.bannerUrl : null),
      bannerBaseColor:
          member.bannerBaseColor ??
          knownMember?.bannerBaseColor ??
          (isCurrentUser ? _currentUserBannerBaseColor() : null),
      bannerCrop: member.bannerCrop ?? knownMember?.bannerCrop,
      memberListBannerUrl:
          member.memberListBannerUrl ??
          knownMember?.memberListBannerUrl ??
          (isCurrentUser ? _currentUser.memberListBannerUrl : null),
      memberListBannerCrop:
          member.memberListBannerCrop ?? knownMember?.memberListBannerCrop,
      originIdentity: member.originIdentity ?? knownMember?.originIdentity,
    );
  }

  String? _localIdForNetworkMember(String? rawId, String networkId) {
    final memberId = rawId?.trim();
    if (memberId == null || memberId.isEmpty) {
      return null;
    }
    if (memberId.contains('/') &&
        !_scopedIdBelongsToNetwork(memberId, networkId)) {
      return null;
    }
    return _safeLocalUserId(memberId);
  }

  bool _scopedIdBelongsToNetwork(String scopedId, String networkId) {
    final network = _safeWorkspaceNetworkIdOrNull(networkId);
    if (network == null) {
      return false;
    }
    final slash = scopedId.indexOf('/');
    if (slash <= 0 || slash == scopedId.length - 1) {
      return false;
    }
    return sameWorkspaceNetworkId(scopedId.substring(0, slash), network) &&
        scopedId.indexOf('/', slash + 1) < 0;
  }

  void _replaceActiveChannelMember(MemberSeed member) {
    final memberId = member.id;
    if (memberId == null || _state.activeChannelMembers.isEmpty) {
      return;
    }
    var replaced = false;
    final nextMembers = [
      for (final existing in _state.activeChannelMembers)
        if (existing.id != null &&
            sameScopedWorkspaceId(existing.id!, memberId)) ...[
          () {
            replaced = true;
            return member;
          }(),
        ] else
          existing,
    ];
    if (replaced) {
      _setState(_state.copyWith(activeChannelMembers: nextMembers));
    }
  }

  List<MemberSeed> _enrichChannelActivityMembersWithMessages(
    List<MemberSeed> members,
    List<MessageSeed> messages,
    ServerSettingsData? settings,
  ) {
    if (settings == null || members.isEmpty || messages.isEmpty) {
      return members;
    }
    final messagesByLocalAuthorId = <String, MessageSeed>{};
    for (final message in messages.reversed) {
      if (message.avatarUrl == null && message.authorColor == null) {
        continue;
      }
      final localAuthorId = _safeLocalUserId(message.authorId);
      if (localAuthorId != null) {
        messagesByLocalAuthorId.putIfAbsent(localAuthorId, () => message);
      }
    }
    if (messagesByLocalAuthorId.isEmpty) {
      return members;
    }
    var matchCount = 0;
    var fillCount = 0;
    final enriched = [
      for (final member in members)
        () {
          final message =
              messagesByLocalAuthorId[_safeLocalUserId(member.id ?? '')];
          if (message != null) {
            matchCount += 1;
          }
          final next = _enrichChannelActivityMemberWithMessage(
            member,
            message,
            settings,
          );
          if (member.avatarUrl == null && next.avatarUrl != null) {
            fillCount += 1;
          }
          return next;
        }(),
    ];
    diagnostics.record('workspace.activity.message_media.result', {
      'networkId': settings.networkId,
      'memberCount': members.length,
      'messageMediaCandidateCount': messagesByLocalAuthorId.length,
      'matchCount': matchCount,
      'fillCount': fillCount,
    });
    return enriched;
  }

  MemberSeed _enrichChannelActivityMemberWithMessage(
    MemberSeed member,
    MessageSeed? message,
    ServerSettingsData settings,
  ) {
    if (message == null ||
        member.id == null ||
        !_scopedIdBelongsToNetwork(member.id!, settings.networkId)) {
      return member;
    }
    return member.copyWith(
      displayColor: member.displayColor ?? message.authorColor,
      avatarUrl: member.avatarUrl ?? message.avatarUrl,
    );
  }

  List<MessageSeed> _applyReactionAdd(
    List<MessageSeed> messages,
    DirectMessagesReactionAddEvent event,
  ) {
    final currentLocalUserId = _safeLocalUserId(_currentUser.id);
    return applyServerReactionAdd(
      messages,
      messageId: event.messageId,
      emoji: event.emoji,
      emojiId: event.emojiId,
      currentLocalUserId: currentLocalUserId,
      eventLocalUserId: event.localUserId,
    );
  }

  List<MessageSeed> _applyReactionRemove(
    List<MessageSeed> messages,
    DirectMessagesReactionRemoveEvent event,
  ) {
    final currentLocalUserId = _safeLocalUserId(_currentUser.id);
    return applyServerReactionRemove(
      messages,
      messageId: event.messageId,
      emoji: event.emoji,
      currentLocalUserId: currentLocalUserId,
      eventLocalUserId: event.localUserId,
    );
  }

  Future<
    ({
      ServerSettingsData settings,
      VerdantUser currentUser,
      ServerSettingsCurrentUserMedia? currentUserMedia,
      String source,
    })
  >
  _loadServerSettingsWithCurrentUserMedia(
    ServerSettingsRepository repository,
    ServerSettingsServer server, {
    required String mode,
  }) async {
    final watch = Stopwatch()..start();
    diagnostics.record('workspace.settings.load.start', {
      'networkId': session.networkId,
      'mode': mode,
      'server': _diagnosticFingerprint(server.id),
    });
    try {
      if (repository is ServerWorkspaceBootstrapRepository) {
        final bootstrapWatch = Stopwatch()..start();
        diagnostics.record('workspace.bootstrap.batch.start', {
          'networkId': session.networkId,
          'mode': mode,
          'server': _diagnosticFingerprint(server.id),
        });
        final bootstrap =
            await (repository as ServerWorkspaceBootstrapRepository)
                .loadServerWorkspaceBootstrap(
                  server,
                  currentUserId: session.user.id,
                  messageLimit: _messagePageSize,
                );
        if (bootstrap != null) {
          final rawCurrentUserMedia = bootstrap.currentUserMedia;
          final preferredStatus = await _loadPreferredCurrentUserStatus(
            rawCurrentUserMedia,
          );
          final currentUser = _effectiveCurrentUser(
            rawCurrentUserMedia,
            preferredStatus: preferredStatus,
          );
          final currentUserMedia = _effectiveCurrentUserMedia(
            rawCurrentUserMedia,
            currentUser.status,
          );
          final hydratedSettings = _withCurrentUserMedia(
            bootstrap.settings,
            currentUserMedia,
          );
          final activeChannelId =
              bootstrap.activeChannelId ??
              _defaultTextChannelId(hydratedSettings);
          _cacheServerChannelData(
            activeChannelId,
            messages: bootstrap.messages,
            activity: bootstrap.activity,
          );
          diagnostics.record('workspace.bootstrap.batch.result', {
            'networkId': session.networkId,
            'mode': mode,
            'status': 'ok',
            'server': _diagnosticFingerprint(server.id),
            'ms': bootstrapWatch.elapsedMilliseconds,
            'channelCount': hydratedSettings.channels.length,
            'memberCount': hydratedSettings.members.length,
            'messageCount': bootstrap.messages.length,
            'activityAvailable': bootstrap.activity.available,
            'activityMemberCount': bootstrap.activity.members.length,
            'activeChannel': activeChannelId != null,
          });
          diagnostics.record('workspace.settings.load.result', {
            'networkId': session.networkId,
            'mode': mode,
            'status': 'ok',
            'source': 'batch',
            'server': _diagnosticFingerprint(server.id),
            'ms': watch.elapsedMilliseconds,
            'channelCount': hydratedSettings.channels.length,
            'roleCount': hydratedSettings.roles.length,
            'memberCount': hydratedSettings.members.length,
            'feedCount': hydratedSettings.feeds.length,
            'botCount': hydratedSettings.bots.length,
            'emojiCount': hydratedSettings.emojis.length,
            'stickerCount': hydratedSettings.stickers.length,
            'hasCurrentUserMedia': currentUserMedia != null,
            'hasCurrentUserAvatar': currentUserMedia?.avatarUrl != null,
            'hasCurrentUserBanner': currentUserMedia?.bannerUrl != null,
            'hasCurrentUserMemberListBanner':
                currentUserMedia?.memberListBannerUrl != null,
          });
          return (
            settings: hydratedSettings,
            currentUser: currentUser,
            currentUserMedia: currentUserMedia,
            source: 'batch',
          );
        }
        diagnostics.record('workspace.bootstrap.batch.result', {
          'networkId': session.networkId,
          'mode': mode,
          'status': 'fallback',
          'reason': 'unsupported',
          'server': _diagnosticFingerprint(server.id),
          'ms': bootstrapWatch.elapsedMilliseconds,
        });
      }
      final settingsFuture = repository.loadServerSettings(server);
      final rawCurrentUserMediaFuture = _loadCurrentUserMediaOrNull(repository);
      final settings = await settingsFuture;
      final rawCurrentUserMedia = await rawCurrentUserMediaFuture;
      final preferredStatus = await _loadPreferredCurrentUserStatus(
        rawCurrentUserMedia,
      );
      final currentUser = _effectiveCurrentUser(
        rawCurrentUserMedia,
        preferredStatus: preferredStatus,
      );
      final currentUserMedia = _effectiveCurrentUserMedia(
        rawCurrentUserMedia,
        currentUser.status,
      );
      final hydratedSettings = _withCurrentUserMedia(
        settings,
        currentUserMedia,
      );
      diagnostics.record('workspace.settings.load.result', {
        'networkId': session.networkId,
        'mode': mode,
        'status': 'ok',
        'source': 'fanout',
        'server': _diagnosticFingerprint(server.id),
        'ms': watch.elapsedMilliseconds,
        'channelCount': hydratedSettings.channels.length,
        'roleCount': hydratedSettings.roles.length,
        'memberCount': hydratedSettings.members.length,
        'feedCount': hydratedSettings.feeds.length,
        'botCount': hydratedSettings.bots.length,
        'emojiCount': hydratedSettings.emojis.length,
        'stickerCount': hydratedSettings.stickers.length,
        'hasCurrentUserMedia': currentUserMedia != null,
        'hasCurrentUserAvatar': currentUserMedia?.avatarUrl != null,
        'hasCurrentUserBanner': currentUserMedia?.bannerUrl != null,
        'hasCurrentUserMemberListBanner':
            currentUserMedia?.memberListBannerUrl != null,
      });
      return (
        settings: hydratedSettings,
        currentUser: currentUser,
        currentUserMedia: currentUserMedia,
        source: 'fanout',
      );
    } on ServerSettingsException catch (error) {
      diagnostics.record('workspace.settings.load.result', {
        'networkId': session.networkId,
        'mode': mode,
        'status': 'failed',
        'server': _diagnosticFingerprint(server.id),
        'ms': watch.elapsedMilliseconds,
        'errorKind': _messageLoadErrorKind(
          error.message,
          isAuthExpired: error.isAuthExpired,
        ),
      });
      rethrow;
    } catch (error) {
      diagnostics.record('workspace.settings.load.result', {
        'networkId': session.networkId,
        'mode': mode,
        'status': 'failed',
        'server': _diagnosticFingerprint(server.id),
        'ms': watch.elapsedMilliseconds,
        'errorType': error.runtimeType.toString(),
      });
      rethrow;
    }
  }

  Future<String?> _loadPreferredCurrentUserStatus(
    ServerSettingsCurrentUserMedia? currentUserMedia,
  ) {
    final profile = currentUserMedia;
    final userId = profile != null && _safeLocalUserId(profile.id) != null
        ? profile.id
        : session.user.id;
    return directMessagesPreferences.loadCurrentUserStatus(
      networkId: session.networkId,
      userId: userId,
    );
  }

  Future<ServerSettingsCurrentUserMedia?> _loadCurrentUserMediaOrNull(
    ServerSettingsRepository repository,
  ) async {
    if (repository is! ServerSettingsCurrentUserMediaRepository) {
      return null;
    }
    final currentUserMediaRepository =
        repository as ServerSettingsCurrentUserMediaRepository;
    try {
      return await currentUserMediaRepository.loadCurrentUserMedia();
    } catch (_) {
      return null;
    }
  }

  ServerSettingsData _withCurrentUserMedia(
    ServerSettingsData settings,
    ServerSettingsCurrentUserMedia? currentUserMedia,
  ) {
    if (currentUserMedia == null) {
      return settings;
    }
    final profileLocalId = _safeLocalUserId(currentUserMedia.id);
    if (profileLocalId == null) {
      return settings;
    }

    var changed = false;
    final members = [
      for (final member in settings.members)
        if (_safeLocalUserId(member.userId ?? '') == profileLocalId)
          _memberWithCurrentUserMedia(member, currentUserMedia, () {
            changed = true;
          })
        else
          member,
    ];
    return changed ? settings.copyWith(members: members) : settings;
  }

  VerdantUser _effectiveCurrentUser(
    ServerSettingsCurrentUserMedia? currentUserMedia, {
    String? preferredStatus,
  }) {
    final profile = currentUserMedia;
    if (profile == null || _safeLocalUserId(profile.id) == null) {
      final status = _effectiveCurrentUserPresenceStatus(
        null,
        session.user.status,
        preferredStatus: preferredStatus,
      );
      return session.user.copyWith(status: status);
    }
    final current = session.user.copyWith(
      id: profile.id,
      username: profile.username ?? session.user.username,
      displayName: profile.displayName ?? session.user.displayName,
      email: profile.email ?? session.user.email,
      status: _effectiveCurrentUserPresenceStatus(
        profile.status,
        session.user.status,
        preferredStatus: preferredStatus,
      ),
      usernameSet: profile.usernameSet ?? session.user.usernameSet,
      emailVerified: profile.emailVerified ?? session.user.emailVerified,
      totpEnabled: profile.totpEnabled ?? session.user.totpEnabled,
      avatarUrl: profile.avatarUrl ?? session.user.avatarUrl,
      bannerUrl: profile.bannerUrl ?? session.user.bannerUrl,
      bannerBaseColor:
          _colorHex(profile.bannerBaseColor) ?? session.user.bannerBaseColor,
      memberListBannerUrl:
          profile.memberListBannerUrl ?? session.user.memberListBannerUrl,
      bio: profile.bio ?? session.user.bio,
    );
    final changed =
        _safeLocalUserId(session.user.id) != _safeLocalUserId(current.id);
    if (changed) {
      diagnostics.record('workspace.current_user.reconciled', {
        'networkId': session.networkId,
        'changed': true,
      });
    }
    return current;
  }

  ServerSettingsCurrentUserMedia? _effectiveCurrentUserMedia(
    ServerSettingsCurrentUserMedia? currentUserMedia,
    String effectiveStatus,
  ) {
    final profile = currentUserMedia;
    if (profile == null || _safeLocalUserId(profile.id) == null) {
      return profile;
    }
    return profile.copyWith(status: effectiveStatus);
  }

  Color? _currentUserBannerBaseColor() {
    return _profileHexColor(_currentUser.bannerBaseColor);
  }

  ServerSettingsListItemSeed _memberWithCurrentUserMedia(
    ServerSettingsListItemSeed member,
    ServerSettingsCurrentUserMedia currentUserMedia,
    void Function() markChanged,
  ) {
    markChanged();
    return ServerSettingsListItemSeed(
      title: member.title,
      subtitle: member.subtitle,
      trailing: member.trailing,
      accent: member.accent,
      id: member.id,
      userId: member.userId,
      roleIds: member.roleIds,
      permissions: member.permissions,
      position: member.position,
      colorOnly: member.colorOnly,
      avatarUrl: currentUserMedia.avatarUrl,
      bannerUrl: currentUserMedia.bannerUrl,
      bannerBaseColor: currentUserMedia.bannerBaseColor,
      bannerCrop: currentUserMedia.bannerCrop,
      memberListBannerUrl: currentUserMedia.memberListBannerUrl,
      memberListBannerCrop: currentUserMedia.memberListBannerCrop,
      originIdentity: member.originIdentity,
    );
  }

  String? _safeLocalUserId(String rawId) {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final slash = trimmed.indexOf('/');
    final localId = slash >= 0 ? trimmed.substring(slash + 1) : trimmed;
    try {
      return safeWorkspaceLocalId(localId);
    } on FormatException {
      return null;
    }
  }

  String? _safeScopedUserId(String networkId, String rawUserId) {
    final network = _safeWorkspaceNetworkIdOrNull(networkId);
    if (network == null) {
      return null;
    }
    final raw = rawUserId.trim();
    if (raw.isEmpty) {
      return null;
    }
    final slash = raw.indexOf('/');
    try {
      if (slash >= 0) {
        if (slash == 0 ||
            slash == raw.length - 1 ||
            raw.indexOf('/', slash + 1) >= 0 ||
            !sameWorkspaceNetworkId(raw.substring(0, slash), network)) {
          return null;
        }
        return '$network/${safeWorkspaceLocalId(raw.substring(slash + 1))}';
      }
      return '$network/${safeWorkspaceLocalId(raw)}';
    } on FormatException {
      return null;
    }
  }

  MemberProfileProjection get _memberProfileProjection {
    return MemberProfileProjection(
      currentUser: _currentUser,
      networkId: session.networkId,
      memberMatchesUser: _memberMatchesUser,
      settingsMemberMatchesUser: _settingsMemberMatchesUser,
      safeScopedUserId: _safeScopedUserId,
      safeLocalUserId: _safeLocalUserId,
    );
  }

  String _messageLoadErrorKind(String message, {required bool isAuthExpired}) {
    if (isAuthExpired) {
      return 'auth';
    }
    final normalized = message.toLowerCase();
    if (normalized.contains('too many') || normalized.contains('rate')) {
      return 'rate_limited';
    }
    if (_isHiddenChannelAccessError(message) ||
        normalized.contains('unauthorized') ||
        normalized.contains('permission') ||
        normalized.contains('forbidden')) {
      return 'auth';
    }
    return 'transport';
  }

  bool _isHiddenChannelAccessError(String message) {
    final normalized = message.toLowerCase();
    return (normalized.contains("channel doesn't exist") &&
            normalized.contains('access')) ||
        (normalized.contains('channel does not exist') &&
            normalized.contains('access')) ||
        normalized.contains('channel not found') ||
        normalized.contains('server not found') ||
        normalized.contains('server was not found') ||
        normalized.contains("don't have access") ||
        normalized.contains('do not have access') ||
        normalized.contains('not have permission') ||
        normalized.contains('forbidden');
  }

  String? _diagnosticFingerprint(String? value) {
    if (value == null) {
      return null;
    }
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  List<String> _serverIdPreview(Iterable<String> serverIds) {
    return serverIds.take(24).toList(growable: false);
  }

  bool _sameSessionLocalId(String left, String right) {
    final leftLocal = _safeLocalUserId(left);
    final rightLocal = _safeLocalUserId(right);
    return leftLocal != null && rightLocal != null && leftLocal == rightLocal;
  }

  String? _localWorkspaceId(String rawId) {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final slash = trimmed.indexOf('/');
    final localId = slash >= 0 ? trimmed.substring(slash + 1) : trimmed;
    try {
      return safeWorkspaceLocalId(localId);
    } on FormatException {
      return null;
    }
  }

  String? _safeWorkspaceNetworkIdOrNull(String networkId) {
    final trimmed = networkId.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed.contains('\\') ||
        trimmed.contains(RegExp(r'\s')) ||
        _containsControlCharacter(trimmed)) {
      return null;
    }
    return trimmed;
  }

  String? _defaultTextChannelId(ServerSettingsData settings) {
    for (final channel in settings.channels) {
      if (channel.type == 0) {
        return channel.id;
      }
    }
    return null;
  }

  void replaceActiveServer(ServerSettingsServer server) {
    final settings = _state.settings;
    final servers = [
      for (final existing in _state.servers)
        existing.id == server.id ? server : existing,
    ];
    _setState(
      _state.copyWith(
        servers: servers,
        activeServer: server,
        settings: settings?.copyWith(server: server),
      ),
    );
  }

  void _setState(WorkspaceState next) {
    _state = next;
    notifyListeners();
  }

  void _connectDirectMessagesRealtime({bool force = false}) {
    final repository = directMessagesRepository;
    if (repository == null) {
      return;
    }
    if (_directMessagesRealtime != null && !force) {
      return;
    }
    unawaited(_directMessagesRealtime?.cancel());
    final currentUser = _currentUser;
    StreamSubscription<DirectMessagesRealtimeEvent>? subscription;
    subscription = repository
        .connectRealtime(
          currentUserId: currentUser.id,
          currentUserName: currentUser.displayLabel,
          currentUserInitials: currentUser.initials,
          currentUserStatus:
              _state.currentUserMedia?.status ?? currentUser.status,
        )
        .listen(
          (event) => unawaited(_applyDirectMessagesRealtimeEvent(event)),
          onError: (Object error) {
            unawaited(_handleDirectMessagesRealtimeError(error));
          },
          onDone: () {
            if (identical(_directMessagesRealtime, subscription)) {
              _directMessagesRealtime = null;
            }
          },
        );
    _directMessagesRealtime = subscription;
  }

  Future<void> _handleDirectMessagesRealtimeError(Object error) async {
    final reason = error is DirectMessagesException
        ? error.message
        : 'Realtime session failed';
    _recordDirectMessagesRealtimeDiagnostic('error', {
      'networkId': session.networkId,
      'reason': reason,
    });
    if (!_isHiddenChannelAccessError(reason)) {
      return;
    }
    _recordDirectMessagesRealtimeDiagnostic('access_denied', {
      'networkId': session.networkId,
      'activeServer': _diagnosticFingerprint(_state.activeServer?.id),
    });
    diagnostics.record('workspace.realtime.access_denied', {
      'networkId': session.networkId,
      'activeServer': _diagnosticFingerprint(_state.activeServer?.id),
      'errorKind': _messageLoadErrorKind(reason, isAuthExpired: false),
    });
    await _reconcileActiveServerMembership(
      source: 'realtime_error',
      errorMessage: 'You no longer have access to this server',
    );
  }

  void _disconnectDirectMessagesRealtime() {
    unawaited(_directMessagesRealtime?.cancel());
    _directMessagesRealtime = null;
  }

  WorkspaceRealtimeCommandSink? get _realtimeCommandSink {
    final repository = directMessagesRepository;
    if (repository is WorkspaceRealtimeCommandSink) {
      return repository as WorkspaceRealtimeCommandSink;
    }
    return null;
  }

  void _syncRealtimeFocus() {
    final commandSink = _realtimeCommandSink;
    if (commandSink == null) {
      return;
    }
    final serverId = _state.activeServer?.id;
    if (serverId != null) {
      _sendRealtimeFocusCommand(commandSink.focusServer(serverId: serverId));
    }
    _sendRealtimeFocusCommand(
      commandSink.focusChannel(channelId: _state.activeChannelId),
    );
  }

  void _focusRealtimeChannel(String? channelId) {
    final commandSink = _realtimeCommandSink;
    if (commandSink == null) {
      return;
    }
    _sendRealtimeFocusCommand(commandSink.focusChannel(channelId: channelId));
  }

  void _sendRealtimeFocusCommand(Future<void> command) {
    unawaited(
      command.catchError((Object error) {
        _recordDirectMessagesRealtimeDiagnostic('focus_error', {
          'networkId': session.networkId,
          'reason': error is DirectMessagesException
              ? error.message
              : 'Realtime focus failed',
        });
      }),
    );
  }

  Future<void> _applyDirectMessagesRealtimeEvent(
    DirectMessagesRealtimeEvent event,
  ) async {
    switch (event) {
      case DirectMessagesSnapshotEvent():
        final scopedData = _directMessagesDataForSession(event.data);
        _restoreHiddenDmPreferencesFromSnapshot(
          scopedData,
          source: 'realtime_ready',
        );
        final directMessages = _directMessagesStore.replaceSnapshot(scopedData);
        final activeConversation = _state.activeDmConversation == null
            ? null
            : _directMessagesStore.conversationFor(
                    _state.activeDmConversation!.channelId,
                  ) ??
                  _state.activeDmConversation;
        _setState(
          _state.copyWith(
            directMessages: directMessages,
            entitlements: directMessages.entitlements.mergeCapabilityFallback(
              _state.entitlements,
            ),
            activeDmConversation: activeConversation,
          ),
        );
      case DirectMessagesMessageCreateEvent():
        final scopedEventChannelId = _scopedWorkspaceIdForSession(
          event.channelId,
        );
        final channelInSession = scopedEventChannelId != null;
        final isActiveServerChannel = _isActiveServerChannelEvent(
          event.channelId,
        );
        diagnostics.record('workspace.realtime.message_create.route', {
          'networkId': session.networkId,
          'activeChannel': _diagnosticFingerprint(_state.activeChannelId),
          'eventChannel': _diagnosticFingerprint(event.channelId),
          'message': _diagnosticFingerprint(event.message.id),
          'author': _diagnosticFingerprint(event.message.authorId),
          'channelInSession': channelInSession,
          'isActiveServerChannel': isActiveServerChannel,
          'isOwnMessage': event.message.isOwnMessage,
        });
        if (!channelInSession) {
          return;
        }
        if (isActiveServerChannel) {
          _applyServerRealtimeMessage(event.message);
          return;
        }
        final directMessages = _directMessagesStore.applyRealtimeMessage(
          channelId: scopedEventChannelId,
          message: event.message,
        );
        final isActiveDmChannel = _isActiveDmChannel(scopedEventChannelId);
        diagnostics.record('workspace.dm.message_create.route', {
          'networkId': session.networkId,
          'channel': _diagnosticFingerprint(scopedEventChannelId),
          'activeChannel': _diagnosticFingerprint(
            _state.activeDmConversation?.channelId,
          ),
          'isActiveDmChannel': isActiveDmChannel,
        });
        final activeConversation = isActiveDmChannel
            ? _directMessagesStore.conversationFor(scopedEventChannelId)
            : _state.activeDmConversation;
        final activeMessages = isActiveDmChannel
            ? _directMessagesStore.messagesFor(scopedEventChannelId)
            : _state.dmMessages;
        _setState(
          _state.copyWith(
            directMessages: directMessages,
            activeDmConversation: activeConversation,
            dmMessages: activeMessages,
          ),
        );
        await _saveHiddenDmPreferences();
      case DirectMessagesMessageUpdateEvent():
        final scopedEventChannelId = _scopedWorkspaceIdForSession(
          event.channelId,
        );
        if (scopedEventChannelId == null) {
          return;
        }
        if (_isActiveServerChannelEvent(event.channelId)) {
          _applyServerRealtimeMessageUpdate(event.message);
          return;
        }
        final directMessages = _directMessagesStore.applyRealtimeMessageUpdate(
          channelId: scopedEventChannelId,
          message: event.message,
        );
        _setState(
          _state.copyWith(
            directMessages: directMessages,
            activeDmConversation: _isActiveDmChannel(scopedEventChannelId)
                ? _directMessagesStore.conversationFor(scopedEventChannelId)
                : _state.activeDmConversation,
            dmMessages: _isActiveDmChannel(scopedEventChannelId)
                ? _directMessagesStore.messagesFor(scopedEventChannelId)
                : _state.dmMessages,
          ),
        );
      case DirectMessagesMessageDeleteEvent():
        final scopedEventChannelId = _scopedWorkspaceIdForSession(
          event.channelId,
        );
        if (scopedEventChannelId == null) {
          return;
        }
        if (_isActiveServerChannelEvent(event.channelId)) {
          _applyServerRealtimeMessageDelete(event.messageId);
          return;
        }
        final directMessages = _directMessagesStore.applyRealtimeMessageDelete(
          channelId: scopedEventChannelId,
          messageId: event.messageId,
        );
        _setState(
          _state.copyWith(
            directMessages: directMessages,
            activeDmConversation: _isActiveDmChannel(scopedEventChannelId)
                ? _directMessagesStore.conversationFor(scopedEventChannelId)
                : _state.activeDmConversation,
            dmMessages: _isActiveDmChannel(scopedEventChannelId)
                ? _directMessagesStore.messagesFor(scopedEventChannelId)
                : _state.dmMessages,
          ),
        );
      case DirectMessagesReactionAddEvent():
        if (_isActiveServerChannelEvent(event.channelId)) {
          _applyServerRealtimeReactionAdd(event);
        }
      case DirectMessagesReactionRemoveEvent():
        if (_isActiveServerChannelEvent(event.channelId)) {
          _applyServerRealtimeReactionRemove(event);
        }
      case DirectMessagesPresenceUpdateEvent():
        final directMessages = _directMessagesStore.applyPresenceUpdate(
          networkId: session.networkId,
          localUserId: event.localUserId,
          status: event.status,
          currentUserId: _currentUser.id,
        );
        final presence = _applyServerRealtimePresence(
          localUserId: event.localUserId,
          status: event.status,
        );
        final activeConversation = _state.activeDmConversation == null
            ? null
            : _directMessagesStore.conversationFor(
                _state.activeDmConversation!.channelId,
              );
        _setState(
          _state.copyWith(
            settings: presence.settings,
            activeChannelMembers: presence.activeChannelMembers,
            activeTypingMembers: presence.activeTypingMembers,
            directMessages: directMessages,
            activeDmConversation: activeConversation,
          ),
        );
      case DirectMessagesBotPresenceUpdateEvent():
        _applyServerRealtimeBotPresence(event);
      case DirectMessagesUserProfileUpdateEvent():
        _applyServerRealtimeUserProfileUpdate(event);
      case DirectMessagesChannelActivityEvent():
        if (_isActiveServerChannelEvent(event.channelId)) {
          _applyServerRealtimeChannelActivity(event);
        }
      case DirectMessagesChannelUnreadEvent():
        final scopedEventChannelId = _scopedWorkspaceIdForSession(
          event.channelId,
        );
        if (scopedEventChannelId == null) {
          return;
        }
        if (event.isDirectMessage) {
          final directMessages = _directMessagesStore.applyUnreadSignal(
            channelId: scopedEventChannelId,
            mentionsCurrentUser: event.mentionsCurrentUser,
          );
          _setState(_state.copyWith(directMessages: directMessages));
          if (_isActiveDmChannel(scopedEventChannelId)) {
            diagnostics.record('workspace.dm.unread.active_refresh', {
              'networkId': session.networkId,
              'channel': _diagnosticFingerprint(scopedEventChannelId),
            });
            unawaited(refreshActiveDirectMessage());
          }
        } else {
          _applyServerRealtimeUnread(event);
        }
      case DirectMessagesTypingStartEvent():
        if (_isActiveServerChannelEvent(event.channelId)) {
          _applyServerRealtimeTypingStart(event);
        } else {
          _recordDirectMessagesRealtimeDiagnostic('typing_start', {
            'networkId': session.networkId,
            'isActiveChannel': false,
          });
        }
      case DirectMessagesServerChannelUpsertEvent():
        _applyServerRealtimeChannelUpsert(event);
      case DirectMessagesServerChannelDeleteEvent():
        _applyServerRealtimeChannelDelete(event);
      case DirectMessagesServerDeleteEvent():
        diagnostics.record('workspace.realtime.server_delete.received', {
          'networkId': session.networkId,
          'server': _diagnosticFingerprint(event.serverId),
          'activeServer': _diagnosticFingerprint(_state.activeServer?.id),
        });
        await _removeServerFromRealtime(
          event.serverId,
          errorMessage: 'Server is no longer available',
        );
      case DirectMessagesServerMemberUpsertEvent():
        diagnostics.record('workspace.realtime.server_member_upsert.received', {
          'networkId': session.networkId,
          'server': _diagnosticFingerprint(event.serverId),
          'user': _diagnosticFingerprint(event.member.id),
          'status': event.member.status,
          'isActive': event.member.isActive,
          'activeServer': _diagnosticFingerprint(_state.activeServer?.id),
        });
        _applyServerRealtimeMemberUpsert(event);
      case DirectMessagesServerMemberRemoveEvent():
        diagnostics.record('workspace.realtime.server_member_remove.received', {
          'networkId': session.networkId,
          'server': _diagnosticFingerprint(event.serverId),
          'user': _diagnosticFingerprint(event.userId),
          'currentUser': _diagnosticFingerprint(_currentUser.id),
        });
        await _applyServerRealtimeMemberRemove(event);
      case DirectMessagesServerMemberRoleUpdateEvent():
        _applyServerRealtimeMemberRoleUpdate(event);
      case DirectMessagesConversationUpsertEvent():
        final conversation = _dmConversationForSession(event.conversation);
        if (conversation == null) {
          return;
        }
        final directMessages = _directMessagesStore.upsertConversation(
          conversation,
        );
        _setState(
          _state.copyWith(
            directMessages: directMessages,
            activeDmConversation: _isActiveDmChannel(conversation.channelId)
                ? _directMessagesStore.conversationFor(conversation.channelId)
                : _state.activeDmConversation,
          ),
        );
        if (_isActiveDmChannel(conversation.channelId)) {
          diagnostics
              .record('workspace.dm.conversation_upsert.active_refresh', {
                'networkId': session.networkId,
                'channel': _diagnosticFingerprint(conversation.channelId),
              });
          unawaited(refreshActiveDirectMessage());
        }
      case DirectMessagesRelationshipUpsertEvent():
        final friend = _dmFriendForSession(event.friend);
        if (friend == null) {
          return;
        }
        final directMessages = _directMessagesStore.upsertRelationship(friend);
        _setState(_state.copyWith(directMessages: directMessages));
      case DirectMessagesRelationshipRemoveEvent():
        final directMessages = _directMessagesStore.removeRelationship(
          networkId: session.networkId,
          localUserId: event.localUserId,
        );
        _setState(_state.copyWith(directMessages: directMessages));
    }
  }

  bool _isActiveServerChannelEvent(String eventChannelId) {
    final activeChannelId = _state.activeChannelId;
    if (activeChannelId == null) {
      return false;
    }
    final activeScopedChannelId = _scopedWorkspaceIdForSession(activeChannelId);
    final eventScopedChannelId = _scopedWorkspaceIdForSession(eventChannelId);
    return activeScopedChannelId != null &&
        eventScopedChannelId != null &&
        sameScopedWorkspaceId(eventScopedChannelId, activeScopedChannelId);
  }

  bool _isActiveDmChannel(String scopedChannelId) {
    final activeChannelId = _state.activeDmConversation?.channelId;
    return activeChannelId != null &&
        sameScopedWorkspaceId(activeChannelId, scopedChannelId);
  }

  String? _scopedWorkspaceIdForSession(String rawId) {
    return _safeScopedUserId(session.networkId, rawId);
  }

  String? _localWorkspaceIdForSessionEvent(String rawId) {
    final scopedId = _scopedWorkspaceIdForSession(rawId);
    return scopedId == null ? null : _localWorkspaceId(scopedId);
  }

  DmConversationPreviewSeed? _dmConversationForSession(
    DmConversationPreviewSeed conversation,
  ) {
    final scopedChannelId = _scopedWorkspaceIdForSession(
      conversation.channelId,
    );
    final localChannelId = scopedChannelId == null
        ? null
        : _localWorkspaceId(scopedChannelId);
    if (scopedChannelId == null || localChannelId == null) {
      return null;
    }
    final localUserId = conversation.localUserId == null
        ? null
        : _safeLocalUserId(conversation.localUserId!);
    return conversation.copyWith(
      channelId: scopedChannelId,
      localChannelId: localChannelId,
      networkId: session.networkId,
      localUserId: localUserId,
    );
  }

  FriendPreviewSeed? _dmFriendForSession(FriendPreviewSeed friend) {
    final scopedUserId = _scopedWorkspaceIdForSession(friend.id);
    final localUserId =
        _safeLocalUserId(friend.localUserId) ?? _safeLocalUserId(friend.id);
    if (scopedUserId == null || localUserId == null) {
      return null;
    }
    return friend.copyWith(
      id: scopedUserId,
      localUserId: localUserId,
      networkId: session.networkId,
    );
  }

  DirectMessagesWorkspaceData _directMessagesDataForSession(
    DirectMessagesWorkspaceData data,
  ) {
    return data.copyWith(
      networkId: session.networkId,
      hiddenChannelIds: data.hiddenChannelIds == null
          ? null
          : {
              for (final channelId in data.hiddenChannelIds!)
                ?_scopedWorkspaceIdForSession(channelId),
            },
      conversations: [
        for (final conversation in data.conversations)
          ?_dmConversationForSession(conversation),
      ],
      friends: [
        for (final friend in data.friends) ?_dmFriendForSession(friend),
      ],
    );
  }

  void _applyServerRealtimeMessage(MessageSeed message) {
    final messages = upsertServerMessage(_state.serverMessages, message);
    _cacheActiveServerMessages(messages);
    _setState(
      _state.copyWith(
        serverMessages: messages,
        activeChannelMembers: _enrichChannelActivityMembersWithMessages(
          _state.activeChannelMembers,
          [message],
          _state.settings,
        ),
      ),
    );
  }

  void _applyServerRealtimeMessageUpdate(MessageSeed message) {
    final messages = replaceServerMessage(_state.serverMessages, message);
    _cacheActiveServerMessages(messages);
    _setState(_state.copyWith(serverMessages: messages));
  }

  void _applyServerRealtimeMessageDelete(String messageId) {
    final messages = removeServerMessage(_state.serverMessages, messageId);
    _cacheActiveServerMessages(messages);
    _setState(_state.copyWith(serverMessages: messages));
  }

  void _applyServerRealtimeChannelActivity(
    DirectMessagesChannelActivityEvent event,
  ) {
    final scopedUserId = _safeScopedUserId(
      session.networkId,
      event.localUserId,
    );
    if (scopedUserId == null) {
      return;
    }
    final localUserId = _safeLocalUserId(event.localUserId);
    if (localUserId == null) {
      return;
    }
    final settings = _state.settings;
    final knownMember = _settingsMemberForActiveServerUser(
      scopedUserId,
      localUserId,
    );
    final existingMembers = _state.activeChannelMembers;
    var replaced = false;
    final nextMembers = [
      for (final member in existingMembers)
        if (_memberMatchesChannelActivity(
          member,
          scopedUserId: scopedUserId,
          localUserId: event.localUserId,
          displayName: event.displayName,
        )) ...[
          _enrichRealtimeChannelActivityMember(
            member.copyWith(
              id: member.id ?? scopedUserId,
              name: event.displayName ?? knownMember?.title ?? member.name,
              username: knownMember?.username ?? member.username,
              status: _channelActivityStatus(
                existingStatus: member.status,
                knownMember: knownMember,
              ),
              initials: event.displayName == null && knownMember == null
                  ? member.initials
                  : initialsForDisplayName(
                      event.displayName ?? knownMember!.title,
                    ),
              role: knownMember?.trailing ?? member.role,
              roleIds: knownMember?.roleIds ?? member.roleIds,
              displayColor: knownMember?.accent ?? member.displayColor,
              avatarUrl:
                  event.avatarUrl ?? member.avatarUrl ?? knownMember?.avatarUrl,
              bannerUrl: knownMember?.bannerUrl ?? member.bannerUrl,
              bannerBaseColor:
                  knownMember?.bannerBaseColor ?? member.bannerBaseColor,
              bannerCrop: knownMember?.bannerCrop ?? member.bannerCrop,
              memberListBannerUrl:
                  knownMember?.memberListBannerUrl ??
                  member.memberListBannerUrl,
              memberListBannerCrop:
                  knownMember?.memberListBannerCrop ??
                  member.memberListBannerCrop,
              originIdentity:
                  knownMember?.originIdentity ?? member.originIdentity,
              lastMessageAt:
                  event.lastMessageAt ??
                  DateTime.now().toUtc().toIso8601String(),
              isActive: true,
            ),
            knownMember: knownMember,
            settings: settings,
          ),
        ] else
          member,
    ];
    replaced = existingMembers.any(
      (member) => _memberMatchesChannelActivity(
        member,
        scopedUserId: scopedUserId,
        localUserId: event.localUserId,
        displayName: event.displayName,
      ),
    );
    if (!replaced) {
      final displayName =
          event.displayName ?? knownMember?.title ?? localUserId;
      nextMembers.add(
        _enrichRealtimeChannelActivityMember(
          MemberSeed(
            id: scopedUserId,
            name: displayName,
            username: knownMember?.username,
            status: _channelActivityStatus(knownMember: knownMember),
            initials: initialsForDisplayName(displayName),
            role: knownMember?.trailing ?? 'Member',
            roleIds: knownMember?.roleIds ?? const [],
            displayColor: knownMember?.accent,
            avatarUrl: event.avatarUrl ?? knownMember?.avatarUrl,
            bannerUrl: knownMember?.bannerUrl,
            bannerBaseColor: knownMember?.bannerBaseColor,
            bannerCrop: knownMember?.bannerCrop,
            memberListBannerUrl: knownMember?.memberListBannerUrl,
            memberListBannerCrop: knownMember?.memberListBannerCrop,
            originIdentity: knownMember?.originIdentity,
            lastMessageAt:
                event.lastMessageAt ?? DateTime.now().toUtc().toIso8601String(),
            isActive: true,
          ),
          knownMember: knownMember,
          settings: settings,
        ),
      );
    }
    _setState(_state.copyWith(activeChannelMembers: nextMembers));
    diagnostics.record('workspace.channel_activity.apply', {
      'networkId': session.networkId,
      'channel': _diagnosticFingerprint(event.channelId),
      'user': _diagnosticFingerprint(scopedUserId),
      'replacedActiveMember': replaced,
      'knownMember': knownMember != null,
      'activeMemberCount': nextMembers.length,
    });
  }

  _ServerPresenceProjection _applyServerRealtimePresence({
    required String localUserId,
    required String status,
    ServerSettingsData? settingsOverride,
    List<MemberSeed>? activeChannelMembersOverride,
    List<MemberSeed>? activeTypingMembersOverride,
  }) {
    final scopedUserId = _safeScopedUserId(session.networkId, localUserId);
    if (scopedUserId == null) {
      return _ServerPresenceProjection(
        settings: settingsOverride ?? _state.settings,
        activeChannelMembers:
            activeChannelMembersOverride ?? _state.activeChannelMembers,
        activeTypingMembers:
            activeTypingMembersOverride ?? _state.activeTypingMembers,
      );
    }
    final normalized = _normalizeRealtimePresenceStatus(status);
    final isCurrentUser =
        _safeLocalUserId(_currentUser.id) == localUserId.trim();
    final sourceActiveChannelMembers =
        activeChannelMembersOverride ?? _state.activeChannelMembers;
    final activeChannelMembers = [
      for (final member in sourceActiveChannelMembers)
        if (_memberMatchesUser(member, scopedUserId, localUserId))
          member.copyWith(
            id: member.id ?? scopedUserId,
            status: normalized,
            isActive: isCurrentUser
                ? member.isActive
                : !_statusLooksOffline(normalized),
          )
        else
          member,
    ];
    final sourceActiveTypingMembers =
        activeTypingMembersOverride ?? _state.activeTypingMembers;
    final activeTypingMembers = [
      for (final member in sourceActiveTypingMembers)
        if (_memberMatchesUser(member, scopedUserId, localUserId))
          member.copyWith(
            id: member.id ?? scopedUserId,
            status: normalized,
            isActive: !_statusLooksOffline(normalized),
          )
        else
          member,
    ];
    final settings = settingsOverride ?? _state.settings;
    if (settings == null) {
      return _ServerPresenceProjection(
        settings: null,
        activeChannelMembers: activeChannelMembers,
        activeTypingMembers: activeTypingMembers,
      );
    }
    final members = [
      for (final member in settings.members)
        if (_settingsMemberMatchesUser(member, scopedUserId, localUserId))
          ServerSettingsListItemSeed(
            title: member.title,
            subtitle: normalized,
            trailing: member.trailing,
            accent: member.accent,
            id: member.id,
            userId: member.userId,
            roleIds: member.roleIds,
            permissions: member.permissions,
            position: member.position,
            colorOnly: member.colorOnly,
            avatarUrl: member.avatarUrl,
            bannerUrl: member.bannerUrl,
            bannerBaseColor: member.bannerBaseColor,
            bannerCrop: member.bannerCrop,
            memberListBannerUrl: member.memberListBannerUrl,
            memberListBannerCrop: member.memberListBannerCrop,
            originIdentity: member.originIdentity,
          )
        else
          member,
    ];
    return _ServerPresenceProjection(
      settings: settings.copyWith(members: members),
      activeChannelMembers: activeChannelMembers,
      activeTypingMembers: activeTypingMembers,
    );
  }

  void _applyServerRealtimeBotPresence(
    DirectMessagesBotPresenceUpdateEvent event,
  ) {
    final settings = _state.settings;
    if (settings == null || !_serverEventMatchesActive(event.serverId)) {
      return;
    }
    final scopedBotId = _safeScopedUserId(session.networkId, event.localBotId);
    if (scopedBotId == null) {
      return;
    }
    final normalized = _normalizeRealtimePresenceStatus(event.status);
    var changed = false;
    final bots = [
      for (final bot in settings.bots)
        if (_settingsMemberMatchesUser(bot, scopedBotId, event.localBotId)) ...[
          _copyListItemWithTrailing(bot, normalized),
        ] else
          bot,
    ];
    changed = settings.bots.any(
      (bot) => _settingsMemberMatchesUser(bot, scopedBotId, event.localBotId),
    );
    if (!changed) {
      return;
    }
    final activeChannelMembers = [
      for (final member in _state.activeChannelMembers)
        if (_memberMatchesUser(member, scopedBotId, event.localBotId))
          member.copyWith(
            id: member.id ?? scopedBotId,
            status: normalized,
            isActive: !_statusLooksOffline(normalized),
          )
        else
          member,
    ];
    _setState(
      _state.copyWith(
        settings: settings.copyWith(bots: bots),
        activeChannelMembers: activeChannelMembers,
      ),
    );
  }

  ServerSettingsListItemSeed _copyListItemWithTrailing(
    ServerSettingsListItemSeed item,
    String trailing,
  ) {
    return ServerSettingsListItemSeed(
      title: item.title,
      subtitle: item.subtitle,
      trailing: trailing,
      accent: item.accent,
      id: item.id,
      userId: item.userId,
      username: item.username,
      roleIds: item.roleIds,
      permissions: item.permissions,
      position: item.position,
      colorOnly: item.colorOnly,
      showAsSection: item.showAsSection,
      colorPriority: item.colorPriority,
      avatarUrl: item.avatarUrl,
      bannerUrl: item.bannerUrl,
      bannerBaseColor: item.bannerBaseColor,
      bannerCrop: item.bannerCrop,
      memberListBannerUrl: item.memberListBannerUrl,
      memberListBannerCrop: item.memberListBannerCrop,
      inviteCode: item.inviteCode,
      inviterUsername: item.inviterUsername,
      inviteUses: item.inviteUses,
      inviteMaxUses: item.inviteMaxUses,
      inviteExpiresAt: item.inviteExpiresAt,
      inviteCreatedAt: item.inviteCreatedAt,
      feedServerId: item.feedServerId,
      feedIcon: item.feedIcon,
      publishRoleIds: item.publishRoleIds,
      visibleRoleIds: item.visibleRoleIds,
      feedCreatedAt: item.feedCreatedAt,
    );
  }

  ServerSettingsListItemSeed _settingsMemberFromRealtimeMember({
    ServerSettingsListItemSeed? existing,
    required MemberSeed member,
    required String scopedUserId,
    required String localUserId,
  }) {
    final status = member.status.trim();
    final role = member.role.trim();
    return ServerSettingsListItemSeed(
      title: member.name,
      subtitle: status.isEmpty ? existing?.subtitle ?? 'Offline' : status,
      trailing: role.isEmpty ? existing?.trailing : role,
      accent: member.displayColor ?? existing?.accent,
      id: existing?.id ?? scopedUserId,
      userId: localUserId,
      username: member.username ?? existing?.username,
      roleIds: member.roleIds.isNotEmpty
          ? member.roleIds
          : existing?.roleIds ?? const [],
      permissions: existing?.permissions,
      position: existing?.position,
      colorOnly: existing?.colorOnly ?? false,
      showAsSection: existing?.showAsSection ?? false,
      colorPriority: existing?.colorPriority,
      avatarUrl: member.avatarUrl ?? existing?.avatarUrl,
      bannerUrl: member.bannerUrl ?? existing?.bannerUrl,
      bannerBaseColor: member.bannerBaseColor ?? existing?.bannerBaseColor,
      bannerCrop: member.bannerCrop ?? existing?.bannerCrop,
      memberListBannerUrl:
          member.memberListBannerUrl ?? existing?.memberListBannerUrl,
      memberListBannerCrop:
          member.memberListBannerCrop ?? existing?.memberListBannerCrop,
    );
  }

  void _applyServerRealtimeUserProfileUpdate(
    DirectMessagesUserProfileUpdateEvent event,
  ) {
    final scopedUserId = _safeScopedUserId(
      session.networkId,
      event.localUserId,
    );
    if (scopedUserId == null) {
      return;
    }
    final activeChannelMembers = _memberProfileProjection
        .applyRealtimeUpdateToMembers(
          _state.activeChannelMembers,
          scopedUserId: scopedUserId,
          localUserId: event.localUserId,
          event: event,
        );
    final activeTypingMembers = _memberProfileProjection
        .applyRealtimeUpdateToMembers(
          _state.activeTypingMembers,
          scopedUserId: scopedUserId,
          localUserId: event.localUserId,
          event: event,
        );
    final settings = _memberProfileProjection
        .applyRealtimeUpdateToSettingsMembers(
          _state.settings,
          scopedUserId: scopedUserId,
          localUserId: event.localUserId,
          event: event,
        );
    final currentUserMedia = _memberProfileProjection
        .applyRealtimeUpdateToCurrentUserMedia(
          _state.currentUserMedia,
          scopedUserId: scopedUserId,
          localUserId: event.localUserId,
          event: event,
        );
    final currentUser = _memberProfileProjection
        .applyRealtimeUpdateToCurrentUser(
          _state.currentUser ?? session.user,
          scopedUserId: scopedUserId,
          event: event,
          currentUserMedia: currentUserMedia,
        );
    _setState(
      _state.copyWith(
        currentUser: currentUser,
        currentUserMedia: currentUserMedia,
        settings: settings,
        activeChannelMembers: activeChannelMembers,
        activeTypingMembers: activeTypingMembers,
      ),
    );
  }

  void _applyServerRealtimeTypingStart(DirectMessagesTypingStartEvent event) {
    if (_sameSessionLocalId(event.localUserId, _currentUser.id)) {
      diagnostics.record('workspace.realtime.typing_start.ignored', {
        'networkId': session.networkId,
        'reason': 'current_user',
        'channel': _diagnosticFingerprint(event.channelId),
      });
      return;
    }
    final scopedUserId = _safeScopedUserId(
      session.networkId,
      event.localUserId,
    );
    if (scopedUserId == null) {
      return;
    }
    final member = _memberForServerRealtimeUser(
      scopedUserId: scopedUserId,
      localUserId: event.localUserId,
    );
    if (member == null) {
      return;
    }
    _serverTypingExpiryTimers.remove(scopedUserId)?.cancel();
    _serverTypingExpiryTimers[scopedUserId] = Timer(
      const Duration(seconds: 6),
      () => _expireServerTyping(scopedUserId),
    );
    final existing = _state.activeTypingMembers;
    final nextMembers = [
      for (final current in existing)
        if (_memberMatchesUser(current, scopedUserId, event.localUserId))
          member
        else
          current,
    ];
    final replaced = existing.any(
      (current) => _memberMatchesUser(current, scopedUserId, event.localUserId),
    );
    if (!replaced) {
      nextMembers.add(member);
    }
    _setState(_state.copyWith(activeTypingMembers: nextMembers));
  }

  MemberSeed? _memberForServerRealtimeUser({
    required String scopedUserId,
    required String localUserId,
  }) {
    for (final member in _state.activeChannelMembers) {
      if (_memberMatchesUser(member, scopedUserId, localUserId)) {
        return member.copyWith(id: member.id ?? scopedUserId);
      }
    }
    final settings = _state.settings;
    if (settings != null) {
      for (final member in settings.members) {
        if (_settingsMemberMatchesUser(member, scopedUserId, localUserId)) {
          return MemberSeed(
            id: scopedUserId,
            name: member.title,
            status: member.subtitle,
            initials: initialsForDisplayName(member.title),
            role: member.trailing ?? 'Member',
            roleIds: member.roleIds,
            displayColor: member.accent,
            avatarUrl: member.avatarUrl,
            bannerUrl: member.bannerUrl,
            bannerBaseColor: member.bannerBaseColor,
            bannerCrop: member.bannerCrop,
            memberListBannerUrl: member.memberListBannerUrl,
            memberListBannerCrop: member.memberListBannerCrop,
            originIdentity: member.originIdentity,
            isActive: !_statusLooksOffline(member.subtitle),
          );
        }
      }
    }
    return null;
  }

  ServerSettingsListItemSeed? _settingsMemberForActiveServerUser(
    String scopedUserId,
    String localUserId,
  ) {
    final settings = _state.settings;
    if (settings == null) {
      return null;
    }
    for (final member in settings.members) {
      if (_settingsMemberMatchesUser(member, scopedUserId, localUserId)) {
        return member;
      }
    }
    return null;
  }

  String _channelActivityStatus({
    String? existingStatus,
    ServerSettingsListItemSeed? knownMember,
  }) {
    final knownStatus = _canonicalRealtimePresenceStatus(knownMember?.subtitle);
    if (knownStatus != null) {
      return _normalizeRealtimePresenceStatus(knownStatus);
    }
    final currentStatus = _canonicalRealtimePresenceStatus(existingStatus);
    if (currentStatus != null) {
      return _normalizeRealtimePresenceStatus(currentStatus);
    }
    return 'Online';
  }

  MemberSeed _enrichRealtimeChannelActivityMember(
    MemberSeed member, {
    required ServerSettingsListItemSeed? knownMember,
    required ServerSettingsData? settings,
  }) {
    if (settings == null) {
      return member;
    }
    return _enrichChannelActivityMember(member, knownMember, settings);
  }

  bool _memberMatchesUser(
    MemberSeed member,
    String scopedUserId,
    String localUserId,
  ) {
    final memberId = member.id?.trim();
    return memberId == localUserId ||
        (memberId != null && sameScopedWorkspaceId(memberId, scopedUserId));
  }

  bool _settingsMemberMatchesUser(
    ServerSettingsListItemSeed member,
    String scopedUserId,
    String localUserId,
  ) {
    final userId = member.userId?.trim();
    if (userId == localUserId ||
        (userId != null && sameScopedWorkspaceId(userId, scopedUserId))) {
      return true;
    }
    final id = member.id?.trim();
    return id == localUserId ||
        (id != null && sameScopedWorkspaceId(id, scopedUserId));
  }

  void _expireServerTyping(String scopedUserId) {
    _serverTypingExpiryTimers.remove(scopedUserId)?.cancel();
    _setState(
      _state.copyWith(
        activeTypingMembers: [
          for (final member in _state.activeTypingMembers)
            if (member.id == null ||
                !sameScopedWorkspaceId(member.id!, scopedUserId))
              member,
        ],
      ),
    );
  }

  void _clearServerTypingIndicators() {
    for (final timer in _serverTypingExpiryTimers.values) {
      timer.cancel();
    }
    _serverTypingExpiryTimers.clear();
    _lastServerTypingStartedAtByChannel.clear();
  }

  bool _memberMatchesChannelActivity(
    MemberSeed member, {
    required String scopedUserId,
    required String localUserId,
    required String? displayName,
  }) {
    final memberId = member.id?.trim();
    if (memberId == localUserId ||
        (memberId != null && sameScopedWorkspaceId(memberId, scopedUserId))) {
      return true;
    }
    if (memberId != null && memberId.isNotEmpty) {
      return false;
    }
    return displayName != null && member.name == displayName;
  }

  void _applyServerRealtimeChannelUpsert(
    DirectMessagesServerChannelUpsertEvent event,
  ) {
    final settings = _state.settings;
    if (settings == null || !_serverEventMatchesActive(event.serverId)) {
      return;
    }
    final localChannelId = _localWorkspaceIdForSessionEvent(event.channel.id);
    if (localChannelId == null) {
      return;
    }
    final incoming = ServerSettingsChannelSeed(
      id: localChannelId,
      name: event.channel.name,
      type: event.channel.type,
    );
    var replaced = false;
    final nextChannels = [
      for (final channel in settings.channels)
        if (channel.id == localChannelId) ...[
          channel.copyWith(name: incoming.name, type: incoming.type),
        ] else
          channel,
    ];
    replaced = settings.channels.any((channel) => channel.id == localChannelId);
    if (!replaced) {
      nextChannels.add(incoming);
    }
    _setState(
      _state.copyWith(settings: settings.copyWith(channels: nextChannels)),
    );
  }

  void _applyServerRealtimeChannelDelete(
    DirectMessagesServerChannelDeleteEvent event,
  ) {
    final settings = _state.settings;
    if (settings == null || !_serverEventMatchesActive(event.serverId)) {
      return;
    }
    final localChannelId = _localWorkspaceIdForSessionEvent(event.channelId);
    if (localChannelId == null) {
      return;
    }
    final nextChannels = [
      for (final channel in settings.channels)
        if (channel.id != localChannelId) channel,
    ];
    final nextSettings = settings.copyWith(channels: nextChannels);
    final deletingActive = _state.activeChannelId == localChannelId;
    _setState(
      _state.copyWith(
        settings: nextSettings,
        activeChannelId: deletingActive
            ? _defaultTextChannelId(nextSettings)
            : _state.activeChannelId,
      ),
    );
    unawaited(
      _reconcileActiveServerMembership(
        source: 'channel_delete',
        errorMessage: 'You no longer have access to this server',
      ),
    );
  }

  void _applyServerRealtimeMemberUpsert(
    DirectMessagesServerMemberUpsertEvent event,
  ) {
    if (!_serverEventMatchesActive(event.serverId)) {
      diagnostics.record('workspace.server.member_upsert.skip', {
        'networkId': session.networkId,
        'reason': 'inactive_server',
        'server': _diagnosticFingerprint(event.serverId),
        'activeServer': _diagnosticFingerprint(_state.activeServer?.id),
      });
      return;
    }
    final scopedUserId = _safeScopedUserId(
      session.networkId,
      event.member.id ?? '',
    );
    if (scopedUserId == null) {
      diagnostics.record('workspace.server.member_upsert.skip', {
        'networkId': session.networkId,
        'reason': 'invalid_user',
        'server': _diagnosticFingerprint(event.serverId),
      });
      return;
    }
    final localUserId = _safeLocalUserId(event.member.id ?? '');
    if (localUserId == null) {
      diagnostics.record('workspace.server.member_upsert.skip', {
        'networkId': session.networkId,
        'reason': 'invalid_local_user',
        'server': _diagnosticFingerprint(event.serverId),
        'user': _diagnosticFingerprint(scopedUserId),
      });
      return;
    }
    var replaced = false;
    final nextMembers = [
      for (final member in _state.activeChannelMembers)
        if (member.id != null &&
            sameScopedWorkspaceId(member.id!, scopedUserId)) ...[
          member.copyWith(
            id: scopedUserId,
            name: event.member.name,
            username: event.member.username ?? member.username,
            status: event.member.status,
            initials: event.member.initials,
            role: event.member.role,
            roleIds: event.member.roleIds.isNotEmpty
                ? event.member.roleIds
                : member.roleIds,
            displayColor: event.member.displayColor ?? member.displayColor,
            avatarUrl: event.member.avatarUrl ?? member.avatarUrl,
            bannerUrl: event.member.bannerUrl ?? member.bannerUrl,
            bannerBaseColor:
                event.member.bannerBaseColor ?? member.bannerBaseColor,
            bannerCrop: event.member.bannerCrop ?? member.bannerCrop,
            memberListBannerUrl:
                event.member.memberListBannerUrl ?? member.memberListBannerUrl,
            memberListBannerCrop:
                event.member.memberListBannerCrop ??
                member.memberListBannerCrop,
            lastMessageAt: event.member.lastMessageAt ?? member.lastMessageAt,
            isActive: event.member.isActive || member.isActive,
          ),
        ] else
          member,
    ];
    replaced = _state.activeChannelMembers.any(
      (member) =>
          member.id != null && sameScopedWorkspaceId(member.id!, scopedUserId),
    );
    if (!replaced) {
      diagnostics.record('workspace.server.member_upsert.active_skip', {
        'networkId': session.networkId,
        'server': _diagnosticFingerprint(event.serverId),
        'user': _diagnosticFingerprint(scopedUserId),
        'reason': 'not_channel_activity',
      });
    }
    final settings = _state.settings;
    ServerSettingsData? nextSettings;
    if (settings != null) {
      var settingsReplaced = false;
      final nextSettingsMembers = [
        for (final member in settings.members)
          if (_settingsMemberMatchesUser(member, scopedUserId, localUserId))
            () {
              settingsReplaced = true;
              return _settingsMemberFromRealtimeMember(
                existing: member,
                member: event.member,
                scopedUserId: scopedUserId,
                localUserId: localUserId,
              );
            }()
          else
            member,
      ];
      if (!settingsReplaced) {
        nextSettingsMembers.add(
          _settingsMemberFromRealtimeMember(
            member: event.member,
            scopedUserId: scopedUserId,
            localUserId: localUserId,
          ),
        );
      }
      nextSettings = settings.copyWith(members: nextSettingsMembers);
    }
    _setState(
      _state.copyWith(
        settings: nextSettings,
        activeChannelMembers: nextMembers,
      ),
    );
    diagnostics.record('workspace.server.member_upsert.apply', {
      'networkId': session.networkId,
      'server': _diagnosticFingerprint(event.serverId),
      'user': _diagnosticFingerprint(scopedUserId),
      'status': event.member.status,
      'isActive': event.member.isActive,
      'replacedActiveMember': replaced,
      'activeMemberCount': nextMembers.length,
      'settingsMemberCount': nextSettings?.members.length ?? 0,
    });
  }

  Future<void> _applyServerRealtimeMemberRemove(
    DirectMessagesServerMemberRemoveEvent event,
  ) async {
    final scopedUserId = _safeScopedUserId(session.networkId, event.userId);
    if (scopedUserId == null) {
      diagnostics.record('workspace.server.member_remove.skip', {
        'networkId': session.networkId,
        'reason': 'invalid_user',
      });
      return;
    }
    if (_sameSessionLocalId(event.userId, _currentUser.id)) {
      await _removeCurrentUserServerMembership(event.serverId);
      return;
    }
    if (!_serverEventMatchesActive(event.serverId)) {
      diagnostics.record('workspace.server.member_remove.skip', {
        'networkId': session.networkId,
        'reason': 'inactive_server',
        'server': _diagnosticFingerprint(event.serverId),
      });
      return;
    }
    final localUserId = _safeLocalUserId(event.userId);
    if (localUserId == null) {
      diagnostics.record('workspace.server.member_remove.skip', {
        'networkId': session.networkId,
        'reason': 'invalid_local_user',
      });
      return;
    }
    _serverTypingExpiryTimers.remove(scopedUserId)?.cancel();
    final settings = _state.settings;
    final activeChannelMembers = [
      for (final member in _state.activeChannelMembers)
        if (!_memberMatchesUser(member, scopedUserId, localUserId)) member,
    ];
    final activeTypingMembers = [
      for (final member in _state.activeTypingMembers)
        if (!_memberMatchesUser(member, scopedUserId, localUserId)) member,
    ];
    final nextSettings = settings?.copyWith(
      members: [
        for (final member in settings.members)
          if (!_settingsMemberMatchesUser(member, scopedUserId, localUserId))
            member,
      ],
    );
    diagnostics.record('workspace.server.member_remove.apply', {
      'networkId': session.networkId,
      'server': _diagnosticFingerprint(event.serverId),
      'user': _diagnosticFingerprint(scopedUserId),
      'activeMemberBeforeCount': _state.activeChannelMembers.length,
      'activeMemberAfterCount': activeChannelMembers.length,
      'typingBeforeCount': _state.activeTypingMembers.length,
      'typingAfterCount': activeTypingMembers.length,
      'settingsBeforeCount': settings?.members.length ?? 0,
      'settingsAfterCount': nextSettings?.members.length ?? 0,
    });
    _setState(
      _state.copyWith(
        settings: nextSettings,
        activeChannelMembers: activeChannelMembers,
        activeTypingMembers: activeTypingMembers,
      ),
    );
  }

  Future<void> _removeCurrentUserServerMembership(String? scopedServerId) {
    return _removeServerFromRealtime(
      scopedServerId ?? _state.activeServer?.id,
      errorMessage: 'You were removed from this server',
    );
  }

  Future<bool> _reconcileActiveServerMembershipAfterAccessDenied(
    String message, {
    required String source,
  }) async {
    if (!_isHiddenChannelAccessError(message)) {
      return false;
    }
    return _reconcileActiveServerMembership(
      source: source,
      errorMessage: 'You no longer have access to this server',
    );
  }

  Future<bool> _reconcileActiveServerMembership({
    required String source,
    required String errorMessage,
  }) async {
    final activeServerId = _state.activeServer?.id;
    if (activeServerId == null) {
      return false;
    }
    diagnostics.record('workspace.server.membership_reconcile.start', {
      'networkId': session.networkId,
      'source': source,
      'server': _diagnosticFingerprint(activeServerId),
    });
    try {
      final servers = await repository.listServers();
      if (_state.activeServer?.id != activeServerId) {
        diagnostics.record('workspace.server.membership_reconcile.result', {
          'networkId': session.networkId,
          'source': source,
          'status': 'stale',
          'server': _diagnosticFingerprint(activeServerId),
          'serverCount': servers.length,
        });
        return false;
      }
      final stillPresent = servers.any((server) {
        final localServerId = _localWorkspaceIdForSessionEvent(server.id);
        return localServerId == activeServerId;
      });
      if (!stillPresent) {
        diagnostics.record('workspace.server.membership_reconcile.result', {
          'networkId': session.networkId,
          'source': source,
          'status': 'removed',
          'server': _diagnosticFingerprint(activeServerId),
          'serverCount': servers.length,
        });
        await _removeServerFromRealtime(
          activeServerId,
          errorMessage: errorMessage,
        );
        return true;
      }
      diagnostics.record('workspace.server.membership_reconcile.result', {
        'networkId': session.networkId,
        'source': source,
        'status': 'kept',
        'server': _diagnosticFingerprint(activeServerId),
        'serverCount': servers.length,
      });
      _setState(_state.copyWith(servers: servers));
      return false;
    } on ServerSettingsException catch (error) {
      diagnostics.record('workspace.server.membership_reconcile.result', {
        'networkId': session.networkId,
        'source': source,
        'status': 'failed',
        'server': _diagnosticFingerprint(activeServerId),
        'errorKind': _messageLoadErrorKind(
          error.message,
          isAuthExpired: error.isAuthExpired,
        ),
      });
      return false;
    } catch (error) {
      diagnostics.record('workspace.server.membership_reconcile.result', {
        'networkId': session.networkId,
        'source': source,
        'status': 'failed',
        'server': _diagnosticFingerprint(activeServerId),
        'errorType': error.runtimeType.toString(),
      });
      return false;
    }
  }

  Future<void> _removeServerFromRealtime(
    String? scopedServerId, {
    required String errorMessage,
  }) async {
    final localServerId = scopedServerId == null
        ? _state.activeServer?.id
        : _localWorkspaceIdForSessionEvent(scopedServerId);
    if (localServerId == null) {
      return;
    }
    final activeServer = _state.activeServer;
    final nextServers = [
      for (final server in _state.servers)
        if (server.id != localServerId) server,
    ];
    diagnostics.record('workspace.server.remove.apply', {
      'networkId': session.networkId,
      'server': _diagnosticFingerprint(localServerId),
      'activeServer': _diagnosticFingerprint(activeServer?.id),
      'remainingServerCount': nextServers.length,
      'reason': errorMessage,
    });
    if (activeServer?.id != localServerId) {
      _setState(_state.copyWith(servers: nextServers));
      return;
    }

    _serverSelectionGeneration += 1;
    _clearServerTypingIndicators();
    _clearServerChannelCaches();
    _focusRealtimeChannel(null);
    if (nextServers.isNotEmpty) {
      await _selectFallbackServerAfterRemoval(
        removedServerId: localServerId,
        fallback: nextServers.first,
        remainingServers: nextServers,
        selectionGeneration: _serverSelectionGeneration,
        errorMessage: errorMessage,
      );
      return;
    }
    _setState(
      _state.copyWith(
        servers: nextServers,
        activeServer: null,
        settings: null,
        activeChannelId: null,
        activeFeedId: null,
        pendingChannelId: null,
        isChannelTransitionLoading: false,
        activeChannelMembers: const [],
        activeTypingMembers: const [],
        hasChannelActivityData: false,
        isChannelActivityLoading: false,
        serverMessages: const [],
        isServerMessagesLoading: false,
        isLoadingOlderServerMessages: false,
        hasMoreServerMessages: false,
        serverMessagesError: null,
        error: errorMessage,
        isAuthExpired: false,
      ),
    );
  }

  Future<void> _selectFallbackServerAfterRemoval({
    required String removedServerId,
    required ServerSettingsServer fallback,
    required List<ServerSettingsServer> remainingServers,
    required int selectionGeneration,
    required String errorMessage,
  }) async {
    diagnostics.record('workspace.server.remove.fallback.start', {
      'networkId': session.networkId,
      'removedServer': _diagnosticFingerprint(removedServerId),
      'fallbackServer': _diagnosticFingerprint(fallback.id),
      'remainingServerCount': remainingServers.length,
    });
    try {
      final loaded = await _loadServerSettingsWithCurrentUserMedia(
        repository,
        fallback,
        mode: 'server_remove_fallback',
      );
      if (!_isCurrentServerSelection(selectionGeneration)) {
        diagnostics.record('workspace.server.remove.fallback.result', {
          'networkId': session.networkId,
          'status': 'stale',
          'removedServer': _diagnosticFingerprint(removedServerId),
          'fallbackServer': _diagnosticFingerprint(fallback.id),
        });
        return;
      }
      final settings = loaded.settings;
      final currentUser = loaded.currentUser;
      final activeChannelId = _defaultTextChannelId(settings);
      final serverMessagesResult = await _loadInitialServerMessages(
        activeChannelId,
        currentUserId: currentUser.id,
        mode: 'server_remove_fallback',
      );
      if (!_isCurrentServerSelection(selectionGeneration)) {
        diagnostics.record('workspace.server.remove.fallback.result', {
          'networkId': session.networkId,
          'status': 'stale',
          'removedServer': _diagnosticFingerprint(removedServerId),
          'fallbackServer': _diagnosticFingerprint(fallback.id),
        });
        return;
      }
      if (serverMessagesResult.isAuthExpired) {
        throw ServerSettingsException(
          serverMessagesResult.error ?? 'Sign in again to continue',
          isAuthExpired: true,
        );
      }
      final serverMessages = serverMessagesResult.messages;
      final activity = await _loadChannelActivityForSettings(
        activeChannelId,
        settings,
      );
      if (!_isCurrentServerSelection(selectionGeneration)) {
        diagnostics.record('workspace.server.remove.fallback.result', {
          'networkId': session.networkId,
          'status': 'stale',
          'removedServer': _diagnosticFingerprint(removedServerId),
          'fallbackServer': _diagnosticFingerprint(fallback.id),
        });
        return;
      }
      if (serverMessagesResult.error == null) {
        _cacheServerChannelData(
          activeChannelId,
          messages: serverMessages,
          activity: activity,
        );
      }
      _setState(
        _state.copyWith(
          isLoading: false,
          error: null,
          servers: remainingServers,
          activeServer: fallback,
          settings: settings,
          currentUser: currentUser,
          currentUserMedia: loaded.currentUserMedia,
          activeChannelId: activeChannelId,
          activeFeedId: null,
          pendingChannelId: null,
          isChannelTransitionLoading: false,
          activeChannelMembers: _enrichChannelActivityMembersWithMessages(
            activity.members,
            serverMessages,
            settings,
          ),
          activeTypingMembers: const [],
          hasChannelActivityData: activity.available,
          isChannelActivityLoading: false,
          serverMessages: serverMessages,
          isServerMessagesLoading: false,
          isLoadingOlderServerMessages: false,
          hasMoreServerMessages: _hasMoreMessagePage(serverMessages),
          serverMessagesError: serverMessagesResult.error,
          isAuthExpired: false,
        ),
      );
      _syncRealtimeFocus();
      diagnostics.record('workspace.server.remove.fallback.result', {
        'networkId': session.networkId,
        'status': 'ok',
        'removedServer': _diagnosticFingerprint(removedServerId),
        'fallbackServer': _diagnosticFingerprint(fallback.id),
        'activeChannel': _diagnosticFingerprint(activeChannelId),
        'messageCount': serverMessages.length,
        'activityAvailable': activity.available,
      });
    } on ServerSettingsException catch (error) {
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      diagnostics.record('workspace.server.remove.fallback.result', {
        'networkId': session.networkId,
        'status': 'failed',
        'removedServer': _diagnosticFingerprint(removedServerId),
        'fallbackServer': _diagnosticFingerprint(fallback.id),
        'errorKind': _messageLoadErrorKind(
          error.message,
          isAuthExpired: error.isAuthExpired,
        ),
      });
      _setState(
        _state.copyWith(
          servers: remainingServers,
          activeServer: null,
          settings: null,
          activeChannelId: null,
          activeFeedId: null,
          pendingChannelId: null,
          isChannelTransitionLoading: false,
          activeChannelMembers: const [],
          activeTypingMembers: const [],
          hasChannelActivityData: false,
          isChannelActivityLoading: false,
          serverMessages: const [],
          isServerMessagesLoading: false,
          isLoadingOlderServerMessages: false,
          hasMoreServerMessages: false,
          serverMessagesError: null,
          error: error.isAuthExpired ? error.message : errorMessage,
          isAuthExpired: error.isAuthExpired,
        ),
      );
    } catch (error) {
      if (!_isCurrentServerSelection(selectionGeneration)) {
        return;
      }
      diagnostics.record('workspace.server.remove.fallback.result', {
        'networkId': session.networkId,
        'status': 'failed',
        'removedServer': _diagnosticFingerprint(removedServerId),
        'fallbackServer': _diagnosticFingerprint(fallback.id),
        'errorType': error.runtimeType.toString(),
      });
      _setState(
        _state.copyWith(
          servers: remainingServers,
          activeServer: null,
          settings: null,
          activeChannelId: null,
          activeFeedId: null,
          pendingChannelId: null,
          isChannelTransitionLoading: false,
          activeChannelMembers: const [],
          activeTypingMembers: const [],
          hasChannelActivityData: false,
          isChannelActivityLoading: false,
          serverMessages: const [],
          isServerMessagesLoading: false,
          isLoadingOlderServerMessages: false,
          hasMoreServerMessages: false,
          serverMessagesError: null,
          error: errorMessage,
          isAuthExpired: false,
        ),
      );
    }
  }

  void _applyServerRealtimeMemberRoleUpdate(
    DirectMessagesServerMemberRoleUpdateEvent event,
  ) {
    if (!_serverEventMatchesActive(event.serverId)) {
      return;
    }
    final scopedUserId = _safeScopedUserId(session.networkId, event.userId);
    if (scopedUserId == null) {
      return;
    }
    final settings = _state.settings;
    final roleLabel = settings == null
        ? event.roleIds.isEmpty
              ? 'Member'
              : '${event.roleIds.length} ${event.roleIds.length == 1 ? 'role' : 'roles'}'
        : _roleLabelForIds(
            event.roleIds,
            settings.roles,
            fallback: event.roleIds.isEmpty
                ? 'Member'
                : '${event.roleIds.length} roles',
          );
    final displayColor = settings == null
        ? null
        : _roleAccentForIds(event.roleIds, settings.roles);
    final nameColorName = settings == null
        ? null
        : _nameColorRoleForIds(event.roleIds, settings.roles)?.title;
    _setState(
      _state.copyWith(
        activeChannelMembers: [
          for (final member in _state.activeChannelMembers)
            if (member.id != null &&
                sameScopedWorkspaceId(member.id!, scopedUserId))
              member.copyWith(
                role: roleLabel,
                roleIds: event.roleIds,
                displayColor: displayColor,
                nameColorName: nameColorName,
              )
            else
              member,
        ],
      ),
    );
  }

  void _applyServerRealtimeUnread(DirectMessagesChannelUnreadEvent event) {
    final settings = _state.settings;
    if (settings == null || _isActiveServerChannelEvent(event.channelId)) {
      return;
    }
    final localChannelId = _localWorkspaceIdForSessionEvent(event.channelId);
    if (localChannelId == null) {
      return;
    }
    _setState(
      _state.copyWith(
        settings: settings.copyWith(
          channels: [
            for (final channel in settings.channels)
              if (channel.id == localChannelId)
                channel.copyWith(
                  unread: true,
                  mentionCount: event.mentionsCurrentUser
                      ? channel.mentionCount + 1
                      : channel.mentionCount,
                )
              else
                channel,
          ],
        ),
      ),
    );
  }

  bool _serverEventMatchesActive(String? scopedServerId) {
    if (scopedServerId == null) {
      return true;
    }
    final activeServerId = _state.activeServer?.id;
    if (activeServerId == null) {
      return false;
    }
    return _localWorkspaceIdForSessionEvent(scopedServerId) == activeServerId;
  }

  void _applyServerRealtimeReactionAdd(DirectMessagesReactionAddEvent event) {
    final messages = _applyReactionAdd(_state.serverMessages, event);
    _cacheActiveServerMessages(messages);
    _setState(_state.copyWith(serverMessages: messages));
  }

  void _applyServerRealtimeReactionRemove(
    DirectMessagesReactionRemoveEvent event,
  ) {
    final messages = _applyReactionRemove(_state.serverMessages, event);
    _cacheActiveServerMessages(messages);
    _setState(_state.copyWith(serverMessages: messages));
  }

  void _recordDirectMessagesRealtimeDiagnostic(
    String event,
    Map<String, Object?> fields,
  ) {
    debugPrint(
      'verdant.dm realtime.$event ${sanitizeAuthDiagnosticFields(fields)}',
    );
  }

  Future<DirectMessagesWorkspaceData>
  _loadDirectMessagesWithAuthoritativeHiddenState(
    VerdantUser currentUser,
  ) async {
    try {
      final hiddenPreferencesRequestEpoch = _hiddenDmPreferenceMutationEpoch;
      final snapshot = await _fetchDirectMessagesSnapshot(currentUser);
      final scoped = _directMessagesDataForSession(
        _withCurrentUserDirectMessagesStatus(snapshot, currentUser),
      );
      final restoredFromSnapshot = _restoreHiddenDmPreferencesFromSnapshot(
        scoped,
        source: 'bootstrap',
        mutationEpochAtRequest: hiddenPreferencesRequestEpoch,
      );
      var preferencesAvailable =
          restoredFromSnapshot || _hiddenDmPreferencesRestored;
      if (!preferencesAvailable) {
        preferencesAvailable = await _restoreHiddenDmPreferences(currentUser);
      }
      return _directMessagesStore.replaceSnapshot(
        preferencesAvailable
            ? scoped
            : scoped.copyWith(conversations: const []),
      );
    } on DirectMessagesException catch (error) {
      return _directMessagesLoadFailure(error.message);
    } catch (_) {
      return _directMessagesLoadFailure('Could not load direct messages');
    }
  }

  Future<DirectMessagesWorkspaceData> _fetchDirectMessagesSnapshot(
    VerdantUser currentUser,
  ) async {
    final repository = directMessagesRepository;
    if (repository == null) {
      return _emptyDirectMessages();
    }
    return repository.loadDirectMessages(
      currentUserId: currentUser.id,
      currentUserName: currentUser.displayLabel,
      currentUserInitials: currentUser.initials,
    );
  }

  DirectMessagesWorkspaceData _directMessagesLoadFailure(String message) {
    final existing = _directMessagesStore.visibleData;
    if (existing != null) {
      return existing.copyWith(isRefreshing: false, error: message);
    }
    return _emptyDirectMessages(error: message);
  }

  Future<bool> _restoreHiddenDmPreferences(VerdantUser currentUser) async {
    if (_hiddenDmPreferencesRestored) {
      return true;
    }
    final inFlight = _hiddenDmPreferencesRestoreFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final restoreFuture = _restoreHiddenDmPreferencesOnce(currentUser);
    _hiddenDmPreferencesRestoreFuture = restoreFuture;
    return restoreFuture;
  }

  bool _restoreHiddenDmPreferencesFromSnapshot(
    DirectMessagesWorkspaceData data, {
    required String source,
    int? mutationEpochAtRequest,
  }) {
    final hidden = data.hiddenChannelIds;
    if (hidden == null) {
      return false;
    }
    if (mutationEpochAtRequest != null &&
        mutationEpochAtRequest < _hiddenDmPreferenceMutationEpoch) {
      _hiddenDmPreferencesRestored = true;
      diagnostics.record('workspace.dm.hidden_prefs.restore.snapshot_stale', {
        'networkId': session.networkId,
        'source': source,
        'hiddenCount': hidden.length,
        'requestEpoch': mutationEpochAtRequest,
        'currentEpoch': _hiddenDmPreferenceMutationEpoch,
      });
      return true;
    }
    if (_pendingHiddenDmPreferenceSaves > 0) {
      _hiddenDmPreferencesRestored = true;
      diagnostics.record('workspace.dm.hidden_prefs.restore.snapshot_ignored', {
        'networkId': session.networkId,
        'source': source,
        'hiddenCount': hidden.length,
        'pendingSaveCount': _pendingHiddenDmPreferenceSaves,
      });
      return true;
    }
    _directMessagesStore.restoreHiddenChannelIds(hidden);
    _hiddenDmPreferencesRestored = true;
    diagnostics.record('workspace.dm.hidden_prefs.restore.snapshot', {
      'networkId': session.networkId,
      'source': source,
      'hiddenCount': hidden.length,
    });
    return true;
  }

  Future<bool> _restoreHiddenDmPreferencesOnce(VerdantUser currentUser) async {
    final repository = directMessagesRepository;
    if (_pendingHiddenDmPreferenceSaves > 0) {
      _hiddenDmPreferencesRestored = true;
      diagnostics.record('workspace.dm.hidden_prefs.restore.pending_save', {
        'networkId': session.networkId,
        'pendingSaveCount': _pendingHiddenDmPreferenceSaves,
      });
      return true;
    }
    try {
      if (repository == null) {
        diagnostics.record('workspace.dm.hidden_prefs.restore.unavailable', {
          'networkId': session.networkId,
          'reason': 'repository_unavailable',
        });
        _directMessagesStore.restoreHiddenChannelIds(const {});
        return false;
      }
      final hiddenPreferencesRequestEpoch = _hiddenDmPreferenceMutationEpoch;
      final hidden = await repository.loadHiddenChannelIds();
      if (hiddenPreferencesRequestEpoch < _hiddenDmPreferenceMutationEpoch) {
        _hiddenDmPreferencesRestored = true;
        diagnostics.record('workspace.dm.hidden_prefs.restore.backend_stale', {
          'networkId': session.networkId,
          'hiddenCount': hidden.length,
          'requestEpoch': hiddenPreferencesRequestEpoch,
          'currentEpoch': _hiddenDmPreferenceMutationEpoch,
        });
        return true;
      }
      if (_pendingHiddenDmPreferenceSaves > 0) {
        _hiddenDmPreferencesRestored = true;
        diagnostics
            .record('workspace.dm.hidden_prefs.restore.backend_ignored', {
              'networkId': session.networkId,
              'hiddenCount': hidden.length,
              'pendingSaveCount': _pendingHiddenDmPreferenceSaves,
            });
        return true;
      }
      diagnostics.record('workspace.dm.hidden_prefs.restore.backend', {
        'networkId': session.networkId,
        'hiddenCount': hidden.length,
      });
      _directMessagesStore.restoreHiddenChannelIds(hidden);
      _hiddenDmPreferencesRestored = true;
      return true;
    } catch (error) {
      diagnostics.record('workspace.dm.hidden_prefs.restore.unavailable', {
        'networkId': session.networkId,
        'reason': error is DirectMessagesException
            ? error.message
            : 'backend_restore_failed',
        'errorType': error.runtimeType.toString(),
      });
      _directMessagesStore.restoreHiddenChannelIds(const {});
      return false;
    } finally {
      _hiddenDmPreferencesRestoreFuture = null;
    }
  }

  Future<void> _saveHiddenDmPreferences() {
    final hidden = Set<String>.of(_directMessagesStore.hiddenChannelIds);
    final repository = directMessagesRepository;
    if (repository == null) {
      return Future<void>.value();
    }
    _pendingHiddenDmPreferenceSaves += 1;
    final save = _hiddenDmPreferencesSaveTail.then((_) async {
      try {
        await repository.saveHiddenChannelIds(channelIds: hidden);
        diagnostics.record('workspace.dm.hidden_prefs.save.backend', {
          'networkId': session.networkId,
          'hiddenCount': hidden.length,
        });
      } catch (error) {
        diagnostics.record('workspace.dm.hidden_prefs.save.failure', {
          'networkId': session.networkId,
          'hiddenCount': hidden.length,
          'reason': error is DirectMessagesException
              ? error.message
              : 'backend_save_failed',
          'errorType': error.runtimeType.toString(),
        });
      } finally {
        _pendingHiddenDmPreferenceSaves -= 1;
      }
    });
    _hiddenDmPreferencesSaveTail = save;
    return save;
  }

  void _markHiddenDmPreferencesMutated() {
    _hiddenDmPreferencesRestored = true;
    _hiddenDmPreferenceMutationEpoch += 1;
  }

  DirectMessagesWorkspaceData _emptyDirectMessages({
    VerdantUser? currentUser,
    String? error,
    bool hasHydrated = true,
  }) {
    final user = currentUser ?? _currentUser;
    return DirectMessagesWorkspaceData.empty(
      networkId: session.networkId,
      currentUserName: user.displayLabel,
      currentUserInitials: user.initials,
      hasHydrated: hasHydrated,
      error: error,
    ).copyWith(
      currentUserStatus: _normalizeRealtimePresenceStatus(user.status),
    );
  }

  DirectMessagesWorkspaceData _withCurrentUserDirectMessagesStatus(
    DirectMessagesWorkspaceData data,
    VerdantUser currentUser,
  ) {
    return data.copyWith(
      currentUserStatus: _normalizeRealtimePresenceStatus(currentUser.status),
    );
  }

  @override
  void dispose() {
    _clearServerTypingIndicators();
    _disconnectDirectMessagesRealtime();
    super.dispose();
  }

  @override
  String toString() {
    return 'WorkspaceController(session: redacted, '
        'networkId: ${session.networkId}, state: ${_state.isLoading ? 'loading' : 'ready'})';
  }
}
