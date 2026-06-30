import 'dart:async';

import 'package:flutter/material.dart';

import '../features/auth/auth_credentials.dart';
import '../features/auth/auth_diagnostics.dart';
import '../features/auth/auth_models.dart';
import '../features/auth/instance_identity.dart';
import '../features/auth/network_profile_store.dart';
import '../features/auth/auth_service.dart';
import '../features/auth/instance_metadata_service.dart';
import '../features/auth/login_workspace.dart';
import '../features/workspace/direct_messages_workspace/direct_messages_service.dart';
import '../features/workspace/direct_messages_workspace/direct_messages_preferences.dart';
import '../features/workspace/server_settings_workspace/federated_invite_service.dart';
import '../features/workspace/server_settings_workspace/federated_membership_service.dart';
import '../features/workspace/server_settings_workspace/server_media_image.dart';
import '../features/workspace/server_settings_workspace/server_settings_service.dart';
import '../features/workspace/shared/inactive_backend_runtime.dart';
import '../features/workspace/shared/media_residency_scope.dart';
import '../features/workspace/user_settings_workspace/user_settings_preferences.dart';
import '../features/workspace/user_settings_workspace/workspace_accessibility_settings.dart';
import '../features/workspace/workspace_shell/workspace_shell.dart';
import '../theme/verdant_theme.dart';
import 'window_chrome.dart';
import 'window_focus_scope.dart';
import 'verdant_app_profile.dart';

class VerdantFlutterApp extends StatefulWidget {
  const VerdantFlutterApp({
    super.key,
    this.authService,
    this.credentialStore,
    this.networkProfileStore,
    this.instanceMetadataService,
    this.instanceIdentityStore,
    this.instanceIdentityManifestService,
    this.authDiagnostics,
    this.windowControls,
    this.serverSettingsRepository,
    this.serverSettingsRepositoryFactory,
    this.federatedMembershipRepositoryFactory,
    this.federatedInvitePreviewRepository,
    this.federatedInviteJoinRepository,
    this.directMessagesRepository,
    this.directMessagesPreferences,
    this.accessibilitySettingsStore,
    this.userSettingsPreferencesStore,
    this.appProfile = VerdantAppProfile.primary,
    this.inactiveWorkspaceIdleTimeout = const Duration(minutes: 5),
    this.syncSummaryClient,
    this.inactiveSummaryPollInterval = const Duration(seconds: 15),
  });

  final AuthService? authService;
  final AuthCredentialStore? credentialStore;
  final NetworkProfileStore? networkProfileStore;
  final InstanceMetadataService? instanceMetadataService;
  final InstanceIdentityStore? instanceIdentityStore;
  final InstanceIdentityManifestService? instanceIdentityManifestService;
  final AuthDiagnostics? authDiagnostics;
  final WindowChromeControls? windowControls;
  final ServerSettingsRepository? serverSettingsRepository;
  final ServerSettingsRepository Function(String apiOrigin)?
  serverSettingsRepositoryFactory;
  final FederatedMembershipRepository Function(String apiOrigin)?
  federatedMembershipRepositoryFactory;
  final FederatedInvitePreviewRepository? federatedInvitePreviewRepository;
  final FederatedInviteJoinRepository? federatedInviteJoinRepository;
  final DirectMessagesRepository? directMessagesRepository;
  final DirectMessagesPreferences? directMessagesPreferences;
  final WorkspaceAccessibilitySettingsStore? accessibilitySettingsStore;
  final UserSettingsPreferencesStore? userSettingsPreferencesStore;
  final VerdantAppProfile appProfile;
  final Duration inactiveWorkspaceIdleTimeout;
  final SyncSummaryClient? syncSummaryClient;
  final Duration inactiveSummaryPollInterval;

  @override
  State<VerdantFlutterApp> createState() => _VerdantFlutterAppState();
}

