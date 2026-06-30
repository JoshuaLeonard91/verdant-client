import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../auth/auth_diagnostics.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_service.dart';
import '../../auth/instance_metadata_service.dart';
import '../../auth/instance_identity.dart';
import '../../auth/auth_models.dart';
import '../../auth/network_profile_store.dart';
import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_theme.dart';
import '../bottom_rail_workspace/bottom_rail_models.dart';
import '../bottom_rail_workspace/bottom_rail_workspace.dart';
import '../bottom_rail_workspace/create_server_modal.dart';
import '../bottom_rail_workspace/joined_network_rail_service.dart';
import '../bottom_rail_workspace/join_network_modal.dart';
import '../bottom_rail_workspace/join_server_modal.dart';
import '../bottom_rail_workspace/server_drawer.dart';
import '../channel_settings_workspace/channel_settings_workspace.dart';
import '../chat_workspace/announcement_feed/announcement_feed_service.dart';
import '../chat_workspace/announcement_feed_workspace.dart';
import '../chat_workspace/chat_invite_link.dart';
import '../chat_workspace/chat_workspace.dart';
import '../chat_workspace/klipy_media_repository.dart';
import '../chat_workspace/link_preview_service.dart';
import '../chat_workspace/server_custom_emojis.dart';
import '../context_workspace/context_workspace.dart';
import '../direct_messages_workspace/direct_messages_models.dart';
import '../direct_messages_workspace/direct_messages_preferences.dart';
import '../direct_messages_workspace/dm_conversation_module.dart';
import '../direct_messages_workspace/direct_messages_service.dart';
import '../direct_messages_workspace/direct_messages_workspace.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/federated_invite_service.dart';
import '../server_settings_workspace/federated_membership_service.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_workspace.dart';
import '../server_settings_workspace/server_settings_service.dart';
import '../shared/inactive_backend_runtime.dart';
import '../shared/sync_summary_service.dart';
import '../shared/user_identity_labels.dart';
import '../shared/workspace_entitlements.dart';
import '../shared/user_context_menu.dart';
import '../shared/custom_expressive_asset.dart';
import '../user_settings_workspace/user_settings_preferences.dart';
import '../user_settings_workspace/user_settings_context.dart';
import '../user_settings_workspace/user_settings_workspace.dart';
import '../user_settings_workspace/workspace_accessibility_settings.dart';
import '../workspace_controller.dart';
import '../workspace_local_id.dart';
import '../workspace_state.dart';
import '../server_workspace/server_workspace.dart';
import '../workspace_seed.dart';
part 'workspace_shell_dialogs.dart';
part 'workspace_shell_widgets.dart';

final _workspaceWarmCustomEmojiPattern = RegExp(r':([A-Za-z0-9_]{2,32}):');

final class WorkspaceRailSnapshot {
  const WorkspaceRailSnapshot({
    this.records = const [],
    this.networkOrder = const [],
    this.railServers = const [],
  });

  final List<RailNetworkRecord> records;
  final List<String> networkOrder;
  final List<RailServerItem> railServers;

  bool get isEmpty =>
      records.isEmpty && networkOrder.isEmpty && railServers.isEmpty;

  String get contentSignature {
    const itemSeparator = '\u001E';
    const sectionSeparator = '\u001F';
    return [
      networkOrder.join(itemSeparator),
      records.map(_railNetworkRecordSignature).join(itemSeparator),
      railServers.map(_railServerSignature).join(itemSeparator),
    ].join(sectionSeparator);
  }

  static String _railNetworkRecordSignature(RailNetworkRecord record) {
    return [
      record.networkId,
      record.networkName,
      record.mode.name,
      record.availability.name,
      record.authStatus.name,
      record.apiOrigin ?? '',
      record.currentUserId ?? '',
      record.currentUsername ?? '',
      record.usernameSet?.toString() ?? '',
      record.credentialKind?.name ?? '',
    ].join('\u001D');
  }