class _VerdantFlutterAppState extends State<VerdantFlutterApp> {
  late final AuthCredentialStore _credentialStore;
  late final NetworkProfileStore _networkProfileStore;
  late final InstanceIdentityStore _instanceIdentityStore;
  late final WorkspaceAccessibilitySettingsStore _accessibilitySettingsStore;
  late final DirectMessagesPreferences _directMessagesPreferences;
  late final UserSettingsPreferencesStore _userSettingsPreferencesStore;
  late final WindowFocusController _windowFocusController;
  late final AuthDiagnostics _authDiagnostics;
  UserSettingsPreferences _userSettingsPreferences =
      const UserSettingsPreferences();
  WidgetBuilder? _windowOverlayBuilder;

  @override
  void initState() {
    super.initState();
    final storageNamespace = widget.appProfile.storageNamespace;
    _credentialStore =
        widget.credentialStore ??
        FlutterSecureAuthCredentialStore(
          keyPrefix: widget.appProfile.credentialKeyPrefix,
        );
    _networkProfileStore =
        widget.networkProfileStore ??
        NetworkProfileStore(storageNamespace: storageNamespace);
    _instanceIdentityStore =
        widget.instanceIdentityStore ??
        InstanceIdentityStore(storageNamespace: storageNamespace);
    _accessibilitySettingsStore =
        widget.accessibilitySettingsStore ??
        WorkspaceAccessibilitySettingsStore(storageNamespace: storageNamespace);
    _directMessagesPreferences =
        widget.directMessagesPreferences ??
        DirectMessagesPreferences(storageNamespace: storageNamespace);
    _userSettingsPreferencesStore =
        widget.userSettingsPreferencesStore ??
        UserSettingsPreferencesStore(storageNamespace: storageNamespace);
    _authDiagnostics = RedactingAuthDiagnostics(
      TaggedAuthDiagnostics(
        delegate: widget.authDiagnostics ?? const DebugPrintAuthDiagnostics(),
        fields: {
          'appProfile': widget.appProfile.id,
          'storageNamespace': widget.appProfile.storageNamespace.isEmpty
              ? 'primary'
              : widget.appProfile.storageNamespace,
        },
      ),
    );
    _authDiagnostics.record('app.profile.start', {
      'windowTitle': widget.appProfile.windowTitle,
      'hasProfileBadge': widget.appProfile.titleBarBadgeLabel != null,
    });
    _windowFocusController = WindowFocusController()
      ..addListener(_handleWindowFocusChanged)
      ..attach();
    unawaited(_loadUserSettingsPreferences());
  }