  static String _railServerSignature(RailServerItem server) {
    return [
      server.networkId,
      server.localServerId,
      server.name,
      server.iconUrl ?? '',
      server.memberCount?.toString() ?? '',
      server.bannerUrl ?? '',
      server.isUnavailable.toString(),
      server.unreadCount.toString(),
      server.mentionCount.toString(),
    ].join('\u001D');
  }
}

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    required this.session,
    required this.credentialStore,
    required this.currentUserName,
    required this.currentUserInitials,
    required this.onLogout,
    this.initialServerId,
    this.authService,
    this.serverSettingsRepository,
    this.serverSettingsRepositoryFactory,
    this.federatedMembershipRepositoryFactory,
    this.federatedInvitePreviewRepository,
    this.federatedInviteJoinRepository,
    this.directMessagesRepository,
    this.directMessagesPreferences,
    this.networkProfileStore,
    this.instanceMetadataService,
    this.instanceIdentityStore,
    this.instanceIdentityManifestService,
    this.syncSummaryClient,
    this.inactiveSummaryPollInterval = const Duration(seconds: 15),
    this.diagnostics,
    this.accessibilitySettingsStore,
    this.userSettingsPreferencesStore,
    this.onUserSettingsPreferencesChanged,
    this.onActivateNetwork,
    this.onWorkspaceReadyChanged,
    this.onWindowOverlayChanged,
    this.initialRailSnapshot = const WorkspaceRailSnapshot(),
    this.onRailSnapshotChanged,
    this.showBottomRail = true,
    this.railInteractionsEnabled = true,
    super.key,
  });

  final AuthSession session;
  final String? initialServerId;
  final AuthCredentialStore credentialStore;
  final String currentUserName;
  final String currentUserInitials;
  final VoidCallback onLogout;
  final AuthService? authService;
  final ServerSettingsRepository? serverSettingsRepository;
  final ServerSettingsRepository Function(String apiOrigin)?
  serverSettingsRepositoryFactory;
  final FederatedMembershipRepository Function(String apiOrigin)?
  federatedMembershipRepositoryFactory;
  final FederatedInvitePreviewRepository? federatedInvitePreviewRepository;
  final FederatedInviteJoinRepository? federatedInviteJoinRepository;
  final DirectMessagesRepository? directMessagesRepository;
  final DirectMessagesPreferences? directMessagesPreferences;
  final NetworkProfileStore? networkProfileStore;
  final InstanceMetadataService? instanceMetadataService;
  final InstanceIdentityStore? instanceIdentityStore;
  final InstanceIdentityManifestService? instanceIdentityManifestService;
  final SyncSummaryClient? syncSummaryClient;
  final Duration inactiveSummaryPollInterval;
  final AuthDiagnostics? diagnostics;
  final WorkspaceAccessibilitySettingsStore? accessibilitySettingsStore;
  final UserSettingsPreferencesStore? userSettingsPreferencesStore;
  final ValueChanged<UserSettingsPreferences>? onUserSettingsPreferencesChanged;
  final ValueChanged<WidgetBuilder?>? onWindowOverlayChanged;
  final Future<NetworkSessionActivationResult> Function({
    required String apiOrigin,
    String? initialServerId,
  })?
  onActivateNetwork;
  final void Function(String networkId, bool isReady, String? activeServerId)?
  onWorkspaceReadyChanged;
  final WorkspaceRailSnapshot initialRailSnapshot;
  final ValueChanged<WorkspaceRailSnapshot>? onRailSnapshotChanged;
  final bool showBottomRail;
  final bool railInteractionsEnabled;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell>
    with TickerProviderStateMixin {
  static const _serverSelectionMinimumDwell = Duration.zero;
  static const _workspaceBlockingMediaWarmBudget = Duration(seconds: 4);
  static const _workspaceBlockingMediaWarmConcurrency = 3;
  static const _workspaceBackgroundMediaWarmConcurrency = 2;

  bool _serverSettingsOpen = false;
  bool _channelSettingsOpen = false;
  bool _userSettingsOpen = false;
  bool _directMessagesOpen = false;
  bool _serverDrawerOpen = false;
  WorkspaceAccessibilitySettings _accessibilitySettings =
      const WorkspaceAccessibilitySettings();
  UserSettingsPreferences _userSettingsPreferences =
      const UserSettingsPreferences();
  List<RailNetworkRecord> _railNetworkRecords = const [];
  List<String> _railNetworkOrder = const [];
  List<RailServerItem> _joinedRailServers = const [];
  final Map<String, ServerCustomEmojiGroup> _customEmojiGroupsByScopedServerId =
      <String, ServerCustomEmojiGroup>{};
  final Map<String, ServerCustomStickerGroup>
  _customStickerGroupsByScopedServerId = <String, ServerCustomStickerGroup>{};
  String? _pendingRailSelectionScopedId;
  String? _railSwitchDiagnosticsScopedId;
  Stopwatch? _railSwitchDiagnosticsWatch;
  TimingsCallback? _railSwitchTimingsCallback;
  final List<FrameTiming> _railSwitchFrameTimings = <FrameTiming>[];
  Map<String, VerdantUser> _settingsUsersByNetworkId = const {};
  final Map<String, ServerSettingsRepository> _userSettingsRepositoryCache =
      <String, ServerSettingsRepository>{};
  bool? _lastReportedWorkspaceReady;
  String? _lastReportedWorkspaceReadyServerId;
  bool _usernamePromptOpen = false;
  bool _usernamePromptScheduled = false;
  bool _initialRailRefreshScheduled = false;
  String? _lastPersistedCurrentUserSignature;
  String? _channelSettingsChannelId;
  ServerSettingsChannelSeed? _channelSettingsFallback;
  ChannelSettingsTabId _channelSettingsTab = ChannelSettingsTabId.overview;
  final Set<String> _dismissedUsernamePromptKeys = <String>{};
  late final AnimationController _serverSettingsAnimation;
  late final Animation<double> _serverSettingsCurve;
  late final AnimationController _channelSettingsAnimation;
  late final Animation<double> _channelSettingsCurve;
  late final AnimationController _userSettingsAnimation;
  late final Animation<double> _userSettingsCurve;
  late final AnimationController _serverDrawerAnimation;
  late final Animation<double> _serverDrawerCurve;
  bool _ownsServerSettingsWindowOverlay = false;
  bool _ownsUserSettingsWindowOverlay = false;
  late final ServerSettingsRepository _repository;
  late final FederatedInvitePreviewRepository _federatedInvitePreviewRepository;
  late final FederatedInviteJoinRepository _federatedInviteJoinRepository;
  late final DirectMessagesRepository _directMessagesRepository;
  late final KlipyMediaRepository _klipyMediaRepository;
  late final HttpMessageLinkPreviewService _messageLinkPreviewService;
  late final NetworkProfileStore _networkProfileStore;
  late final InstanceMetadataService _instanceMetadataService;
  late final SyncSummaryClient _syncSummaryClient;
  late final AuthService _authService;
  late final WorkspaceAccessibilitySettingsStore _accessibilitySettingsStore;
  late final UserSettingsPreferencesStore _userSettingsPreferencesStore;
  late final bool _ownsInstanceMetadataService;
  late final bool _ownsFederatedInvitePreviewRepository;
  late final bool _ownsFederatedInviteJoinRepository;
  late final bool _ownsSyncSummaryClient;
  late final bool _ownsAuthService;
  late final WorkspaceController _controller;
  final Map<String, String> _syncSummaryCursorsByNetworkId = <String, String>{};
  Timer? _inactiveSummaryTimer;
  Timer? _workspaceBlockingMediaWarmBudgetTimer;
  String? _pendingInitialRailServerId;
  String? _lastBlockingWorkspaceMediaWarmSignature;
  String? _lastBackgroundWorkspaceMediaWarmSignature;
  String? _blockingWorkspaceMediaWarmSignature;
  bool _workspaceMediaHydrating = false;
  bool _initialWorkspaceRevealReady = false;
  bool _initialWorkspaceRevealScheduled = false;
  bool _skipNextWorkspaceReadyMediaWarm = false;

  @override
  void initState() {
    super.initState();
    _applyRailSnapshot(widget.initialRailSnapshot);
    _serverSettingsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      reverseDuration: const Duration(milliseconds: 210),
    );
    _serverSettingsCurve = CurvedAnimation(
      parent: _serverSettingsAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _channelSettingsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      reverseDuration: const Duration(milliseconds: 210),
    );
    _channelSettingsCurve = CurvedAnimation(
      parent: _channelSettingsAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _userSettingsAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      reverseDuration: const Duration(milliseconds: 210),
    );
    _userSettingsCurve = CurvedAnimation(
      parent: _userSettingsAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _serverDrawerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 170),
    );
    _serverDrawerCurve = CurvedAnimation(
      parent: _serverDrawerAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _repository =
        widget.serverSettingsRepository ??
        ServerSettingsService(
          apiOrigin: widget.session.apiOrigin,
          credentialStore: widget.credentialStore,
        );
    _federatedInvitePreviewRepository =
        widget.federatedInvitePreviewRepository ??
        HttpFederatedInvitePreviewService();
    _federatedInviteJoinRepository =
        widget.federatedInviteJoinRepository ??
        HttpFederatedInviteJoinService(
          apiOrigin: widget.session.apiOrigin,
          credentialStore: widget.credentialStore,
          authService: widget.authService,
        );
    _directMessagesRepository =
        widget.directMessagesRepository ??
        VerdantDirectMessagesService(
          apiOrigin: widget.session.apiOrigin,
          credentialStore: widget.credentialStore,
        );
    _klipyMediaRepository = HttpKlipyMediaRepository(
      apiOrigin: widget.session.apiOrigin,
      credentialStore: widget.credentialStore,
    );
    _messageLinkPreviewService = HttpMessageLinkPreviewService(
      apiOrigin: widget.session.apiOrigin,
      credentialStore: widget.credentialStore,
    );
    _networkProfileStore = widget.networkProfileStore ?? NetworkProfileStore();
    _instanceMetadataService =
        widget.instanceMetadataService ?? HttpInstanceMetadataService();
    _syncSummaryClient =
        widget.syncSummaryClient ??
        HttpSyncSummaryClient(credentialStore: widget.credentialStore);
    _authService = widget.authService ?? HttpAuthService();
    _accessibilitySettingsStore =
        widget.accessibilitySettingsStore ??
        WorkspaceAccessibilitySettingsStore();
    _userSettingsPreferencesStore =
        widget.userSettingsPreferencesStore ?? UserSettingsPreferencesStore();
    _ownsInstanceMetadataService = widget.instanceMetadataService == null;
    _ownsFederatedInvitePreviewRepository =
        widget.federatedInvitePreviewRepository == null;
    _ownsFederatedInviteJoinRepository =
        widget.federatedInviteJoinRepository == null;
    _ownsSyncSummaryClient = widget.syncSummaryClient == null;
    _ownsAuthService = widget.authService == null;
    _controller = WorkspaceController(
      session: widget.session,
      repository: _repository,
      initialServerId: widget.initialServerId,
      directMessagesRepository: _directMessagesRepository,
      directMessagesPreferences: widget.directMessagesPreferences,
      serverAccessFilter:
          widget.session.credentialKind == AuthCredentialKind.federatedClient
          ? _loadFederatedAllowedServerIdsForActiveSession
          : null,
      diagnostics: widget.diagnostics ?? const DebugPrintAuthDiagnostics(),
      serverSelectionMinimumDwell: _serverSelectionMinimumDwell,
    );
    _controller.addListener(_handleControllerStateChanged);
    _controller.load();
    _configureInactiveSummaryPolling();
    unawaited(_loadAccessibilitySettings());
    unawaited(_loadUserSettingsPreferences());
  }

  @override
  void didUpdateWidget(WorkspaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.initialRailSnapshot.isEmpty &&
        !_sameRailSnapshot(
          oldWidget.initialRailSnapshot,
          widget.initialRailSnapshot,
        )) {
      _applyRailSnapshot(widget.initialRailSnapshot);
    }
    if (oldWidget.initialServerId != widget.initialServerId &&
        widget.initialServerId != null) {
      _pendingInitialRailServerId = widget.initialServerId;
      if (_directMessagesOpen || _serverDrawerOpen) {
        setState(() {
          _directMessagesOpen = false;
          _hideServerDrawerImmediately();
        });
      }
      _configureDirectMessagesRefresh(false);
      _selectPendingInitialServerIfLoaded();
    }
    if (oldWidget.showBottomRail != widget.showBottomRail ||
        oldWidget.inactiveSummaryPollInterval !=
            widget.inactiveSummaryPollInterval) {
      _configureInactiveSummaryPolling();
    }
    if (!oldWidget.showBottomRail &&
        widget.showBottomRail &&
        _controller.state.settings != null) {
      _initialRailRefreshScheduled = true;
      unawaited(_refreshRailNetworkMetadata());
    }
  }

  @override
  void dispose() {
    _clearRailSwitchDiagnostics();
    _clearServerSettingsWindowOverlay();
    _clearUserSettingsWindowOverlay();
    _serverSettingsAnimation.dispose();
    _channelSettingsAnimation.dispose();
    _userSettingsAnimation.dispose();
    _serverDrawerAnimation.dispose();
    _controller
      ..removeListener(_handleControllerStateChanged)
      ..dispose();
    if (_repository is ServerSettingsService) {
      _repository.close();
    }
    for (final repository in _userSettingsRepositoryCache.values) {
      if (repository is ServerSettingsService) {
        repository.close();
      }
    }
    _userSettingsRepositoryCache.clear();
    if (_directMessagesRepository is HttpDirectMessagesService) {
      _directMessagesRepository.close();
    }
    if (_directMessagesRepository is VerdantDirectMessagesService) {
      _directMessagesRepository.close();
    }
    if (_ownsFederatedInvitePreviewRepository &&
        _federatedInvitePreviewRepository
            is HttpFederatedInvitePreviewService) {
      _federatedInvitePreviewRepository.close();
    }
    if (_ownsFederatedInviteJoinRepository &&
        _federatedInviteJoinRepository is HttpFederatedInviteJoinService) {
      _federatedInviteJoinRepository.close();
    }
    _inactiveSummaryTimer?.cancel();
    _workspaceBlockingMediaWarmBudgetTimer?.cancel();
    _workspaceBlockingMediaWarmBudgetTimer = null;
    if (_ownsSyncSummaryClient && _syncSummaryClient is HttpSyncSummaryClient) {
      _syncSummaryClient.close();
    }
    if (_klipyMediaRepository is HttpKlipyMediaRepository) {
      _klipyMediaRepository.close();
    }
    _messageLinkPreviewService.close();
    if (_ownsInstanceMetadataService &&
        _instanceMetadataService is HttpInstanceMetadataService) {
      _instanceMetadataService.close();
    }
    if (_ownsAuthService && _authService is HttpAuthService) {
      _authService.close();
    }
    super.dispose();
  }

  void _handleControllerStateChanged() {
    if (_serverSettingsOpen) {
      _publishServerSettingsWindowOverlay();
    }
    if (_userSettingsOpen && widget.onWindowOverlayChanged != null) {
      _publishUserSettingsWindowOverlay();
    }
    final state = _controller.state;
    final currentUser = state.currentUser;
    if (currentUser == null || state.isLoading || state.error != null) {
      _reportWorkspaceReadyIfChanged();
      _selectPendingInitialServerIfLoaded();
      return;
    }
    if (!_initialWorkspaceRevealReady) {
      _scheduleInitialWorkspaceReveal();
      _reportWorkspaceReadyIfChanged();
      _selectPendingInitialServerIfLoaded();
      return;
    }
    if (_skipNextWorkspaceReadyMediaWarm) {
      _skipNextWorkspaceReadyMediaWarm = false;
    } else {
      unawaited(
        _warmHydratedWorkspaceMedia(
          railServers: const [],
          settings: state.settings,
          blockWorkspaceHydration: true,
          reason: 'workspace_ready',
          includeActiveServerMedia: true,
          includeVisibleCurrentUserAvatar: true,
        ),
      );
    }
    unawaited(
      _warmHydratedWorkspaceMedia(
        railServers: const [],
        settings: state.settings,
        reason: 'workspace_background',
        includeActiveServerMedia: false,
        includeVisibleCurrentUserAvatar: false,
        includeCurrentUserProfileMedia: true,
        includeActiveChannelMemberMedia: true,
        includeMessageAuthorAvatars: true,
        includeMessageCustomEmojiMedia: true,
      ),
    );
    _reportWorkspaceReadyIfChanged();
    _selectPendingInitialServerIfLoaded();
    if (widget.showBottomRail &&
        !_initialRailRefreshScheduled &&
        state.settings != null) {
      _initialRailRefreshScheduled = true;
      unawaited(_refreshRailNetworkMetadata());
    }
    unawaited(_persistActiveCurrentUserSnapshot(currentUser));
    _scheduleActiveUsernamePrompt(currentUser);
  }

  void _configureInactiveSummaryPolling() {
    _inactiveSummaryTimer?.cancel();
    _inactiveSummaryTimer = null;
    if (!widget.showBottomRail ||
        widget.inactiveSummaryPollInterval <= Duration.zero) {
      return;
    }
    _inactiveSummaryTimer = Timer.periodic(
      widget.inactiveSummaryPollInterval,
      (_) => unawaited(_pollInactiveSummaryBadges()),
    );
  }

  void _scheduleInitialWorkspaceReveal() {
    if (_initialWorkspaceRevealReady || _initialWorkspaceRevealScheduled) {
      return;
    }
    final state = _controller.state;
    if (state.isLoading ||
        state.error != null ||
        state.settings == null ||
        state.currentUser == null) {
      return;
    }
    _initialWorkspaceRevealScheduled = true;
    unawaited(_completeInitialWorkspaceReveal());
  }

  Future<void> _completeInitialWorkspaceReveal() async {
    final watch = Stopwatch()..start();
    widget.diagnostics?.record('workspace.startup.hydration.start', {
      'networkId': widget.session.networkId,
      'apiOrigin': widget.session.apiOrigin,
      'showBottomRail': widget.showBottomRail,
      'hasInitialRailSnapshot': !widget.initialRailSnapshot.isEmpty,
    });
    try {
      if (widget.showBottomRail) {
        _initialRailRefreshScheduled = true;
        await _refreshRailNetworkMetadata();
      }
      if (!mounted) {
        return;
      }
      final state = _controller.state;
      final settings = state.settings;
      if (!state.isLoading && state.error == null && settings != null) {
        await _warmHydratedWorkspaceMedia(
          railServers: _bottomRailServersForActiveWorkspace(
            state: state,
            settings: settings,
          ),
          settings: settings,
          blockWorkspaceHydration: true,
          reason: 'workspace_startup',
          includeActiveServerMedia: true,
          includeVisibleCurrentUserAvatar: true,
          includeCurrentUserProfileMedia: true,
          includeRailServerIcons: widget.showBottomRail,
          includeActiveChannelMemberMedia: true,
          includeMessageAuthorAvatars: true,
          includeMessageCustomEmojiMedia: true,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _initialWorkspaceRevealReady = true;
        _initialWorkspaceRevealScheduled = false;
        _skipNextWorkspaceReadyMediaWarm = true;
      });
      widget.diagnostics?.record('workspace.startup.hydration.ready', {
        'networkId': widget.session.networkId,
        'apiOrigin': widget.session.apiOrigin,
        'ms': watch.elapsedMilliseconds,
        'railRecordCount': _railNetworkRecords.length,
        'railServerCount': _joinedRailServers.length,
      });
      _handleControllerStateChanged();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialWorkspaceRevealReady = true;
        _initialWorkspaceRevealScheduled = false;
        _skipNextWorkspaceReadyMediaWarm = true;
      });
      widget.diagnostics?.record('workspace.startup.hydration.ready', {
        'networkId': widget.session.networkId,
        'apiOrigin': widget.session.apiOrigin,
        'ms': watch.elapsedMilliseconds,
        'railRecordCount': _railNetworkRecords.length,
        'railServerCount': _joinedRailServers.length,
        'errorType': error.runtimeType.toString(),
      });
      _handleControllerStateChanged();
    }
  }

  Future<void> _pollInactiveSummaryBadges() async {
    if (!mounted ||
        !widget.showBottomRail ||
        _joinedRailServers.isEmpty ||
        _railNetworkRecords.isEmpty) {
      return;
    }
    final nextRailServers = await _serversWithInactiveSummaryBadges(
      railServers: _joinedRailServers,
      records: _railNetworkRecords,
    );
    if (!mounted ||
        _sameRailServerBadges(_joinedRailServers, nextRailServers)) {
      return;
    }
    setState(() => _joinedRailServers = nextRailServers);
    _publishRailSnapshot();
  }

  void _applyRailSnapshot(WorkspaceRailSnapshot snapshot) {
    if (snapshot.isEmpty) {
      return;
    }
    _railNetworkRecords = List.unmodifiable(snapshot.records);
    _railNetworkOrder = List.unmodifiable(snapshot.networkOrder);
    _joinedRailServers = List.unmodifiable(snapshot.railServers);
  }

  void _publishRailSnapshot() {
    if (!widget.showBottomRail) {
      return;
    }
    widget.onRailSnapshotChanged?.call(
      WorkspaceRailSnapshot(
        records: _railNetworkRecords,
        networkOrder: _railNetworkOrder,
        railServers: _joinedRailServers,
      ),
    );
  }

  List<RailServerItem> _bottomRailServersForActiveWorkspace({
    required WorkspaceState state,
    required ServerSettingsData settings,
  }) {
    final activeRailServers = [
      for (final server in state.servers)
        RailServerItem.fromServer(
          networkId: settings.networkId,
          server: server,
          mediaPolicy: settings.mediaPolicy,
        ),
    ];
    if (_joinedRailServers.isEmpty) {
      return activeRailServers;
    }

    final activeServersByScopedId = {
      for (final server in activeRailServers) server.scopedServerId: server,
    };
    final seen = <String>{};
    final merged = <RailServerItem>[];
    int? activeInsertionIndex;

    for (final server in _joinedRailServers) {
      if (sameWorkspaceNetworkId(server.networkId, settings.networkId)) {
        activeInsertionIndex ??= merged.length;
        final replacement = activeServersByScopedId[server.scopedServerId];
        if (replacement != null && seen.add(replacement.scopedServerId)) {
          merged.add(replacement);
        }
        continue;
      }
      if (seen.add(server.scopedServerId)) {
        merged.add(server);
      }
    }

    final missingActiveServers = [
      for (final server in activeRailServers)
        if (seen.add(server.scopedServerId)) server,
    ];
    if (missingActiveServers.isEmpty) {
      return merged;
    }

    final insertionIndex = activeInsertionIndex ?? merged.length;
    merged.insertAll(insertionIndex, missingActiveServers);
    return merged;
  }

  List<ServerCustomEmojiGroup> _customEmojiGroupsForRailOrder({
    required ServerSettingsSeed activeSettings,
    required ServerMediaPolicy activeMediaPolicy,
    required List<RailServerItem> railServers,
  }) {
    final activeScopedServerId =
        '${activeSettings.networkId}/${activeSettings.localServerId}';
    final activeGroups = serverCustomEmojiGroupsFromSettings(
      activeSettings,
      mediaPolicy: activeMediaPolicy,
    );
    if (activeGroups.isEmpty) {
      _customEmojiGroupsByScopedServerId.remove(activeScopedServerId);
    } else {
      _customEmojiGroupsByScopedServerId[activeScopedServerId] =
          activeGroups.first;
    }

    final seen = <String>{};
    final groups = <ServerCustomEmojiGroup>[];
    for (final server in railServers) {
      final group = _customEmojiGroupsByScopedServerId[server.scopedServerId];
      if (group == null || group.emojis.isEmpty) {
        continue;
      }
      if (!seen.add(server.scopedServerId)) {
        continue;
      }
      groups.add(
        ServerCustomEmojiGroup(
          serverId: server.localServerId,
          networkId: server.networkId,
          label: server.name,
          iconUrl: server.iconUrl,
          mediaPolicy: group.mediaPolicy ?? server.mediaPolicy,
          emojis: group.emojis,
        ),
      );
    }

    if (!seen.contains(activeScopedServerId) && activeGroups.isNotEmpty) {
      groups.add(activeGroups.first);
    }
    return List.unmodifiable(groups);
  }

  List<ServerCustomStickerGroup> _customStickerGroupsForRailOrder({
    required ServerSettingsSeed activeSettings,
    required ServerMediaPolicy activeMediaPolicy,
    required List<RailServerItem> railServers,
  }) {
    final activeScopedServerId =
        '${activeSettings.networkId}/${activeSettings.localServerId}';
    final activeGroups = serverCustomStickerGroupsFromSettings(
      activeSettings,
      mediaPolicy: activeMediaPolicy,
    );
    if (activeGroups.isEmpty) {
      _customStickerGroupsByScopedServerId.remove(activeScopedServerId);
    } else {
      _customStickerGroupsByScopedServerId[activeScopedServerId] =
          activeGroups.first;
    }

    final seen = <String>{};
    final groups = <ServerCustomStickerGroup>[];
    for (final server in railServers) {
      final group = _customStickerGroupsByScopedServerId[server.scopedServerId];
      if (group == null || group.stickers.isEmpty) {
        continue;
      }
      if (!seen.add(server.scopedServerId)) {
        continue;
      }
      groups.add(
        ServerCustomStickerGroup(
          serverId: server.localServerId,
          networkId: server.networkId,
          label: server.name,
          iconUrl: server.iconUrl,
          mediaPolicy: group.mediaPolicy ?? server.mediaPolicy,
          stickers: group.stickers,
        ),
      );
    }

    if (!seen.contains(activeScopedServerId) && activeGroups.isNotEmpty) {
      groups.add(activeGroups.first);
    }
    return List.unmodifiable(groups);
  }

  void _reportWorkspaceReadyIfChanged() {
    final state = _controller.state;
    final activeServerId = state.activeServer?.id;
    final isReady =
        _initialWorkspaceRevealReady &&
        !state.isLoading &&
        state.settings != null &&
        state.error == null &&
        !_workspaceMediaHydrating &&
        !state.isChannelTransitionLoading &&
        !state.isServerMessagesLoading;
    if (_lastReportedWorkspaceReady == isReady &&
        _lastReportedWorkspaceReadyServerId == activeServerId) {
      return;
    }
    _lastReportedWorkspaceReady = isReady;
    _lastReportedWorkspaceReadyServerId = activeServerId;
    widget.onWorkspaceReadyChanged?.call(
      widget.session.networkId,
      isReady,
      activeServerId,
    );
  }

  void _selectPendingInitialServerIfLoaded() {
    final serverId = _pendingInitialRailServerId;
    if (serverId == null) {
      return;
    }
    if (_selectLoadedInitialServer(serverId)) {
      _pendingInitialRailServerId = null;
    }
  }

  bool _selectLoadedInitialServer(String serverId) {
    final state = _controller.state;
    if (state.isLoading || state.settings == null) {
      return false;
    }
    final activeServer = state.activeServer;
    if (activeServer?.id == serverId) {
      return true;
    }
    for (final server in state.servers) {
      if (server.id == serverId) {
        _selectRailServer(server);
        return true;
      }
    }
    widget.diagnostics?.record('workspace.rail.select.miss', {
      'networkId': widget.session.networkId,
      'server': serverId,
      'reason': 'initial_server_not_loaded',
      'activeNetworkId': widget.session.networkId,
      'scopedServerId': '${widget.session.networkId}/$serverId',
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        if (state.isLoading) {
          return const _WorkspaceStatus(
            label: 'Connecting...',
            showProgress: true,
          );
        }
        if (state.error != null || state.settings == null) {
          final error = state.error ?? 'Server workspace is unavailable';
          final federatedAccessExpired =
              state.isAuthExpired &&
              widget.session.credentialKind ==
                  AuthCredentialKind.federatedClient;
          return _WorkspaceStatus(
            label: error,
            actionLabel: federatedAccessExpired
                ? 'Reconnect'
                : state.isAuthExpired
                ? 'Sign In'
                : 'Retry',
            onAction: federatedAccessExpired
                ? _reconnectFederatedAccess
                : state.isAuthExpired
                ? widget.onLogout
                : _controller.refresh,
          );
        }
        if (!_initialWorkspaceRevealReady) {
          return const _WorkspaceStatus(
            label: 'Loading workspace...',
            showProgress: true,
          );
        }
        if (_workspaceMediaHydrating) {
          return const _WorkspaceStatus(
            label: 'Loading assets...',
            showProgress: true,
          );
        }

        final settings = state.settings!;
        final currentUser = state.currentUser ?? widget.session.user;
        final currentUserName = currentUser.displayLabel;
        final currentUserInitials = currentUser.initials;
        final currentUserBannerBaseColor =
            state.currentUserMedia?.bannerBaseColor ??
            _profileHexColor(currentUser.bannerBaseColor) ??
            (_userSettingsPreferences.profileBannerBaseColor == null
                ? null
                : Color(_userSettingsPreferences.profileBannerBaseColor!));
        final seed = WorkspaceSeed.fromSettingsData(
          settings,
          currentUserId: currentUser.id,
          currentUserName: currentUserName,
          currentUserInitials: currentUserInitials,
          currentUserAvatarUrl: currentUser.avatarUrl,
          currentUserBannerUrl: currentUser.bannerUrl,
          currentUserBannerBaseColor: currentUserBannerBaseColor,
          currentUserMemberListBannerUrl: currentUser.memberListBannerUrl,
          activeChannelId: state.activeChannelId,
          activeFeedId: state.activeFeedId,
          messages: state.serverMessages,
        );
        final railServers = _bottomRailServersForActiveWorkspace(
          state: state,
          settings: settings,
        );
        final customEmojiGroups = _customEmojiGroupsForRailOrder(
          activeSettings: seed.serverSettings,
          activeMediaPolicy: settings.mediaPolicy,
          railServers: railServers,
        );
        final customStickerGroups = _customStickerGroupsForRailOrder(
          activeSettings: seed.serverSettings,
          activeMediaPolicy: settings.mediaPolicy,
          railServers: railServers,
        );
        final activeScopedServerId = state.activeServer == null
            ? null
            : '${settings.networkId}/${state.activeServer!.id}';
        final activeFeed = _activeFeedForId(settings.feeds, state.activeFeedId);
        final dmData =
            state.directMessages ??
            DirectMessagesWorkspaceData.empty(
              networkId: settings.networkId,
              currentUserName: currentUserName,
              currentUserInitials: currentUserInitials,
            );
        final showSessionLogout =
            widget.session.credentialKind != AuthCredentialKind.federatedClient;

        final appearanceTheme = _workspaceThemeFor(_userSettingsPreferences);
        final appearanceColors = appearanceTheme
            .extension<VerdantThemeColors>()!;
        return Theme(
          data: appearanceTheme,
          child: Scaffold(
            backgroundColor: appearanceColors.background,
            body: DecoratedBox(
              decoration: BoxDecoration(color: appearanceColors.background),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 1100;
                      final serverWidth = compact ? 220.0 : 360.0;
                      final contextWidth = compact ? 210.0 : 320.0;
                      final settingsWidth = constraints.maxWidth < 720
                          ? constraints.maxWidth
                          : (constraints.maxWidth * 0.6)
                                .clamp(640.0, 820.0)
                                .toDouble();
                      final serverSettingsWidth = constraints.maxWidth >= 960
                          ? 820.0
                          : settingsWidth;

                      return Column(
                        children: [
                          Expanded(
                            child: _WorkspaceTextScale(
                              scale: _accessibilitySettings.textScaleFactor,
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      KeyedSubtree(
                                        key: const ValueKey(
                                          'network-left-workspace-region',
                                        ),
                                        child: _LeftWorkspacePane(
                                          width: serverWidth,
                                          showDirectMessages:
                                              _directMessagesOpen,
                                          serverChild: ServerWorkspace(
                                            key: ValueKey(
                                              'server-sidebar-${activeScopedServerId ?? 'none'}',
                                            ),
                                            seed: seed,
                                            width: serverWidth,
                                            currentUserId: currentUser.id,
                                            currentUserName: currentUserName,
                                            currentUserInitials:
                                                currentUserInitials,
                                            currentUserUsername:
                                                currentUser.username,
                                            currentUserAvatarUrl:
                                                currentUser.avatarUrl,
                                            currentUserBannerUrl:
                                                state
                                                    .currentUserMedia
                                                    ?.bannerUrl ??
                                                currentUser.bannerUrl,
                                            currentUserBannerBaseColor:
                                                currentUserBannerBaseColor,
                                            currentUserBannerCrop: state
                                                .currentUserMedia
                                                ?.bannerCrop,
                                            currentUserStatus:
                                                state
                                                    .currentUserMedia
                                                    ?.status ??
                                                currentUser.status,
                                            currentUserBio: currentUser.bio,
                                            showLogout: showSessionLogout,
                                            onLogout: widget.onLogout,
                                            onOpenServerSettings:
                                                _openServerSettings,
                                            onOpenUserSettings:
                                                _openUserSettings,
                                            onOpenChannelSettings: (channel) =>
                                                _openChannelSettings(
                                                  channel,
                                                  ChannelSettingsTabId.overview,
                                                ),
                                            onOpenChannelPermissions:
                                                (channel) =>
                                                    _openChannelSettings(
                                                      channel,
                                                      ChannelSettingsTabId
                                                          .permissions,
                                                    ),
                                            onUpdateCurrentUserStatus:
                                                _controller
                                                    .updateCurrentUserStatus,
                                            onSelectTextChannel: (channel) =>
                                                _controller.selectTextChannel(
                                                  channel.id,
                                                ),
                                            onSelectFeed: (feed) => _controller
                                                .selectAnnouncementFeed(
                                                  feed.id ?? feed.title,
                                                ),
                                          ),
                                          directMessagesChild: DmSidebarModule(
                                            data: dmData,
                                            width: serverWidth,
                                            activeChannelId: state
                                                .activeDmConversation
                                                ?.channelId,
                                            currentUserId: currentUser.id,
                                            currentUserUsername:
                                                currentUser.username,
                                            currentUserAvatarUrl:
                                                currentUser.avatarUrl,
                                            currentUserBannerUrl:
                                                state
                                                    .currentUserMedia
                                                    ?.bannerUrl ??
                                                currentUser.bannerUrl,
                                            currentUserBannerBaseColor:
                                                currentUserBannerBaseColor,
                                            currentUserBannerCrop: state
                                                .currentUserMedia
                                                ?.bannerCrop,
                                            currentUserBio: currentUser.bio,
                                            mediaPolicy: seed.mediaPolicy,
                                            showLogout: showSessionLogout,
                                            onLogout: widget.onLogout,
                                            onOpenUserSettings:
                                                _openUserSettings,
                                            onUpdateCurrentUserStatus:
                                                _controller
                                                    .updateCurrentUserStatus,
                                            onShowFriends: _controller
                                                .showDirectMessageFriends,
                                            onOpenConversation: _controller
                                                .openDirectMessageConversation,
                                            onCloseConversation: _controller
                                                .closeDirectMessageConversation,
                                            onRemoveFriend:
                                                _controller.removeRelationship,
                                          ),
                                        ),
                                      ),
                                      const _VerticalRule(),
                                      Expanded(
                                        child: KeyedSubtree(
                                          key: const ValueKey(
                                            'network-main-workspace-region',
                                          ),
                                          child: _MainWorkspacePane(
                                            showDirectMessages:
                                                _directMessagesOpen,
                                            serverChild: Column(
                                              key: ValueKey(
                                                'server-workspace-${activeScopedServerId ?? 'none'}',
                                              ),
                                              children: [
                                                if (activeFeed == null)
                                                  ChannelHeaderModule(
                                                    channelName:
                                                        _selectedChannelName(
                                                          seed,
                                                        ),
                                                    seed: seed,
                                                    messages:
                                                        state.serverMessages,
                                                    members: _mergeChatMembers(
                                                      seed.members,
                                                      state
                                                          .activeChannelMembers,
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            activeFeed == null
                                                            ? ChatWorkspace(
                                                                seed: seed,
                                                                currentUserId:
                                                                    currentUser
                                                                        .id,
                                                                currentUserName:
                                                                    currentUserName,
                                                                currentUserInitials:
                                                                    currentUserInitials,
                                                                isLoading: state
                                                                    .isServerMessagesLoading,
                                                                error: state
                                                                    .serverMessagesError,
                                                                identityMembers:
                                                                    _mergeChatMembers(
                                                                      seed.members,
                                                                      state
                                                                          .activeChannelMembers,
                                                                    ),
                                                                typingMembers: state
                                                                    .activeTypingMembers,
                                                                hasOlderMessages:
                                                                    state
                                                                        .hasMoreServerMessages,
                                                                isLoadingOlderMessages:
                                                                    state
                                                                        .isLoadingOlderServerMessages,
                                                                klipyRepository:
                                                                    _klipyMediaRepository,
                                                                linkPreviewService:
                                                                    _messageLinkPreviewService,
                                                                customEmojiGroups:
                                                                    customEmojiGroups,
                                                                customStickerGroups:
                                                                    customStickerGroups,
                                                                showHeader:
                                                                    false,
                                                                onSendMessage:
                                                                    _controller
                                                                        .sendServerMessage,
                                                                onTyping:
                                                                    _controller
                                                                        .sendServerTypingStart,
                                                                onLoadOlderMessages:
                                                                    _controller
                                                                        .loadOlderServerMessages,
                                                                onDeleteMessage:
                                                                    _controller
                                                                        .deleteServerMessage,
                                                                onSetReaction:
                                                                    _controller
                                                                        .setServerReaction,
                                                                onPreviewInvite:
                                                                    _previewChatInvite,
                                                                onAcceptInvite:
                                                                    _acceptChatInvite,
                                                                onPrepareMemberProfile:
                                                                    _controller
                                                                        .prepareMemberProfile,
                                                              )
                                                            : AnnouncementFeedWorkspace(
                                                                feed:
                                                                    activeFeed,
                                                                seed: seed,
                                                                announcementRepository:
                                                                    _repository
                                                                        is AnnouncementFeedRepository
                                                                    ? _repository
                                                                          as AnnouncementFeedRepository
                                                                    : null,
                                                              ),
                                                      ),
                                                      const _VerticalRule(),
                                                      ContextWorkspace(
                                                        members: seed.members,
                                                        activeMembers:
                                                            state
                                                                .hasChannelActivityData
                                                            ? state
                                                                  .activeChannelMembers
                                                            : null,
                                                        isLoading: state
                                                            .isChannelActivityLoading,
                                                        mediaPolicy:
                                                            seed.mediaPolicy,
                                                        width: contextWidth,
                                                        onOpenMemberContextMenu:
                                                            _showMemberContextMenu,
                                                        onPrepareMemberProfile:
                                                            _controller
                                                                .prepareMemberProfile,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            directMessagesChild:
                                                state.activeDmConversation ==
                                                    null
                                                ? FriendsListModule(
                                                    data: dmData,
                                                    onAddFriend: _controller
                                                        .sendFriendRequest,
                                                    onAcceptFriend: _controller
                                                        .acceptFriendRequest,
                                                    onRemoveFriend: _controller
                                                        .removeRelationship,
                                                    onMessageFriend: _controller
                                                        .openDirectMessage,
                                                    mediaPolicy:
                                                        seed.mediaPolicy,
                                                  )
                                                : DmConversationModule(
                                                    conversation: state
                                                        .activeDmConversation!,
                                                    messages: state.dmMessages,
                                                    isLoading: state
                                                        .isDmMessagesLoading,
                                                    error:
                                                        state.dmMessagesError,
                                                    hasOlderMessages:
                                                        state.hasMoreDmMessages,
                                                    isLoadingOlderMessages: state
                                                        .isLoadingOlderDmMessages,
                                                    mediaPolicy:
                                                        seed.mediaPolicy,
                                                    currentUserId:
                                                        currentUser.id,
                                                    currentUserName:
                                                        dmData.currentUserName,
                                                    currentUserInitials: dmData
                                                        .currentUserInitials,
                                                    onSendMessage: _controller
                                                        .sendDirectMessage,
                                                    onLoadOlderMessages: _controller
                                                        .loadOlderDirectMessages,
                                                    onDeleteMessage: _controller
                                                        .deleteDirectMessage,
                                                    klipyRepository:
                                                        _klipyMediaRepository,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_serverDrawerOpen)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _serverDrawerCurve,
                                        builder: (context, _) {
                                          final value =
                                              _serverDrawerCurve.value;
                                          return Semantics(
                                            key: const ValueKey(
                                              'server-drawer-backdrop',
                                            ),
                                            button: true,
                                            label: 'Close server list',
                                            child: Material(
                                              color: Color.fromARGB(
                                                (0x33 * value).round(),
                                                0,
                                                0,
                                                0,
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  unawaited(
                                                    _closeServerDrawer(),
                                                  );
                                                },
                                                hoverColor: Colors.transparent,
                                                splashColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                child: const SizedBox.expand(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  if (_serverDrawerOpen)
                                    Positioned(
                                      left: 74,
                                      bottom: 8,
                                      child: AnimatedBuilder(
                                        animation: _serverDrawerCurve,
                                        builder: (context, child) {
                                          final value =
                                              _serverDrawerCurve.value;
                                          return Opacity(
                                            opacity: value
                                                .clamp(0, 1)
                                                .toDouble(),
                                            child: ClipRect(
                                              child: Align(
                                                alignment: Alignment.bottomLeft,
                                                widthFactor: value
                                                    .clamp(0.04, 1)
                                                    .toDouble(),
                                                heightFactor: value
                                                    .clamp(0.04, 1)
                                                    .toDouble(),
                                                child: child,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ServerDrawerModule(
                                          networkId: settings.networkId,
                                          networkName: _railNetworkName(
                                            settings.networkId,
                                          ),
                                          servers: state.servers,
                                          activeServerId:
                                              state.activeServer?.id,
                                          mediaPolicy: settings.mediaPolicy,
                                          onSelectServer: (server) {
                                            _selectRailServer(server);
                                          },
                                          onClose: () {
                                            unawaited(_closeServerDrawer());
                                          },
                                        ),
                                      ),
                                    ),
                                  if (_channelSettingsOpen &&
                                      _activeChannelSettingsChannel(settings) !=
                                          null)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _channelSettingsCurve,
                                        builder: (context, child) {
                                          final value =
                                              _channelSettingsCurve.value;
                                          return Stack(
                                            children: [
                                              GestureDetector(
                                                key: const ValueKey(
                                                  'channel-settings-backdrop',
                                                ),
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: _closeChannelSettings,
                                                child: ColoredBox(
                                                  color: Color.fromARGB(
                                                    (0x99 * value).round(),
                                                    0,
                                                    0,
                                                    0,
                                                  ),
                                                  child:
                                                      const SizedBox.expand(),
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    serverSettingsWidth *
                                                        (1 - value),
                                                    0,
                                                  ),
                                                  child: child,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        child: SizedBox(
                                          width: settingsWidth,
                                          child: ChannelSettingsWorkspace(
                                            data: settings,
                                            channel:
                                                _activeChannelSettingsChannel(
                                                  settings,
                                                )!,
                                            initialTab: _channelSettingsTab,
                                            repository:
                                                _repository
                                                    is ChannelSettingsRepository
                                                ? _repository
                                                      as ChannelSettingsRepository
                                                : null,
                                            canManageChannels:
                                                ServerSettingsSeed.fromData(
                                                  settings,
                                                  currentUserId: currentUser.id,
                                                ).canManageChannels,
                                            onChannelUpdated:
                                                _handleChannelUpdated,
                                            onClose: _closeChannelSettings,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_userSettingsOpen &&
                                      widget.onWindowOverlayChanged == null)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _userSettingsCurve,
                                        builder: (context, child) {
                                          final value =
                                              _userSettingsCurve.value;
                                          return Stack(
                                            children: [
                                              GestureDetector(
                                                key: const ValueKey(
                                                  'user-settings-backdrop',
                                                ),
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: _closeUserSettings,
                                                child: ColoredBox(
                                                  color: Color.fromARGB(
                                                    (0x99 * value).round(),
                                                    0,
                                                    0,
                                                    0,
                                                  ),
                                                  child:
                                                      const SizedBox.expand(),
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    settingsWidth * (1 - value),
                                                    0,
                                                  ),
                                                  child: child,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        child: SizedBox(
                                          width: settingsWidth,
                                          child: _buildUserSettingsWorkspace(
                                            settings: settings,
                                            currentUser: currentUser,
                                            state: state,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          ExcludeSemantics(
                            excluding:
                                !widget.showBottomRail ||
                                !widget.railInteractionsEnabled,
                            child: IgnorePointer(
                              ignoring:
                                  !widget.showBottomRail ||
                                  !widget.railInteractionsEnabled,
                              child: Opacity(
                                opacity: widget.showBottomRail ? 1 : 0,
                                child: BottomRailWorkspace(
                                  networkId: settings.networkId,
                                  servers: state.servers,
                                  activeServerId: state.activeServer?.id,
                                  mediaPolicy: settings.mediaPolicy,
                                  railServers: railServers,
                                  networkRecords: _railNetworkRecords,
                                  networkOrder: _railNetworkOrder,
                                  directMessagesOpen: _directMessagesOpen,
                                  serverGridOpen: _serverDrawerOpen,
                                  onToggleDirectMessages: _toggleDirectMessages,
                                  onToggleServerGrid: _toggleServerDrawer,
                                  onSelectServer: _selectRailServer,
                                  onSelectRailServer: _selectScopedRailServer,
                                  onCreateServer: _openCreateServer,
                                  onJoinServer: _openJoinServer,
                                  onJoinNetwork: _openJoinNetwork,
                                  onCreateInviteForServer:
                                      _createInviteForRailServer,
                                  onLeaveServer: _confirmLeaveRailServer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: SizedBox.shrink(
                      key: ValueKey(
                        'workspace-appearance-${_userSettingsPreferences.theme.value}-${_userSettingsPreferences.density.value}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openServerSettings() {
    final settings = _controller.state.settings;
    if (settings == null) {
      return;
    }
    final currentUser = _controller.state.currentUser ?? widget.session.user;
    final settingsSeed = ServerSettingsSeed.fromData(
      settings,
      currentUserId: currentUser.id,
    );
    if (!settingsSeed.canManageServer) {
      return;
    }
    if (!_serverSettingsOpen) {
      setState(() {
        _serverSettingsOpen = true;
        _channelSettingsOpen = false;
        _userSettingsOpen = false;
      });
      _channelSettingsAnimation.value = 0;
      _userSettingsAnimation.value = 0;
      _clearUserSettingsWindowOverlay();
    }
    _publishServerSettingsWindowOverlay();
    _serverSettingsAnimation.forward();
  }

  void _publishServerSettingsWindowOverlay() {
    final publisher = widget.onWindowOverlayChanged;
    if (publisher == null) {
      return;
    }
    _ownsServerSettingsWindowOverlay = true;
    publisher(_buildServerSettingsWindowOverlay);
  }

  Widget _buildServerSettingsWindowOverlay(BuildContext context) {
    final settings = _controller.state.settings;
    if (!_serverSettingsOpen || settings == null) {
      return const SizedBox.shrink();
    }
    final currentUser = _controller.state.currentUser ?? widget.session.user;
    final appearanceTheme = _workspaceThemeFor(_userSettingsPreferences);
    final size = MediaQuery.sizeOf(context);
    final settingsWidth = size.width < 720
        ? size.width
        : (size.width * 0.6).clamp(640.0, 820.0).toDouble();
    final serverSettingsWidth = size.width >= 960 ? 820.0 : settingsWidth;

    return Theme(
      data: appearanceTheme,
      child: _WorkspaceTextScale(
        scale: _accessibilitySettings.textScaleFactor,
        child: AnimatedBuilder(
          animation: _serverSettingsCurve,
          builder: (context, child) {
            final value = _serverSettingsCurve.value;
            return Stack(
              key: const ValueKey('server-settings-root-overlay'),
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('server-settings-backdrop'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeServerSettings,
                    child: ColoredBox(
                      color: Color.fromARGB((0xAA * value).round(), 0, 0, 0),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: Offset(serverSettingsWidth * (1 - value), 0),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: SizedBox(
            width: serverSettingsWidth,
            height: double.infinity,
            child: RepaintBoundary(
              child: ServerSettingsWorkspace(
                data: settings,
                repository: _repository,
                onServerUpdated: _controller.replaceActiveServer,
                onEmojisChanged: _controller.updateCachedEmojis,
                onStickersChanged: _controller.updateCachedStickers,
                onClose: _closeServerSettings,
                currentUserId: currentUser.id,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _publishUserSettingsWindowOverlay() {
    final publisher = widget.onWindowOverlayChanged;
    if (publisher == null) {
      return;
    }
    _ownsUserSettingsWindowOverlay = true;
    publisher(_buildUserSettingsWindowOverlay);
  }

  Widget _buildUserSettingsWindowOverlay(BuildContext context) {
    final state = _controller.state;
    final settings = state.settings;
    if (!_userSettingsOpen || settings == null) {
      return const SizedBox.shrink();
    }
    final currentUser = state.currentUser ?? widget.session.user;
    final appearanceTheme = _workspaceThemeFor(_userSettingsPreferences);
    final size = MediaQuery.sizeOf(context);
    final settingsWidth = size.width < 720
        ? size.width
        : (size.width * 0.6).clamp(640.0, 820.0).toDouble();
    final userSettingsWidth = size.width >= 960 ? 820.0 : settingsWidth;

    return Theme(
      data: appearanceTheme,
      child: _WorkspaceTextScale(
        scale: _accessibilitySettings.textScaleFactor,
        child: AnimatedBuilder(
          animation: _userSettingsCurve,
          builder: (context, child) {
            final value = _userSettingsCurve.value;
            return Stack(
              key: const ValueKey('user-settings-root-overlay'),
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('user-settings-backdrop'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeUserSettings,
                    child: ColoredBox(
                      color: Color.fromARGB((0x99 * value).round(), 0, 0, 0),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: Offset(userSettingsWidth * (1 - value), 0),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: SizedBox(
            width: userSettingsWidth,
            height: double.infinity,
            child: RepaintBoundary(
              child: _buildUserSettingsWorkspace(
                settings: settings,
                currentUser: currentUser,
                state: state,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSettingsWorkspace({
    required ServerSettingsData settings,
    required VerdantUser currentUser,
    required WorkspaceState state,
  }) {
    final networkRecordsKey = _railNetworkRecords
        .map((record) => record.networkId)
        .join('|');
    return UserSettingsWorkspace(
      key: ValueKey('user-settings-${settings.networkId}-$networkRecordsKey'),
      currentUser: currentUser,
      currentUserMedia: state.currentUserMedia,
      mediaPolicy: settings.mediaPolicy,
      entitlements: state.entitlements,
      repository: _repository is UserSettingsRepository
          ? _repository as UserSettingsRepository
          : null,
      settingsContexts: _userSettingsContexts(
        activeUser: currentUser,
        activeUserMedia: state.currentUserMedia,
        activeSettings: settings,
        activeEntitlements: state.entitlements,
      ),
      accessibilitySettings: _accessibilitySettings,
      preferencesStore: _userSettingsPreferencesStore,
      networkRecords: _railNetworkRecords,
      activeNetworkId: settings.networkId,
      homeNetworkId: widget.session.networkId,
      onPreferencesChanged: _applyUserSettingsPreferences,
      onAccessibilityChanged: _updateAccessibilitySettings,
      onProfileUpdated: _controller.refreshCurrentUserProfile,
      onSetNetworkUsername: _openNetworkUsernameFromSettings,
      onRetryNetwork: _retryNetworkFromSettings,
      onRemoveNetwork: _removeNetworkFromSettings,
      onClose: _closeUserSettings,
    );
  }

  void _openChannelSettings(ChannelSeed channel, ChannelSettingsTabId tab) {
    final settings = _controller.state.settings;
    if (settings == null) {
      return;
    }
    final currentUser = _controller.state.currentUser ?? widget.session.user;
    final settingsSeed = ServerSettingsSeed.fromData(
      settings,
      currentUserId: currentUser.id,
    );
    if (!settingsSeed.canManageChannels) {
      return;
    }
    final fallback = ServerSettingsChannelSeed(
      id: channel.id,
      name: channel.name,
      type: channel.type,
      topic: channel.topic,
      readOnly: channel.readOnly,
      slowmodeSeconds: channel.slowmodeSeconds,
      unread: channel.unread,
      mentionCount: channel.mentionCount,
    );
    setState(() {
      _channelSettingsOpen = true;
      _serverSettingsOpen = false;
      _userSettingsOpen = false;
      _channelSettingsChannelId = channel.id;
      _channelSettingsFallback = fallback;
      _channelSettingsTab = tab;
    });
    _serverSettingsAnimation.value = 0;
    _clearServerSettingsWindowOverlay();
    _userSettingsAnimation.value = 0;
    _clearUserSettingsWindowOverlay();
    _hideServerDrawerImmediately();
    _channelSettingsAnimation.forward();
  }

  ServerSettingsChannelSeed? _activeChannelSettingsChannel(
    ServerSettingsData settings,
  ) {
    final channelId = _channelSettingsChannelId;
    if (channelId == null) {
      return null;
    }
    for (final channel in settings.channels) {
      if (channel.id == channelId) {
        return channel;
      }
    }
    return _channelSettingsFallback;
  }

  void _handleChannelUpdated(ServerSettingsChannelSeed channel) {
    _channelSettingsFallback = channel;
    _controller.updateCachedChannel(channel);
  }

  void _closeChannelSettings() {
    if (!_channelSettingsOpen) {
      return;
    }
    _channelSettingsAnimation.reverse().whenComplete(() {
      if (!mounted) {
        return;
      }
      if (_channelSettingsAnimation.value == 0) {
        setState(() => _channelSettingsOpen = false);
      }
    });
  }

  void _openUserSettings() {
    if (_serverSettingsOpen) {
      _closeServerSettings();
      _clearServerSettingsWindowOverlay();
    }
    if (_channelSettingsOpen) {
      _closeChannelSettings();
    }
    _hideServerDrawerImmediately();
    if (!_userSettingsOpen) {
      setState(() => _userSettingsOpen = true);
    }
    _publishUserSettingsWindowOverlay();
    _userSettingsAnimation.forward();
  }

  void _closeUserSettings() {
    if (!_userSettingsOpen) {
      return;
    }
    _userSettingsAnimation.reverse().whenComplete(() {
      if (!mounted) {
        return;
      }
      if (_userSettingsAnimation.value == 0) {
        setState(() => _userSettingsOpen = false);
        _clearUserSettingsWindowOverlay();
      }
    });
  }

  Future<void> _loadAccessibilitySettings() async {
    final settings = await _accessibilitySettingsStore.load();
    if (!mounted) {
      return;
    }
    setState(() => _accessibilitySettings = settings);
  }

  Future<void> _loadUserSettingsPreferences() async {
    final preferences = await _userSettingsPreferencesStore.load();
    if (!mounted) {
      return;
    }
    setState(() => _userSettingsPreferences = preferences);
    if (_serverSettingsOpen) {
      _publishServerSettingsWindowOverlay();
    }
    if (_userSettingsOpen && widget.onWindowOverlayChanged != null) {
      _publishUserSettingsWindowOverlay();
    }
    widget.onUserSettingsPreferencesChanged?.call(preferences);
  }

  void _updateAccessibilitySettings(WorkspaceAccessibilitySettings settings) {
    setState(() => _accessibilitySettings = settings);
    if (_serverSettingsOpen) {
      _publishServerSettingsWindowOverlay();
    }
    if (_userSettingsOpen && widget.onWindowOverlayChanged != null) {
      _publishUserSettingsWindowOverlay();
    }
    unawaited(_accessibilitySettingsStore.save(settings));
  }

  void _applyUserSettingsPreferences(UserSettingsPreferences preferences) {
    setState(() => _userSettingsPreferences = preferences);
    if (_serverSettingsOpen) {
      _publishServerSettingsWindowOverlay();
    }
    if (_userSettingsOpen && widget.onWindowOverlayChanged != null) {
      _publishUserSettingsWindowOverlay();
    }
    widget.onUserSettingsPreferencesChanged?.call(preferences);
  }

  void _toggleDirectMessages() {
    final nextOpen = !_directMessagesOpen;
    setState(() {
      _directMessagesOpen = nextOpen;
      _hideServerDrawerImmediately();
    });
    _configureDirectMessagesRefresh(nextOpen);
  }

  void _toggleServerDrawer() {
    if (_serverDrawerOpen) {
      unawaited(_closeServerDrawer());
      return;
    }
    setState(() => _serverDrawerOpen = true);
    _serverDrawerAnimation.forward(from: 0);
  }

  Future<void> _closeServerDrawer() async {
    if (!_serverDrawerOpen) {
      return;
    }
    await _serverDrawerAnimation.reverse();
    if (!mounted) {
      return;
    }
    setState(() => _serverDrawerOpen = false);
  }

  bool _beginRailSelection({
    required String scopedServerId,
    required String networkId,
    required String serverId,
    required String activeNetworkId,
    required String busyReason,
  }) {
    final pendingScopedServerId = _pendingRailSelectionScopedId;
    if (pendingScopedServerId != null) {
      widget.diagnostics?.record('workspace.rail.select.busy_ignore', {
        'networkId': networkId,
        'server': serverId,
        'activeNetworkId': activeNetworkId,
        'scopedServerId': scopedServerId,
        'pendingScopedServerId': pendingScopedServerId,
        'reason': pendingScopedServerId == scopedServerId
            ? busyReason
            : 'pending_selection',
      });
      return false;
    }
    _pendingRailSelectionScopedId = scopedServerId;
    return true;
  }

  void _finishRailSelection(String scopedServerId) {
    if (_pendingRailSelectionScopedId == scopedServerId) {
      _pendingRailSelectionScopedId = null;
    }
  }

  void _startRailSwitchDiagnostics({
    required String scopedServerId,
    required String targetNetworkId,
    required String targetServerId,
    required String activeNetworkId,
    required String apiOrigin,
  }) {
    _clearRailSwitchDiagnostics();
    _railSwitchDiagnosticsScopedId = scopedServerId;
    _railSwitchDiagnosticsWatch = Stopwatch()..start();
    void callback(List<FrameTiming> timings) {
      if (_railSwitchDiagnosticsScopedId != scopedServerId) {
        return;
      }
      _railSwitchFrameTimings.addAll(timings);
    }

    _railSwitchTimingsCallback = callback;
    WidgetsBinding.instance.addTimingsCallback(callback);
    widget.diagnostics?.record('workspace.rail.switch.probe.start', {
      'targetNetworkId': targetNetworkId,
      'targetServerId': targetServerId,
      'activeNetworkId': activeNetworkId,
      'scopedServerId': scopedServerId,
      'apiOrigin': apiOrigin,
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _railSwitchDiagnosticsScopedId != scopedServerId) {
        return;
      }
      widget.diagnostics?.record('workspace.rail.switch.probe.first_frame', {
        'targetNetworkId': targetNetworkId,
        'targetServerId': targetServerId,
        'activeNetworkId': activeNetworkId,
        'scopedServerId': scopedServerId,
        'ms': _railSwitchDiagnosticsWatch?.elapsedMilliseconds ?? 0,
        'frameCount': _railSwitchFrameTimings.length,
      });
    });
  }

  void _recordRailSwitchActivationComplete({
    required String scopedServerId,
    required String targetNetworkId,
    required String targetServerId,
    required String activeNetworkId,
    required NetworkSessionActivationResult result,
  }) {
    widget.diagnostics?.record('workspace.rail.switch.activation_complete', {
      'targetNetworkId': targetNetworkId,
      'targetServerId': targetServerId,
      'activeNetworkId': activeNetworkId,
      'scopedServerId': scopedServerId,
      'status': result.status.name,
      'opened': result.opened,
      'ms': _railSwitchDiagnosticsWatch?.elapsedMilliseconds ?? 0,
      'frameCount': _railSwitchFrameTimings.length,
    });
  }

  void _scheduleRailSwitchDiagnosticsFinish({
    required String scopedServerId,
    required String targetNetworkId,
    required String targetServerId,
    required String activeNetworkId,
    required String status,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _railSwitchDiagnosticsScopedId != scopedServerId) {
          return;
        }
        _finishRailSwitchDiagnostics(
          scopedServerId: scopedServerId,
          targetNetworkId: targetNetworkId,
          targetServerId: targetServerId,
          activeNetworkId: activeNetworkId,
          status: status,
        );
      });
    });
  }

  void _finishRailSwitchDiagnostics({
    required String scopedServerId,
    required String targetNetworkId,
    required String targetServerId,
    required String activeNetworkId,
    required String status,
  }) {
    if (_railSwitchDiagnosticsScopedId != scopedServerId) {
      return;
    }
    final watch = _railSwitchDiagnosticsWatch;
    final timings = List<FrameTiming>.of(_railSwitchFrameTimings);
    widget.diagnostics?.record('workspace.rail.switch.probe.finish', {
      'targetNetworkId': targetNetworkId,
      'targetServerId': targetServerId,
      'activeNetworkId': activeNetworkId,
      'scopedServerId': scopedServerId,
      'status': status,
      'ms': watch?.elapsedMilliseconds ?? 0,
      'frameCount': timings.length,
      'maxFrameTotalUs': _maxFrameTimingMicros(
        timings.map((timing) => timing.totalSpan),
      ),
      'maxBuildUs': _maxFrameTimingMicros(
        timings.map((timing) => timing.buildDuration),
      ),
      'maxRasterUs': _maxFrameTimingMicros(
        timings.map((timing) => timing.rasterDuration),
      ),
    });
    _clearRailSwitchDiagnostics();
  }

  int _maxFrameTimingMicros(Iterable<Duration> timings) {
    var maxMicros = 0;
    for (final timing in timings) {
      if (timing.inMicroseconds > maxMicros) {
        maxMicros = timing.inMicroseconds;
      }
    }
    return maxMicros;
  }

  void _clearRailSwitchDiagnostics() {
    final callback = _railSwitchTimingsCallback;
    if (callback != null) {
      WidgetsBinding.instance.removeTimingsCallback(callback);
    }
    _railSwitchTimingsCallback = null;
    _railSwitchDiagnosticsScopedId = null;
    _railSwitchDiagnosticsWatch = null;
    _railSwitchFrameTimings.clear();
  }

  void _selectRailServer(ServerSettingsServer server) {
    final watch = Stopwatch()..start();
    final scopedServerId = '${widget.session.networkId}/${server.id}';
    if (!_beginRailSelection(
      scopedServerId: scopedServerId,
      networkId: widget.session.networkId,
      serverId: server.id,
      activeNetworkId: widget.session.networkId,
      busyReason: 'pending_local_selection',
    )) {
      return;
    }
    widget.diagnostics?.record('workspace.rail.select.local', {
      'networkId': widget.session.networkId,
      'server': server.id,
      'activeNetworkId': widget.session.networkId,
      'scopedServerId': scopedServerId,
    });
    setState(() {
      _directMessagesOpen = false;
      _hideServerDrawerImmediately();
    });
    _configureDirectMessagesRefresh(false);
    unawaited(
      _controller.selectServer(server).whenComplete(() {
        _finishRailSelection(scopedServerId);
        widget.diagnostics?.record('workspace.rail.select.local.complete', {
          'ms': watch.elapsedMilliseconds,
          'networkId': widget.session.networkId,
          'server': server.id,
          'activeNetworkId': widget.session.networkId,
          'scopedServerId': scopedServerId,
        });
      }),
    );
  }

  Future<void> _reconnectFederatedAccess() async {
    if (widget.session.credentialKind != AuthCredentialKind.federatedClient) {
      await _controller.refresh();
      return;
    }
    final activeServerId =
        _controller.state.activeServer?.id ?? widget.initialServerId;
    final activateNetwork = widget.onActivateNetwork;
    if (activateNetwork == null) {
      widget.diagnostics?.record('workspace.federated.reconnect.skip', {
        'networkId': widget.session.networkId,
        'apiOrigin': widget.session.apiOrigin,
        'reason': 'activation_unavailable',
        'hasActiveServer': activeServerId != null,
      });
      await _controller.refresh();
      return;
    }

    final watch = Stopwatch()..start();
    widget.diagnostics?.record('workspace.federated.reconnect.start', {
      'networkId': widget.session.networkId,
      'apiOrigin': widget.session.apiOrigin,
      'hasActiveServer': activeServerId != null,
    });
    final result = await activateNetwork(
      apiOrigin: widget.session.apiOrigin,
      initialServerId: activeServerId,
    );
    widget.diagnostics?.record('workspace.federated.reconnect.result', {
      'ms': watch.elapsedMilliseconds,
      'networkId': widget.session.networkId,
      'apiOrigin': widget.session.apiOrigin,
      'status': result.status.name,
      'hasActiveServer': activeServerId != null,
    });
    if (!mounted) {
      return;
    }
    if (result.opened) {
      await _controller.refresh();
      return;
    }
    _showRailNotice('Could not reconnect federated access');
  }

  Future<void> _selectScopedRailServer(RailServerItem railServer) async {
    final watch = Stopwatch()..start();
    final activeNetworkId =
        _controller.state.settings?.networkId ?? widget.session.networkId;
    final scopedServerId = railServer.scopedServerId;
    if (sameWorkspaceNetworkId(railServer.networkId, activeNetworkId)) {
      ServerSettingsServer? server;
      for (final candidate in _controller.state.servers) {
        if (candidate.id == railServer.localServerId) {
          server = candidate;
          break;
        }
      }
      if (server != null) {
        _selectRailServer(server);
      } else {
        widget.diagnostics?.record('workspace.rail.select.miss', {
          'networkId': railServer.networkId,
          'server': railServer.localServerId,
          'reason': 'local_server_not_loaded',
          'activeNetworkId': activeNetworkId,
          'scopedServerId': scopedServerId,
        });
      }
      return;
    }

    final record = _railNetworkRecordFor(railServer.networkId);
    final apiOrigin = record?.apiOrigin;
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      widget.diagnostics?.record('workspace.rail.select.miss', {
        'networkId': railServer.networkId,
        'server': railServer.localServerId,
        'reason': 'missing_api_origin',
        'activeNetworkId': activeNetworkId,
        'scopedServerId': scopedServerId,
      });
      _showRailNotice('This network is missing its API origin');
      return;
    }
    final activateNetwork = widget.onActivateNetwork;
    if (activateNetwork == null) {
      widget.diagnostics?.record('workspace.rail.select.miss', {
        'networkId': railServer.networkId,
        'server': railServer.localServerId,
        'reason': 'activation_unavailable',
        'activeNetworkId': activeNetworkId,
        'scopedServerId': scopedServerId,
      });
      _showRailNotice('This network cannot be opened yet');
      return;
    }
    if (!_beginRailSelection(
      scopedServerId: scopedServerId,
      networkId: railServer.networkId,
      serverId: railServer.localServerId,
      activeNetworkId: activeNetworkId,
      busyReason: 'pending_activation',
    )) {
      return;
    }
    _startRailSwitchDiagnostics(
      scopedServerId: scopedServerId,
      targetNetworkId: railServer.networkId,
      targetServerId: railServer.localServerId,
      activeNetworkId: activeNetworkId,
      apiOrigin: apiOrigin,
    );
    NetworkSessionActivationResult? activationResult;
    try {
      widget.diagnostics?.record('workspace.rail.select.start', {
        'networkId': railServer.networkId,
        'server': railServer.localServerId,
        'activeNetworkId': activeNetworkId,
        'scopedServerId': scopedServerId,
      });
      final result = await activateNetwork(
        apiOrigin: apiOrigin,
        initialServerId: railServer.localServerId,
      );
      activationResult = result;
      _recordRailSwitchActivationComplete(
        scopedServerId: scopedServerId,
        targetNetworkId: railServer.networkId,
        targetServerId: railServer.localServerId,
        activeNetworkId: activeNetworkId,
        result: result,
      );
      widget.diagnostics?.record('workspace.rail.select.result', {
        'ms': watch.elapsedMilliseconds,
        'networkId': railServer.networkId,
        'server': railServer.localServerId,
        'status': result.status.name,
        'activeNetworkId': activeNetworkId,
        'scopedServerId': scopedServerId,
      });
      if (!mounted) {
        return;
      }
      if (result.opened) {
        setState(() {
          _directMessagesOpen = false;
          _hideServerDrawerImmediately();
        });
        _configureDirectMessagesRefresh(false);
        return;
      }
      switch (result.status) {
        case NetworkSessionActivationStatus.opened:
          return;
        case NetworkSessionActivationStatus.requiresAuth:
          _showRailNotice(
            'Sign in to ${record?.networkName ?? 'this network'}',
          );
        case NetworkSessionActivationStatus.busy:
          _showRailNotice('Another network is still opening');
        case NetworkSessionActivationStatus.unavailable:
          _showRailNotice(
            'Could not open ${record?.networkName ?? 'this network'}',
          );
      }
    } finally {
      _scheduleRailSwitchDiagnosticsFinish(
        scopedServerId: scopedServerId,
        targetNetworkId: railServer.networkId,
        targetServerId: railServer.localServerId,
        activeNetworkId: activeNetworkId,
        status: activationResult?.status.name ?? 'aborted',
      );
      _finishRailSelection(scopedServerId);
    }
  }

  Future<void> _openCreateServer() async {
    unawaited(_closeServerDrawer());
    final networkOptions = await _loadCreateServerNetworkOptions();
    if (!mounted) {
      return;
    }
    final result = await showDialog<ServerCreationResult>(
      context: context,
      builder: (context) => CreateServerRailModal(
        networkOptions: networkOptions,
        initialApiOrigin: _initialCreateServerApiOrigin(networkOptions),
        onCreate: _createServerOnSelectedNetwork,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _showRailNotice(result.warning ?? 'Created ${result.server.name}');
  }

  String _initialCreateServerApiOrigin(
    List<CreateServerNetworkOption> networkOptions,
  ) {
    if (widget.session.credentialKind != AuthCredentialKind.federatedClient) {
      return widget.session.apiOrigin;
    }
    for (final option in networkOptions) {
      if (option.canCreate) {
        return option.apiOrigin;
      }
    }
    return widget.session.apiOrigin;
  }

  Future<List<CreateServerNetworkOption>>
  _loadCreateServerNetworkOptions() async {
    final profilesByOrigin = <String, NetworkProfile>{};
    try {
      final profileState = await _networkProfileStore.load();
      for (final profile in profileState.profiles) {
        profilesByOrigin[profile.apiOrigin] = profile;
      }
    } catch (_) {
      // Keep create-server usable for the authenticated session if profile
      // metadata is temporarily unavailable.
    }

    profilesByOrigin.putIfAbsent(
      widget.session.apiOrigin,
      () => NetworkProfile(
        name: _hostLabelForApiOrigin(widget.session.apiOrigin),
        apiOrigin: widget.session.apiOrigin,
      ),
    );

    final profiles = profilesByOrigin.values.toList(growable: false)
      ..sort((left, right) {
        if (left.apiOrigin == widget.session.apiOrigin) {
          return -1;
        }
        if (right.apiOrigin == widget.session.apiOrigin) {
          return 1;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });

    final options = <CreateServerNetworkOption>[];
    for (final profile in profiles) {
      final isCurrentSession = profile.apiOrigin == widget.session.apiOrigin;
      final access = isCurrentSession
          ? _createServerAccessForActiveSession(profile.name)
          : await _createServerAccessForSavedProfile(profile);
      options.add(
        CreateServerNetworkOption(
          name: profile.name,
          apiOrigin: profile.apiOrigin,
          networkId: profile.networkId,
          canCreate: access.canCreate,
          disabledLabel: access.disabledLabel,
          disabledReason: access.disabledReason,
        ),
      );
    }
    return options;
  }

  ({bool canCreate, String? disabledLabel, String? disabledReason})
  _createServerAccessForActiveSession(String networkName) {
    if (widget.session.credentialKind != AuthCredentialKind.federatedClient) {
      return (canCreate: true, disabledLabel: null, disabledReason: null);
    }
    return _federatedCreateServerAccess(networkName);
  }

  Future<({bool canCreate, String? disabledLabel, String? disabledReason})>
  _createServerAccessForSavedProfile(NetworkProfile profile) async {
    try {
      final credentials = await widget.credentialStore.read(profile.apiOrigin);
      if (credentials == null) {
        return (
          canCreate: false,
          disabledLabel: 'Sign in required',
          disabledReason:
              'Sign in to ${profile.name} before creating a server there.',
        );
      }
      if (credentials.kind == AuthCredentialKind.federatedClient) {
        return _federatedCreateServerAccess(profile.name);
      }
      return (canCreate: true, disabledLabel: null, disabledReason: null);
    } catch (_) {
      return (
        canCreate: false,
        disabledLabel: 'Sign in required',
        disabledReason:
            'Sign in to ${profile.name} before creating a server there.',
      );
    }
  }

  ({bool canCreate, String disabledLabel, String disabledReason})
  _federatedCreateServerAccess(String networkName) {
    return (
      canCreate: false,
      disabledLabel: 'Federated access only',
      disabledReason: 'Create servers with a local account on $networkName.',
    );
  }

  Future<ServerCreationResult> _createServerOnSelectedNetwork(
    ServerCreationRequest request,
  ) async {
    final targetOrigin = normalizeBackendApiOrigin(request.apiOrigin);
    await _ensureCreateServerCredentialAllowed(targetOrigin);
    if (targetOrigin == widget.session.apiOrigin) {
      return _controller.createServer(request);
    }

    final repository =
        widget.serverSettingsRepositoryFactory?.call(targetOrigin) ??
        ServerSettingsService(
          apiOrigin: targetOrigin,
          credentialStore: widget.credentialStore,
        );
    try {
      return await _controller.createServer(
        request,
        targetRepository: repository,
      );
    } finally {
      if (repository is ServerSettingsService) {
        repository.close();
      }
    }
  }

  Future<void> _ensureCreateServerCredentialAllowed(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    if (normalizedOrigin == widget.session.apiOrigin) {
      if (widget.session.credentialKind == AuthCredentialKind.federatedClient) {
        throw ServerSettingsException(
          'Create servers with a local account on ${_hostLabelForApiOrigin(normalizedOrigin)}.',
        );
      }
      return;
    }
    final credentials = await widget.credentialStore.read(normalizedOrigin);
    if (credentials?.kind == AuthCredentialKind.federatedClient) {
      throw ServerSettingsException(
        'Create servers with a local account on ${_hostLabelForApiOrigin(normalizedOrigin)}.',
      );
    }
  }

  Future<void> _openJoinServer() async {
    unawaited(_closeServerDrawer());
    final result = await showDialog<ServerSettingsServer>(
      context: context,
      builder: (context) => JoinServerRailModal(
        apiOrigin: widget.session.apiOrigin,
        networkLabel: _networkLabel,
        onPreview: _previewChatInvite,
        onJoin: _acceptChatInvite,
        onOpenExisting: _openExistingChatInvite,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _showRailNotice('Opened ${result.name}');
  }

  Future<ServerInvitePreview> _previewChatInvite(
    ChatInviteTarget target,
  ) async {
    final apiOrigin = _apiOriginForInviteTarget(target);
    if (!_isActiveApiOrigin(apiOrigin)) {
      try {
        return await _federatedInvitePreviewRepository.previewInvite(
          apiOrigin: apiOrigin,
          code: target.code,
        );
      } on FederatedInvitePreviewException catch (error) {
        if (!error.federationDisabled) {
          rethrow;
        }
      }
    }
    final repository = _repositoryForNetworkRail(apiOrigin);
    final closeRepository = _temporaryRepositoryCloser(repository);
    try {
      return await repository.previewInvite(code: target.code);
    } finally {
      closeRepository?.call();
    }
  }

  Future<ServerSettingsServer> _acceptChatInvite(
    ChatInviteTarget target,
    ServerInvitePreview preview,
  ) async {
    final apiOrigin = _apiOriginForInviteTarget(target);
    if (_isActiveApiOrigin(apiOrigin)) {
      final server = await _controller.acceptServerInvite(target.code);
      _closeChatSurfaceAfterInvite();
      return server;
    }

    if (preview.federated && preview.instanceId != null) {
      await _federatedInviteJoinRepository.joinInvite(
        targetApiOrigin: apiOrigin,
        targetPeerId: preview.instanceId!,
        serverId: preview.server.id,
        code: target.code,
      );
      await _networkProfileStore.saveProfile(
        name: _hostLabelForApiOrigin(apiOrigin),
        apiOrigin: apiOrigin,
      );
      await _recordFederatedInviteIdentity(apiOrigin, preview);
      await _refreshRailNetworkMetadata();
      if (widget.onActivateNetwork != null) {
        try {
          await _activateInviteNetwork(
            apiOrigin,
            initialServerId: preview.server.id,
          );
        } on ServerSettingsException catch (error) {
          if (mounted) {
            _showRailNotice(error.message);
          }
        }
      }
      if (mounted) {
        _showRailNotice('Joined ${preview.server.name}');
      }
      _closeChatSurfaceAfterInvite();
      return preview.server;
    }
    if (preview.federated) {
      throw const FederatedInviteJoinException(
        'Federated invite did not include backend identity',
      );
    }

    final repository = _repositoryForNetworkRail(apiOrigin);
    final closeRepository = _temporaryRepositoryCloser(repository);
    try {
      final server = await repository.acceptInvite(code: target.code);
      await _refreshRailNetworkMetadata();
      try {
        await _activateInviteNetwork(apiOrigin, initialServerId: server.id);
      } on ServerSettingsException catch (error) {
        if (mounted) {
          _showRailNotice(error.message);
        }
      }
      _closeChatSurfaceAfterInvite();
      return server;
    } finally {
      closeRepository?.call();
    }
  }

  Future<void> _recordFederatedInviteIdentity(
    String apiOrigin,
    ServerInvitePreview preview,
  ) async {
    final identityStore = widget.instanceIdentityStore;
    final instanceId = preview.instanceId?.trim();
    if (identityStore == null || instanceId == null || instanceId.isEmpty) {
      return;
    }
    final normalizedApiOrigin = _normalizeRailApiOrigin(apiOrigin);
    if (normalizedApiOrigin == null) {
      return;
    }
    final parsed = Uri.tryParse(normalizedApiOrigin);
    final host = parsed?.host;
    final domain = host == null || host.trim().isEmpty
        ? _hostLabelForApiOrigin(normalizedApiOrigin)
        : host;
    final mode = preview.instanceMode?.trim().isNotEmpty == true
        ? preview.instanceMode!.trim()
        : 'federated';
    try {
      await identityStore.recordSelfReportedManifest(
        connectedApiOrigin: normalizedApiOrigin,
        manifest: InstanceManifestIdentity(
          instanceId: instanceId,
          registryTrust: 'self_reported',
          name: _hostLabelForApiOrigin(normalizedApiOrigin),
          domain: domain,
          mode: mode,
          apiUrl: normalizedApiOrigin,
        ),
      );
    } catch (_) {
      // Invite metadata is best-effort public identity cache; join state and
      // credentials stay owned by the target backend and credential store.
    }
  }

  Future<void> _openExistingChatInvite(
    ChatInviteTarget target,
    ServerSettingsServer server,
  ) async {
    final apiOrigin = _apiOriginForInviteTarget(target);
    if (_isActiveApiOrigin(apiOrigin)) {
      await _controller.selectServer(server);
      return;
    }
    await _activateInviteNetwork(apiOrigin, initialServerId: server.id);
  }

  String _apiOriginForInviteTarget(ChatInviteTarget target) {
    final apiOrigin = target.apiOrigin;
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      return widget.session.apiOrigin;
    }
    return normalizeBackendApiOrigin(apiOrigin);
  }

  bool _isActiveApiOrigin(String apiOrigin) {
    return normalizeBackendApiOrigin(apiOrigin) == widget.session.apiOrigin;
  }

  VoidCallback? _temporaryRepositoryCloser(
    ServerSettingsRepository repository,
  ) {
    if (repository is ServerSettingsService &&
        !identical(repository, _repository)) {
      return repository.close;
    }
    return null;
  }

  Future<void> _activateInviteNetwork(
    String apiOrigin, {
    required String initialServerId,
  }) async {
    final activateNetwork = widget.onActivateNetwork;
    if (activateNetwork == null) {
      throw const ServerSettingsException('This network cannot be opened yet');
    }
    final result = await activateNetwork(
      apiOrigin: apiOrigin,
      initialServerId: initialServerId,
    );
    if (result.opened) {
      return;
    }
    throw ServerSettingsException(switch (result.status) {
      NetworkSessionActivationStatus.requiresAuth =>
        'Sign in to this network before opening the server',
      NetworkSessionActivationStatus.busy => 'This network is still connecting',
      NetworkSessionActivationStatus.unavailable =>
        'This network profile is unavailable',
      NetworkSessionActivationStatus.opened => 'Could not open this network',
    });
  }

  void _closeChatSurfaceAfterInvite() {
    if (mounted) {
      setState(() {
        _directMessagesOpen = false;
        _hideServerDrawerImmediately();
      });
      _configureDirectMessagesRefresh(false);
    }
  }

  Future<void> _openJoinNetwork() async {
    unawaited(_closeServerDrawer());
    final result = await showDialog<NetworkProfile>(
      context: context,
      builder: (context) => JoinNetworkRailModal(
        profileStore: _networkProfileStore,
        metadataService: _instanceMetadataService,
        identityStore: widget.instanceIdentityStore,
        identityManifestService: widget.instanceIdentityManifestService,
        currentApiOrigin: widget.session.apiOrigin,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    await _refreshRailNetworkMetadata();
    if (!mounted) {
      return;
    }
    final record = _railRecordForSavedProfile(result);
    await _openNetworkAuthFromSettings(
      record,
      initialMode: _NetworkAuthMode.signIn,
    );
  }

  RailNetworkRecord _railRecordForSavedProfile(NetworkProfile profile) {
    for (final record in _railNetworkRecords) {
      if (record.apiOrigin == profile.apiOrigin ||
          sameWorkspaceNetworkId(record.networkId, profile.networkId)) {
        return record;
      }
    }
    return RailNetworkRecord(
      networkId: profile.networkId,
      networkName: profile.name,
      mode: RailNetworkMode.unknown,
      availability: RailNetworkAvailability.requiresAuth,
      authStatus: RailNetworkAuthStatus.signedOut,
      apiOrigin: profile.apiOrigin,
    );
  }

  Future<void> _refreshRailNetworkMetadata() async {
    if (!widget.showBottomRail) {
      return;
    }
    final profileStateProfiles = <NetworkProfile>[];
    try {
      final profileState = await _networkProfileStore.load();
      profileStateProfiles.addAll(profileState.profiles);
    } catch (_) {
      // Saved network metadata is local UI state. Keep the active session rail
      // usable if the local profile cache is temporarily unavailable.
    }

    final instanceModesByApiOrigin = <String, String>{};
    final identityStore = widget.instanceIdentityStore;
    if (identityStore != null) {
      try {
        for (final identity in await identityStore.load()) {
          instanceModesByApiOrigin[identity.apiOrigin] = identity.instanceMode;
        }
      } catch (_) {
        // Instance identity is cached display metadata. Rail routing and
        // authorization must not depend on reading it successfully.
      }
    }

    final settings = _controller.state.settings;
    final service = JoinedNetworkRailService(
      credentialStore: widget.credentialStore,
      repositoryFactory: _repositoryForNetworkRail,
      networkProfileStore: _networkProfileStore,
      federatedMembershipRepositoryFactory:
          widget.federatedMembershipRepositoryFactory ??
          (apiOrigin) => HttpFederatedMembershipService(
            apiOrigin: apiOrigin,
            credentialStore: widget.credentialStore,
            authService: _authService,
          ),
      diagnostics: widget.diagnostics ?? const DebugPrintAuthDiagnostics(),
    );
    final snapshot = await service.load(
      activeSession: widget.session,
      activeCurrentUser: _controller.state.currentUser,
      savedProfiles: profileStateProfiles,
      activeServers: _controller.state.servers,
      activeMediaPolicy: settings?.mediaPolicy,
      cachedRailServers: _joinedRailServers,
      instanceModesByApiOrigin: instanceModesByApiOrigin,
      preferCachedServers: true,
    );
    final railServersWithSummaries = await _serversWithInactiveSummaryBadges(
      railServers: snapshot.railServers,
      records: snapshot.records,
    );
    final railServerCountsByNetworkId = <String, int>{};
    for (final server in railServersWithSummaries) {
      railServerCountsByNetworkId.update(
        server.networkId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    widget.diagnostics?.record('workspace.rail.snapshot', {
      'activeNetworkId': widget.session.networkId,
      'profileCount': profileStateProfiles.length,
      'recordCount': snapshot.records.length,
      'railServerCount': railServersWithSummaries.length,
      'records': [
        for (final record in snapshot.records)
          {
            'networkId': record.networkId,
            'apiOrigin': record.apiOrigin,
            'mode': record.mode.name,
            'availability': record.availability.name,
            'authStatus': record.authStatus.name,
            'credentialKind': record.credentialKind?.wireName,
            'serverCount': railServerCountsByNetworkId[record.networkId] ?? 0,
          },
      ],
    });
    final settingsUsersByNetworkId = <String, VerdantUser>{};
    final activeUser = _controller.state.currentUser ?? widget.session.user;
    settingsUsersByNetworkId[widget.session.networkId] = activeUser;
    for (final record in snapshot.records) {
      final apiOrigin = _normalizeRailApiOrigin(record.apiOrigin);
      if (apiOrigin == null) {
        continue;
      }
      if (apiOrigin == widget.session.apiOrigin ||
          sameWorkspaceNetworkId(record.networkId, widget.session.networkId)) {
        settingsUsersByNetworkId[record.networkId] = activeUser;
        continue;
      }
      try {
        final credentials = await widget.credentialStore.read(apiOrigin);
        final user = credentials?.user;
        if (user != null) {
          settingsUsersByNetworkId[record.networkId] = user;
        }
      } catch (_) {
        // This is non-secret display cache only. Do not make settings or rail
        // availability depend on reading cached profile metadata.
      }
    }

    if (!mounted) {
      return;
    }
    final nextSnapshot = WorkspaceRailSnapshot(
      records: snapshot.records,
      networkOrder: snapshot.networkOrder,
      railServers: railServersWithSummaries,
    );
    setState(() {
      _railNetworkRecords = nextSnapshot.records;
      _railNetworkOrder = nextSnapshot.networkOrder;
      _joinedRailServers = nextSnapshot.railServers;
      _settingsUsersByNetworkId = Map.unmodifiable(settingsUsersByNetworkId);
    });
    widget.onRailSnapshotChanged?.call(nextSnapshot);
  }

  Future<void> _warmHydratedWorkspaceMedia({
    required List<RailServerItem> railServers,
    required ServerSettingsData? settings,
    bool blockWorkspaceHydration = false,
    String reason = 'workspace',
    bool includeActiveServerMedia = true,
    bool includeVisibleCurrentUserAvatar = true,
    bool includeCurrentUserProfileMedia = false,
    bool includeRailServerIcons = false,
    bool includeActiveChannelMemberMedia = false,
    bool includeMessageAuthorAvatars = false,
    bool includeMessageCustomEmojiMedia = false,
  }) {
    final state = _controller.state;
    final activePolicy =
        settings?.mediaPolicy ??
        ServerMediaPolicy.fromOrigins(apiOrigin: widget.session.apiOrigin);
    final currentUser = state.currentUser ?? widget.session.user;
    final currentUserMedia = state.currentUserMedia;
    final requestsByKey = <String, ServerMediaWarmRequest>{};
    final requestsBySurface = <String, int>{};
    final requestsByKind = <String, int>{};
    final missingMediaByKind = <String, int>{};
    final rejectedMediaByKind = <String, int>{};

    void increment(Map<String, int> counts, String key) {
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    void addMedia({
      required String kind,
      required String? url,
      required ServerMediaPolicy policy,
      required ServerMediaSurface surface,
    }) {
      if (url == null || url.trim().isEmpty) {
        increment(missingMediaByKind, kind);
        return;
      }
      final uri = safeServerMediaUri(url, policy: policy);
      if (uri == null) {
        increment(rejectedMediaByKind, kind);
        return;
      }
      final key = '${surface.name}|${policy.hashCode}|$uri';
      requestsByKey.putIfAbsent(key, () {
        increment(requestsBySurface, surface.name);
        increment(requestsByKind, kind);
        return ServerMediaWarmRequest(
          uri: uri,
          policy: policy,
          surface: surface,
        );
      });
    }

    final customEmojiByName = <String, ServerSettingsListItemSeed>{};
    final customEmojiById = <String, ServerSettingsListItemSeed>{};
    final customStickerByName = <String, ServerSettingsListItemSeed>{};
    if (settings != null && includeMessageCustomEmojiMedia) {
      for (final emoji in settings.emojis) {
        final imageUrl = emoji.avatarUrl?.trim();
        if (imageUrl == null || imageUrl.isEmpty) {
          continue;
        }
        final name = normalizeCustomEmojiName(emoji.title).toLowerCase();
        if (name.isNotEmpty) {
          customEmojiByName.putIfAbsent(name, () => emoji);
        }
        final id = emoji.id?.trim();
        if (id == null || id.isEmpty) {
          continue;
        }
        customEmojiById.putIfAbsent(id, () => emoji);
        try {
          final localId = safeWorkspaceLocalId(id, allowScopedPrefix: true);
          customEmojiById.putIfAbsent(localId, () => emoji);
        } on FormatException {
          // The backend may return legacy/non-snowflake emoji ids. Keep the raw
          // id lookup above and skip only the local-id alias.
        }
      }
      for (final sticker in settings.stickers) {
        final imageUrl = sticker.avatarUrl?.trim();
        if (imageUrl == null || imageUrl.isEmpty) {
          continue;
        }
        final name = normalizeCustomStickerName(sticker.title).toLowerCase();
        if (name.isNotEmpty) {
          customStickerByName.putIfAbsent(name, () => sticker);
        }
      }
    }

    final warmedCustomExpressionKeys = <String>{};

    void addCustomExpressionMedia({
      required String kind,
      required ServerSettingsListItemSeed? item,
    }) {
      if (item == null || warmedCustomExpressionKeys.length >= 12) {
        return;
      }
      final key = item.id?.trim().isNotEmpty == true
          ? item.id!.trim()
          : normalizeCustomExpressionName(item.title).toLowerCase();
      if (key.isEmpty || !warmedCustomExpressionKeys.add(key)) {
        return;
      }
      addMedia(
        kind: kind,
        url: item.avatarUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.image,
      );
    }

    final activeServer = state.activeServer;
    if (includeActiveServerMedia) {
      addMedia(
        kind: 'activeServer.banner',
        url: activeServer?.bannerUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.serverBanner,
      );
      addMedia(
        kind: 'activeServer.icon',
        url: activeServer?.iconUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.serverIcon,
      );
    }
    if (includeVisibleCurrentUserAvatar) {
      final avatarUrl = currentUserMedia?.avatarUrl ?? currentUser.avatarUrl;
      addMedia(
        kind: 'currentUser.avatar',
        url: avatarUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.image,
      );
      addMedia(
        kind: 'currentUser.avatarIcon',
        url: avatarUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.serverIcon,
      );
    }
    if (includeCurrentUserProfileMedia) {
      addMedia(
        kind: 'currentUser.banner',
        url: currentUserMedia?.bannerUrl ?? currentUser.bannerUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.serverBanner,
      );
      addMedia(
        kind: 'currentUser.memberListBanner',
        url:
            currentUserMedia?.memberListBannerUrl ??
            currentUser.memberListBannerUrl,
        policy: activePolicy,
        surface: ServerMediaSurface.serverBanner,
      );
    }

    if (includeRailServerIcons) {
      for (final server in railServers.take(24)) {
        addMedia(
          kind: 'railServer.icon',
          url: server.iconUrl,
          policy: server.mediaPolicy,
          surface: ServerMediaSurface.serverIcon,
        );
      }
    }
    if (includeActiveChannelMemberMedia) {
      for (final member in state.activeChannelMembers.take(12)) {
        addMedia(
          kind: 'activeMember.avatar',
          url: member.avatarUrl,
          policy: activePolicy,
          surface: ServerMediaSurface.image,
        );
        addMedia(
          kind: 'activeMember.banner',
          url: member.bannerUrl,
          policy: activePolicy,
          surface: ServerMediaSurface.serverBanner,
        );
        addMedia(
          kind: 'activeMember.memberListBanner',
          url: member.memberListBannerUrl,
          policy: activePolicy,
          surface: ServerMediaSurface.serverBanner,
        );
      }
    }
    if (includeMessageAuthorAvatars) {
      for (final message in state.serverMessages.take(16)) {
        addMedia(
          kind: 'messageAuthor.avatar',
          url: message.avatarUrl,
          policy: activePolicy,
          surface: ServerMediaSurface.image,
        );
      }
    }
    if (includeMessageCustomEmojiMedia &&
        (customEmojiByName.isNotEmpty || customStickerByName.isNotEmpty)) {
      for (final message in state.serverMessages.take(16)) {
        if (message.body.contains(':')) {
          for (final match in _workspaceWarmCustomEmojiPattern.allMatches(
            message.body,
          )) {
            final name = match.group(1)?.toLowerCase();
            addCustomExpressionMedia(
              kind: 'messageCustomEmoji.image',
              item: name == null ? null : customEmojiByName[name],
            );
            addCustomExpressionMedia(
              kind: 'messageCustomSticker.image',
              item: name == null ? null : customStickerByName[name],
            );
          }
        }
        for (final reaction in message.reactions.take(12)) {
          final byId = reaction.emojiId?.trim();
          final byEmojiName = normalizeCustomEmojiName(
            reaction.emoji,
          ).toLowerCase();
          addCustomExpressionMedia(
            kind: 'messageReactionCustomEmoji.image',
            item:
                (byId == null || byId.isEmpty ? null : customEmojiById[byId]) ??
                customEmojiByName[byEmojiName],
          );
        }
      }
    }

    final requests = requestsByKey.values.toList(growable: false);
    widget.diagnostics?.record('workspace.media.warm.selection', {
      'reason': reason,
      'requestCount': requests.length,
      'requestCountBySurface': Map.unmodifiable(requestsBySurface),
      'requestCountByKind': Map.unmodifiable(requestsByKind),
      'missingMediaByKind': Map.unmodifiable(missingMediaByKind),
      'rejectedMediaByKind': Map.unmodifiable(rejectedMediaByKind),
      'railServerCount': railServers.length,
      'memberCandidateCount': state.activeChannelMembers.length,
      'messageCandidateCount': state.serverMessages.length,
      'hasActiveServerBanner': activeServer?.bannerUrl != null,
      'hasActiveServerIcon': activeServer?.iconUrl != null,
      'hasCurrentUserAvatar':
          currentUserMedia?.avatarUrl != null || currentUser.avatarUrl != null,
      'hasCurrentUserBanner':
          currentUserMedia?.bannerUrl != null || currentUser.bannerUrl != null,
      'hasCurrentUserMemberListBanner':
          currentUserMedia?.memberListBannerUrl != null ||
          currentUser.memberListBannerUrl != null,
      'includeActiveServerMedia': includeActiveServerMedia,
      'includeVisibleCurrentUserAvatar': includeVisibleCurrentUserAvatar,
      'includeCurrentUserProfileMedia': includeCurrentUserProfileMedia,
      'includeRailServerIcons': includeRailServerIcons,
      'includeActiveChannelMemberMedia': includeActiveChannelMemberMedia,
      'includeMessageAuthorAvatars': includeMessageAuthorAvatars,
      'includeMessageCustomEmojiMedia': includeMessageCustomEmojiMedia,
      'customEmojiCandidateCount': customEmojiByName.length,
      'blocking': blockWorkspaceHydration,
    });
    if (requests.isEmpty) {
      if (blockWorkspaceHydration && _workspaceMediaHydrating && mounted) {
        setState(() => _workspaceMediaHydrating = false);
        _reportWorkspaceReadyIfChanged();
      }
      return Future<void>.value();
    }
    final signature = requests
        .map(
          (request) =>
              '${request.surface.name}|${request.policy.hashCode}|${request.uri}',
        )
        .join('\u001E');
    final lastSignature = blockWorkspaceHydration
        ? _lastBlockingWorkspaceMediaWarmSignature
        : _lastBackgroundWorkspaceMediaWarmSignature;
    if (signature == lastSignature) {
      return Future<void>.value();
    }
    if (blockWorkspaceHydration) {
      _lastBlockingWorkspaceMediaWarmSignature = signature;
    } else {
      _lastBackgroundWorkspaceMediaWarmSignature = signature;
    }
    if (blockWorkspaceHydration && mounted) {
      _blockingWorkspaceMediaWarmSignature = signature;
      setState(() => _workspaceMediaHydrating = true);
    }
    final warmWatch = Stopwatch()..start();
    widget.diagnostics?.record('workspace.media.warm.queued', {
      'reason': reason,
      'requestCount': requests.length,
      'requestCountBySurface': Map.unmodifiable(requestsBySurface),
      'requestCountByKind': Map.unmodifiable(requestsByKind),
      'missingMediaByKind': Map.unmodifiable(missingMediaByKind),
      'rejectedMediaByKind': Map.unmodifiable(rejectedMediaByKind),
      'railServerCount': railServers.length,
      'memberCandidateCount': state.activeChannelMembers.length,
      'messageCandidateCount': state.serverMessages.length,
      'hasActiveServerBanner': activeServer?.bannerUrl != null,
      'hasActiveServerIcon': activeServer?.iconUrl != null,
      'hasCurrentUserAvatar':
          currentUserMedia?.avatarUrl != null || currentUser.avatarUrl != null,
      'hasCurrentUserBanner':
          currentUserMedia?.bannerUrl != null || currentUser.bannerUrl != null,
      'hasCurrentUserMemberListBanner':
          currentUserMedia?.memberListBannerUrl != null ||
          currentUser.memberListBannerUrl != null,
      'blocking': blockWorkspaceHydration,
    });
    final future = warmServerMediaImageCache(
      requests,
      maxConcurrent: blockWorkspaceHydration
          ? _workspaceBlockingMediaWarmConcurrency
          : _workspaceBackgroundMediaWarmConcurrency,
    );
    if (!blockWorkspaceHydration) {
      return future.whenComplete(() {
        widget.diagnostics?.record('workspace.media.warm.ready', {
          'reason': reason,
          'requestCount': requests.length,
          'railServerCount': railServers.length,
          'blocking': false,
          'ms': warmWatch.elapsedMilliseconds,
        });
      });
    }
    unawaited(
      future.whenComplete(() {
        widget.diagnostics?.record('workspace.media.warm.completed', {
          'reason': reason,
          'requestCount': requests.length,
          'railServerCount': railServers.length,
          'blocking': true,
          'ms': warmWatch.elapsedMilliseconds,
        });
      }),
    );
    return () async {
      var completedBeforeBudget = false;
      try {
        completedBeforeBudget = await Future.any<bool>([
          future.then((_) => true, onError: (_) => true),
          _waitForBlockingMediaWarmBudget(),
        ]);
      } catch (_) {
        completedBeforeBudget = true;
      }
      if (completedBeforeBudget) {
        _workspaceBlockingMediaWarmBudgetTimer?.cancel();
        _workspaceBlockingMediaWarmBudgetTimer = null;
      }
      if (!mounted || _blockingWorkspaceMediaWarmSignature != signature) {
        return;
      }
      _blockingWorkspaceMediaWarmSignature = null;
      setState(() => _workspaceMediaHydrating = false);
      _reportWorkspaceReadyIfChanged();
      widget.diagnostics?.record('workspace.media.warm.ready', {
        'reason': reason,
        'requestCount': requests.length,
        'railServerCount': railServers.length,
        'blocking': true,
        'completedBeforeBudget': completedBeforeBudget,
        'budgetMs': _workspaceBlockingMediaWarmBudget.inMilliseconds,
        'ms': warmWatch.elapsedMilliseconds,
      });
    }();
  }

  Future<bool> _waitForBlockingMediaWarmBudget() {
    final completer = Completer<bool>();
    _workspaceBlockingMediaWarmBudgetTimer?.cancel();
    late final Timer timer;
    timer = Timer(_workspaceBlockingMediaWarmBudget, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      if (identical(_workspaceBlockingMediaWarmBudgetTimer, timer)) {
        _workspaceBlockingMediaWarmBudgetTimer = null;
      }
    });
    _workspaceBlockingMediaWarmBudgetTimer = timer;
    return completer.future;
  }

  Future<Set<String>?> _loadFederatedAllowedServerIdsForActiveSession() async {
    if (widget.session.credentialKind != AuthCredentialKind.federatedClient) {
      return null;
    }
    final activeApiOrigin = widget.session.apiOrigin;
    List<NetworkProfile> profiles;
    try {
      profiles = (await _networkProfileStore.load()).profiles;
    } catch (error) {
      widget.diagnostics?.record('workspace.federated.access_filter.error', {
        'networkId': widget.session.networkId,
        'apiOrigin': widget.session.apiOrigin,
        'stage': 'profiles',
        'errorType': error.runtimeType.toString(),
      });
      return null;
    }

    final allowedServerIds = <String>{};
    var homeCandidateCount = 0;
    var membershipCount = 0;
    for (final profile in profiles) {
      final homeApiOrigin = profile.apiOrigin;
      if (homeApiOrigin == activeApiOrigin) {
        continue;
      }
      AuthCredentialBundle? credentials;
      try {
        credentials = await widget.credentialStore.read(homeApiOrigin);
      } catch (error) {
        widget.diagnostics?.record('workspace.federated.access_filter.error', {
          'networkId': widget.session.networkId,
          'apiOrigin': widget.session.apiOrigin,
          'homeNetworkId': profile.networkId,
          'homeApiOrigin': homeApiOrigin,
          'stage': 'credentials',
          'errorType': error.runtimeType.toString(),
        });
        continue;
      }
      if (credentials == null || credentials.isFederatedClient) {
        widget.diagnostics?.record('workspace.federated.access_filter.skip', {
          'networkId': widget.session.networkId,
          'apiOrigin': widget.session.apiOrigin,
          'homeNetworkId': profile.networkId,
          'homeApiOrigin': homeApiOrigin,
          'credentialKind': credentials?.kind.wireName ?? 'none',
        });
        continue;
      }

      homeCandidateCount += 1;
      FederatedMembershipRepository? repository;
      try {
        repository =
            widget.federatedMembershipRepositoryFactory?.call(homeApiOrigin) ??
            HttpFederatedMembershipService(
              apiOrigin: homeApiOrigin,
              credentialStore: widget.credentialStore,
              authService: _authService,
            );
        final memberships = await repository.listMemberships();
        membershipCount += memberships.length;
        for (final membership in memberships) {
          if (membership.isActive &&
              membership.targetApiOrigin == activeApiOrigin) {
            allowedServerIds.add(membership.targetServerId);
          }
        }
      } catch (error) {
        widget.diagnostics?.record('workspace.federated.access_filter.error', {
          'networkId': widget.session.networkId,
          'apiOrigin': widget.session.apiOrigin,
          'homeNetworkId': profile.networkId,
          'homeApiOrigin': homeApiOrigin,
          'stage': 'memberships',
          'errorType': error.runtimeType.toString(),
        });
      } finally {
        final ownedRepository = repository;
        if (ownedRepository is HttpFederatedMembershipService) {
          ownedRepository.close();
        }
      }
    }

    widget.diagnostics?.record('workspace.federated.access_filter.result', {
      'networkId': widget.session.networkId,
      'apiOrigin': widget.session.apiOrigin,
      'homeCandidateCount': homeCandidateCount,
      'membershipCount': membershipCount,
      'allowedServerCount': allowedServerIds.length,
      'allowedServerIds': allowedServerIds.take(24).toList(growable: false),
      'enforced': allowedServerIds.isNotEmpty,
    });
    return allowedServerIds.isEmpty ? null : allowedServerIds;
  }

  Future<List<RailServerItem>> _serversWithInactiveSummaryBadges({
    required List<RailServerItem> railServers,
    required List<RailNetworkRecord> records,
  }) async {
    if (!widget.showBottomRail || railServers.isEmpty || records.isEmpty) {
      return railServers;
    }
    final summariesByNetworkId = <String, SyncSummarySnapshot>{};
    for (final record in records) {
      if (_shouldSkipInactiveSummary(record)) {
        continue;
      }
      final apiOrigin = _normalizeRailApiOrigin(record.apiOrigin);
      if (apiOrigin == null) {
        continue;
      }
      try {
        final snapshot = await _syncSummaryClient.fetchSummary(
          JoinedBackendRuntimeProfile(
            networkId: record.networkId,
            apiOrigin: apiOrigin,
            authenticated: true,
            available: true,
          ),
          since: _syncSummaryCursorsByNetworkId[record.networkId],
        );
        _syncSummaryCursorsByNetworkId[record.networkId] = snapshot.cursor;
        summariesByNetworkId[record.networkId] = snapshot;
      } on SyncSummaryClientException {
        // Summary polling is a lightweight badge path. Auth, permission, and
        // availability failures should not route through another backend or
        // tear down the active workspace.
      }
    }
    if (summariesByNetworkId.isEmpty) {
      return railServers;
    }
    return [
      for (final server in railServers)
        _serverWithSummaryBadge(server, summariesByNetworkId[server.networkId]),
    ];
  }

  bool _shouldSkipInactiveSummary(RailNetworkRecord record) {
    if (sameWorkspaceNetworkId(record.networkId, widget.session.networkId)) {
      return true;
    }
    if (record.authStatus != RailNetworkAuthStatus.authenticated ||
        record.availability != RailNetworkAvailability.available) {
      return true;
    }
    return false;
  }

  RailServerItem _serverWithSummaryBadge(
    RailServerItem server,
    SyncSummarySnapshot? snapshot,
  ) {
    if (snapshot == null) {
      return server;
    }
    for (final summary in snapshot.servers) {
      if (summary.serverId == server.localServerId) {
        return server.copyWith(
          unreadCount: summary.unreadCount,
          mentionCount: summary.mentionCount,
        );
      }
    }
    return server;
  }

  bool _sameRailServerBadges(
    List<RailServerItem> previous,
    List<RailServerItem> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (var i = 0; i < previous.length; i += 1) {
      final left = previous[i];
      final right = next[i];
      if (left.scopedServerId != right.scopedServerId ||
          left.unreadCount != right.unreadCount ||
          left.mentionCount != right.mentionCount) {
        return false;
      }
    }
    return true;
  }

  bool _sameRailSnapshot(
    WorkspaceRailSnapshot previous,
    WorkspaceRailSnapshot next,
  ) {
    return previous.contentSignature == next.contentSignature;
  }

  Future<void> _persistActiveCurrentUserSnapshot(
    VerdantUser currentUser,
  ) async {
    final signature = _currentUserCredentialSignature(currentUser);
    if (_lastPersistedCurrentUserSignature == signature) {
      return;
    }
    _lastPersistedCurrentUserSignature = signature;
    try {
      final credentials = await widget.credentialStore.read(
        widget.session.apiOrigin,
      );
      if (credentials == null) {
        return;
      }
      final savedUser = credentials.user;
      if (savedUser != null &&
          _currentUserCredentialSignature(savedUser) == signature) {
        return;
      }
      await widget.credentialStore.save(credentials.withUser(currentUser));
      await _refreshRailNetworkMetadata();
    } catch (_) {
      // Credential user metadata is a local cache. Failed writes must not turn
      // a live workspace into a signed-out state.
    }
  }

  String _currentUserCredentialSignature(VerdantUser user) {
    const separator = '\u001F';
    return [
      widget.session.apiOrigin,
      user.id,
      user.username,
      user.usernameSet.toString(),
      user.displayName ?? '',
      user.email,
      user.emailVerified.toString(),
      user.totpEnabled.toString(),
      user.avatarUrl ?? '',
      user.bannerUrl ?? '',
      user.memberListBannerUrl ?? '',
      user.bio ?? '',
    ].join(separator);
  }

  void _scheduleActiveUsernamePrompt(VerdantUser currentUser) {
    if (_usernamePromptOpen || _usernamePromptScheduled) {
      return;
    }
    final record = _activeNetworkRecordForCurrentUser(currentUser);
    if (!railNetworkRecordNeedsUsername(record)) {
      return;
    }
    final promptKey = _usernamePromptKey(record);
    if (_dismissedUsernamePromptKeys.contains(promptKey)) {
      return;
    }
    _usernamePromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernamePromptScheduled = false;
      if (!mounted || _usernamePromptOpen) {
        return;
      }
      final latestUser = _controller.state.currentUser ?? widget.session.user;
      final latestRecord = _activeNetworkRecordForCurrentUser(latestUser);
      if (!railNetworkRecordNeedsUsername(latestRecord)) {
        return;
      }
      final latestPromptKey = _usernamePromptKey(latestRecord);
      if (_dismissedUsernamePromptKeys.contains(latestPromptKey)) {
        return;
      }
      unawaited(
        _openNetworkUsernameFromSettings(latestRecord, automatic: true),
      );
    });
  }

  RailNetworkRecord _activeNetworkRecordForCurrentUser(VerdantUser user) {
    RailNetworkRecord? existing;
    for (final record in _railNetworkRecords) {
      if (sameWorkspaceNetworkId(record.networkId, widget.session.networkId)) {
        existing = record;
        break;
      }
    }
    return RailNetworkRecord(
      networkId: widget.session.networkId,
      networkName:
          existing?.networkName ??
          _hostLabelForApiOrigin(widget.session.apiOrigin),
      mode: existing?.mode ?? RailNetworkMode.unknown,
      availability: existing?.availability ?? RailNetworkAvailability.available,
      authStatus: RailNetworkAuthStatus.authenticated,
      apiOrigin: widget.session.apiOrigin,
      currentUserId: user.id,
      currentUsername: user.username,
      usernameSet: user.usernameSet,
      credentialKind: widget.session.credentialKind,
    );
  }

  String _usernamePromptKey(RailNetworkRecord record) {
    final userId = record.currentUserId ?? 'unknown';
    final username = record.currentUsername ?? '';
    return '${record.networkId}/$userId/$username';
  }

  Future<void> _openNetworkAuthFromSettings(
    RailNetworkRecord record, {
    required _NetworkAuthMode initialMode,
  }) async {
    final apiOrigin = record.apiOrigin;
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      _showRailNotice('This network is missing its API origin');
      return;
    }

    final authResult = await showDialog<_NetworkAuthDialogResult>(
      context: context,
      builder: (context) => _NetworkSignInDialog(
        networkName: record.networkName,
        apiOrigin: apiOrigin,
        initialMode: initialMode,
        authService: _authService,
        instanceMetadataService: _instanceMetadataService,
        credentialStore: widget.credentialStore,
      ),
    );
    if (!mounted || authResult == null) {
      return;
    }

    await _refreshRailNetworkMetadata();
    if (!mounted) {
      return;
    }
    if (authResult.user.usernameSet == false) {
      await _openNetworkUsernameFromSettings(record);
      return;
    }
    if (mounted) {
      _showRailNotice(
        authResult.mode == _NetworkAuthMode.register
            ? 'Created account on ${record.networkName}'
            : 'Signed in to ${record.networkName}',
      );
    }
  }

  Future<void> _openNetworkUsernameFromSettings(
    RailNetworkRecord record, {
    bool automatic = false,
  }) async {
    final apiOrigin = record.apiOrigin;
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      _showRailNotice('This network is missing its API origin');
      return;
    }
    if (_usernamePromptOpen) {
      return;
    }

    _usernamePromptOpen = true;
    String? username;
    try {
      username = await showDialog<String>(
        context: context,
        builder: (context) => _NetworkUsernameDialog(
          networkName: record.networkName,
          apiOrigin: apiOrigin,
        ),
      );
    } finally {
      _usernamePromptOpen = false;
    }
    if (!mounted || username == null) {
      if (automatic) {
        _dismissedUsernamePromptKeys.add(_usernamePromptKey(record));
      }
      return;
    }

    final repository = _repositoryForNetworkRail(apiOrigin);
    VoidCallback? closeRepository;
    if (repository is ServerSettingsService &&
        !identical(repository, _repository)) {
      closeRepository = repository.close;
    }
    try {
      _dismissedUsernamePromptKeys.remove(_usernamePromptKey(record));
      if (repository is! UserSettingsRepository) {
        _showRailNotice('This network cannot update usernames yet');
        return;
      }
      final userSettingsRepository = repository as UserSettingsRepository;
      final user = await userSettingsRepository.setCurrentUsername(
        username: username,
      );
      final credentials = await widget.credentialStore.read(apiOrigin);
      if (credentials != null) {
        await widget.credentialStore.save(credentials.withUser(user));
      }
      await _refreshRailNetworkMetadata();
      if (sameWorkspaceNetworkId(record.networkId, widget.session.networkId)) {
        await _controller.refresh();
      }
      if (mounted) {
        _showRailNotice('Saved username for ${record.networkName}');
      }
    } on ServerSettingsException catch (error) {
      if (mounted) {
        _showRailNotice(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showRailNotice('Could not save username');
      }
    } finally {
      closeRepository?.call();
    }
  }

  ServerSettingsRepository _repositoryForNetworkRail(String apiOrigin) {
    if (normalizeBackendApiOrigin(apiOrigin) == widget.session.apiOrigin) {
      return _repository;
    }
    return widget.serverSettingsRepositoryFactory?.call(apiOrigin) ??
        ServerSettingsService(
          apiOrigin: apiOrigin,
          credentialStore: widget.credentialStore,
        );
  }

  List<UserSettingsContext> _userSettingsContexts({
    required VerdantUser activeUser,
    required ServerSettingsCurrentUserMedia? activeUserMedia,
    required ServerSettingsData activeSettings,
    required WorkspaceEntitlements activeEntitlements,
  }) {
    final records = <String, RailNetworkRecord>{
      for (final record in _railNetworkRecords) record.networkId: record,
    };
    records.putIfAbsent(
      widget.session.networkId,
      () => _activeNetworkRecordForCurrentUser(activeUser),
    );

    return [
      for (final record in records.values)
        _userSettingsContextForRecord(
          record,
          activeUser: activeUser,
          activeUserMedia: activeUserMedia,
          activeSettings: activeSettings,
          activeEntitlements: activeEntitlements,
        ),
    ];
  }

  UserSettingsContext _userSettingsContextForRecord(
    RailNetworkRecord record, {
    required VerdantUser activeUser,
    required ServerSettingsCurrentUserMedia? activeUserMedia,
    required ServerSettingsData activeSettings,
    required WorkspaceEntitlements activeEntitlements,
  }) {
    final apiOrigin = _normalizeRailApiOrigin(record.apiOrigin);
    final isActive =
        sameWorkspaceNetworkId(record.networkId, widget.session.networkId) ||
        apiOrigin == widget.session.apiOrigin;
    final signedIn = record.authStatus == RailNetworkAuthStatus.authenticated;
    final user = isActive
        ? activeUser
        : _settingsUsersByNetworkId[record.networkId] ??
              _userFromRailNetworkRecord(record);
    final repository = signedIn && apiOrigin != null
        ? _userSettingsRepositoryForApiOrigin(apiOrigin)
        : null;

    return UserSettingsContext(
      networkId: record.networkId,
      networkName: record.networkName,
      apiOrigin: apiOrigin ?? record.apiOrigin ?? '',
      currentUser: user,
      currentUserMedia: isActive ? activeUserMedia : null,
      mediaPolicy: isActive
          ? activeSettings.mediaPolicy
          : ServerMediaPolicy.fromOrigins(
              apiOrigin: apiOrigin ?? widget.session.apiOrigin,
            ),
      entitlements: isActive
          ? activeEntitlements
          : const WorkspaceEntitlements.disabled(),
      repository: repository,
      signedIn: signedIn && repository != null,
    );
  }

  UserSettingsRepository? _userSettingsRepositoryForApiOrigin(
    String apiOrigin,
  ) {
    final normalizedApiOrigin = normalizeBackendApiOrigin(apiOrigin);
    final repository = normalizedApiOrigin == widget.session.apiOrigin
        ? _repository
        : _userSettingsRepositoryCache.putIfAbsent(
            normalizedApiOrigin,
            () =>
                widget.serverSettingsRepositoryFactory?.call(
                  normalizedApiOrigin,
                ) ??
                ServerSettingsService(
                  apiOrigin: normalizedApiOrigin,
                  credentialStore: widget.credentialStore,
                ),
          );
    return repository is UserSettingsRepository
        ? repository as UserSettingsRepository
        : null;
  }

  VerdantUser _userFromRailNetworkRecord(RailNetworkRecord record) {
    final rawUserId = record.currentUserId;
    final localUserId = rawUserId == null || rawUserId.trim().isEmpty
        ? 'unknown'
        : railLocalUserId(rawUserId);
    final username = record.currentUsername?.trim();
    return VerdantUser(
      id: localUserId,
      username: username == null || username.isEmpty ? 'signed-out' : username,
      displayName: username == null || username.isEmpty
          ? record.networkName
          : null,
      email: '',
      status: record.authStatus == RailNetworkAuthStatus.authenticated
          ? 'online'
          : 'offline',
      usernameSet: record.usernameSet ?? true,
      emailVerified: true,
      totpEnabled: false,
    );
  }

  void _closeCachedUserSettingsRepository(String apiOrigin) {
    final normalizedApiOrigin = normalizeBackendApiOrigin(apiOrigin);
    final removed = _userSettingsRepositoryCache.remove(normalizedApiOrigin);
    if (removed is ServerSettingsService) {
      removed.close();
    }
  }

  Future<void> _retryNetworkFromSettings(RailNetworkRecord record) async {
    final apiOrigin = record.apiOrigin;
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      _showRailNotice('This network is missing its API origin');
      return;
    }
    if (_normalizeRailApiOrigin(apiOrigin) == null) {
      _showRailNotice('This network has an invalid API origin');
      return;
    }

    await _refreshRailNetworkMetadata();
    if (mounted) {
      _showRailNotice('Retried ${record.networkName}');
    }
  }

  Future<void> _removeNetworkFromSettings(RailNetworkRecord record) async {
    final apiOrigin = record.apiOrigin;
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      _showRailNotice('This network is missing its API origin');
      return;
    }
    final normalizedApiOrigin = _normalizeRailApiOrigin(apiOrigin);
    if (normalizedApiOrigin == null) {
      _showRailNotice('This network has an invalid API origin');
      return;
    }
    if (normalizedApiOrigin == officialApiOrigin) {
      _showRailNotice('The official network cannot be removed');
      return;
    }

    try {
      await widget.credentialStore.clear(normalizedApiOrigin);
      _closeCachedUserSettingsRepository(normalizedApiOrigin);
    } catch (_) {
      if (mounted) {
        _showRailNotice('Could not remove ${record.networkName}');
      }
      return;
    }
    try {
      await _networkProfileStore.removeProfile(normalizedApiOrigin);
      if (_isActiveNetworkRecord(record)) {
        widget.onLogout();
        return;
      }
      final removedNetworkId = networkIdFromApiOrigin(normalizedApiOrigin);
      if (mounted) {
        setState(() {
          _railNetworkRecords = [
            for (final existing in _railNetworkRecords)
              if (!sameWorkspaceNetworkId(existing.networkId, removedNetworkId))
                existing,
          ];
          _railNetworkOrder = [
            for (final networkId in _railNetworkOrder)
              if (!sameWorkspaceNetworkId(networkId, removedNetworkId))
                networkId,
          ];
          _joinedRailServers = [
            for (final server in _joinedRailServers)
              if (!sameWorkspaceNetworkId(server.networkId, removedNetworkId))
                server,
          ];
          _settingsUsersByNetworkId = Map.unmodifiable({
            for (final entry in _settingsUsersByNetworkId.entries)
              if (!sameWorkspaceNetworkId(entry.key, removedNetworkId))
                entry.key: entry.value,
          });
        });
      }
      await _refreshRailNetworkMetadata();
      if (mounted) {
        _showRailNotice('Removed ${record.networkName}');
      }
    } catch (_) {
      if (mounted) {
        _showRailNotice('Could not remove ${record.networkName}');
      }
    }
  }

  bool _isActiveNetworkRecord(RailNetworkRecord record) {
    final apiOrigin = _normalizeRailApiOrigin(record.apiOrigin);
    return sameWorkspaceNetworkId(record.networkId, widget.session.networkId) ||
        (apiOrigin != null && apiOrigin == widget.session.apiOrigin);
  }

  String? _normalizeRailApiOrigin(String? apiOrigin) {
    if (apiOrigin == null || apiOrigin.trim().isEmpty) {
      return null;
    }
    try {
      return normalizeBackendApiOrigin(apiOrigin);
    } catch (_) {
      return null;
    }
  }

  Future<void> _createInviteForRailServer(RailServerItem railServer) async {
    try {
      final apiOrigin = _apiOriginForRailServer(railServer);
      if (apiOrigin == null) {
        _showRailNotice('This network is missing its API origin');
        return;
      }
      final repository = _repositoryForNetworkRail(apiOrigin);
      final closeRepository = _temporaryRepositoryCloser(repository);
      try {
        final invite = await repository.createInvite(
          serverId: railServer.localServerId,
        );
        final code = _inviteCodeFromSeed(invite);
        final link = buildChatInviteShareLink(code, apiOrigin: apiOrigin);
        await Clipboard.setData(ClipboardData(text: link));
      } finally {
        closeRepository?.call();
      }
      if (!mounted) {
        return;
      }
      _showRailNotice('Copied invite link for ${railServer.name}');
    } on ServerSettingsException catch (error) {
      if (mounted) {
        _showRailNotice(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showRailNotice('Could not create invite link');
      }
    }
  }

  String? _apiOriginForRailServer(RailServerItem railServer) {
    final activeNetworkId =
        _controller.state.settings?.networkId ?? widget.session.networkId;
    if (sameWorkspaceNetworkId(railServer.networkId, activeNetworkId)) {
      return widget.session.apiOrigin;
    }
    return _normalizeRailApiOrigin(
      _railNetworkRecordFor(railServer.networkId)?.apiOrigin,
    );
  }

  Future<void> _confirmLeaveRailServer(ServerSettingsServer server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VerdantColors.panel,
        title: const Text('Leave Server'),
        content: Text(
          'Are you sure you want to leave ${server.name}? You will need a new invite to rejoin.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('server-rail-leave-cancel-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('server-rail-leave-confirm-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave Server'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _controller.leaveServer(server);
      if (!mounted) {
        return;
      }
      setState(() {
        _directMessagesOpen = false;
        _hideServerDrawerImmediately();
      });
      _showRailNotice('Left ${server.name}');
    } on ServerSettingsException catch (error) {
      if (mounted) {
        _showRailNotice(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showRailNotice('Could not leave server');
      }
    }
  }

  String _inviteCodeFromSeed(ServerSettingsListItemSeed invite) {
    final code = invite.inviteCode ?? invite.id;
    if (code != null && code.trim().isNotEmpty) {
      return code.trim();
    }
    final title = invite.title.trim();
    if (title.toLowerCase().startsWith('invite ')) {
      return title.substring(7).trim();
    }
    return title;
  }

  String get _networkLabel {
    return 'Network: ${_railNetworkName(widget.session.networkId)}';
  }

  String _railNetworkName(String networkId) {
    final record = _railNetworkRecordFor(networkId);
    if (record != null) {
      return record.networkName;
    }
    return 'this network';
  }

  RailNetworkRecord? _railNetworkRecordFor(String networkId) {
    for (final record in _railNetworkRecords) {
      if (sameWorkspaceNetworkId(record.networkId, networkId)) {
        return record;
      }
    }
    return null;
  }

  String _hostLabelForApiOrigin(String apiOrigin) {
    final host = Uri.tryParse(apiOrigin)?.host;
    if (host == null || host.trim().isEmpty) {
      return 'Saved Network';
    }
    return host;
  }

  void _showRailNotice(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        ),
      );
  }

  void _hideServerDrawerImmediately() {
    _serverDrawerAnimation.value = 0;
    _serverDrawerOpen = false;
  }

  void _configureDirectMessagesRefresh(bool enabled) {
    if (!enabled) {
      return;
    }
    unawaited(_controller.refreshDirectMessages());
  }

  Future<void> _showMemberContextMenu(
    MemberSeed member,
    Offset globalPosition,
  ) async {
    final localUserId = _safeMemberLocalId(member);
    final currentUser = _controller.state.currentUser ?? widget.session.user;
    final selected = await showWorkspaceUserContextMenu(
      context: context,
      globalPosition: globalPosition,
      entries: [
        const WorkspaceUserContextMenuItem(
          id: 'profile',
          label: 'Profile',
          icon: PhosphorIconsRegular.user,
          enabled: false,
        ),
        WorkspaceUserContextMenuItem(
          id: 'message',
          label: 'Message',
          icon: PhosphorIconsRegular.chatDots,
          enabled: localUserId != null && localUserId != currentUser.id,
        ),
        const WorkspaceUserContextMenuDivider(),
        WorkspaceUserContextMenuItem(
          id: 'copy',
          label: workspaceUserCopyLabel(member.id),
          icon: PhosphorIconsRegular.copy,
        ),
      ],
    );

    switch (selected) {
      case 'message':
        if (localUserId == null) {
          return;
        }
        setState(() => _directMessagesOpen = true);
        _configureDirectMessagesRefresh(true);
        await _controller.openDirectMessage(localUserId);
        break;
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: workspaceUserClipboardId(member.id, fallback: member.name),
          ),
        );
    }
  }

  String? _safeMemberLocalId(MemberSeed member) {
    final id = member.id?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    try {
      if (id.contains('/')) {
        final scoped = scopedWorkspaceId(widget.session.networkId, id);
        return scoped.substring(scoped.indexOf('/') + 1);
      }
      return safeWorkspaceLocalId(id);
    } on FormatException {
      return null;
    }
  }

  void _closeServerSettings() {
    if (!_serverSettingsOpen) {
      return;
    }
    _serverSettingsAnimation.reverse().whenComplete(() {
      if (!mounted) {
        return;
      }
      if (_serverSettingsAnimation.value == 0) {
        setState(() => _serverSettingsOpen = false);
        _clearServerSettingsWindowOverlay();
      }
    });
  }

  void _clearServerSettingsWindowOverlay() {
    if (!_ownsServerSettingsWindowOverlay) {
      return;
    }
    widget.onWindowOverlayChanged?.call(null);
    _ownsServerSettingsWindowOverlay = false;
  }

  void _clearUserSettingsWindowOverlay() {
    if (!_ownsUserSettingsWindowOverlay) {
      return;
    }
    widget.onWindowOverlayChanged?.call(null);
    _ownsUserSettingsWindowOverlay = false;
  }
}

ServerSettingsListItemSeed? _activeFeedForId(
  List<ServerSettingsListItemSeed> feeds,
  String? activeFeedId,
) {
  if (activeFeedId == null) {
    return null;
  }
  final activeLocalId = _localFeedId(activeFeedId);
  for (final feed in feeds) {
    final id = feed.id;
    if (id == null) {
      continue;
    }
    if (id == activeFeedId || _localFeedId(id) == activeLocalId) {
      return feed;
    }
  }
  return null;
}

String _localFeedId(String value) {
  final slash = value.indexOf('/');
  return slash < 0 ? value : value.substring(slash + 1);
}