  @override
  void dispose() {
    _windowFocusController.removeListener(_handleWindowFocusChanged);
    _windowFocusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _appThemeFor(_userSettingsPreferences);
    return AnimatedBuilder(
      animation: _windowFocusController,
      builder: (context, child) => WindowFocusScope(
        focused: _windowFocusController.isFocused,
        child: MediaResidencyScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: widget.appProfile.windowTitle,
            theme: appTheme,
            home: VerdantWindowFrame(
              controls:
                  widget.windowControls ?? const WindowManagerChromeControls(),
              profileBadgeLabel: widget.appProfile.titleBarBadgeLabel,
              overlayBuilder: _windowOverlayBuilder,
              child: LoginWorkspace(
                authService: widget.authService ?? HttpAuthService(),
                credentialStore: _credentialStore,
                networkProfileStore: _networkProfileStore,
                instanceMetadataService: widget.instanceMetadataService,
                instanceIdentityStore: _instanceIdentityStore,
                instanceIdentityManifestService:
                    widget.instanceIdentityManifestService,
                federatedMembershipRepositoryFactory:
                    widget.federatedMembershipRepositoryFactory,
                diagnostics: _authDiagnostics,
                profileBadgeLabel: widget.appProfile.titleBarBadgeLabel,
                authenticatedBuilder:
                    (
                      context,
                      session,
                      onLogout,
                      onActivateNetwork,
                      initialServerId,
                    ) => _MultiNetworkWorkspaceHost(
                      session: session,
                      initialServerId: initialServerId,
                      credentialStore: _credentialStore,
                      authService: widget.authService,
                      serverSettingsRepository: widget.serverSettingsRepository,
                      serverSettingsRepositoryFactory:
                          widget.serverSettingsRepositoryFactory,
                      federatedMembershipRepositoryFactory:
                          widget.federatedMembershipRepositoryFactory,
                      federatedInvitePreviewRepository:
                          widget.federatedInvitePreviewRepository,
                      federatedInviteJoinRepository:
                          widget.federatedInviteJoinRepository,
                      directMessagesRepository: widget.directMessagesRepository,
                      networkProfileStore: _networkProfileStore,
                      instanceMetadataService: widget.instanceMetadataService,
                      instanceIdentityStore: _instanceIdentityStore,
                      instanceIdentityManifestService:
                          widget.instanceIdentityManifestService,
                      authDiagnostics: _authDiagnostics,
                      accessibilitySettingsStore: _accessibilitySettingsStore,
                      directMessagesPreferences: _directMessagesPreferences,
                      userSettingsPreferencesStore:
                          _userSettingsPreferencesStore,
                      inactiveWorkspaceIdleTimeout:
                          widget.inactiveWorkspaceIdleTimeout,
                      syncSummaryClient: widget.syncSummaryClient,
                      inactiveSummaryPollInterval:
                          widget.inactiveSummaryPollInterval,
                      onUserSettingsPreferencesChanged:
                          _applyUserSettingsPreferences,
                      currentUserName: session.user.displayLabel,
                      currentUserInitials: session.user.initials,
                      onActivateNetwork: onActivateNetwork,
                      onWindowOverlayChanged: _setWindowOverlay,
                      onLogout: () {
                        clearServerMediaImageCache();
                        onLogout();
                      },
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserSettingsPreferences() async {
    final preferences = await _userSettingsPreferencesStore.load();
    if (!mounted) {
      return;
    }
    setState(() => _userSettingsPreferences = preferences);
  }

  void _applyUserSettingsPreferences(UserSettingsPreferences preferences) {
    if (_userSettingsPreferences == preferences) {
      return;
    }
    setState(() => _userSettingsPreferences = preferences);
  }

  void _setWindowOverlay(WidgetBuilder? builder) {
    if (!mounted) {
      return;
    }
    setState(() => _windowOverlayBuilder = builder);
  }

  void _handleWindowFocusChanged() {
    if (!_windowFocusController.isFocused) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}

final class _WorkspaceHostEntry {
  _WorkspaceHostEntry({
    required this.session,
    required this.serverSettingsRepository,
    this.initialServerId,
  });

  AuthSession session;
  String? initialServerId;
  final ServerSettingsRepository? serverSettingsRepository;
  bool isReady = false;
  String? activeServerId;
}

class _MultiNetworkWorkspaceHost extends StatefulWidget {
  const _MultiNetworkWorkspaceHost({
    required this.session,
    required this.credentialStore,
    required this.currentUserName,
    required this.currentUserInitials,
    required this.onLogout,
    required this.onActivateNetwork,
    required this.userSettingsPreferencesStore,
    required this.inactiveWorkspaceIdleTimeout,
    required this.inactiveSummaryPollInterval,
    required this.onUserSettingsPreferencesChanged,
    required this.onWindowOverlayChanged,
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
    this.authDiagnostics,
    this.accessibilitySettingsStore,
    this.syncSummaryClient,
  });

  final AuthSession session;
  final String? initialServerId;
  final AuthCredentialStore credentialStore;
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
  final AuthDiagnostics? authDiagnostics;
  final WorkspaceAccessibilitySettingsStore? accessibilitySettingsStore;
  final UserSettingsPreferencesStore userSettingsPreferencesStore;
  final Duration inactiveWorkspaceIdleTimeout;
  final SyncSummaryClient? syncSummaryClient;
  final Duration inactiveSummaryPollInterval;
  final ValueChanged<UserSettingsPreferences> onUserSettingsPreferencesChanged;
  final ValueChanged<WidgetBuilder?> onWindowOverlayChanged;
  final String currentUserName;
  final String currentUserInitials;
  final VoidCallback onLogout;
  final Future<NetworkSessionActivationResult> Function({
    required String apiOrigin,
    String? initialServerId,
  })
  onActivateNetwork;

  @override
  State<_MultiNetworkWorkspaceHost> createState() =>
      _MultiNetworkWorkspaceHostState();
}

class _MultiNetworkWorkspaceHostState
    extends State<_MultiNetworkWorkspaceHost> {
  static const _minimumNetworkSwitchDwell = Duration.zero;

  final _entries = <String, _WorkspaceHostEntry>{};
  final _inactiveReleaseTimers = <String, Timer>{};
  WorkspaceRailSnapshot _railSnapshot = const WorkspaceRailSnapshot();
  late String _targetNetworkId;
  late String _visibleNetworkId;
  String? _pendingVisibleNetworkId;
  Timer? _pendingVisibleNetworkTimer;
  bool _pendingVisibleNetworkDwellComplete = false;
  Stopwatch? _pendingVisibleNetworkWatch;

  @override
  void initState() {
    super.initState();
    _targetNetworkId = widget.session.networkId;
    _visibleNetworkId = widget.session.networkId;
    _upsertEntry(widget.session, widget.initialServerId);
  }

  @override
  void didUpdateWidget(_MultiNetworkWorkspaceHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetNetworkId = widget.session.networkId;
    final entry = _upsertEntry(widget.session, widget.initialServerId);
    _targetNetworkId = targetNetworkId;
    if (!_entries.containsKey(_visibleNetworkId)) {
      _visibleNetworkId = targetNetworkId;
      _clearPendingVisibleNetworkTransition();
      return;
    }
    if (_visibleNetworkId != targetNetworkId) {
      _beginTargetNetworkTransition(targetNetworkId, entry);
      return;
    }
    _clearPendingVisibleNetworkTransition();
    if (_entryReadyForTarget(entry)) {
      _showNetwork(targetNetworkId);
    }
  }

  @override
  void dispose() {
    for (final timer in _inactiveReleaseTimers.values) {
      timer.cancel();
    }
    _inactiveReleaseTimers.clear();
    _pendingVisibleNetworkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries.entries.toList(growable: false);
    return ClipRect(
      key: const ValueKey('multi-network-workspace-stack'),
      child: Stack(
        children: [
          for (final entry in entries)
            _buildNetworkPane(entry.key, entry.value),
        ],
      ),
    );
  }

  Widget _buildNetworkPane(String networkId, _WorkspaceHostEntry entry) {
    final isCurrent = networkId == _visibleNetworkId;
    final child = WorkspaceShell(
      key: ValueKey('workspace-shell-$networkId'),
      session: entry.session,
      initialServerId: entry.initialServerId,
      credentialStore: widget.credentialStore,
      authService: widget.authService,
      serverSettingsRepository: entry.serverSettingsRepository,
      serverSettingsRepositoryFactory: widget.serverSettingsRepositoryFactory,
      federatedMembershipRepositoryFactory:
          widget.federatedMembershipRepositoryFactory,
      federatedInvitePreviewRepository: widget.federatedInvitePreviewRepository,
      federatedInviteJoinRepository: widget.federatedInviteJoinRepository,
      directMessagesRepository: widget.directMessagesRepository,
      directMessagesPreferences: widget.directMessagesPreferences,
      networkProfileStore: widget.networkProfileStore,
      instanceMetadataService: widget.instanceMetadataService,
      instanceIdentityStore: widget.instanceIdentityStore,
      instanceIdentityManifestService: widget.instanceIdentityManifestService,
      syncSummaryClient: widget.syncSummaryClient,
      inactiveSummaryPollInterval: widget.inactiveSummaryPollInterval,
      diagnostics: widget.authDiagnostics,
      accessibilitySettingsStore: widget.accessibilitySettingsStore,
      userSettingsPreferencesStore: widget.userSettingsPreferencesStore,
      onUserSettingsPreferencesChanged: widget.onUserSettingsPreferencesChanged,
      onWindowOverlayChanged: isCurrent ? widget.onWindowOverlayChanged : null,
      showBottomRail: isCurrent,
      railInteractionsEnabled: isCurrent,
      currentUserName: entry.session.user.displayLabel,
      currentUserInitials: entry.session.user.initials,
      onActivateNetwork: widget.onActivateNetwork,
      onWorkspaceReadyChanged: _handleWorkspaceReadyChanged,
      initialRailSnapshot: _railSnapshot,
      onRailSnapshotChanged: isCurrent ? _handleRailSnapshotChanged : null,
      onLogout: widget.onLogout,
    );
    return Positioned.fill(
      key: ValueKey('multi-network-workspace-pane-$networkId'),
      child: Offstage(
        offstage: !isCurrent,
        child: TickerMode(
          enabled: isCurrent,
          child: ExcludeFocus(
            key: ValueKey('multi-network-focus-guard-$networkId'),
            excluding: !isCurrent,
            child: ExcludeSemantics(
              excluding: !isCurrent,
              child: IgnorePointer(ignoring: !isCurrent, child: child),
            ),
          ),
        ),
      ),
    );
  }

  _WorkspaceHostEntry _upsertEntry(
    AuthSession session,
    String? initialServerId,
  ) {
    _cancelInactiveRelease(session.networkId);
    final existing = _entries[session.networkId];
    if (existing != null) {
      existing.session = session;
      existing.initialServerId = initialServerId;
      return existing;
    }
    final entry = _WorkspaceHostEntry(
      session: session,
      serverSettingsRepository: _serverSettingsRepositoryFor(session),
      initialServerId: initialServerId,
    );
    _entries[session.networkId] = entry;
    return entry;
  }

  void _showNetwork(String networkId, {int? transitionMs}) {
    if (_visibleNetworkId == networkId) {
      _cancelInactiveRelease(networkId);
      return;
    }
    final previousNetworkId = _visibleNetworkId;
    setState(() {
      _visibleNetworkId = networkId;
    });
    _cancelInactiveRelease(networkId);
    _scheduleInactiveRelease(previousNetworkId);
    widget.authDiagnostics?.record('workspace.network.visible', {
      'networkId': networkId,
      'previousNetworkId': previousNetworkId,
      'reason': 'ready_target',
      'ms': transitionMs,
    });
  }

  void _beginTargetNetworkTransition(
    String networkId,
    _WorkspaceHostEntry entry,
  ) {
    _cancelInactiveRelease(networkId);
    if (_pendingVisibleNetworkId != networkId) {
      _pendingVisibleNetworkTimer?.cancel();
      _pendingVisibleNetworkId = networkId;
      _pendingVisibleNetworkWatch = Stopwatch()..start();
      _pendingVisibleNetworkDwellComplete =
          _minimumNetworkSwitchDwell <= Duration.zero;
      if (!_pendingVisibleNetworkDwellComplete) {
        _pendingVisibleNetworkTimer = Timer(_minimumNetworkSwitchDwell, () {
          _pendingVisibleNetworkTimer = null;
          _pendingVisibleNetworkDwellComplete = true;
          if (mounted) {
            _tryShowPendingVisibleNetwork();
          }
        });
      }
      widget.authDiagnostics?.record('workspace.network.target', {
        'networkId': networkId,
        'previousNetworkId': _visibleNetworkId,
        'isReady': entry.isReady,
        'activeServerId': entry.activeServerId,
        'initialServerId': entry.initialServerId,
        'minimumDwellMs': _minimumNetworkSwitchDwell.inMilliseconds,
        'ms': _pendingVisibleNetworkWatch?.elapsedMilliseconds ?? 0,
      });
    }
    _tryShowPendingVisibleNetwork();
  }

  void _tryShowPendingVisibleNetwork() {
    final networkId = _pendingVisibleNetworkId;
    if (networkId == null) {
      return;
    }
    final entry = _entries[networkId];
    if (entry == null) {
      _clearPendingVisibleNetworkTransition();
      return;
    }
    if (!_entryReadyForTarget(entry)) {
      return;
    }
    if (!_pendingVisibleNetworkDwellComplete) {
      widget.authDiagnostics?.record('workspace.network.visible.wait', {
        'networkId': networkId,
        'activeServerId': entry.activeServerId,
        'initialServerId': entry.initialServerId,
        'minimumDwellMs': _minimumNetworkSwitchDwell.inMilliseconds,
        'ms': _pendingVisibleNetworkWatch?.elapsedMilliseconds ?? 0,
      });
      return;
    }
    final transitionMs = _pendingVisibleNetworkWatch?.elapsedMilliseconds;
    _clearPendingVisibleNetworkTransition();
    _showNetwork(networkId, transitionMs: transitionMs);
  }

  void _clearPendingVisibleNetworkTransition() {
    _pendingVisibleNetworkTimer?.cancel();
    _pendingVisibleNetworkTimer = null;
    _pendingVisibleNetworkId = null;
    _pendingVisibleNetworkDwellComplete = false;
    _pendingVisibleNetworkWatch = null;
  }

  void _scheduleInactiveRelease(String networkId) {
    if (!_entries.containsKey(networkId) || networkId == _visibleNetworkId) {
      return;
    }
    _inactiveReleaseTimers.remove(networkId)?.cancel();
    final timeout = widget.inactiveWorkspaceIdleTimeout;
    if (timeout <= Duration.zero) {
      _releaseInactiveNetwork(networkId);
      return;
    }
    _inactiveReleaseTimers[networkId] = Timer(timeout, () {
      _inactiveReleaseTimers.remove(networkId);
      _releaseInactiveNetwork(networkId);
    });
  }

  void _cancelInactiveRelease(String networkId) {
    _inactiveReleaseTimers.remove(networkId)?.cancel();
  }

  void _handleRailSnapshotChanged(WorkspaceRailSnapshot snapshot) {
    if (_railSnapshot.contentSignature == snapshot.contentSignature) {
      return;
    }
    setState(() {
      _railSnapshot = snapshot;
    });
  }

  void _releaseInactiveNetwork(String networkId) {
    if (!mounted ||
        networkId == _visibleNetworkId ||
        networkId == _targetNetworkId ||
        !_entries.containsKey(networkId)) {
      return;
    }
    setState(() {
      _entries.remove(networkId);
    });
  }

  bool _entryReadyForTarget(_WorkspaceHostEntry entry) {
    if (!entry.isReady) {
      return false;
    }
    final requestedServerId = entry.initialServerId;
    return requestedServerId == null ||
        entry.activeServerId == requestedServerId;
  }

  void _handleWorkspaceReadyChanged(
    String networkId,
    bool isReady,
    String? activeServerId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyWorkspaceReadyChanged(networkId, isReady, activeServerId);
      }
    });
  }

  void _applyWorkspaceReadyChanged(
    String networkId,
    bool isReady,
    String? activeServerId,
  ) {
    final entry = _entries[networkId];
    if (entry == null) {
      return;
    }
    final changed =
        entry.isReady != isReady || entry.activeServerId != activeServerId;
    if (changed) {
      setState(() {
        entry.isReady = isReady;
        entry.activeServerId = activeServerId;
        if (isReady &&
            activeServerId != null &&
            networkId == _visibleNetworkId) {
          entry.initialServerId = activeServerId;
        }
      });
    }
    if (_entryReadyForTarget(entry) && networkId == _targetNetworkId) {
      if (_visibleNetworkId == networkId) {
        _showNetwork(networkId);
      } else {
        _tryShowPendingVisibleNetwork();
      }
    }
  }

  ServerSettingsRepository? _serverSettingsRepositoryFor(AuthSession session) {
    final factory = widget.serverSettingsRepositoryFactory;
    if (factory != null) {
      return factory(session.apiOrigin);
    }
    return widget.serverSettingsRepository;
  }
}

ThemeData _appThemeFor(UserSettingsPreferences preferences) {
  return buildVerdantTheme(mode: _appThemeModeFor(preferences.theme));
}

VerdantThemeMode _appThemeModeFor(UserSettingsThemePreference preference) {
  return switch (preference) {
    UserSettingsThemePreference.dark => VerdantThemeMode.dark,
    UserSettingsThemePreference.light => VerdantThemeMode.light,
  };
}
