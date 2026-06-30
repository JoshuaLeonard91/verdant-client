import 'dart:async';
import 'dart:convert';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/verdant_app_profile.dart';
import 'package:verdant_flutter/app/verdant_flutter_app.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_diagnostics.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/instance_identity.dart';
import 'package:verdant_flutter/features/auth/network_profile_store.dart';
import 'package:verdant_flutter/features/auth/auth_service.dart';
import 'package:verdant_flutter/features/auth/instance_metadata_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/federated_invite_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/federated_membership_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_image.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_loader.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_models.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_settings_service.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/dm_conversation_module.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_models.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_preferences.dart';
import 'package:verdant_flutter/features/workspace/direct_messages_workspace/direct_messages_service.dart';
import 'package:verdant_flutter/features/workspace/shared/inactive_backend_runtime.dart';
import 'package:verdant_flutter/features/workspace/shared/workspace_entitlements.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_notifications.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_preferences.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/user_settings_sessions.dart';
import 'package:verdant_flutter/features/workspace/user_settings_workspace/workspace_accessibility_settings.dart';
import 'package:verdant_flutter/features/workspace/workspace_shell/workspace_shell.dart';
import 'package:verdant_flutter/theme/verdant_button.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';
import 'package:verdant_flutter/features/workspace/workspace_seed.dart';

void main() {
  testWidgets(
    'starts on the real login surface instead of the workspace mock',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pump();

      await tester.pumpWidget(_testApp(authService: _FakeAuthService()));

      expect(
        find.byKey(const ValueKey('startup-loading-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('startup-loading-progress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('login-email-field')).hitTestable(),
        findsNothing,
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('startup-loading-surface')),
        findsNothing,
      );
      expect(find.text('Sign in to Verdant'), findsOneWidget);
      expect(find.text('API origin'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('login-brand-app-icon')),
        findsOneWidget,
      );
      final logo = tester.widget<Image>(
        find.byKey(const ValueKey('login-brand-app-icon')),
      );
      expect(logo.width, 56);
      expect(logo.height, 56);
      expect(find.byKey(const ValueKey('login-brand-title')), findsNothing);
      expect(find.text('Flutter client'), findsNothing);
      expect(find.text('Message #general'), findsNothing);
    },
  );

  testWidgets(
    'startup restore keeps login controls hidden while saved auth is pending',
    (tester) async {
      final restoreGate = Completer<void>();
      final credentialStore = _MemoryCredentialStore(
        beforeRead: (_) => restoreGate.future,
      );
      await _saveOfficialCredential(credentialStore);

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          serverSettingsRepository: _FakeServerSettingsRepository(
            data: _sampleSettingsData,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('startup-loading-surface')),
        findsOneWidget,
      );
      expect(find.text('Starting Verdant'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('login-email-field')).hitTestable(),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('login-submit-button')).hitTestable(),
        findsNothing,
      );

      restoreGate.complete();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('startup-loading-surface')),
        findsNothing,
      );
      expect(find.text('Message #general'), findsOneWidget);
      expect(find.text('Sign in to Verdant'), findsNothing);
    },
  );

  testWidgets('secondary profile stays visible on signed-out auth surface', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        appProfile: VerdantAppProfile.secondary,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(find.text('Secondary Test Client'), findsWidgets);
    expect(find.byKey(const ValueKey('login-profile-badge')), findsOneWidget);
  });

  testWidgets('sign in panel fits inside the minimum desktop window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(980, 620);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(authService: _FailingAuthService()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'password',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    var maxVerticalExtent = 0.0;
    for (final state in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (state.position.axis == Axis.vertical &&
          state.position.maxScrollExtent > maxVerticalExtent) {
        maxVerticalExtent = state.position.maxScrollExtent;
      }
    }
    expect(maxVerticalExtent, 0);
    expect(find.byKey(const ValueKey('login-submit-button')), findsOneWidget);
    expect(
      tester
          .getBottomLeft(find.byKey(const ValueKey('login-submit-button')))
          .dy,
      lessThanOrEqualTo(620),
    );
  });

  testWidgets('starts in the workspace when credentials are saved securely', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message #general'), findsOneWidget);
    expect(find.text('Sign in to Verdant'), findsNothing);
    expect(find.text('access-token-not-rendered'), findsNothing);
    expect(find.text('session-token-not-rendered'), findsNothing);
  });

  testWidgets(
    'prompts for username setup from live workspace current-user state',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final repository =
          _FakeServerSettingsRepository(data: _sampleSettingsData)
            ..currentUserMedia = const ServerSettingsCurrentUserMedia(
              id: '42',
              username: 'user_42',
              email: 'boji@example.com',
              usernameSet: false,
              emailVerified: true,
              totpEnabled: false,
            );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          serverSettingsRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose username'), findsOneWidget);
      expect(find.text(officialApiOrigin), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('network-username-field')),
        'joshy',
      );
      await tester.tap(find.byKey(const ValueKey('network-username-submit')));
      await tester.pumpAndSettle();

      expect(repository.setUsernames, ['joshy']);
      final credentials = await credentialStore.read(officialApiOrigin);
      expect(credentials?.user?.username, 'joshy');
      expect(credentials?.user?.usernameSet, isTrue);
      expect(find.text('access-token-not-rendered'), findsNothing);
      expect(find.text('session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets('workspace loading state uses connecting copy', (tester) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final pendingServers = Completer<List<ServerSettingsServer>>();

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(
          data: _sampleSettingsData,
          listServersFuture: pendingServers.future,
        ),
      ),
    );
    for (var i = 0; i < 4; i += 1) {
      await tester.pump();
    }

    expect(find.text('Connecting...'), findsOneWidget);
    expect(find.text('Loading server workspace'), findsNothing);
  });

  testWidgets(
    'startup workspace reveal waits for joined network rail hydration',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      await _saveOfficialCredential(credentialStore);
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final selfHostNetworkId = networkIdFromApiOrigin(selfHostOrigin);
      final selfHostServer = _sampleSettingsData.server.copyWith(
        id: 'selfhost-server',
        name: 'Selfhost Grove',
      );
      final selfHostData = _sampleSettingsDataForNetwork(
        networkId: selfHostNetworkId,
        server: selfHostServer,
      );
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: selfHostOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'selfhost-user',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final pendingSelfHostServers = Completer<List<ServerSettingsServer>>();

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (normalizeBackendApiOrigin(apiOrigin) == selfHostOrigin) {
              return _FakeServerSettingsRepository(
                data: selfHostData,
                listServersFuture: pendingSelfHostServers.future,
              );
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Loading workspace...'), findsOneWidget);
      expect(find.text('Message #general'), findsNothing);
      expect(
        find.byKey(
          ValueKey('server-rail-item-$selfHostNetworkId/selfhost-server'),
        ),
        findsNothing,
      );

      pendingSelfHostServers.complete([selfHostServer]);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Loading workspace...'), findsNothing);
      expect(find.text('Message #general'), findsOneWidget);
      expect(
        find.byKey(
          ValueKey('server-rail-item-$selfHostNetworkId/selfhost-server'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'workspace text defaults to 125 percent while bottom rail stays fixed',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          accessibilitySettingsStore:
              WorkspaceAccessibilitySettingsStore.memory(),
        ),
      );
      await tester.pumpAndSettle();

      final workspaceTextContext = tester.element(
        find.text('Message #general'),
      );
      expect(
        MediaQuery.textScalerOf(workspaceTextContext).scale(10),
        closeTo(12.5, 0.01),
      );

      final railContext = tester.element(
        find.byKey(const ValueKey('bottom-rail-workspace')),
      );
      expect(MediaQuery.textScalerOf(railContext).scale(10), 10);
    },
  );

  testWidgets('message composer centers with the current user panel', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 620);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
      ),
    );
    await tester.pumpAndSettle();

    final panelRect = tester.getRect(
      find.byKey(const ValueKey('workspace-current-user-panel')),
    );
    final composerFrameRect = tester.getRect(
      find.byKey(const ValueKey('message-composer-frame')),
    );

    expect(composerFrameRect.center.dy, closeTo(panelRect.center.dy, 2));
  });

  testWidgets('workspace text scale preserves platform accessibility scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2560, 1440);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        accessibilitySettingsStore:
            WorkspaceAccessibilitySettingsStore.memory(),
      ),
    );
    await tester.pumpAndSettle();

    final workspaceTextContext = tester.element(find.text('Message #general'));
    expect(
      MediaQuery.textScalerOf(workspaceTextContext).scale(10),
      closeTo(20, 0.01),
    );

    final railContext = tester.element(
      find.byKey(const ValueKey('bottom-rail-workspace')),
    );
    expect(MediaQuery.textScalerOf(railContext).scale(10), closeTo(20, 0.01));
  });

  testWidgets(
    'user settings opens on profile before accessibility text scaling',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final accessibilityStore = WorkspaceAccessibilitySettingsStore.memory();

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          accessibilitySettingsStore: accessibilityStore,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-settings-workspace')),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('User Settings'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsNothing);
      expect(find.text('APP'), findsNothing);
      expect(find.text('PRODUCT'), findsNothing);
      final profileTop = tester.getTopLeft(
        find.byKey(const ValueKey('user-settings-category-profile')),
      );
      final accessibilityTop = tester.getTopLeft(
        find.byKey(const ValueKey('user-settings-category-accessibility')),
      );
      final accountTop = tester.getTopLeft(
        find.byKey(const ValueKey('user-settings-category-account')),
      );
      expect(profileTop.dy, lessThan(accessibilityTop.dy));
      expect(accountTop.dy, greaterThan(profileTop.dy));
      expect(accountTop.dy, lessThan(accessibilityTop.dy));
      expect(
        find.byKey(const ValueKey('user-settings-category-security')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-sessions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-network')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-general')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-appearance')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-voice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-notifications')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-category-about')),
        findsOneWidget,
      );
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('PROFILE COSMETICS'), findsNothing);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('@boji'), findsWidgets);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Profile Description'), findsOneWidget);
      expect(find.text('Profile Visuals'), findsNothing);
      expect(
        find.byKey(const ValueKey('profile-banner-preview')),
        findsOneWidget,
      );
      final profileCategoryButton = find.byKey(
        const ValueKey('user-settings-category-profile'),
      );
      expect(tester.getSize(profileCategoryButton).height, 48);
      final profileCategoryLabel = tester.widget<Text>(
        find.descendant(
          of: profileCategoryButton,
          matching: find.text('Profile'),
        ),
      );
      expect(profileCategoryLabel.style?.fontSize, 13);
      expect(profileCategoryLabel.style?.fontWeight, FontWeight.w800);
      final profileTextSizes = tester
          .widgetList<Text>(find.text('Profile'))
          .map((widget) => widget.style?.fontSize)
          .whereType<double>();
      expect(profileTextSizes, everyElement(lessThanOrEqualTo(14)));
      expect(
        find.byKey(const ValueKey('profile-avatar-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-identity-avatar-upload-target')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-identity-banner-upload-target')),
        findsOneWidget,
      );
      final avatarTop = tester.getTopLeft(
        find.byKey(const ValueKey('profile-avatar-preview')),
      );
      final bannerTop = tester.getTopLeft(
        find.byKey(const ValueKey('profile-banner-preview')),
      );
      expect(bannerTop.dy, lessThan(avatarTop.dy));
      final avatarSize = tester.getSize(
        find.byKey(const ValueKey('profile-avatar-preview')),
      );
      final bannerSize = tester.getSize(
        find.byKey(const ValueKey('profile-banner-preview')),
      );
      expect(avatarSize.width, lessThanOrEqualTo(88));
      expect(avatarSize.height, lessThanOrEqualTo(88));
      expect(bannerSize.height, lessThanOrEqualTo(150));
      expect(find.text('Member List Banner'), findsOneWidget);
      expect(find.text('Accessibility'), findsWidgets);
      expect(find.text('Workspace Text Size'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('user-settings-category-account')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT ACCESS'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Change Password'), findsNothing);

      final accessibilityCategory = find.byKey(
        const ValueKey('user-settings-category-accessibility'),
      );
      await tester.ensureVisible(accessibilityCategory);
      await tester.pumpAndSettle();
      await tester.tap(accessibilityCategory);
      await tester.pumpAndSettle();

      expect(find.text('Workspace Text Size'), findsOneWidget);
      expect(find.text('125%'), findsWidgets);
      expect(
        find.byKey(const ValueKey('accessibility-text-scale-slider')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('accessibility-text-scale-137%')),
      );
      await tester.pumpAndSettle();
      expect(find.text('137%'), findsWidgets);

      for (final entry in <String, String>{
        'security': 'Two-Factor Authentication',
        'sessions': 'Current Session',
        'network': 'Joined Networks',
        'general': 'Minimize to tray on close',
        'appearance': 'Theme',
        'voice': 'Push to Talk',
        'notifications': 'Desktop Notifications',
        'about': 'Verdant',
      }.entries) {
        final category = find.byKey(
          ValueKey('user-settings-category-${entry.key}'),
        );
        await tester.ensureVisible(category);
        await tester.pumpAndSettle();
        await tester.tap(category);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsWidgets);
        expect(find.text('Planned'), findsNothing);
      }

      final profileCategory = find.byKey(
        const ValueKey('user-settings-category-profile'),
      );
      await tester.ensureVisible(profileCategory);
      await tester.pumpAndSettle();
      await tester.tap(profileCategory);
      await tester.pumpAndSettle();
      expect(find.text('PROFILE COSMETICS'), findsNothing);
      expect(find.text('Profile Visuals'), findsNothing);
      expect(find.text('Member List Banner'), findsOneWidget);
    },
  );

  testWidgets(
    'security settings exposes two factor actions without basic labeling',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      final repository = _FakeServerSettingsRepository(
        data: _sampleSettingsData.copyWith(
          entitlements: const WorkspaceEntitlements(
            officialSubscriptionActive: true,
            officialSubscriptionTier: 'Purple',
            imageUploads: true,
            fileSharing: false,
            messageAttachments: false,
            voiceChat: false,
            videoStreaming: false,
            crossServerEmoji: false,
            animatedAvatar: false,
            animatedBanner: false,
            memberListBanner: true,
            maxUploadBytes: 64,
            maxVoiceBitrate: null,
            officialBadge: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          serverSettingsRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final securityCategory = find.byKey(
        const ValueKey('user-settings-category-security'),
      );
      await tester.ensureVisible(securityCategory);
      await tester.tap(securityCategory);
      await tester.pumpAndSettle();

      expect(find.text('Basic'), findsNothing);
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('user-settings-2fa-enable-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('user-settings-2fa-enable-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-settings-2fa-password-field')),
        findsOneWidget,
      );

      final passwordField = find.byKey(
        const ValueKey('user-settings-2fa-password-field'),
      );
      final passwordTextField = tester.widget<TextField>(passwordField);
      expect(passwordTextField.focusNode, isNotNull);

      await tester.tap(
        find.byKey(const ValueKey('user-settings-2fa-password-field')),
      );
      await tester.pump();
      expect(passwordTextField.focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      await tester.enterText(
        find.byKey(const ValueKey('user-settings-2fa-password-field')),
        'current password',
      );
      await tester.pumpAndSettle();
      expect(find.text('current password'), findsOneWidget);
      final continueButton = find.descendant(
        of: find.byKey(
          const ValueKey('user-settings-2fa-password-continue-button'),
        ),
        matching: find.byType(OutlinedButton),
      );
      expect(continueButton, findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(continueButton).onPressed,
        isNotNull,
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.twoFactorSetupPasswords, ['current password']);

      expect(find.text('access-token-not-rendered'), findsNothing);
      expect(find.text('session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'network settings is status-only and does not launch add network',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final networkCategory = find.byKey(
        const ValueKey('user-settings-category-network'),
      );
      await tester.ensureVisible(networkCategory);
      await tester.tap(networkCategory);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-settings-add-network-button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('join-network-modal')), findsNothing);
      expect(
        find.byKey(const ValueKey('join-network-origin-field')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'network settings completes username for a saved network without replacing active credentials',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-token-not-rendered',
          sessionToken: 'official-session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'user_84',
            email: 'new@example.com',
            status: 'online',
            usernameSet: false,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      final activeRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
      );
      final selfHostRepository =
          _FakeServerSettingsRepository(
              data: _sampleSettingsDataForNetwork(
                networkId: testNetworkId,
                server: _sampleSettingsData.server.copyWith(
                  id: 'selfhost-server',
                  name: 'Selfhost Grove',
                ),
              ),
            )
            ..currentUserMedia = const ServerSettingsCurrentUserMedia(
              id: '84',
              username: 'user_84',
              email: 'new@example.com',
              usernameSet: false,
              emailVerified: true,
              totpEnabled: false,
            );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepository: activeRepository,
          serverSettingsRepositoryFactory: (apiOrigin) =>
              apiOrigin == testOrigin ? selfHostRepository : activeRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final networkCategory = find.byKey(
        const ValueKey('user-settings-category-network'),
      );
      await tester.ensureVisible(networkCategory);
      await tester.tap(networkCategory);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Username needed'), findsOneWidget);
      final setUsernameButton = find.byKey(
        ValueKey('user-settings-network-set-username-$testNetworkId'),
      );
      expect(setUsernameButton, findsOneWidget);

      await tester.ensureVisible(setUsernameButton);
      await tester.pumpAndSettle();
      await tester.tap(setUsernameButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('network-username-field')),
        'community_josh',
      );
      await tester.tap(find.byKey(const ValueKey('network-username-submit')));
      await tester.pumpAndSettle();

      expect(selfHostRepository.setUsernames, ['community_josh']);
      final officialCredentials = await credentialStore.read(officialApiOrigin);
      final selfHostCredentials = await credentialStore.read(testOrigin);
      expect(officialCredentials?.user?.username, 'boji');
      expect(selfHostCredentials?.user?.username, 'community_josh');
      expect(selfHostCredentials?.user?.usernameSet, isTrue);
      expect(find.text('official-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'appearance and voice settings give selectable persisted feedback',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final preferencesStore = UserSettingsPreferencesStore.memory();

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          userSettingsPreferencesStore: preferencesStore,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('workspace-appearance-dark-comfortable')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final appearanceCategory = find.byKey(
        const ValueKey('user-settings-category-appearance'),
      );
      await tester.ensureVisible(appearanceCategory);
      await tester.tap(appearanceCategory);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-settings-theme-dark')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-theme-light')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-theme-verdant')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('user-settings-theme-light')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-settings-appearance-preview-light')),
        findsOneWidget,
      );
      final lightSettingsSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('user-settings-workspace')),
      );
      expect(
        (lightSettingsSurface.decoration as BoxDecoration).color,
        VerdantThemeColors.light.panelRaised,
      );
      final lightWindowTitleBar = tester.widget<Container>(
        find.byKey(const ValueKey('verdant-window-title-bar')),
      );
      expect(
        (lightWindowTitleBar.decoration as BoxDecoration).color,
        VerdantThemeColors.light.background,
      );
      final lightServerSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('server-workspace-surface')),
      );
      expect(
        (lightServerSurface.decoration as BoxDecoration).color,
        VerdantThemeColors.light.panel,
      );
      final lightChatSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('chat-workspace-surface')),
      );
      expect(
        (lightChatSurface.decoration as BoxDecoration).color,
        VerdantThemeColors.light.panelRaised,
      );
      final lightContextSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('context-workspace-surface')),
      );
      expect(
        (lightContextSurface.decoration as BoxDecoration).color,
        VerdantThemeColors.light.panel,
      );
      final lightBottomRail = tester.widget<Container>(
        find.byKey(const ValueKey('bottom-rail-workspace')),
      );
      expect(
        (lightBottomRail.decoration as BoxDecoration).color,
        VerdantThemeColors.light.background,
      );
      final appearanceCategoryLabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('user-settings-category-appearance')),
          matching: find.text('Appearance'),
        ),
      );
      expect(
        appearanceCategoryLabel.style?.fontSize,
        VerdantThemeTypography.fromColors(
          VerdantThemeColors.light,
        ).settingsNavigationSelectedLabel.fontSize,
      );
      expect(
        appearanceCategoryLabel.style?.fontWeight,
        VerdantThemeTypography.fromColors(
          VerdantThemeColors.light,
        ).settingsNavigationSelectedLabel.fontWeight,
      );

      final compactDensity = find.byKey(
        const ValueKey('user-settings-density-compact'),
      );
      await tester.ensureVisible(compactDensity);
      await tester.tap(compactDensity);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('workspace-appearance-light-compact')),
        findsOneWidget,
      );

      final voiceCategory = find.byKey(
        const ValueKey('user-settings-category-voice'),
      );
      await tester.ensureVisible(voiceCategory);
      await tester.tap(voiceCategory);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('user-settings-input-device-select')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('user-settings-output-device-select')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('user-settings-input-device-select')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Communications Microphone').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('user-settings-output-device-select')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Communications Speakers').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('user-settings-close-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('server-settings-open-button')),
      );
      await tester.pumpAndSettle();

      final serverSettingsSurface = tester.widget<Container>(
        find.byKey(const ValueKey('server-settings-workspace')),
      );
      expect(
        (serverSettingsSurface.decoration as BoxDecoration).color,
        VerdantThemeColors.light.panelRaised,
      );
      final serverNameField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('server-settings-name-field')),
          matching: find.byType(TextField),
        ),
      );
      expect(
        serverNameField.decoration?.fillColor,
        VerdantThemeColors.light.panel,
      );

      await tester.tap(find.byKey(const ValueKey('server-settings-tab-roles')));
      await tester.pumpAndSettle();
      final roleButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('server-role-row-owner')),
      );
      expect(
        roleButton.style?.foregroundColor?.resolve(<WidgetState>{}),
        VerdantThemeColors.light.accentStrong,
      );

      final saved = await preferencesStore.load();
      expect(saved.theme, UserSettingsThemePreference.light);
      expect(saved.density, UserSettingsDensityPreference.compact);
      expect(saved.voiceInputDeviceId, 'communications-input');
      expect(saved.voiceOutputDeviceId, 'communications-output');
    },
  );

  testWidgets(
    'member list banner rejects oversized files before upload preview',
    (tester) async {
      final originalFileSelector = FileSelectorPlatform.instance;
      final fileSelector = _FakeFileSelectorPlatform(
        file: XFile.fromData(
          Uint8List(65),
          name: 'oversized.webp',
          mimeType: 'image/webp',
        ),
      );
      FileSelectorPlatform.instance = fileSelector;
      addTearDown(() {
        FileSelectorPlatform.instance = originalFileSelector;
      });

      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final repository = _FakeServerSettingsRepository(
        data: _sampleSettingsData.copyWith(
          entitlements: const WorkspaceEntitlements(
            officialSubscriptionActive: true,
            officialSubscriptionTier: 'Purple',
            imageUploads: true,
            fileSharing: false,
            messageAttachments: false,
            voiceChat: false,
            videoStreaming: false,
            crossServerEmoji: false,
            animatedAvatar: false,
            animatedBanner: false,
            memberListBanner: true,
            maxUploadBytes: 64,
            maxVoiceBitrate: null,
            officialBadge: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          serverSettingsRepository: repository,
          directMessagesRepository: _FakeDirectMessagesRepository(
            data: _sampleDirectMessagesData.copyWith(
              entitlements: const WorkspaceEntitlements(
                officialSubscriptionActive: true,
                officialSubscriptionTier: 'Purple',
                imageUploads: true,
                fileSharing: false,
                messageAttachments: false,
                voiceChat: false,
                videoStreaming: false,
                crossServerEmoji: false,
                animatedAvatar: false,
                animatedBanner: false,
                memberListBanner: true,
                maxUploadBytes: 64,
                maxVoiceBitrate: null,
                officialBadge: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('user-settings-category-profile')),
      );
      await tester.pumpAndSettle();
      final uploadButton = find.byKey(
        const ValueKey('member-list-banner-add-button'),
      );
      await tester.ensureVisible(uploadButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Member List Banner'));
      await tester.pumpAndSettle();

      expect(fileSelector.openFileCount, 1);
      expect(repository.uploadedMemberListBannerFiles, isEmpty);
      expect(repository.updatedMemberListBannerCrops, isEmpty);
      expect(find.textContaining('Member list banner is too large'), findsOne);
      expect(find.textContaining('64 bytes'), findsOne);
    },
  );

  testWidgets('stale saved credentials return to sign in before workspace', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'expired-access-token-not-rendered',
        sessionToken: 'expired-session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FailingAuthService(),
        credentialStore: credentialStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(find.text('Message #general'), findsNothing);
    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsNothing,
    );
    expect(find.text('expired-access-token-not-rendered'), findsNothing);
    expect(find.text('expired-session-token-not-rendered'), findsNothing);
    expect(await credentialStore.contains('https://api.verdant.chat'), isFalse);
  });

  testWidgets('authenticated workspace renders real server settings data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(
          data: _realSettingsData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actual Verdant'), findsWidgets);
    expect(find.text('Flutter parity workspace'), findsNothing);
    expect(
      find.byKey(const ValueKey('context-member-row-official/42')),
      findsOneWidget,
    );
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('workspace-channel-header')),
    );
    final contextToggleCenter = tester.getCenter(
      find.byKey(const ValueKey('context-members-toggle')),
    );
    expect(headerRect.right, greaterThan(contextToggleCenter.dx));

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('context-member-row-official/42')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Copy User ID'), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(
        find.byKey(const ValueKey('user-context-menu-item-copy')),
      ),
    );
    await tester.pumpAndSettle();
    final hoveredCopySurface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('user-context-menu-item-surface-copy')),
    );
    final hoveredCopyDecoration =
        hoveredCopySurface.decoration! as BoxDecoration;
    expect(hoveredCopyDecoration.color, VerdantColors.panelHover);
    await mouse.removePointer();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-settings-open-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('server-settings-workspace')), findsOne);
    expect(find.text('Real backend server'), findsWidgets);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('server-settings-workspace')))
          .width,
      820,
    );
    expect(
      find.byKey(const ValueKey('server-settings-page-scrollbar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('server-settings-tab-roles')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('server-role-row-admin-role')), findsOne);
    expect(find.text('Admin'), findsWidgets);
    expect(
      find.byKey(const ValueKey('server-settings-page-scrollbar')),
      findsNothing,
    );
    final rolesContent = find.byKey(
      const ValueKey('server-settings-content-roles'),
    );
    expect(
      find.descendant(of: rolesContent, matching: find.byType(Scrollbar)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: rolesContent,
        matching: find.byKey(
          const ValueKey('server-role-mini-scroll-indicator'),
        ),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('server-permission-roles-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-color-roles-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-role-editor-scroll')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('server-role-row-admin-role')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-role-editor-scroll')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('server-settings-tab-emoji')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-settings-page-scrollbar')),
      findsOneWidget,
    );
    expect(find.text(':verdant:'), findsOneWidget);
    expect(find.text('fake-server-1'), findsNothing);
  });

  testWidgets('channel search stays aligned to the header right edge', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(
          data: _realSettingsData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headerRect = tester.getRect(
      find.byKey(const ValueKey('workspace-channel-header')),
    );
    final searchRect = tester.getRect(
      find.byKey(const ValueKey('channel-message-search-box')),
    );

    expect(headerRect.right - searchRect.right, lessThanOrEqualTo(20));
  });

  testWidgets('member context menu rejects mismatched scoped user ids', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository(
      data: _sampleDirectMessagesData,
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(
          data: _realSettingsData.copyWith(
            members: const [
              ServerSettingsListItemSeed(
                title: 'Poison',
                subtitle: 'Online - joined 2026-06-01',
                trailing: 'Member',
                userId: 'other-network/poison',
              ),
            ],
          ),
        ),
        directMessagesRepository: directMessagesRepository,
      ),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('context-member-row-Poison'));
    expect(row, findsOneWidget);
    await tester.tapAt(tester.getCenter(row), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('user-context-menu-item-message')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('user-context-menu-item-message')),
    );
    await tester.pumpAndSettle();

    expect(directMessagesRepository.openedLocalUserIds, isEmpty);
  });

  testWidgets('member message action does not copy the user id', (
    tester,
  ) async {
    final clipboardWrites = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments;
          clipboardWrites.add(
            arguments is Map ? arguments['text'] as String? : null,
          );
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final directMessagesRepository = _FakeDirectMessagesRepository(
      data: _sampleDirectMessagesData,
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(
          data: _realSettingsData.copyWith(
            members: const [
              ServerSettingsListItemSeed(
                title: 'Avery',
                subtitle: 'Online - joined 2026-06-01',
                trailing: 'Member',
                userId: '181051381515448321',
              ),
            ],
          ),
        ),
        directMessagesRepository: directMessagesRepository,
      ),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(
      const ValueKey('context-member-row-official/181051381515448321'),
    );
    expect(row, findsOneWidget);
    await tester.tapAt(tester.getCenter(row), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('user-context-menu-item-message')),
    );
    await tester.pumpAndSettle();

    expect(directMessagesRepository.openedLocalUserIds, ['181051381515448321']);
    expect(clipboardWrites, isEmpty);
  });

  testWidgets('non-owners do not see the server settings action', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final data = _realSettingsData.copyWith(
      server: _realSettingsData.server.copyWith(ownerId: 'not-current-user'),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(data: data),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-open-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('server-settings-workspace')),
      findsNothing,
    );
  });

  testWidgets('scoped server owners see the server settings action', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final data = _realSettingsData.copyWith(
      server: _realSettingsData.server.copyWith(ownerId: 'official/42'),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(data: data),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-open-button')),
      findsOneWidget,
    );
  });

  testWidgets('users with manage server permission see server settings', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final data = _realSettingsData.copyWith(
      server: _realSettingsData.server.copyWith(ownerId: 'not-current-user'),
      roles: const [
        ServerSettingsListItemSeed(
          id: 'admin-role',
          title: 'Admin',
          subtitle: '16 permissions',
          trailing: '#13eab3',
          accent: Color(0xFF13EAB3),
          permissions: 16,
          position: 1,
        ),
      ],
      members: const [
        ServerSettingsListItemSeed(
          userId: '42',
          title: 'boji',
          subtitle: 'online - joined 2026-06-01',
          trailing: '1 role',
          roleIds: ['admin-role'],
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: _FakeServerSettingsRepository(data: data),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-open-button')),
      findsOneWidget,
    );
  });

  testWidgets('expired saved session returns to sign in from workspace error', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'expired-access-token-not-rendered',
        sessionToken: 'expired-session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: const _ExpiredServerSettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsOneWidget,
    );
    expect(find.text('expired-access-token-not-rendered'), findsNothing);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(await credentialStore.contains('https://api.verdant.chat'), isFalse);
  });

  testWidgets('lone federated target credential does not open workspace', (
    tester,
  ) async {
    const targetOrigin = 'https://api-test.pryzmapp.com';
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: targetOrigin,
    );
    await networkProfileStore.selectProfile(targetOrigin);
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: targetOrigin,
        accessToken: 'federated-access-token-not-rendered',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
        user: VerdantUser(
          id: 'fed_42',
          username: 'fed_josh',
          email: 'fed@example.invalid',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        serverSettingsRepository: const _ExpiredServerSettingsRepository(
          'Federated access expired. Rejoin the server invite to continue.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(
      find.text(
        'Federated access expired. Rejoin the server invite to continue.',
      ),
      findsNothing,
    );
    expect(find.text('federated-access-token-not-rendered'), findsNothing);
  });

  testWidgets(
    'selected federated target does not hide home workspace on startup',
    (tester) async {
      const targetOrigin = 'https://api-test.pryzmapp.com';
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      final diagnostics = _RecordingAuthDiagnostics();
      await _saveOfficialCredential(credentialStore);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: targetOrigin,
      );
      await networkProfileStore.selectProfile(targetOrigin);
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: targetOrigin,
          accessToken: 'federated-access-token-not-rendered',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: 'fed_42',
            username: 'fed_josh',
            email: 'fed@example.invalid',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          authDiagnostics: diagnostics,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == targetOrigin) {
              return const _ExpiredServerSettingsRepository(
                'Federated access expired. Rejoin the server invite to continue.',
              );
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verdant'), findsWidgets);
      expect(find.text('Message #general'), findsOneWidget);
      expect(
        find.text(
          'Federated access expired. Rejoin the server invite to continue.',
        ),
        findsNothing,
      );
      expect(find.text('federated-access-token-not-rendered'), findsNothing);
      expect(
        diagnostics.events.map((event) => event.name),
        contains('credential.restore.federated.root.skip'),
      );
      expect(
        (await networkProfileStore.load()).selectedApiOrigin,
        officialApiOrigin,
      );
    },
  );

  testWidgets(
    'non-auth workspace failures that mention sign in keep credentials',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          serverSettingsRepository: const _NonAuthWorkspaceFailureRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Realtime connection timed out; sign in state unknown.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to Verdant'), findsNothing);
      expect(
        await credentialStore.contains('https://api.verdant.chat'),
        isTrue,
      );
      expect(find.text('access-token-not-rendered'), findsNothing);
      expect(find.text('session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'credential fields avoid suggestions and clear submitted secrets',
    (tester) async {
      await tester.pumpWidget(_testApp(authService: _FailingAuthService()));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(
        find.byKey(const ValueKey('login-email-field')),
      );
      final passwordField = tester.widget<TextField>(
        find.byKey(const ValueKey('login-password-field')),
      );
      expect(emailField.autocorrect, isFalse);
      expect(emailField.enableSuggestions, isFalse);
      expect(passwordField.autocorrect, isFalse);
      expect(passwordField.enableSuggestions, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'boji@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'wrong-password',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pumpAndSettle();

      final clearedPasswordField = tester.widget<TextField>(
        find.byKey(const ValueKey('login-password-field')),
      );
      expect(clearedPasswordField.controller?.text, isEmpty);
      expect(find.text('Invalid credentials'), findsOneWidget);
    },
  );

  testWidgets('opens the fake workspace after a successful real auth result', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authService: _FakeAuthService()));

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    final autofillFinishFlags = await _captureAutofillFinishFlags(
      tester,
      () async {
        await tester.tap(find.byKey(const ValueKey('login-submit-button')));
        await tester.pumpAndSettle();
      },
    );

    expect(find.text('general'), findsWidgets);
    expect(find.text('Message #general'), findsOneWidget);
    expect(find.text('Active in this channel'), findsOneWidget);
    expect(find.text('Joshy'), findsWidgets);
    expect(autofillFinishFlags, contains(false));
    expect(autofillFinishFlags, isNot(contains(true)));
  });

  testWidgets('current user panel logout returns to the login screen', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authService: _FakeAuthService()));

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('workspace-logout-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('workspace-logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(find.text('Message #general'), findsNothing);
  });

  testWidgets('opens server settings from the workspace and returns to chat', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authService: _FakeAuthService()));

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-settings-open-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-workspace')),
      findsOneWidget,
    );
    final titleBarRect = tester.getRect(
      find.byKey(const ValueKey('verdant-window-title-bar')),
    );
    final backdropRect = tester.getRect(
      find.byKey(const ValueKey('server-settings-backdrop')),
    );
    final railRect = tester.getRect(
      find.byKey(const ValueKey('bottom-rail-workspace')),
    );
    final settingsRect = tester.getRect(
      find.byKey(const ValueKey('server-settings-workspace')),
    );
    expect(backdropRect.top, 0);
    expect(backdropRect.bottom, greaterThanOrEqualTo(railRect.bottom));
    expect(settingsRect.top, lessThan(titleBarRect.bottom));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Verdant'), findsWidgets);
    expect(find.text('Server Settings'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Emoji'), findsOneWidget);
    expect(find.text('Invites'), findsOneWidget);
    expect(find.text('Roles'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('Feeds'), findsOneWidget);
    expect(find.text('Bots'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-settings-network-chip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('server-settings-server-id-chip')),
      findsNothing,
    );
    final serverSettingsWorkspace = find.byKey(
      const ValueKey('server-settings-workspace'),
    );
    expect(
      find.descendant(
        of: serverSettingsWorkspace,
        matching: find.text('Member Count'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: serverSettingsWorkspace,
        matching: find.text('Owner'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: serverSettingsWorkspace,
        matching: find.text('Created'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('server-settings-tab-members')));
    await tester.pumpAndSettle();

    expect(find.text('Members'), findsWidgets);
    expect(find.text('Joshy'), findsWidgets);
    expect(
      find.descendant(
        of: serverSettingsWorkspace,
        matching: find.text('Owner'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('server-settings-close-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-workspace')),
      findsNothing,
    );
    expect(find.text('Message #general'), findsOneWidget);
  });

  testWidgets('server settings invite links can be copied and created', (
    tester,
  ) async {
    final clipboardWrites = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments;
          clipboardWrites.add(
            arguments is Map ? arguments['text'] as String? : null,
          );
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final serverSettingsRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        serverSettingsRepository: serverSettingsRepository,
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-settings-open-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-settings-tab-invites')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-invite-link-flutter')),
      findsOneWidget,
    );
    expect(find.text('https://verdant.chat/invite/flutter'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-settings-invite-backend-flutter')),
      findsOneWidget,
    );
    expect(find.text('Backend: api.verdant.chat'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('server-settings-invite-copy-flutter')),
    );
    await tester.pumpAndSettle();
    expect(clipboardWrites, contains('https://verdant.chat/invite/flutter'));

    await tester.ensureVisible(
      find.byKey(const ValueKey('server-settings-create-invite-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('server-settings-create-invite-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-settings-create-invite-options')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('server-settings-invite-max-uses-5')),
    );
    await tester.tap(
      find.byKey(const ValueKey('server-settings-invite-duration-1h')),
    );
    await tester.tap(
      find.byKey(const ValueKey('server-settings-create-invite-confirm')),
    );
    await tester.pumpAndSettle();

    expect(serverSettingsRepository.createdInviteServerIds, ['fake-server-1']);
    expect(serverSettingsRepository.createdInviteMaxUses, [5]);
    expect(serverSettingsRepository.createdInviteExpiresIn, [
      const Duration(hours: 1),
    ]);
    expect(clipboardWrites, contains('https://verdant.chat/invite/newcode'));
    expect(find.text('https://verdant.chat/invite/newcode'), findsOneWidget);

    expect(find.textContaining('expires expired'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('server-settings-invite-revoke-newcode')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('server-settings-invite-row-newcode')),
      findsNothing,
    );
  });

  testWidgets('bottom rail buttons open visible workspace surfaces', (
    tester,
  ) async {
    final serverSettingsRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
    );
    final directMessagesRepository = _FakeDirectMessagesRepository(
      data: _sampleDirectMessagesData,
    );
    final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
    final networkProfileStore = NetworkProfileStore.memory();
    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        serverSettingsRepository: serverSettingsRepository,
        directMessagesRepository: directMessagesRepository,
        networkProfileStore: networkProfileStore,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('bottom-rail-server-grid-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('server-drawer-module')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('server-drawer-item-official/fake-server-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('server-drawer-backdrop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('server-drawer-module')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom-rail-dm-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('direct-messages-workspace')),
      findsOneWidget,
    );
    expect(find.text('Message #general', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const ValueKey('dm-sidebar-module')), findsOneWidget);
    expect(find.byKey(const ValueKey('friends-list-module')), findsOneWidget);
    expect(find.byKey(const ValueKey('dm-sidebar-search-field')), findsOne);
    expect(find.byKey(const ValueKey('friends-search-field')), findsOne);
    expect(
      find.byKey(ValueKey('friend-card-$officialNetworkId/181051381515448321')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('friend-card-$officialNetworkId/user-morgan')),
      findsOneWidget,
    );
    expect(find.text('User 181051381515448320'), findsNothing);
    expect(find.text('Mira'), findsNothing);

    expect(find.text('Friend'), findsNothing);

    await tester.tapAt(
      tester.getCenter(
        find.byKey(ValueKey('friend-card-$officialNetworkId/user-morgan')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Accept Request'), findsOneWidget);
    expect(find.text('Remove Friend'), findsNothing);
    await tester.tap(find.text('Accept Request'));
    await tester.pumpAndSettle();
    expect(directMessagesRepository.acceptedLocalUserIds, ['user-morgan']);
    expect(find.text('Morgan accepted'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('friends-add-toggle-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-friend-username-field')),
      'Luna',
    );
    await tester.tap(find.byKey(const ValueKey('add-friend-submit-button')));
    await tester.pumpAndSettle();
    expect(directMessagesRepository.sentFriendRequests, ['Luna']);
    expect(
      find.byKey(ValueKey('friend-card-$officialNetworkId/user-luna')),
      findsOneWidget,
    );

    await tester.tapAt(
      tester.getCenter(
        find.byKey(ValueKey('friend-card-$officialNetworkId/user-luna')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancel Request'), findsOneWidget);
    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();
    expect(directMessagesRepository.removedLocalUserIds, ['user-luna']);
    expect(
      find.byKey(ValueKey('friend-card-$officialNetworkId/user-luna')),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      'Avery',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('friend-card-$officialNetworkId/181051381515448321')),
      findsOneWidget,
    );
    expect(find.text('Morgan'), findsNothing);

    await tester.tap(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dm-conversation-module')),
      findsOneWidget,
    );
    expect(find.text('Beginning of DM with Avery'), findsOneWidget);
    expect(find.text('Hello from Avery'), findsWidgets);
    expect(find.text('No messages yet'), findsNothing);
    expect(
      directMessagesRepository.loadedConversationChannelIds,
      contains('$officialNetworkId/dm-avery'),
    );

    await tester.tap(
      find.byKey(ValueKey('dm-conversation-close-$officialNetworkId/dm-avery')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friends-list-module')), findsOneWidget);
    expect(find.byKey(const ValueKey('dm-conversation-module')), findsNothing);
    expect(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('friends-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('friend-card-$officialNetworkId/181051381515448321')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
    );
    await tester.pump();
    expect(find.text('Hello from Avery'), findsWidgets);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('server-rail-item-official/fake-server-1')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('direct-messages-workspace')),
      findsNothing,
    );
    expect(find.text('Message #general'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('bottom-rail-create-server-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-server-modal')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-server-icon-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create-server-icon-upload-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create-server-banner-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create-server-banner-upload-button')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('create-server-name-field')),
      'New Grove',
    );
    await tester.tap(find.byKey(const ValueKey('create-server-submit-button')));
    await tester.pumpAndSettle();
    expect(serverSettingsRepository.createdServerNames, ['New Grove']);
    expect(
      find.byKey(const ValueKey('server-rail-item-official/created-server')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('bottom-rail-join-server-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('join-server-modal')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('join-server-invite-field')),
      'join-code',
    );
    await tester.tap(find.byKey(const ValueKey('join-server-preview-button')));
    await tester.pumpAndSettle();
    expect(serverSettingsRepository.previewedInviteCodes, ['join-code']);
    expect(
      find.byKey(const ValueKey('join-server-preview-card')),
      findsOneWidget,
    );
    expect(find.text('Joined Server'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('join-server-submit-button')));
    await tester.pumpAndSettle();
    expect(serverSettingsRepository.acceptedInviteCodes, ['join-code']);
    expect(
      find.byKey(const ValueKey('server-rail-item-official/joined-server')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('bottom-rail-join-network-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('join-network-modal')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('join-network-name-field')),
      'Community',
    );
    await tester.enterText(
      find.byKey(const ValueKey('join-network-origin-field')),
      'https://api.community.example',
    );
    await tester.tap(find.byKey(const ValueKey('join-network-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('network-auth-dialog')), findsOneWidget);
    expect(find.text('Sign in to Community'), findsOneWidget);
    final profiles = await networkProfileStore.load();
    expect(
      profiles.profiles.map((profile) => profile.apiOrigin),
      contains('https://api.community.example'),
    );
  });

  testWidgets(
    'DM conversation keeps cached messages visible while refreshing',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const conversation = DmConversationPreviewSeed(
        channelId: 'official/dm-avery',
        localChannelId: 'dm-avery',
        networkId: 'official',
        displayName: 'Avery',
        initials: 'AV',
        status: 'Online',
        lastMessage: 'Last active 2026-06-02',
        localUserId: '181051381515448321',
      );
      const messages = DmConversationMessages(
        channelId: 'official/dm-avery',
        messages: [
          MessageSeed(
            id: 'official/dm-avery/message-1',
            authorId: 'official/181051381515448321',
            author: 'Avery',
            time: '10:21 AM',
            body: 'Hello from Avery',
            initials: 'AV',
          ),
        ],
      );

      await tester.pumpWidget(
        TooltipVisibility(
          visible: false,
          child: MaterialApp(
            theme: buildVerdantTheme(),
            home: Scaffold(
              body: DmConversationModule(
                conversation: conversation,
                messages: messages,
                isLoading: true,
                error: null,
                mediaPolicy: _sampleSettingsData.mediaPolicy,
                currentUserId: '42',
                currentUserName: 'boji',
                currentUserInitials: 'BO',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello from Avery'), findsWidgets);
      expect(find.text('Loading messages'), findsNothing);
      expect(
        find.byKey(const ValueKey('dm-message-loading-overlay')),
        findsOneWidget,
      );
    },
  );

  testWidgets('DM refresh keeps hidden rows out without sidebar sync chrome', (
    tester,
  ) async {
    final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
    final hiddenStorage = MemoryDirectMessagesPreferenceStorage();
    final preferences = DirectMessagesPreferences(storage: hiddenStorage);
    await preferences.saveHiddenChannelIds(
      networkId: officialNetworkId,
      userId: '42',
      channelIds: {'$officialNetworkId/dm-avery'},
    );
    final refreshCompleter = Completer<DirectMessagesWorkspaceData>();
    final directMessagesRepository = _FakeDirectMessagesRepository(
      data: _sampleDirectMessagesData,
      loadDirectMessagesResults: [
        _sampleDirectMessagesData,
        refreshCompleter.future,
      ],
    )..hiddenChannelIds = {'$officialNetworkId/dm-avery'};

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        directMessagesRepository: directMessagesRepository,
        directMessagesPreferences: preferences,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-rail-dm-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('server-rail-item-official/fake-server-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-rail-dm-button')));
    await tester.pump();

    expect(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dm-sidebar-refresh-overlay')),
      findsNothing,
    );
    expect(find.text('Syncing'), findsNothing);

    refreshCompleter.complete(_sampleDirectMessagesData);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('dm-conversation-$officialNetworkId/dm-avery')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dm-sidebar-refresh-overlay')),
      findsNothing,
    );
    expect(find.text('Syncing'), findsNothing);
  });

  testWidgets(
    'joining a network from the rail opens sign in for the saved network',
    (tester) async {
      final service = _FakeAuthService();
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      await tester.pumpWidget(
        _testApp(
          authService: service,
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'boji@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'correct horse battery staple',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('bottom-rail-join-network-button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('join-network-name-field')),
        'Community',
      );
      await tester.enterText(
        find.byKey(const ValueKey('join-network-origin-field')),
        'https://api.community.example',
      );
      await tester.tap(find.byKey(const ValueKey('join-network-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('network-auth-dialog')), findsOneWidget);
      expect(find.text('Sign in to Community'), findsOneWidget);
      expect(find.text('https://api.community.example'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('network-signin-email-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('network-signin-password-field')),
        findsOneWidget,
      );
    },
  );

  testWidgets('DM workspace switch focus-guards without transition animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        serverSettingsRepository: _FakeServerSettingsRepository(
          data: _sampleSettingsData,
        ),
        directMessagesRepository: _FakeDirectMessagesRepository(
          data: _sampleDirectMessagesData,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom-rail-dm-button')));
    await tester.pump();

    final primaryFocusGuards = tester
        .widgetList<ExcludeFocus>(
          find.byKey(
            const ValueKey('workspace-swap-primary-focus-guard'),
            skipOffstage: false,
          ),
        )
        .toList();
    final alternateFocusGuards = tester
        .widgetList<ExcludeFocus>(
          find.byKey(
            const ValueKey('workspace-swap-alternate-focus-guard'),
            skipOffstage: false,
          ),
        )
        .toList();

    expect(primaryFocusGuards, isNotEmpty);
    expect(alternateFocusGuards, isNotEmpty);
    expect(primaryFocusGuards.every((guard) => guard.excluding), isTrue);
    expect(alternateFocusGuards.every((guard) => !guard.excluding), isTrue);
    expect(
      find.byKey(const ValueKey('direct-messages-workspace')),
      findsOneWidget,
    );
    final dmAnimationAncestors = tester
        .widgetList<AnimatedBuilder>(
          find.ancestor(
            of: find.byKey(const ValueKey('direct-messages-workspace')),
            matching: find.byType(AnimatedBuilder),
          ),
        )
        .toList();
    expect(
      dmAnimationAncestors.where(
        (builder) => builder.listenable is Animation<double>,
      ),
      isEmpty,
    );
  });

  testWidgets('chat invite links preview and join the server', (tester) async {
    final credentialStore = _MemoryCredentialStore();
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: officialApiOrigin,
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final serverSettingsRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
      channelMessages: const [
        MessageSeed(
          id: 'official/message-invite',
          authorId: 'official/user-avery',
          author: 'Avery',
          body: 'Join this server https://verdant.chat/invite/chat123',
          initials: 'AV',
          time: '10:00 AM',
          isOwnMessage: false,
          reactions: [],
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        serverSettingsRepository: serverSettingsRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      find.byKey(const ValueKey('message-invite-card-official/message-invite')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('message-invite-preview-button')),
    );
    await tester.pumpAndSettle();
    expect(serverSettingsRepository.previewedInviteCodes, ['chat123']);
    expect(find.text('Joined Server'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('message-invite-preview-backend')),
      findsOneWidget,
    );
    expect(find.text('Backend: api.verdant.chat'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('message-invite-join-official/message-invite')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('message-invite-join-official/message-invite')),
    );
    await tester.pumpAndSettle();

    expect(serverSettingsRepository.acceptedInviteCodes, ['chat123']);
    expect(
      find.byKey(const ValueKey('server-rail-item-official/joined-server')),
      findsOneWidget,
    );
  });

  testWidgets(
    'chat invite links preserve federated network metadata without local account prompts',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      final identityStore = InstanceIdentityStore(
        storage: MemoryNetworkProfileStorage(),
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final selfHostNetworkId = networkIdFromApiOrigin(selfHostOrigin);
      final activeRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
        channelMessages: const [
          MessageSeed(
            id: 'official/message-selfhost-invite',
            authorId: 'official/user-avery',
            author: 'Avery',
            body:
                'Join this server https://api-test.pryzmapp.com/invite/self123',
            initials: 'AV',
            time: '10:00 AM',
            isOwnMessage: false,
            reactions: [],
          ),
        ],
      );
      final federatedPreviewRepository =
          _FakeFederatedInvitePreviewRepository();
      final federatedJoinRepository = _FakeFederatedInviteJoinRepository();

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          instanceIdentityStore: identityStore,
          serverSettingsRepository: activeRepository,
          federatedInvitePreviewRepository: federatedPreviewRepository,
          federatedInviteJoinRepository: federatedJoinRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == officialApiOrigin) {
              return activeRepository;
            }
            throw StateError('Target credential repository should not be used');
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        find.byKey(
          const ValueKey(
            'message-invite-card-official/message-selfhost-invite',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('message-invite-preview-button')),
      );
      await tester.pumpAndSettle();

      expect(activeRepository.previewedInviteCodes, isEmpty);
      expect(federatedPreviewRepository.previewed, [
        (apiOrigin: selfHostOrigin, code: 'self123'),
      ]);
      expect(find.text('Backend: api-test.pryzmapp.com'), findsWidgets);
      expect(find.text('Federated Server'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'message-invite-join-official/message-selfhost-invite',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(activeRepository.acceptedInviteCodes, isEmpty);
      expect(federatedJoinRepository.joined, [
        (
          targetApiOrigin: selfHostOrigin,
          targetPeerId: 'host:api-test.pryzmapp.com',
          serverId: 'federated-server',
          code: 'self123',
        ),
      ]);

      final identity = await identityStore.read(selfHostOrigin);
      expect(identity?.instanceMode, 'federated');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          instanceIdentityStore: identityStore,
          serverSettingsRepository: activeRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == officialApiOrigin) {
              return activeRepository;
            }
            throw StateError('Target credential repository should not be used');
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final networkCategory = find.byKey(
        const ValueKey('user-settings-category-network'),
      );
      await tester.ensureVisible(networkCategory);
      await tester.tap(networkCategory);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('user-settings-network-row-$selfHostNetworkId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reconnect needed'), findsWidgets);
      expect(
        find.text(
          'Rejoin a federated server invite to restore access on this network.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('user-settings-network-signin-$selfHostNetworkId')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('user-settings-network-create-account-$selfHostNetworkId'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('user-settings-network-logout-$selfHostNetworkId')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'federated invite accept restores target server rail after restart',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      final identityStore = InstanceIdentityStore(
        storage: MemoryNetworkProfileStorage(),
      );
      await _saveOfficialCredential(credentialStore);
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final selfHostNetworkId = networkIdFromApiOrigin(selfHostOrigin);
      final activeRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
        channelMessages: const [
          MessageSeed(
            id: 'official/message-selfhost-invite',
            authorId: 'official/user-avery',
            author: 'Avery',
            body:
                'Join this server https://api-test.pryzmapp.com/invite/self123',
            initials: 'AV',
            time: '10:00 AM',
            isOwnMessage: false,
            reactions: [],
          ),
        ],
      );
      final targetRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: selfHostNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'federated-server',
            name: 'Federated Server',
          ),
        ),
      );
      final requestedOrigins = <String>[];
      final federatedPreviewRepository =
          _FakeFederatedInvitePreviewRepository();
      final federatedJoinRepository = _FakeFederatedInviteJoinRepository(
        credentialStore: credentialStore,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _federatedMembership(
          id: 'mem-federated-server',
          targetApiOrigin: selfHostOrigin,
          targetServerId: 'federated-server',
          serverName: 'Federated Server',
        ),
      ]);

      ServerSettingsRepository repositoryFor(String apiOrigin) {
        requestedOrigins.add(apiOrigin);
        return apiOrigin == selfHostOrigin
            ? targetRepository
            : activeRepository;
      }

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          instanceIdentityStore: identityStore,
          serverSettingsRepository: activeRepository,
          federatedInvitePreviewRepository: federatedPreviewRepository,
          federatedInviteJoinRepository: federatedJoinRepository,
          federatedMembershipRepositoryFactory: (_) => membershipRepository,
          serverSettingsRepositoryFactory: repositoryFor,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('message-invite-preview-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'message-invite-join-official/message-selfhost-invite',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(await credentialStore.contains(selfHostOrigin), isTrue);
      expect(
        (await credentialStore.read(selfHostOrigin))?.kind,
        AuthCredentialKind.federatedClient,
      );
      expect(
        (await identityStore.read(selfHostOrigin))?.instanceMode,
        'federated',
      );

      requestedOrigins.clear();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          instanceIdentityStore: identityStore,
          serverSettingsRepository: activeRepository,
          federatedMembershipRepositoryFactory: (_) => membershipRepository,
          serverSettingsRepositoryFactory: repositoryFor,
        ),
      );
      await tester.pumpAndSettle();
      await _settleNetworkSwitch(tester);

      expect(requestedOrigins, contains(selfHostOrigin));
      expect(
        find.byKey(
          ValueKey('server-rail-item-$selfHostNetworkId/federated-server'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workspace-logout-button')),
        findsOneWidget,
      );

      await tester.tap(
        find
            .byKey(
              ValueKey('server-rail-item-$selfHostNetworkId/federated-server'),
            )
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      expect(find.text('Federated Server'), findsWidgets);
      expect(
        find.byKey(const ValueKey('workspace-logout-button')),
        findsNothing,
      );
      expect(
        find.text('target-federated-access-token-not-rendered'),
        findsNothing,
      );
    },
  );

  testWidgets('create server routes through the selected saved network', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    await _saveOfficialCredential(credentialStore);
    const communityOrigin = 'https://api.community.example';
    final communityNetworkId = networkIdFromApiOrigin(communityOrigin);
    await networkProfileStore.saveProfile(
      name: 'Community',
      apiOrigin: communityOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: communityOrigin,
        accessToken: 'community-access-token-not-rendered',
        sessionToken: 'community-session-token-not-rendered',
      ),
    );

    final officialRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
    );
    final communityRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsDataForNetwork(
        networkId: communityNetworkId,
        server: _sampleSettingsData.server.copyWith(
          id: 'community-server-1',
          name: 'Community Home',
        ),
      ),
    );
    final requestedOrigins = <String>[];

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        serverSettingsRepository: officialRepository,
        serverSettingsRepositoryFactory: (apiOrigin) {
          requestedOrigins.add(apiOrigin);
          return apiOrigin == communityOrigin
              ? communityRepository
              : officialRepository;
        },
      ),
    );

    await tester.pumpAndSettle();
    requestedOrigins.clear();

    await tester.tap(
      find.byKey(const ValueKey('bottom-rail-create-server-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create-server-network-dropdown')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('create-server-network-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(
            const ValueKey(
              'create-server-network-option-https://api.community.example',
            ),
          )
          .last,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('create-server-name-field')),
      'Community Grove',
    );
    await tester.tap(find.byKey(const ValueKey('create-server-submit-button')));
    await tester.pumpAndSettle();

    expect(requestedOrigins, contains(communityOrigin));
    expect(officialRepository.createdServerNames, isEmpty);
    expect(communityRepository.createdServerNames, ['Community Grove']);
    expect(
      find.byKey(
        ValueKey('server-rail-item-$communityNetworkId/created-server'),
      ),
      findsOneWidget,
    );
    expect(find.text('community-access-token-not-rendered'), findsNothing);
    expect(find.text('community-session-token-not-rendered'), findsNothing);
  });

  testWidgets(
    'create server disables federated access credentials as targets',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      await _saveOfficialCredential(credentialStore);
      const federatedOrigin = 'https://api-test.pryzmapp.com';
      await networkProfileStore.saveProfile(
        name: 'Pryzm Federated',
        apiOrigin: federatedOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: federatedOrigin,
          accessToken: 'federated-access-token-not-rendered',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: 'fed_129fa6f4b31ac2c4a38906be',
            username: 'joshy',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      final officialRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
      );
      final federatedRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: networkIdFromApiOrigin(federatedOrigin),
          server: _sampleSettingsData.server.copyWith(
            id: 'federated-created-server',
            name: 'Federated Created',
          ),
        ),
      );
      final requestedOrigins = <String>[];

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepository: officialRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            requestedOrigins.add(apiOrigin);
            return apiOrigin == federatedOrigin
                ? federatedRepository
                : officialRepository;
          },
        ),
      );

      await tester.pumpAndSettle();
      requestedOrigins.clear();

      await tester.tap(
        find.byKey(const ValueKey('bottom-rail-create-server-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('create-server-network-dropdown')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pryzm Federated'), findsOneWidget);
      expect(find.text('Federated access only'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'create-server-network-option-https://api-test.pryzmapp.com',
          ),
        ),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(requestedOrigins, isEmpty);
      expect(federatedRepository.createdServerNames, isEmpty);
      expect(officialRepository.createdServerNames, isEmpty);
      expect(find.text('federated-access-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'create server defaults active federated access to a local account target',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const federatedOrigin = 'https://api-test.pryzmapp.com';
      final federatedNetworkId = networkIdFromApiOrigin(federatedOrigin);
      await _saveOfficialCredential(credentialStore);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Federated',
        apiOrigin: federatedOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: federatedOrigin,
          accessToken: 'federated-access-token-not-rendered',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: 'fed_129fa6f4b31ac2c4a38906be',
            username: 'joshy',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final officialRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
      );
      final federatedRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: federatedNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'federated-server',
            name: 'Federated Grove',
          ),
        ),
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _federatedMembership(
          id: 'mem-federated-server',
          targetApiOrigin: federatedOrigin,
          targetServerId: 'federated-server',
          serverName: 'Federated Grove',
        ),
      ]);

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepository: officialRepository,
          federatedMembershipRepositoryFactory: (_) => membershipRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return apiOrigin == federatedOrigin
                ? federatedRepository
                : officialRepository;
          },
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(
              ValueKey('server-rail-item-$federatedNetworkId/federated-server'),
            )
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      await tester.tap(
        find.byKey(const ValueKey('bottom-rail-create-server-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network: Official'), findsOneWidget);
      expect(
        find.textContaining('Create servers with a local account on'),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const ValueKey('create-server-name-field')),
        'Home Grove',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(officialRepository.createdServerNames, ['Home Grove']);
      expect(
        find.textContaining('Create servers with a local account on'),
        findsNothing,
      );
      expect(federatedRepository.createdServerNames, isEmpty);
      expect(find.text('federated-access-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'workspace rail shows saved signed-out self-host network without backend egress',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      final requestedOrigins = <String>[];

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            requestedOrigins.add(apiOrigin);
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'boji@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'correct horse battery staple',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('server-rail-network-$testNetworkId')),
        findsNothing,
      );
      expect(find.text('Pryzm Test Self-Host'), findsNothing);
      expect(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-1')),
        findsNothing,
      );
      expect(requestedOrigins, [officialApiOrigin]);
      expect(find.textContaining('token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'network settings does not expose local account prompts for saved networks',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      final authService = _FakeAuthService();
      final requestedOrigins = <String>[];
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'selfhost-settings-server',
            name: 'Selfhost Settings Grove',
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: authService,
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            requestedOrigins.add(apiOrigin);
            return selfHostRepository;
          },
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'boji@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'correct horse battery staple',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pumpAndSettle();
      expect(requestedOrigins, [officialApiOrigin]);
      requestedOrigins.clear();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('user-settings-category-network')),
      );
      await tester.tap(
        find.byKey(const ValueKey('user-settings-category-network')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disconnected'), findsWidgets);
      expect(
        find.byKey(ValueKey('user-settings-network-signin-$testNetworkId')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('user-settings-network-create-account-$testNetworkId'),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('network-auth-dialog')), findsNothing);
      expect(find.text('Sign in to Pryzm Test Self-Host'), findsNothing);
      expect(authService.lastApiOrigin, officialApiOrigin);
      expect(await credentialStore.contains(testOrigin), isFalse);
      expect(requestedOrigins, isEmpty);
      expect(find.text('access-token-not-rendered'), findsNothing);
      expect(find.text('session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'inactive summary polling updates self-host rail badges through owning origin',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      await _saveOfficialCredential(credentialStore);
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'selfhost-user',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final officialRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'selfhost-1',
            name: 'Selfhost Grove',
          ),
        ),
      );
      final summaryClient = _FakeSyncSummaryClient({
        testNetworkId: const SyncSummarySnapshot(
          cursor: '1800000000100',
          servers: [
            SyncServerSummary(
              serverId: 'selfhost-1',
              unreadCount: 5,
              mentionCount: 3,
              lastActivityAt: '2026-06-21T12:00:00Z',
            ),
          ],
          dms: [],
          notifications: [],
          requiresReconnect: false,
        ),
      });

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepository: officialRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return normalizeBackendApiOrigin(apiOrigin) == testOrigin
                ? selfHostRepository
                : officialRepository;
          },
          syncSummaryClient: summaryClient,
          inactiveSummaryPollInterval: Duration.zero,
        ),
      );

      await tester.pumpAndSettle();

      expect(summaryClient.polledOrigins, [testOrigin]);
      expect(summaryClient.polledOrigins, isNot(contains(officialApiOrigin)));
      expect(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-1')),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets('inactive opened network pane is released after idle timeout', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    await _saveOfficialCredential(credentialStore);
    const testOrigin = 'https://api-test.pryzmapp.com';
    final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
    final testNetworkId = networkIdFromApiOrigin(testOrigin);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: testOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: testOrigin,
        accessToken: 'selfhost-access-token-not-rendered',
        sessionToken: 'selfhost-session-token-not-rendered',
        user: VerdantUser(
          id: '84',
          username: 'selfhost-user',
          email: 'selfhost@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final officialRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
    );
    final selfHostRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsDataForNetwork(
        networkId: testNetworkId,
        server: _sampleSettingsData.server.copyWith(
          id: 'selfhost-1',
          name: 'Selfhost Grove',
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        serverSettingsRepository: officialRepository,
        serverSettingsRepositoryFactory: (apiOrigin) {
          return normalizeBackendApiOrigin(apiOrigin) == testOrigin
              ? selfHostRepository
              : officialRepository;
        },
        inactiveWorkspaceIdleTimeout: const Duration(milliseconds: 100),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(
        ValueKey('multi-network-workspace-pane-$officialNetworkId'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-1')),
    );
    await _settleNetworkSwitch(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(
      find.byKey(
        ValueKey('multi-network-workspace-pane-$officialNetworkId'),
        skipOffstage: false,
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey('multi-network-workspace-pane-$testNetworkId'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
    expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
  });

  testWidgets(
    'inactive backend keeps websocket warm for five minutes then cancels it',
    (tester) async {
      final harness = await _pumpTwoNetworkWorkspace(tester);

      expect(harness.realtimeRepository.realtimeConnectCount, 1);
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 1);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-${harness.testNetworkId}/selfhost-1'),
        ),
      );
      await _settleNetworkSwitch(tester);

      expect(harness.realtimeRepository.realtimeConnectCount, 2);
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 2);
      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.officialNetworkId}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(minutes: 4, seconds: 59));
      harness.realtimeRepository.emitRealtime(
        const DirectMessagesPresenceUpdateEvent(
          localUserId: '84',
          status: 'online',
        ),
      );
      await tester.pump();
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 2);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(harness.realtimeRepository.realtimeCancelCount, 1);
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 1);
      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.officialNetworkId}'),
          skipOffstage: false,
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.testNetworkId}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'returning to inactive backend before five minutes cancels release timer',
    (tester) async {
      final harness = await _pumpTwoNetworkWorkspace(tester);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-${harness.testNetworkId}/selfhost-1'),
        ),
      );
      await _settleNetworkSwitch(tester);
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 2);

      await tester.pump(const Duration(minutes: 1));
      await tester.tap(
        find.byKey(
          ValueKey(
            'server-rail-item-${harness.officialNetworkId}/fake-server-1',
          ),
          skipOffstage: false,
        ),
      );
      await _settleNetworkSwitch(tester);

      await tester.pump(const Duration(minutes: 5));
      await tester.pump();

      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.officialNetworkId}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.testNetworkId}'),
          skipOffstage: false,
        ),
        findsNothing,
      );
      expect(harness.realtimeRepository.realtimeCancelCount, 1);
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 1);
    },
  );

  testWidgets(
    'reopening released backend recreates workspace and reconnects realtime',
    (tester) async {
      final harness = await _pumpTwoNetworkWorkspace(tester);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-${harness.testNetworkId}/selfhost-1'),
        ),
      );
      await _settleNetworkSwitch(tester);
      await tester.pump(const Duration(minutes: 5));
      await tester.pump();

      expect(harness.realtimeRepository.realtimeConnectCount, 2);
      expect(harness.realtimeRepository.realtimeCancelCount, 1);
      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.officialNetworkId}'),
          skipOffstage: false,
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          ValueKey(
            'server-rail-item-${harness.officialNetworkId}/fake-server-1',
          ),
          skipOffstage: false,
        ),
      );
      await _settleNetworkSwitch(tester);

      expect(harness.realtimeRepository.realtimeConnectCount, 3);
      expect(harness.realtimeRepository.activeRealtimeSubscriptions, 2);
      expect(
        find.byKey(
          ValueKey('multi-network-workspace-pane-${harness.officialNetworkId}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'workspace rail opens scoped servers through their saved network session',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      final identityStore = InstanceIdentityStore(
        storage: MemoryNetworkProfileStorage(),
      );
      await _saveOfficialCredential(credentialStore);
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await identityStore.recordSelfReportedManifest(
        connectedApiOrigin: testOrigin,
        manifest: InstanceManifestIdentity.fromJson({
          'instanceId': 'host:api-test.pryzmapp.com',
          'registryTrust': 'self_reported',
          'name': 'Pryzm Test Self-Host',
          'domain': 'api-test.pryzmapp.com',
          'mode': 'federated',
          'apiUrl': testOrigin,
          'publicKeyFingerprint': 'sha256:${'a' * 64}',
        }),
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'selfhost-server',
            name: 'Selfhost Grove',
          ),
        ),
      );
      final requestedOrigins = <String>[];

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          instanceIdentityStore: identityStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            requestedOrigins.add(apiOrigin);
            return apiOrigin == testOrigin
                ? selfHostRepository
                : _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(requestedOrigins, contains(testOrigin));
      expect(find.text('Pryzm Test Self-Host'), findsNothing);
      expect(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('server-rail-network-badge-$testNetworkId/selfhost-server'),
        ),
        findsOneWidget,
      );
      requestedOrigins.clear();
      await tester.tap(
        find
            .byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server'))
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      expect(requestedOrigins, contains(testOrigin));
      expect(find.text('Selfhost Grove'), findsWidgets);
      expect(
        find.text(
          'Opening Selfhost Grove on Pryzm Test Self-Host is not available yet',
        ),
        findsNothing,
      );
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'cross-network server selection leaves retained DM state for server view',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      await _saveOfficialCredential(credentialStore);
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'selfhost-server',
            name: 'Selfhost Grove',
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return apiOrigin == testOrigin
                ? selfHostRepository
                : _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bottom-rail-dm-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('direct-messages-workspace')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server')),
      );
      await _settleNetworkSwitch(tester);
      expect(
        find.byKey(const ValueKey('direct-messages-workspace')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$officialNetworkId/fake-server-1'),
        ),
      );
      await _settleNetworkSwitch(tester);

      expect(
        find.byKey(const ValueKey('direct-messages-workspace')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('server-workspace-official/fake-server-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'cross-network server selection waits for retained target server readiness',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      final selfHostPrimary = _sampleSettingsData.server.copyWith(
        id: 'selfhost-primary',
        name: 'Selfhost Grove',
      );
      final selfHostArchive = _sampleSettingsData.server.copyWith(
        id: 'selfhost-archive',
        name: 'Selfhost Archive',
      );
      final selfHostLoadDelays = <String, Future<void>>{};
      await _saveOfficialCredential(credentialStore);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: selfHostPrimary,
        ),
        listServersFuture: Future.value([selfHostPrimary, selfHostArchive]),
        loadServerSettingsDelays: selfHostLoadDelays,
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return apiOrigin == testOrigin
                ? selfHostRepository
                : _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$testNetworkId/selfhost-primary'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Selfhost Grove'), findsWidgets);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$officialNetworkId/fake-server-1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Verdant'), findsWidgets);

      final archiveLoad = Completer<void>();
      selfHostLoadDelays[selfHostArchive.id] = archiveLoad.future;
      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$testNetworkId/selfhost-archive'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final selfHostPaneOffstage = tester
          .widgetList<Offstage>(
            find.descendant(
              of: find.byKey(
                ValueKey('multi-network-workspace-pane-$testNetworkId'),
                skipOffstage: false,
              ),
              matching: find.byType(Offstage, skipOffstage: false),
            ),
          )
          .first;
      expect(selfHostPaneOffstage.offstage, isTrue);
      expect(find.text('Selfhost Archive'), findsNothing);

      archiveLoad.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final readySelfHostPaneOffstage = tester
          .widgetList<Offstage>(
            find.descendant(
              of: find.byKey(
                ValueKey('multi-network-workspace-pane-$testNetworkId'),
                skipOffstage: false,
              ),
              matching: find.byType(Offstage, skipOffstage: false),
            ),
          )
          .first;
      expect(readySelfHostPaneOffstage.offstage, isFalse);
      expect(find.text('Selfhost Archive'), findsWidgets);
    },
  );

  testWidgets(
    'cross-network server selection reselects a retained target server',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      final selfHostPrimary = _sampleSettingsData.server.copyWith(
        id: 'selfhost-primary',
        name: 'Selfhost Grove',
      );
      final selfHostArchive = _sampleSettingsData.server.copyWith(
        id: 'selfhost-archive',
        name: 'Selfhost Archive',
      );
      await _saveOfficialCredential(credentialStore);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: selfHostPrimary,
        ),
        listServersFuture: Future.value([selfHostPrimary, selfHostArchive]),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return apiOrigin == testOrigin
                ? selfHostRepository
                : _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$testNetworkId/selfhost-primary'),
        ),
      );
      await _settleNetworkSwitch(tester);
      expect(find.text('Selfhost Grove'), findsWidgets);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$testNetworkId/selfhost-archive'),
        ),
      );
      await _settleNetworkSwitch(tester);
      expect(find.text('Selfhost Archive'), findsWidgets);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$officialNetworkId/fake-server-1'),
        ),
      );
      await _settleNetworkSwitch(tester);
      expect(find.text('Verdant'), findsWidgets);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$testNetworkId/selfhost-primary'),
        ),
      );
      await _settleNetworkSwitch(tester);

      expect(find.text('Selfhost Grove'), findsWidgets);
      expect(find.text('Selfhost Archive'), findsNothing);
      expect(
        find.byKey(ValueKey('multi-network-workspace-pane-$testNetworkId')),
        findsOneWidget,
      );
    },
  );

  testWidgets('workspace swaps servers without transition animation', (
    tester,
  ) async {
    final secondServer = _sampleSettingsData.server.copyWith(
      id: 'fake-server-2',
      name: 'Archive Grove',
    );
    final serverSettingsRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
      listServersFuture: Future.value([
        _sampleSettingsData.server,
        secondServer,
      ]),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        serverSettingsRepository: serverSettingsRepository,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('server-rail-item-official/fake-server-2')),
    );
    await _settleNetworkSwitch(tester);

    expect(find.text('Archive Grove'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('server-workspace-previous-focus-guard'),
        skipOffstage: false,
      ),
      findsNothing,
    );
    final archiveAnimationAncestors = tester
        .widgetList<AnimatedBuilder>(
          find.ancestor(
            of: find.text('Archive Grove'),
            matching: find.byType(AnimatedBuilder),
          ),
        )
        .toList();
    expect(
      archiveAnimationAncestors.where(
        (builder) => builder.listenable is AnimationController,
      ),
      isEmpty,
    );
  });

  test('user settings preferences round-trip profile banner base color', () {
    final preferences = const UserSettingsPreferences(
      profileBannerBaseColor: 0xFF2EC4B6,
    );

    final restored = UserSettingsPreferences.fromJson(preferences.toJson());

    expect(restored.profileBannerBaseColor, 0xFF2EC4B6);
  });

  testWidgets(
    'profile base color swatch updates the no-banner preview and saves backend profile color',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final preferencesStore = UserSettingsPreferencesStore.memory();
      final repository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-token-not-rendered',
          sessionToken: 'session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          serverSettingsRepository: repository,
          userSettingsPreferencesStore: preferencesStore,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();

      const swatchColor = Color(0xFF2EC4B6);
      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-banner-base-color-swatch-ff2ec4b6')),
      );
      await tester.tap(
        find.byKey(const ValueKey('profile-banner-base-color-swatch-ff2ec4b6')),
      );
      await tester.pumpAndSettle();

      final previewFallback = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(const ValueKey('profile-banner-preview')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final previewDecoration = previewFallback.decoration as BoxDecoration;
      final previewGradient = previewDecoration.gradient as LinearGradient;
      expect(previewGradient.colors.first, swatchColor.withValues(alpha: 0.66));

      final restored = await preferencesStore.load();
      expect(restored.profileBannerBaseColor, swatchColor.toARGB32());
      expect(repository.profilePatches, isNotEmpty);
      expect(repository.profilePatches.last['bannerBaseColor'], '#2EC4B6');
    },
  );

  testWidgets(
    'workspace rail keeps current pane while network refresh hydrates',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      final selfHostServer = _sampleSettingsData.server.copyWith(
        id: 'selfhost-server',
        name: 'Selfhost Grove',
      );
      final selfHostData = _sampleSettingsDataForNetwork(
        networkId: testNetworkId,
        server: selfHostServer,
      );
      await _saveOfficialCredential(credentialStore);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      var selfHostRepositoryCount = 0;
      final targetHydration = Completer<List<ServerSettingsServer>>();
      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == testOrigin) {
              selfHostRepositoryCount += 1;
              return _FakeServerSettingsRepository(
                data: selfHostData,
                listServersFuture: selfHostRepositoryCount >= 2
                    ? targetHydration.future
                    : null,
              );
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Verdant'), findsWidgets);
      expect(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server')),
        findsOneWidget,
      );
      final selfHostRailIconKey = ValueKey(
        'server-rail-item-$testNetworkId/selfhost-server',
      );
      final selfHostRailIconLeftBeforeSwitch = tester
          .getTopLeft(find.byKey(selfHostRailIconKey))
          .dx;

      await tester.tap(find.byKey(selfHostRailIconKey).hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Connecting...'), findsNothing);
      expect(find.text('Verdant'), findsWidgets);
      expect(find.text('Selfhost Grove'), findsNothing);
      expect(
        find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('server-rail-item-') &&
              key.value.endsWith('/fake-server-1');
        }),
        findsWidgets,
      );

      targetHydration.complete([selfHostServer]);
      await tester.pump();
      await tester.pump();

      expect(find.text('Selfhost Grove'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final selfHostRailIconLeftAfterSwitch = tester
          .getTopLeft(find.byKey(selfHostRailIconKey))
          .dx;
      expect(
        selfHostRailIconLeftAfterSwitch,
        closeTo(selfHostRailIconLeftBeforeSwitch, 0.01),
      );

      final selfHostShell = find.byKey(
        ValueKey('workspace-shell-$testNetworkId'),
        skipOffstage: false,
      );
      expect(selfHostShell, findsOneWidget);
      final animatedAncestors = tester
          .widgetList<AnimatedBuilder>(
            find.ancestor(
              of: selfHostShell,
              matching: find.byType(AnimatedBuilder),
            ),
          )
          .toList();
      expect(
        animatedAncestors.where(
          (builder) => builder.listenable is Animation<double>,
        ),
        isEmpty,
      );
      final railTranslationAncestors = tester
          .widgetList<FractionalTranslation>(
            find.ancestor(
              of: find.byKey(
                ValueKey('server-rail-item-$testNetworkId/selfhost-server'),
                skipOffstage: false,
              ),
              matching: find.byType(FractionalTranslation),
            ),
          )
          .toList();
      expect(
        railTranslationAncestors.any(
          (translation) => translation.translation.dx.abs() > 0.01,
        ),
        isFalse,
      );
      await tester.pumpAndSettle();

      expect(find.text('Selfhost Grove'), findsWidgets);
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
      final selfHostRepositoryCountAfterHydration = selfHostRepositoryCount;
      expect(selfHostRepositoryCount, selfHostRepositoryCountAfterHydration);
    },
  );

  testWidgets(
    'federated rail hydration remints missing target credential from home membership',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const targetOrigin = 'https://api-test.pryzmapp.com';
      final targetNetworkId = networkIdFromApiOrigin(targetOrigin);
      final targetServer = _sampleSettingsData.server.copyWith(
        id: 'federated-server',
        name: 'Federated Grove',
      );
      final targetData = _sampleSettingsDataForNetwork(
        networkId: targetNetworkId,
        server: targetServer,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _federatedMembership(
          id: 'mem-1',
          targetApiOrigin: targetOrigin,
          targetServerId: targetServer.id,
          serverName: targetServer.name,
        ),
      ]);
      final diagnostics = _RecordingAuthDiagnostics();
      var targetListCalls = 0;
      await _saveOfficialCredential(credentialStore);

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          authDiagnostics: diagnostics,
          federatedMembershipRepositoryFactory: (_) => membershipRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == targetOrigin) {
              targetListCalls += 1;
              return _FakeServerSettingsRepository(data: targetData);
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );
      await tester.pumpAndSettle();

      final hydratedTargetCredentials = await credentialStore.read(
        targetOrigin,
      );
      expect(
        hydratedTargetCredentials?.kind,
        AuthCredentialKind.federatedClient,
      );
      expect(hydratedTargetCredentials?.accessToken, 'target-federated-access');
      expect(
        find.byKey(
          ValueKey('server-rail-item-$targetNetworkId/${targetServer.id}'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find
            .byKey(
              ValueKey('server-rail-item-$targetNetworkId/${targetServer.id}'),
            )
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      final targetCredentials = await credentialStore.read(targetOrigin);
      expect(targetCredentials?.kind, AuthCredentialKind.federatedClient);
      expect(targetCredentials?.accessToken, 'target-federated-access');
      expect(targetCredentials?.sessionToken, isEmpty);
      expect(membershipRepository.listCalls, greaterThanOrEqualTo(1));
      expect(membershipRepository.refreshCalls, ['mem-1']);
      expect(targetListCalls, greaterThanOrEqualTo(1));
      expect(
        diagnostics.events.map((event) => event.name),
        containsAllInOrder([
          'workspace.rail.hydration.federated_refresh.start',
          'workspace.rail.hydration.federated_refresh.result',
          'workspace.rail.hydration.federated_refresh.success',
        ]),
      );
      final restoreResultEvent = diagnostics.events.lastWhere(
        (event) =>
            event.name == 'workspace.rail.hydration.federated_refresh.result',
      );
      expect(restoreResultEvent.fields['targetApiOrigin'], targetOrigin);
      expect(restoreResultEvent.fields['capabilityStatus'], 'ready');
      final profileState = await networkProfileStore.load();
      final targetProfile = profileState.profiles.firstWhere(
        (profile) => profile.apiOrigin == targetOrigin,
      );
      expect(targetProfile.name, 'api-test.pryzmapp.com');
      expect(find.text('Federated Grove'), findsWidgets);
      expect(find.text('target-federated-access'), findsNothing);
    },
  );

  testWidgets(
    'federated rail click replaces stale target credential before opening',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const targetOrigin = 'https://api-test.pryzmapp.com';
      final targetNetworkId = networkIdFromApiOrigin(targetOrigin);
      final targetServer = _sampleSettingsData.server.copyWith(
        id: 'federated-server',
        name: 'Federated Grove',
      );
      final targetData = _sampleSettingsDataForNetwork(
        networkId: targetNetworkId,
        server: targetServer,
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _federatedMembership(
          id: 'mem-1',
          targetApiOrigin: targetOrigin,
          targetServerId: targetServer.id,
          serverName: targetServer.name,
        ),
      ]);
      var targetListCalls = 0;
      await _saveOfficialCredential(credentialStore);
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: targetOrigin,
          accessToken: 'stale-target-federated-access',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: 'fed_old',
            username: 'fed_old',
            email: '',
            status: 'offline',
            usernameSet: true,
            emailVerified: false,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          federatedMembershipRepositoryFactory: (_) => membershipRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == targetOrigin) {
              return _FakeServerSettingsRepository(
                data: targetData,
                beforeListServers: () async {
                  targetListCalls += 1;
                  final credentials = await credentialStore.read(targetOrigin);
                  if (credentials?.accessToken != 'target-federated-access') {
                    throw const ServerSettingsException(
                      'Your session has expired. Please sign in again.',
                      isAuthExpired: true,
                    );
                  }
                },
              );
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          ValueKey('server-rail-item-$targetNetworkId/${targetServer.id}'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find
            .byKey(
              ValueKey('server-rail-item-$targetNetworkId/${targetServer.id}'),
            )
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      final targetCredentials = await credentialStore.read(targetOrigin);
      expect(targetCredentials?.kind, AuthCredentialKind.federatedClient);
      expect(targetCredentials?.accessToken, 'target-federated-access');
      expect(membershipRepository.refreshCalls, contains('mem-1'));
      // One call validates the stale saved target credential, one validates
      // the reminted rail state, and one opens the selected workspace.
      expect(targetListCalls, 3);
      final profileState = await networkProfileStore.load();
      final targetProfile = profileState.profiles.firstWhere(
        (profile) => profile.apiOrigin == targetOrigin,
      );
      expect(targetProfile.name, 'api-test.pryzmapp.com');
      expect(find.text('Federated Grove'), findsWidgets);
      expect(find.text('stale-target-federated-access'), findsNothing);
      expect(find.text('target-federated-access'), findsNothing);
    },
  );

  testWidgets('federated rail click reuses unexpired target credential', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    final diagnostics = _RecordingAuthDiagnostics();
    const targetOrigin = 'https://api-test.pryzmapp.com';
    final targetNetworkId = networkIdFromApiOrigin(targetOrigin);
    final targetServer = _sampleSettingsData.server.copyWith(
      id: 'federated-server',
      name: 'Federated Grove',
    );
    final targetData = _sampleSettingsDataForNetwork(
      networkId: targetNetworkId,
      server: targetServer,
    );
    final membershipRepository = _FakeFederatedMembershipRepository([
      _federatedMembership(
        id: 'mem-1',
        targetApiOrigin: targetOrigin,
        targetServerId: targetServer.id,
        serverName: targetServer.name,
      ),
    ]);
    await _saveOfficialCredential(credentialStore);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: targetOrigin,
    );
    await credentialStore.save(
      AuthCredentialBundle(
        apiOrigin: targetOrigin,
        accessToken: 'existing-target-federated-access',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
        expiresAt: DateTime.utc(2099),
        user: const VerdantUser(
          id: 'fed_existing',
          username: 'fed_existing',
          email: '',
          status: 'offline',
          usernameSet: true,
          emailVerified: false,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        authDiagnostics: diagnostics,
        federatedMembershipRepositoryFactory: (_) => membershipRepository,
        serverSettingsRepositoryFactory: (apiOrigin) {
          if (apiOrigin == targetOrigin) {
            return _FakeServerSettingsRepository(
              data: targetData,
              beforeListServers: () async {
                final credentials = await credentialStore.read(targetOrigin);
                expect(
                  credentials?.accessToken,
                  'existing-target-federated-access',
                );
              },
            );
          }
          return _FakeServerSettingsRepository(data: _sampleSettingsData);
        },
      ),
    );
    await tester.pumpAndSettle();

    final refreshCallsBeforeClick = membershipRepository.refreshCalls.length;
    await tester.tap(
      find
          .byKey(
            ValueKey('server-rail-item-$targetNetworkId/${targetServer.id}'),
          )
          .hitTestable(),
    );
    await _settleNetworkSwitch(tester);

    final targetCredentials = await credentialStore.read(targetOrigin);
    expect(targetCredentials?.kind, AuthCredentialKind.federatedClient);
    expect(targetCredentials?.accessToken, 'existing-target-federated-access');
    expect(membershipRepository.refreshCalls.length, refreshCallsBeforeClick);
    expect(
      diagnostics.events.map((event) => event.name),
      contains('federated.access.restore.cached'),
    );
    expect(find.text('Federated Grove'), findsWidgets);
    expect(find.text('existing-target-federated-access'), findsNothing);
  });

  testWidgets(
    'federated rail click remints from saved home while active session is federated',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const firstOrigin = 'https://api-first.pryzmapp.com';
      const secondOrigin = 'https://api-second.pryzmapp.com';
      final firstNetworkId = networkIdFromApiOrigin(firstOrigin);
      final secondNetworkId = networkIdFromApiOrigin(secondOrigin);
      final firstServer = _sampleSettingsData.server.copyWith(
        id: 'first-federated-server',
        name: 'First Grove',
      );
      final secondServer = _sampleSettingsData.server.copyWith(
        id: 'second-federated-server',
        name: 'Second Grove',
      );
      final membershipRepository = _FakeFederatedMembershipRepository([
        _federatedMembership(
          id: 'mem-first',
          targetApiOrigin: firstOrigin,
          targetServerId: firstServer.id,
          serverName: firstServer.name,
        ),
        _federatedMembership(
          id: 'mem-second',
          targetApiOrigin: secondOrigin,
          targetServerId: secondServer.id,
          serverName: secondServer.name,
        ),
      ]);
      await _saveOfficialCredential(credentialStore);

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          federatedMembershipRepositoryFactory: (_) => membershipRepository,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == firstOrigin) {
              return _FakeServerSettingsRepository(
                data: _sampleSettingsDataForNetwork(
                  networkId: firstNetworkId,
                  server: firstServer,
                ),
              );
            }
            if (apiOrigin == secondOrigin) {
              return _FakeServerSettingsRepository(
                data: _sampleSettingsDataForNetwork(
                  networkId: secondNetworkId,
                  server: secondServer,
                ),
                beforeListServers: () async {
                  final credentials = await credentialStore.read(secondOrigin);
                  if (credentials?.accessToken != 'target-federated-access') {
                    throw const ServerSettingsException(
                      'Federated access expired. Rejoin the server invite to continue.',
                      isAuthExpired: true,
                    );
                  }
                },
              );
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byKey(
              ValueKey('server-rail-item-$firstNetworkId/${firstServer.id}'),
            )
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      final secondRefreshCallsBeforeClick = membershipRepository.refreshCalls
          .where((membershipId) => membershipId == 'mem-second')
          .length;
      await credentialStore.save(
        AuthCredentialBundle(
          apiOrigin: secondOrigin,
          accessToken: 'future-stale-second-target-federated-access',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          expiresAt: DateTime.utc(2000),
          user: const VerdantUser(
            id: 'fed_old_second',
            username: 'fed_old_second',
            email: '',
            status: 'offline',
            usernameSet: true,
            emailVerified: false,
            totpEnabled: false,
          ),
        ),
      );

      await tester.tap(
        find
            .byKey(
              ValueKey('server-rail-item-$secondNetworkId/${secondServer.id}'),
            )
            .hitTestable(),
      );
      await _settleNetworkSwitch(tester);

      final secondCredentials = await credentialStore.read(secondOrigin);
      expect(secondCredentials?.kind, AuthCredentialKind.federatedClient);
      expect(secondCredentials?.accessToken, 'target-federated-access');
      expect(
        membershipRepository.refreshCalls
            .where((membershipId) => membershipId == 'mem-second')
            .length,
        greaterThan(secondRefreshCallsBeforeClick),
      );
      expect(find.text('Second Grove'), findsWidgets);
      expect(
        find.text(
          'Federated access expired. Rejoin the server invite to continue.',
        ),
        findsNothing,
      );
      expect(
        find.text('future-stale-second-target-federated-access'),
        findsNothing,
      );
      expect(find.text('target-federated-access'), findsNothing);
    },
  );

  testWidgets('federated reconnect remints before refreshing workspace', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final diagnostics = _RecordingAuthDiagnostics();
    const targetOrigin = 'https://api-test.pryzmapp.com';
    final targetNetworkId = networkIdFromApiOrigin(targetOrigin);
    final targetServer = _sampleSettingsData.server.copyWith(
      id: 'federated-server',
      name: 'Federated Grove',
    );
    final targetData = _sampleSettingsDataForNetwork(
      networkId: targetNetworkId,
      server: targetServer,
    );
    const fedUser = VerdantUser(
      id: 'fed_129fa6f4b31ac2c4a38906be',
      username: 'fed_josh',
      email: '',
      status: 'offline',
      usernameSet: true,
      emailVerified: true,
      totpEnabled: false,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: targetOrigin,
        accessToken: 'stale-target-federated-access',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
        user: fedUser,
      ),
    );
    final repository = _FakeServerSettingsRepository(
      data: targetData,
      beforeListServers: () async {
        final credentials = await credentialStore.read(targetOrigin);
        if (credentials?.accessToken != 'fresh-target-federated-access') {
          throw const ServerSettingsException(
            'Federated access expired. Rejoin the server invite to continue.',
            isAuthExpired: true,
          );
        }
      },
    );
    var activationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerdantTheme(mode: VerdantThemeMode.dark),
        home: WorkspaceShell(
          session: AuthSession.authenticated(
            apiOrigin: targetOrigin,
            user: fedUser,
            hasSessionToken: false,
            credentialKind: AuthCredentialKind.federatedClient,
          ),
          credentialStore: credentialStore,
          serverSettingsRepository: repository,
          directMessagesRepository: _FakeDirectMessagesRepository(
            data: _sampleDirectMessagesData,
          ),
          networkProfileStore: NetworkProfileStore.memory(),
          instanceIdentityStore: InstanceIdentityStore(
            storage: MemoryNetworkProfileStorage(),
          ),
          accessibilitySettingsStore:
              WorkspaceAccessibilitySettingsStore.memory(),
          userSettingsPreferencesStore: UserSettingsPreferencesStore.memory(),
          diagnostics: diagnostics,
          currentUserName: fedUser.displayLabel,
          currentUserInitials: fedUser.initials,
          showBottomRail: false,
          onLogout: () {},
          onActivateNetwork:
              ({required String apiOrigin, String? initialServerId}) async {
                activationCalls += 1;
                expect(apiOrigin, targetOrigin);
                expect(initialServerId, isNull);
                await credentialStore.save(
                  const AuthCredentialBundle(
                    apiOrigin: targetOrigin,
                    accessToken: 'fresh-target-federated-access',
                    sessionToken: '',
                    kind: AuthCredentialKind.federatedClient,
                    user: fedUser,
                  ),
                );
                return const NetworkSessionActivationResult.opened();
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Federated access expired. Rejoin the server invite to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reconnect'), findsOneWidget);

    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();

    expect(activationCalls, 1);
    expect(find.text('Federated Grove'), findsWidgets);
    expect(find.text('Message #general'), findsOneWidget);
    expect(find.text('stale-target-federated-access'), findsNothing);
    expect(find.text('fresh-target-federated-access'), findsNothing);
    expect(
      diagnostics.events.map((event) => event.name),
      containsAllInOrder([
        'workspace.federated.reconnect.start',
        'workspace.federated.reconnect.result',
        'workspace.load.result',
      ]),
    );
  });

  testWidgets(
    'workspace rail ignores busy taps while target activation is pending',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      final authService = _DelayedRefreshAuthService(delayedOrigin: testOrigin);
      final diagnostics = _RecordingAuthDiagnostics();
      await _saveOfficialCredential(credentialStore);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final selfHostServer = _sampleSettingsData.server.copyWith(
        id: 'selfhost-server',
        name: 'Selfhost Grove',
      );

      await tester.pumpWidget(
        _testApp(
          authService: authService,
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          authDiagnostics: diagnostics,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return apiOrigin == testOrigin
                ? _FakeServerSettingsRepository(
                    data: _sampleSettingsDataForNetwork(
                      networkId: testNetworkId,
                      server: selfHostServer,
                    ),
                  )
                : _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );
      await tester.pumpAndSettle();

      final selfHostRailIcon = find
          .byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server'))
          .hitTestable();
      await tester.tap(selfHostRailIcon);
      await tester.pump();
      await tester.tap(selfHostRailIcon);
      await tester.pump();

      expect(
        authService.refreshOrigins.where((origin) => origin == testOrigin),
        [testOrigin],
      );
      final busyIgnoreEvents = diagnostics.events
          .where((event) => event.name == 'workspace.rail.select.busy_ignore')
          .toList(growable: false);
      expect(busyIgnoreEvents, hasLength(1));
      expect(busyIgnoreEvents.single.fields['reason'], 'pending_activation');
      expect(busyIgnoreEvents.single.fields['networkId'], testNetworkId);
      expect(busyIgnoreEvents.single.fields['server'], 'selfhost-server');

      authService.completeDelayedRefresh();
      await _settleNetworkSwitch(tester);

      expect(find.text('Selfhost Grove'), findsWidgets);
    },
  );

  testWidgets('workspace rail opens ready cross-network server without dwell', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    const testOrigin = 'https://api-test.pryzmapp.com';
    final testNetworkId = networkIdFromApiOrigin(testOrigin);
    final diagnostics = _RecordingAuthDiagnostics();
    await _saveOfficialCredential(credentialStore);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: testOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: testOrigin,
        accessToken: 'selfhost-access-token-not-rendered',
        sessionToken: 'selfhost-session-token-not-rendered',
        user: VerdantUser(
          id: '84',
          username: 'community_josh',
          email: 'selfhost@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final selfHostServer = _sampleSettingsData.server.copyWith(
      id: 'selfhost-server',
      name: 'Selfhost Grove',
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        authDiagnostics: diagnostics,
        serverSettingsRepositoryFactory: (apiOrigin) {
          return apiOrigin == testOrigin
              ? _FakeServerSettingsRepository(
                  data: _sampleSettingsDataForNetwork(
                    networkId: testNetworkId,
                    server: selfHostServer,
                  ),
                )
              : _FakeServerSettingsRepository(data: _sampleSettingsData);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server'))
          .hitTestable(),
    );
    for (var i = 0; i < 6; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Selfhost Grove'), findsWidgets);
    final targetEvents = diagnostics.events
        .where((event) => event.name == 'workspace.network.target')
        .toList(growable: false);
    expect(targetEvents, isNotEmpty);
    expect(targetEvents.last.fields['minimumDwellMs'], 0);
    final visibleEvents = diagnostics.events
        .where((event) => event.name == 'workspace.network.visible')
        .toList(growable: false);
    expect(visibleEvents, isNotEmpty);
    expect(visibleEvents.last.fields['ms'], lessThan(1500));
  });

  testWidgets('workspace rail records per-network restore counts', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    const testOrigin = 'https://api-test.pryzmapp.com';
    final testNetworkId = networkIdFromApiOrigin(testOrigin);
    final diagnostics = _RecordingAuthDiagnostics();
    await _saveOfficialCredential(credentialStore);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: testOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: testOrigin,
        accessToken: 'selfhost-access-token-not-rendered',
        sessionToken: 'selfhost-session-token-not-rendered',
        user: VerdantUser(
          id: '84',
          username: 'community_josh',
          email: 'selfhost@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
    final selfHostServer = _sampleSettingsData.server.copyWith(
      id: 'selfhost-server',
      name: 'Selfhost Grove',
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        authDiagnostics: diagnostics,
        serverSettingsRepositoryFactory: (apiOrigin) {
          return apiOrigin == testOrigin
              ? _FakeServerSettingsRepository(
                  data: _sampleSettingsDataForNetwork(
                    networkId: testNetworkId,
                    server: selfHostServer,
                  ),
                )
              : _FakeServerSettingsRepository(data: _sampleSettingsData);
        },
      ),
    );
    await tester.pumpAndSettle();

    final snapshotEvents = diagnostics.events
        .where((event) => event.name == 'workspace.rail.snapshot')
        .toList(growable: false);
    expect(snapshotEvents, isNotEmpty);
    final fields = snapshotEvents.last.fields;
    expect(fields['profileCount'], 2);
    expect(fields['recordCount'], 2);
    expect(fields['railServerCount'], 2);
    final records = fields['records'];
    expect(records, isA<List<Object?>>());
    final recordMaps = [
      for (final record in records as List<Object?>)
        Map<String, Object?>.from(record! as Map),
    ];
    final selfHostRecord = recordMaps.singleWhere(
      (record) => record['networkId'] == testNetworkId,
    );
    expect(selfHostRecord['availability'], 'available');
    expect(selfHostRecord['authStatus'], 'authenticated');
    expect(selfHostRecord['serverCount'], 1);
    expect(selfHostRecord['apiOrigin'], testOrigin);
  });

  testWidgets(
    'workspace rail ignores other server taps while local hydration is pending',
    (tester) async {
      final secondServer = _sampleSettingsData.server.copyWith(
        id: 'fake-server-2',
        name: 'Archive Grove',
      );
      final thirdServer = _sampleSettingsData.server.copyWith(
        id: 'fake-server-3',
        name: 'Canopy Grove',
      );
      final secondLoad = Completer<void>();
      final thirdLoad = Completer<void>();
      final diagnostics = _RecordingAuthDiagnostics();
      final serverSettingsRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsData,
        listServersFuture: Future.value([
          _sampleSettingsData.server,
          secondServer,
          thirdServer,
        ]),
        loadServerSettingsDelays: {
          secondServer.id: secondLoad.future,
          thirdServer.id: thirdLoad.future,
        },
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          authDiagnostics: diagnostics,
          serverSettingsRepository: serverSettingsRepository,
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'boji@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'correct horse battery staple',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('server-rail-item-official/fake-server-2')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('server-rail-item-official/fake-server-3')),
      );
      await tester.pump();

      expect(
        serverSettingsRepository.loadedServerSettingsIds,
        contains(secondServer.id),
      );
      expect(
        serverSettingsRepository.loadedServerSettingsIds,
        isNot(contains(thirdServer.id)),
      );
      final busyIgnoreEvents = diagnostics.events
          .where((event) => event.name == 'workspace.rail.select.busy_ignore')
          .toList(growable: false);
      expect(busyIgnoreEvents, hasLength(1));
      expect(busyIgnoreEvents.single.fields['reason'], 'pending_selection');
      expect(
        busyIgnoreEvents.single.fields['pendingScopedServerId'],
        isNotNull,
      );

      secondLoad.complete();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Archive Grove'), findsWidgets);
      expect(find.text('Canopy Grove'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('Archive Grove'), findsWidgets);
      expect(find.text('Canopy Grove'), findsNothing);
    },
  );

  testWidgets(
    'workspace rail accepts cross-network taps after target workspace is ready',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      final authService = _RailRefreshFailingAuthService();
      await _saveOfficialCredential(credentialStore);
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      final selfHostServer = _sampleSettingsData.server.copyWith(
        id: 'selfhost-server',
        name: 'Selfhost Grove',
      );
      final selfHostData = _sampleSettingsDataForNetwork(
        networkId: testNetworkId,
        server: selfHostServer,
      );
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      var selfHostRepositoryCount = 0;
      final targetHydration = Completer<List<ServerSettingsServer>>();
      await tester.pumpWidget(
        _testApp(
          authService: authService,
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) {
            if (apiOrigin == testOrigin) {
              selfHostRepositoryCount += 1;
              return _FakeServerSettingsRepository(
                data: selfHostData,
                listServersFuture: selfHostRepositoryCount >= 2
                    ? targetHydration.future
                    : null,
              );
            }
            return _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server')),
      );
      await tester.pump();
      targetHydration.complete([selfHostServer]);
      await tester.pump();
      await _settleNetworkSwitch(tester);

      expect(authService.refreshOrigins, [officialApiOrigin, testOrigin]);
      expect(find.text('Selfhost Grove'), findsWidgets);

      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$officialNetworkId/fake-server-1'),
        ),
      );
      await _settleNetworkSwitch(tester);

      expect(authService.refreshOrigins, [officialApiOrigin, testOrigin]);
      expect(find.text('Verdant'), findsWidgets);
    },
  );

  testWidgets(
    'workspace rail reuses recent home refresh during retained refresh blips',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      final authService = _RailRefreshFailingAuthService();
      final diagnostics = _RecordingAuthDiagnostics();
      await _saveOfficialCredential(credentialStore);
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
          user: VerdantUser(
            id: '84',
            username: 'community_josh',
            email: 'selfhost@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'selfhost-server',
            name: 'Selfhost Grove',
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: authService,
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          authDiagnostics: diagnostics,
          serverSettingsRepositoryFactory: (apiOrigin) {
            return apiOrigin == testOrigin
                ? selfHostRepository
                : _FakeServerSettingsRepository(data: _sampleSettingsData);
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/selfhost-server')),
      );
      await _settleNetworkSwitch(tester);

      expect(find.text('Selfhost Grove'), findsWidgets);

      authService.failOfficialRefresh = true;
      final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
      await tester.tap(
        find.byKey(
          ValueKey('server-rail-item-$officialNetworkId/fake-server-1'),
        ),
      );
      await _settleNetworkSwitch(tester);

      expect(find.text('Verdant'), findsWidgets);
      expect(find.text('Selfhost Grove'), findsNothing);
      expect(find.text('Could not open Official'), findsNothing);
      expect(find.text('Sign in to Official'), findsNothing);
      expect(find.text('Sign in to Verdant'), findsNothing);
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(await credentialStore.contains(testOrigin), isTrue);
      expect(authService.refreshOrigins, [officialApiOrigin, testOrigin]);
      expect(
        diagnostics.events.map((event) => event.name),
        contains('credential.restore.refresh.reuse'),
      );
      expect(find.text('official-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);

      final submittingWorkspaceRenders = diagnostics.events.where(
        (event) =>
            event.name == 'auth.gate.render' &&
            event.fields['surface'] == 'workspace' &&
            event.fields['isSubmitting'] == true,
      );
      expect(submittingWorkspaceRenders, isEmpty);
      final activatingWorkspaceRenders = diagnostics.events.where(
        (event) =>
            event.name == 'auth.gate.render' &&
            event.fields['surface'] == 'workspace' &&
            event.fields['isNetworkActivating'] == true,
      );
      expect(activatingWorkspaceRenders, isEmpty);
    },
  );

  testWidgets('network settings renders a collapsed multi-network list', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    const testOrigin = 'https://api-test.pryzmapp.com';
    final testNetworkId = networkIdFromApiOrigin(testOrigin);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: testOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: testOrigin,
        accessToken: 'selfhost-access-token-not-rendered',
        sessionToken: 'selfhost-session-token-not-rendered',
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        serverSettingsRepositoryFactory: (_) =>
            _FakeServerSettingsRepository(data: _sampleSettingsData),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('workspace-user-settings-button')),
    );
    await tester.pumpAndSettle();
    final networkCategory = find.byKey(
      const ValueKey('user-settings-category-network'),
    );
    await tester.ensureVisible(networkCategory);
    await tester.tap(networkCategory);
    await tester.pumpAndSettle();

    expect(find.text('Official Network'), findsNothing);
    expect(
      find.byKey(
        ValueKey(
          'user-settings-network-row-${networkIdFromApiOrigin(officialApiOrigin)}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      findsOneWidget,
    );
    expect(find.text('Active'), findsNothing);
    expect(find.text('Home Network'), findsWidgets);
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('Federated Network'), findsNothing);
    expect(find.text('Standalone'), findsNothing);
    expect(find.text('Local Network'), findsNothing);
    expect(find.text(testOrigin), findsNothing);

    await tester.tap(
      find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
    );
    await tester.pumpAndSettle();

    expect(find.text(testOrigin), findsOneWidget);
    expect(find.text('Federated Network'), findsOneWidget);
    expect(find.text('Network Origin'), findsOneWidget);
    expect(find.text('Connected As'), findsOneWidget);
    expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
    expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
  });

  testWidgets('network settings labels signed out networks as disconnected', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    const testOrigin = 'https://api-test.pryzmapp.com';
    final testNetworkId = networkIdFromApiOrigin(testOrigin);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: testOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: officialApiOrigin,
        accessToken: 'official-access-token-not-rendered',
        sessionToken: 'official-session-token-not-rendered',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        serverSettingsRepositoryFactory: (_) =>
            _FakeServerSettingsRepository(data: _sampleSettingsData),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('workspace-user-settings-button')),
    );
    await tester.pumpAndSettle();
    final networkCategory = find.byKey(
      const ValueKey('user-settings-category-network'),
    );
    await tester.ensureVisible(networkCategory);
    await tester.tap(networkCategory);
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      findsOneWidget,
    );
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('Sign in required'), findsNothing);
    expect(find.text('Active'), findsNothing);
    expect(find.text('official-access-token-not-rendered'), findsNothing);
  });

  testWidgets(
    'network settings treats federated credentials as federation access',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-token-not-rendered',
          sessionToken: 'official-session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'federated-access-token-not-rendered',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: 'fed_129fa6f4b31ac2c4a38906be',
            username: 'fed_129fa6f4b31ac2c4a38906be',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: false,
            totpEnabled: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (_) =>
              _FakeServerSettingsRepository(data: _sampleSettingsData),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('server-rail-item-$testNetworkId/fake-server-1')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final networkCategory = find.byKey(
        const ValueKey('user-settings-category-network'),
      );
      await tester.ensureVisible(networkCategory);
      await tester.tap(networkCategory);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Federated Network'), findsWidgets);
      expect(
        find.text('Connected as @fed_129fa6f4b31ac2c4a38906be'),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('user-settings-network-logout-$testNetworkId')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('user-settings-network-signin-$testNetworkId')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('user-settings-network-create-account-$testNetworkId'),
        ),
        findsNothing,
      );
      expect(find.text('federated-access-token-not-rendered'), findsNothing);
    },
  );

  testWidgets('active federated sessions hide the generic logout button', (
    tester,
  ) async {
    final credentialStore = _MemoryCredentialStore();
    final networkProfileStore = NetworkProfileStore.memory();
    const testOrigin = 'https://api-test.pryzmapp.com';
    final testNetworkId = networkIdFromApiOrigin(testOrigin);
    await _saveOfficialCredential(credentialStore);
    await networkProfileStore.saveProfile(
      name: 'Pryzm Test Self-Host',
      apiOrigin: testOrigin,
    );
    await credentialStore.save(
      const AuthCredentialBundle(
        apiOrigin: testOrigin,
        accessToken: 'federated-access-token-not-rendered',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
        user: VerdantUser(
          id: 'fed_129fa6f4b31ac2c4a38906be',
          username: 'fed_129fa6f4b31ac2c4a38906be',
          email: '',
          status: 'online',
          usernameSet: true,
          emailVerified: false,
          totpEnabled: false,
        ),
      ),
    );
    final officialRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsData,
    );
    final federatedRepository = _FakeServerSettingsRepository(
      data: _sampleSettingsDataForNetwork(
        networkId: testNetworkId,
        server: _sampleSettingsData.server.copyWith(
          id: 'federated-server',
          name: 'Federated Grove',
        ),
      ),
    );
    final membershipRepository = _FakeFederatedMembershipRepository([
      _federatedMembership(
        id: 'mem-federated-server',
        targetApiOrigin: testOrigin,
        targetServerId: 'federated-server',
        serverName: 'Federated Grove',
      ),
    ]);

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        serverSettingsRepository: officialRepository,
        federatedMembershipRepositoryFactory: (_) => membershipRepository,
        serverSettingsRepositoryFactory: (apiOrigin) {
          return apiOrigin == testOrigin
              ? federatedRepository
              : officialRepository;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(ValueKey('server-rail-item-$testNetworkId/federated-server'))
          .hitTestable(),
    );
    await _settleNetworkSwitch(tester);

    expect(
      find.byKey(const ValueKey('workspace-user-settings-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('workspace-logout-button')), findsNothing);
    expect(find.text('federated-access-token-not-rendered'), findsNothing);
  });

  testWidgets(
    'network settings retries and removes only the target saved network',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final networkProfileStore = NetworkProfileStore.memory();
      const testOrigin = 'https://api-test.pryzmapp.com';
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-token-not-rendered',
          sessionToken: 'official-session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
        ),
      );
      final selfHostRepository = _FakeServerSettingsRepository(
        data: _sampleSettingsDataForNetwork(
          networkId: testNetworkId,
          server: _sampleSettingsData.server.copyWith(
            id: 'selfhost-retried-server',
            name: 'Retried Selfhost Grove',
          ),
        ),
        listServersResults: [
          const ServerSettingsException('network unavailable'),
          null,
          null,
        ],
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (apiOrigin) =>
              normalizeBackendApiOrigin(apiOrigin) == testOrigin
              ? selfHostRepository
              : _FakeServerSettingsRepository(data: _sampleSettingsData),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final networkCategory = find.byKey(
        const ValueKey('user-settings-category-network'),
      );
      await tester.ensureVisible(networkCategory);
      await tester.tap(networkCategory);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Error'), findsNothing);

      final retryButton = find.byKey(
        ValueKey('user-settings-network-retry-$testNetworkId'),
      );
      await tester.ensureVisible(retryButton);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          ValueKey('server-rail-item-$testNetworkId/selfhost-retried-server'),
        ),
        findsOneWidget,
      );
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(await credentialStore.contains(testOrigin), isTrue);
      expect(
        find.byKey(ValueKey('user-settings-network-logout-$testNetworkId')),
        findsNothing,
      );

      final removeButton = find.byKey(
        ValueKey('user-settings-network-remove-$testNetworkId'),
      );
      await tester.ensureVisible(removeButton);
      await tester.tap(removeButton);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final profileState = await networkProfileStore.load();
      expect(profileState.profiles.map((profile) => profile.apiOrigin), [
        officialApiOrigin,
      ]);
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets(
    'network settings keeps a saved network when credential removal fails',
    (tester) async {
      const testOrigin = 'https://api-test.pryzmapp.com';
      final credentialStore = _MemoryCredentialStore(
        clearFailures: {testOrigin},
      );
      final networkProfileStore = NetworkProfileStore.memory();
      final testNetworkId = networkIdFromApiOrigin(testOrigin);
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: testOrigin,
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-token-not-rendered',
          sessionToken: 'official-session-token-not-rendered',
          user: VerdantUser(
            id: '42',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: testOrigin,
          accessToken: 'selfhost-access-token-not-rendered',
          sessionToken: 'selfhost-session-token-not-rendered',
        ),
      );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          networkProfileStore: networkProfileStore,
          serverSettingsRepositoryFactory: (_) =>
              _FakeServerSettingsRepository(data: _sampleSettingsData),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-user-settings-button')),
      );
      await tester.pumpAndSettle();
      final networkCategory = find.byKey(
        const ValueKey('user-settings-category-network'),
      );
      await tester.ensureVisible(networkCategory);
      await tester.tap(networkCategory);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
      );
      await tester.pumpAndSettle();

      final removeButton = find.byKey(
        ValueKey('user-settings-network-remove-$testNetworkId'),
      );
      await tester.ensureVisible(removeButton);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Could not remove Pryzm Test Self-Host'),
        findsOneWidget,
      );
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(await credentialStore.contains(testOrigin), isTrue);
      expect(
        find.byKey(ValueKey('user-settings-network-row-$testNetworkId')),
        findsOneWidget,
      );
      final profileState = await networkProfileStore.load();
      expect(profileState.profiles.map((profile) => profile.apiOrigin), [
        officialApiOrigin,
        testOrigin,
      ]);
      expect(find.text('selfhost-access-token-not-rendered'), findsNothing);
      expect(find.text('selfhost-session-token-not-rendered'), findsNothing);
    },
  );

  testWidgets('clicking outside server settings dismisses the panel', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authService: _FakeAuthService()));
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-settings-open-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('server-settings-workspace')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(24, 160));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('server-settings-workspace')),
      findsNothing,
    );
  });

  testWidgets('missing welcome channel selection falls back to none', (
    tester,
  ) async {
    final data = _realSettingsData.copyWith(
      server: _realSettingsData.server.copyWith(
        welcomeChannelId: '176495822366048257',
      ),
    );
    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        serverSettingsRepository: _FakeServerSettingsRepository(data: data),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('server-settings-open-button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const ValueKey('server-settings-welcome-channel-field')),
    );
    expect(dropdown.initialValue, '');
  });

  testWidgets('server workspace renders allowed banner and icon media', (
    tester,
  ) async {
    const origin = 'https://cdn.pryzmapp.com';
    final requestedPaths = <String>[];
    debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
      requestedPaths.add(uri.path);
      if (uri.path.startsWith('/cdn-cgi/image/')) {
        throw const ServerMediaLoadException(
          'Media request failed: HTTP 400',
          statusCode: 400,
        );
      }
      return uri.path.endsWith('.webp') ? _webpBytes : _pngBytes;
    });
    addTearDown(() => debugSetServerMediaWidgetLoader(null));
    final data = _realSettingsData.copyWith(
      server: _realSettingsData.server.copyWith(
        iconUrl: '$origin/server-icons/123/icon.png',
        bannerUrl: '$origin/server-banners/123/banner.webp',
      ),
      mediaPolicy: ServerMediaPolicy.fromOrigins(apiOrigin: officialApiOrigin),
    );

    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        serverSettingsRepository: _FakeServerSettingsRepository(data: data),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('server-banner-media-image')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('server-icon-media-image')), findsWidgets);
    expect(
      requestedPaths.any((path) => path.startsWith('/cdn-cgi/image/')),
      isTrue,
    );
    expect(
      requestedPaths.any((path) => path.startsWith('/server-banners/')),
      isTrue,
    );
    expect(
      requestedPaths.any((path) => path.startsWith('/server-icons/')),
      isTrue,
    );
  });

  testWidgets(
    'workspace media warm budget releases the workspace when visible assets stall',
    (tester) async {
      final credentialStore = _MemoryCredentialStore();
      final diagnostics = _RecordingAuthDiagnostics();
      await _saveOfficialCredential(credentialStore);

      final stalledMedia = Completer<Uint8List>();
      final requestedPaths = <String>[];
      debugSetServerMediaWidgetLoader((uri, {required policy, maxBytes}) async {
        requestedPaths.add(uri.path);
        return stalledMedia.future;
      });
      addTearDown(() {
        if (!stalledMedia.isCompleted) {
          stalledMedia.complete(Uint8List.fromList(_webpBytes));
        }
        debugSetServerMediaWidgetLoader(null);
      });

      const origin = 'https://cdn.pryzmapp.com';
      final data = _realSettingsData.copyWith(
        server: _realSettingsData.server.copyWith(
          iconUrl: '$origin/server-icons/123/icon.webp',
          bannerUrl: '$origin/server-banners/123/banner.webp',
        ),
        members: const [
          ServerSettingsListItemSeed(
            userId: '42',
            title: 'boji',
            subtitle: 'online - joined 2026-06-01',
            trailing: 'Owner',
            avatarUrl: '$origin/avatars/boji.webp',
            bannerUrl: '$origin/banners/boji.webp',
            memberListBannerUrl: '$origin/member-list-banners/boji.webp',
          ),
          ServerSettingsListItemSeed(
            userId: '84',
            title: 'avery',
            subtitle: 'online - joined 2026-06-01',
            trailing: 'Member',
            avatarUrl: '$origin/avatars/avery.webp',
            bannerUrl: '$origin/banners/avery.webp',
            memberListBannerUrl: '$origin/member-list-banners/avery.webp',
          ),
        ],
        emojis: const [
          ServerSettingsListItemSeed(
            id: 'emoji-spark',
            title: ':spark:',
            subtitle: 'Static emoji asset',
            trailing: 'PNG',
            avatarUrl: '$origin/bot-avatars/spark.png',
          ),
          ServerSettingsListItemSeed(
            id: 'emoji-heart',
            title: ':heart:',
            subtitle: 'Reaction emoji asset',
            trailing: 'PNG',
            avatarUrl: '$origin/bot-avatars/heart.png',
          ),
        ],
        mediaPolicy: ServerMediaPolicy.fromOrigins(
          apiOrigin: officialApiOrigin,
        ),
      );
      final repository =
          _FakeServerSettingsRepository(
              data: data,
              channelMessages: [
                MessageSeed(
                  id: '321/message-1',
                  authorId: '84',
                  author: 'avery',
                  body: 'Server message from backend :spark:',
                  initials: 'AV',
                  time: '10:00 AM',
                  avatarUrl: '$origin/avatars/message-author.webp',
                  reactions: const [
                    ReactionSeed(
                      emoji: ':heart:',
                      emojiId: 'emoji-heart',
                      count: 2,
                    ),
                  ],
                ),
              ],
            )
            ..currentUserMedia = const ServerSettingsCurrentUserMedia(
              id: '42',
              username: 'boji',
              email: 'boji@example.com',
              avatarUrl: '$origin/avatars/current-user.webp',
              bannerUrl: '$origin/banners/current-user.webp',
              memberListBannerUrl:
                  '$origin/member-list-banners/current-user.webp',
            );

      await tester.pumpWidget(
        _testApp(
          authService: _FakeAuthService(),
          credentialStore: credentialStore,
          authDiagnostics: diagnostics,
          serverSettingsRepository: repository,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Loading workspace...'), findsOneWidget);
      expect(find.text('Message #general'), findsNothing);
      expect(requestedPaths, isNotEmpty);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      expect(find.text('Loading workspace...'), findsNothing);
      expect(find.text('Message #general'), findsOneWidget);
      final readyEvents = diagnostics.events
          .where(
            (event) =>
                event.name == 'workspace.media.warm.ready' &&
                event.fields['blocking'] == true,
          )
          .toList(growable: false);
      expect(readyEvents, isNotEmpty);
      expect(readyEvents.last.fields['completedBeforeBudget'], isFalse);
      expect(readyEvents.last.fields['budgetMs'], 4000);
      final startupSelection = diagnostics.events.lastWhere(
        (event) =>
            event.name == 'workspace.media.warm.selection' &&
            event.fields['reason'] == 'workspace_startup',
      );
      final kindCounts = Map<String, Object?>.from(
        startupSelection.fields['requestCountByKind']! as Map,
      );
      final surfaceCounts = Map<String, Object?>.from(
        startupSelection.fields['requestCountBySurface']! as Map,
      );
      expect(kindCounts['activeServer.banner'], 1);
      expect(kindCounts['activeServer.icon'], 1);
      expect(kindCounts['currentUser.avatar'], 1);
      expect(kindCounts['currentUser.avatarIcon'], 1);
      expect(kindCounts['currentUser.banner'], 1);
      expect(kindCounts['currentUser.memberListBanner'], 1);
      expect(kindCounts['messageAuthor.avatar'], 1);
      expect(kindCounts['messageCustomEmoji.image'], 1);
      expect(kindCounts['messageReactionCustomEmoji.image'], 1);
      expect(surfaceCounts['serverBanner'], 3);
      expect(surfaceCounts['serverIcon'], 2);
      expect(surfaceCounts['image'], 4);
    },
  );

  testWidgets('logout after registration returns to the sign-in panel', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(authService: _FakeAuthService()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('login-show-register-button')),
    );
    await tester.tap(find.byKey(const ValueKey('login-show-register-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('register-email-field')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password-field')),
      'correct horse battery staple',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('register-legal-checkbox')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('register-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Message #general'), findsOneWidget);
    if (find.text('Choose username').evaluate().isNotEmpty) {
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('workspace-logout-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('credentials-form')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-form')), findsNothing);
    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
  });

  testWidgets('adds and selects a saved network from the login panel', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(_testApp(authService: service));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('login-network-selector-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose network'), findsOneWidget);
    expect(find.text('Official'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is VerdantButton &&
            widget.variant == VerdantButtonVariant.secondary &&
            widget.label == 'New API URL',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('login-add-network-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-network-name-field')),
      'Local dev',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-network-origin-field')),
      'https://api-test.pryzmapp.com',
    );
    await tester.tap(find.byKey(const ValueKey('login-network-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Verdant'), findsOneWidget);
    expect(find.text('Local dev'), findsOneWidget);
    expect(find.text('https://api-test.pryzmapp.com'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'boji@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit-button')));
    await tester.pumpAndSettle();

    expect(service.lastApiOrigin, 'https://api-test.pryzmapp.com');
    expect(find.text('Message #general'), findsOneWidget);
  });

  testWidgets('login network selector surfaces identity warnings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        authService: _FakeAuthService(),
        instanceIdentityManifestService: _StaticInstanceIdentityManifestService(
          InstanceManifestIdentity.fromJson({
            'instanceId': 'host:fake.example',
            'registryTrust': 'self_reported',
            'name': 'Official Verdant',
            'domain': 'api.verdant.chat',
            'mode': 'official',
            'apiUrl': officialApiOrigin,
            'publicKeyFingerprint': 'sha256:${'a' * 64}',
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('login-network-selector-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-add-network-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-network-name-field')),
      'Official Verdant',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-network-origin-field')),
      'https://real.community.example',
    );
    await tester.tap(find.byKey(const ValueKey('login-network-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Official Verdant'), findsOneWidget);
    expect(find.text('https://real.community.example'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey(
          'login-network-selector-trust-${networkIdFromApiOrigin('https://real.community.example')}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Warning: https://real.community.example'),
      findsOneWidget,
    );
  });

  testWidgets(
    'network transition removes the previous sign-in fields cleanly',
    (tester) async {
      await tester.pumpWidget(_testApp(authService: _FakeAuthService()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('login-network-selector-button')),
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Choose network'), findsOneWidget);
      expect(find.text('Sign in to Verdant'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.text('Password'), findsNothing);
    },
  );

  testWidgets('creates a new account on the selected network', (tester) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(_testApp(authService: service));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('login-network-selector-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-add-network-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-network-name-field')),
      'Self-host',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-network-origin-field')),
      'https://api.example.com',
    );
    await tester.tap(find.byKey(const ValueKey('login-network-save-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('login-show-register-button')),
    );
    await tester.tap(find.byKey(const ValueKey('login-show-register-button')));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('https://api.example.com'), findsOneWidget);
    expect(find.text('Registration key'), findsNothing);
    expect(
      find.byKey(const ValueKey('register-registration-key-field')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('register-email-field')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password-field')),
      'correct horse battery staple',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password-field')),
      'correct horse battery staple',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-legal-checkbox')),
    );
    await tester.tap(find.byKey(const ValueKey('register-legal-checkbox')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    final autofillFinishFlags = await _captureAutofillFinishFlags(
      tester,
      () async {
        await tester.tap(find.byKey(const ValueKey('register-submit-button')));
        await tester.pumpAndSettle();
      },
    );

    expect(service.lastRegisterApiOrigin, 'https://api.example.com');
    expect(service.lastRegisterEmail, 'new@example.com');
    expect(service.lastRegisterTermsAccepted, isTrue);
    expect(service.lastRegisterPrivacyAccepted, isTrue);
    expect(find.text('Message #general'), findsOneWidget);
    expect(find.text('correct horse battery staple'), findsNothing);
    expect(autofillFinishFlags, contains(false));
    expect(autofillFinishFlags, isNot(contains(true)));
  });

  testWidgets('shows invite-only account creation policy clearly', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      _testApp(
        authService: service,
        instanceMetadataService: const _StaticInstanceMetadataService(
          InstanceRegistrationPolicy.invite,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('login-show-register-button')),
    );
    await tester.tap(find.byKey(const ValueKey('login-show-register-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('register-email-field')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password-field')),
      'correct horse battery staple',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password-field')),
      'correct horse battery staple',
    );
    await tester.tap(find.byKey(const ValueKey('register-legal-checkbox')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('register-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('This network is invite-only for new accounts'),
      findsOneWidget,
    );
    expect(service.lastRegisterApiOrigin, isNull);
    expect(find.text('Message #general'), findsNothing);
  });

  testWidgets(
    'prompts for two factor and finishes sign-in on the same network',
    (tester) async {
      final service = _TwoFactorFakeAuthService();
      await tester.pumpWidget(_testApp(authService: service));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'boji@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'correct horse battery staple',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Two-factor authentication'), findsOneWidget);
      expect(find.text('Message #general'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('login-code-field')),
        '123456',
      );
      final autofillFinishFlags = await _captureAutofillFinishFlags(
        tester,
        () async {
          await tester.tap(
            find.byKey(const ValueKey('login-code-submit-button')),
          );
          await tester.pumpAndSettle();
        },
      );

      expect(service.lastTwoFactorApiOrigin, 'https://api.verdant.chat');
      expect(service.lastTicket, 'ticket-secret');
      expect(service.lastCode, '123456');
      expect(find.text('Message #general'), findsOneWidget);
      expect(find.text('ticket-secret'), findsNothing);
      expect(autofillFinishFlags, contains(false));
      expect(autofillFinishFlags, isNot(contains(true)));
    },
  );
}

Future<List<Object?>> _captureAutofillFinishFlags(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final flags = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.textInput,
    (call) async {
      if (call.method == 'TextInput.finishAutofillContext') {
        flags.add(call.arguments);
      }
      return null;
    },
  );
  try {
    await action();
  } finally {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      null,
    );
    tester.testTextInput.register();
  }
  return flags;
}

final class _FakeFileSelectorPlatform extends FileSelectorPlatform {
  _FakeFileSelectorPlatform({required this.file});

  final XFile? file;
  var openFileCount = 0;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    openFileCount += 1;
    return file;
  }
}

Widget _testApp({
  required AuthService authService,
  AuthCredentialStore? credentialStore,
  NetworkProfileStore? networkProfileStore,
  InstanceIdentityStore? instanceIdentityStore,
  ServerSettingsRepository? serverSettingsRepository,
  ServerSettingsRepository Function(String apiOrigin)?
  serverSettingsRepositoryFactory,
  FederatedMembershipRepository Function(String apiOrigin)?
  federatedMembershipRepositoryFactory,
  FederatedInvitePreviewRepository? federatedInvitePreviewRepository,
  FederatedInviteJoinRepository? federatedInviteJoinRepository,
  DirectMessagesRepository? directMessagesRepository,
  DirectMessagesPreferences? directMessagesPreferences,
  WorkspaceAccessibilitySettingsStore? accessibilitySettingsStore,
  UserSettingsPreferencesStore? userSettingsPreferencesStore,
  AuthDiagnostics authDiagnostics = const SilentAuthDiagnostics(),
  SyncSummaryClient? syncSummaryClient,
  Duration inactiveSummaryPollInterval = const Duration(seconds: 15),
  Duration inactiveWorkspaceIdleTimeout = const Duration(minutes: 5),
  VerdantAppProfile appProfile = VerdantAppProfile.primary,
  InstanceMetadataService instanceMetadataService =
      const _StaticInstanceMetadataService(InstanceRegistrationPolicy.public),
  InstanceIdentityManifestService instanceIdentityManifestService =
      const NoopInstanceIdentityManifestService(),
}) {
  return TooltipVisibility(
    visible: false,
    child: VerdantFlutterApp(
      authService: authService,
      instanceMetadataService: instanceMetadataService,
      instanceIdentityManifestService: instanceIdentityManifestService,
      credentialStore: credentialStore ?? _MemoryCredentialStore(),
      networkProfileStore: networkProfileStore ?? NetworkProfileStore.memory(),
      instanceIdentityStore:
          instanceIdentityStore ??
          InstanceIdentityStore(storage: MemoryNetworkProfileStorage()),
      authDiagnostics: authDiagnostics,
      serverSettingsRepository:
          serverSettingsRepository ??
          _FakeServerSettingsRepository(data: _sampleSettingsData),
      serverSettingsRepositoryFactory: serverSettingsRepositoryFactory,
      federatedMembershipRepositoryFactory:
          federatedMembershipRepositoryFactory ??
          (_) => const _EmptyFederatedMembershipRepository(),
      federatedInvitePreviewRepository: federatedInvitePreviewRepository,
      federatedInviteJoinRepository: federatedInviteJoinRepository,
      directMessagesRepository:
          directMessagesRepository ??
          _FakeDirectMessagesRepository(data: _sampleDirectMessagesData),
      directMessagesPreferences:
          directMessagesPreferences ?? DirectMessagesPreferences.memory(),
      accessibilitySettingsStore:
          accessibilitySettingsStore ??
          WorkspaceAccessibilitySettingsStore.memory(),
      userSettingsPreferencesStore:
          userSettingsPreferencesStore ?? UserSettingsPreferencesStore.memory(),
      syncSummaryClient: syncSummaryClient,
      inactiveSummaryPollInterval: inactiveSummaryPollInterval,
      inactiveWorkspaceIdleTimeout: inactiveWorkspaceIdleTimeout,
      appProfile: appProfile,
    ),
  );
}

Future<void> _settleNetworkSwitch(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _saveOfficialCredential(
  AuthCredentialStore credentialStore,
) async {
  await credentialStore.save(
    const AuthCredentialBundle(
      apiOrigin: officialApiOrigin,
      accessToken: 'official-access-token-not-rendered',
      sessionToken: 'official-session-token-not-rendered',
      user: VerdantUser(
        id: '42',
        username: 'boji',
        email: 'boji@example.com',
        status: 'online',
        usernameSet: true,
        emailVerified: true,
        totpEnabled: false,
      ),
    ),
  );
}

final class _TwoNetworkWorkspaceHarness {
  const _TwoNetworkWorkspaceHarness({
    required this.officialNetworkId,
    required this.testNetworkId,
    required this.testOrigin,
    required this.realtimeRepository,
  });

  final String officialNetworkId;
  final String testNetworkId;
  final String testOrigin;
  final _FakeDirectMessagesRepository realtimeRepository;
}

Future<_TwoNetworkWorkspaceHarness> _pumpTwoNetworkWorkspace(
  WidgetTester tester, {
  Duration inactiveWorkspaceIdleTimeout = const Duration(minutes: 5),
}) async {
  final credentialStore = _MemoryCredentialStore();
  final networkProfileStore = NetworkProfileStore.memory();
  await _saveOfficialCredential(credentialStore);
  const testOrigin = 'https://api-test.pryzmapp.com';
  final officialNetworkId = networkIdFromApiOrigin(officialApiOrigin);
  final testNetworkId = networkIdFromApiOrigin(testOrigin);
  await networkProfileStore.saveProfile(
    name: 'Pryzm Test Self-Host',
    apiOrigin: testOrigin,
  );
  await credentialStore.save(
    const AuthCredentialBundle(
      apiOrigin: testOrigin,
      accessToken: 'selfhost-access-token-not-rendered',
      sessionToken: 'selfhost-session-token-not-rendered',
      user: VerdantUser(
        id: '84',
        username: 'selfhost-user',
        email: 'selfhost@example.com',
        status: 'online',
        usernameSet: true,
        emailVerified: true,
        totpEnabled: false,
      ),
    ),
  );
  final officialRepository = _FakeServerSettingsRepository(
    data: _sampleSettingsData,
  );
  final selfHostRepository = _FakeServerSettingsRepository(
    data: _sampleSettingsDataForNetwork(
      networkId: testNetworkId,
      server: _sampleSettingsData.server.copyWith(
        id: 'selfhost-1',
        name: 'Selfhost Grove',
      ),
    ),
  );
  final realtimeRepository = _FakeDirectMessagesRepository(
    data: _sampleDirectMessagesData,
  );

  await tester.pumpWidget(
    _testApp(
      authService: _FakeAuthService(),
      credentialStore: credentialStore,
      networkProfileStore: networkProfileStore,
      serverSettingsRepository: officialRepository,
      serverSettingsRepositoryFactory: (apiOrigin) {
        return normalizeBackendApiOrigin(apiOrigin) == testOrigin
            ? selfHostRepository
            : officialRepository;
      },
      directMessagesRepository: realtimeRepository,
      inactiveWorkspaceIdleTimeout: inactiveWorkspaceIdleTimeout,
    ),
  );

  await tester.pumpAndSettle();

  return _TwoNetworkWorkspaceHarness(
    officialNetworkId: officialNetworkId,
    testNetworkId: testNetworkId,
    testOrigin: testOrigin,
    realtimeRepository: realtimeRepository,
  );
}

final class _StaticInstanceMetadataService implements InstanceMetadataService {
  const _StaticInstanceMetadataService(this.policy);

  final InstanceRegistrationPolicy policy;

  @override
  Future<InstanceRegistrationPolicy> fetchRegistrationPolicy({
    required String apiOrigin,
  }) async {
    return policy;
  }
}

final class _FailingAuthService implements AuthService {
  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    throw const AuthException('Registration failed');
  }

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) async {
    throw const AuthException('Invalid credentials');
  }

  @override
  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) async {
    throw const AuthRefreshException(
      'Sign in again to continue',
      shouldClearCredentials: true,
    );
  }
}

final class _StaticInstanceIdentityManifestService
    implements InstanceIdentityManifestService {
  const _StaticInstanceIdentityManifestService(this.manifest);

  final InstanceManifestIdentity? manifest;

  @override
  Future<InstanceManifestIdentity?> fetchManifest({
    required String apiOrigin,
  }) async {
    return manifest;
  }
}

final class _FakeAuthService implements AuthService {
  String? lastApiOrigin;
  String? lastRegisterApiOrigin;
  String? lastRegisterEmail;
  bool? lastRegisterTermsAccepted;
  bool? lastRegisterPrivacyAccepted;

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) async {
    lastApiOrigin = apiOrigin;
    return AuthLoginSuccess(
      credentials: AuthCredentialBundle(
        apiOrigin: apiOrigin,
        accessToken: 'access-token-not-rendered',
        sessionToken: 'session-token-not-rendered',
      ),
      session: AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: const VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
  }

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    lastRegisterApiOrigin = apiOrigin;
    lastRegisterEmail = email;
    lastRegisterTermsAccepted = termsAccepted;
    lastRegisterPrivacyAccepted = privacyAccepted;
    return AuthLoginSuccess(
      credentials: AuthCredentialBundle(
        apiOrigin: apiOrigin,
        accessToken: 'register-access-token-not-rendered',
        sessionToken: 'register-session-token-not-rendered',
      ),
      session: AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: const VerdantUser(
          id: '84',
          username: 'new-user',
          email: 'new@example.com',
          status: 'online',
          usernameSet: false,
          emailVerified: true,
          totpEnabled: false,
        ),
      ),
    );
  }

  @override
  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) async {
    return const AuthRefreshResult(
      accessToken: 'refreshed-access-token-not-rendered',
    );
  }
}

final class _RailRefreshFailingAuthService extends _FakeAuthService {
  bool failOfficialRefresh = false;
  final refreshOrigins = <String>[];

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    refreshOrigins.add(normalizedOrigin);
    if (failOfficialRefresh && normalizedOrigin == officialApiOrigin) {
      throw const AuthRefreshException(
        'Could not verify saved session',
        shouldClearCredentials: false,
      );
    }
    return const AuthRefreshResult(
      accessToken: 'refreshed-access-token-not-rendered',
    );
  }
}

final class _DelayedRefreshAuthService extends _FakeAuthService {
  _DelayedRefreshAuthService({required String delayedOrigin})
    : delayedOrigin = normalizeBackendApiOrigin(delayedOrigin);

  final String delayedOrigin;
  final refreshOrigins = <String>[];
  final _refreshCompleter = Completer<AuthRefreshResult>();

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    refreshOrigins.add(normalizedOrigin);
    if (normalizedOrigin == delayedOrigin) {
      return _refreshCompleter.future;
    }
    return super.refreshSession(
      apiOrigin: apiOrigin,
      sessionToken: sessionToken,
    );
  }

  void completeDelayedRefresh() {
    if (_refreshCompleter.isCompleted) {
      return;
    }
    _refreshCompleter.complete(
      const AuthRefreshResult(accessToken: 'delayed-access-token-not-rendered'),
    );
  }
}

final class _TwoFactorFakeAuthService implements AuthService {
  String? lastTwoFactorApiOrigin;
  String? lastTicket;
  String? lastCode;

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) => throw UnimplementedError();

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) async {
    return const AuthLoginRequiresTwoFactor(ticket: 'ticket-secret');
  }

  @override
  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  }) async {
    lastTwoFactorApiOrigin = apiOrigin;
    lastTicket = ticket;
    lastCode = code;
    return AuthLoginSuccess(
      credentials: AuthCredentialBundle(
        apiOrigin: apiOrigin,
        accessToken: 'two-factor-access-token-not-rendered',
        sessionToken: 'two-factor-session-token-not-rendered',
      ),
      session: AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: const VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: true,
        ),
      ),
    );
  }

  @override
  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) => throw UnimplementedError();
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  _MemoryCredentialStore({
    Set<String> clearFailures = const {},
    this.beforeRead,
  }) : _clearFailures = {
         for (final origin in clearFailures) normalizeBackendApiOrigin(origin),
       };

  final _credentials = <String, AuthCredentialBundle>{};
  final Set<String> _clearFailures;
  final Future<void> Function(String apiOrigin)? beforeRead;

  @override
  Future<void> clear(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    if (_clearFailures.contains(normalizedOrigin)) {
      throw const AuthException('Could not clear credentials');
    }
    _credentials.remove(normalizedOrigin);
  }

  @override
  Future<bool> contains(String apiOrigin) async {
    return _credentials.containsKey(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    await beforeRead?.call(normalizedOrigin);
    return _credentials[normalizedOrigin];
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    _credentials[credentials.normalizedApiOrigin] = credentials;
  }
}

final class _RecordingAuthDiagnostics implements AuthDiagnostics {
  final events = <({String name, Map<String, Object?> fields})>[];

  @override
  void record(String event, Map<String, Object?> fields) {
    events.add((name: event, fields: Map.unmodifiable(fields)));
  }
}

final class _FakeSyncSummaryClient implements SyncSummaryClient {
  _FakeSyncSummaryClient(this.snapshots);

  final Map<String, SyncSummarySnapshot> snapshots;
  final polledOrigins = <String>[];
  final polledCursors = <String?>[];

  @override
  Future<SyncSummarySnapshot> fetchSummary(
    JoinedBackendRuntimeProfile profile, {
    String? since,
  }) async {
    polledOrigins.add(profile.apiOrigin);
    polledCursors.add(since);
    return snapshots[profile.networkId] ??
        const SyncSummarySnapshot(
          cursor: '1800000000000',
          servers: [],
          dms: [],
          notifications: [],
          requiresReconnect: false,
        );
  }
}

final _realSettingsData = ServerSettingsData(
  networkId: 'official',
  server: const ServerSettingsServer(
    id: '123',
    name: 'Actual Verdant',
    ownerId: '42',
    iconUrl: 'https://media.verdant.chat/server-icons/123/icon.webp',
    description: 'Real backend server',
    voiceBitrate: 64000,
    welcomeChannelId: '321',
    announceChannelId: null,
    bannerUrl: 'https://media.verdant.chat/server-banners/123/banner.webp',
    bannerCrop: BannerCrop(x: 10, y: 20, width: 80, height: 45),
    accentColor: '#13eab3',
    bannerOffsetY: 50,
    memberCount: 42,
    large: false,
    createdAt: '2026-06-01T10:00:00Z',
    updatedAt: '2026-06-01T10:00:00Z',
  ),
  channels: const [
    ServerSettingsChannelSeed(id: '321', name: 'general'),
    ServerSettingsChannelSeed(id: '654', name: 'announcements'),
  ],
  emojis: const [
    ServerSettingsListItemSeed(title: ':verdant:', subtitle: 'Created by boji'),
  ],
  invites: const [
    ServerSettingsListItemSeed(
      id: 'realcode',
      title: 'Invite realcode',
      subtitle: 'Created by boji',
      trailing: '2 / unlimited',
      inviteCode: 'realcode',
      inviterUsername: 'boji',
      inviteUses: 2,
    ),
  ],
  roles: const [
    ServerSettingsListItemSeed(
      id: 'admin-role',
      title: 'Admin',
      subtitle: '8 permissions',
      trailing: '#13eab3',
      accent: Color(0xFF13EAB3),
      permissions: 8,
      position: 1,
    ),
  ],
  members: const [
    ServerSettingsListItemSeed(
      userId: '42',
      title: 'boji',
      subtitle: 'online - joined 2026-06-01',
      trailing: 'Owner',
    ),
  ],
  auditEvents: const [
    ServerSettingsListItemSeed(
      title: 'boji updated server settings',
      subtitle: '2026-06-01T11:00:00Z',
    ),
  ],
  feeds: const [],
  bots: const [],
);

const _sampleSettingsData = ServerSettingsData(
  networkId: 'official',
  server: ServerSettingsServer(
    id: 'fake-server-1',
    name: 'Verdant',
    ownerId: '42',
    iconUrl: null,
    description: 'Flutter parity workspace',
    voiceBitrate: 64000,
    welcomeChannelId: 'fake-channel-general',
    announceChannelId: null,
    bannerUrl: null,
    bannerCrop: null,
    accentColor: '#13eab3',
    bannerOffsetY: 50,
    memberCount: 2,
    large: false,
    createdAt: '2026-06-01T10:00:00Z',
    updatedAt: '2026-06-01T10:00:00Z',
  ),
  channels: [
    ServerSettingsChannelSeed(id: 'fake-channel-general', name: 'general'),
    ServerSettingsChannelSeed(
      id: 'fake-channel-change-logs',
      name: 'change-logs',
    ),
    ServerSettingsChannelSeed(id: 'fake-channel-bot-test', name: 'bot-test'),
  ],
  emojis: [
    ServerSettingsListItemSeed(
      title: ':verdant:',
      subtitle: 'Static emoji asset',
      trailing: 'PNG',
    ),
  ],
  invites: [
    ServerSettingsListItemSeed(
      id: 'flutter',
      title: 'Invite flutter',
      subtitle: 'Created by Joshy',
      trailing: '12 / unlimited',
      inviteCode: 'flutter',
      inviterUsername: 'Joshy',
      inviteUses: 12,
    ),
  ],
  roles: [
    ServerSettingsListItemSeed(
      title: 'Owner',
      subtitle: 'Full administrative control',
      trailing: '1',
      accent: Color(0xFF7CFFDE),
    ),
    ServerSettingsListItemSeed(
      title: 'Member',
      subtitle: 'Default server access',
      trailing: '1',
      accent: Color(0xFFC1B3FF),
    ),
  ],
  members: [
    ServerSettingsListItemSeed(
      title: 'Joshy',
      subtitle: 'Online - joined 2026-06-01',
      trailing: 'Owner',
      accent: Color(0xFF7CFFDE),
    ),
    ServerSettingsListItemSeed(
      title: 'User 181051381515448320',
      subtitle: 'Idle - joined 2026-06-01',
      trailing: 'Member',
    ),
  ],
  auditEvents: [
    ServerSettingsListItemSeed(
      title: 'Joshy updated server settings',
      subtitle: 'Changed welcome channel to #general',
      trailing: '2m',
    ),
  ],
  feeds: [
    ServerSettingsListItemSeed(
      title: 'Announcements',
      subtitle: 'Posts release notes into #change-logs',
      trailing: 'Active',
    ),
  ],
  bots: [
    ServerSettingsListItemSeed(
      title: 'Verdant Helper',
      subtitle: 'Scoped bot presence',
      trailing: 'Online',
    ),
  ],
);

const _sampleDirectMessagesData = DirectMessagesWorkspaceData(
  networkId: 'official',
  currentUserName: 'boji',
  currentUserInitials: 'BO',
  conversations: [
    DmConversationPreviewSeed(
      channelId: 'official/dm-avery',
      localChannelId: 'dm-avery',
      networkId: 'official',
      displayName: 'Avery',
      initials: 'AV',
      status: 'Online',
      lastMessage: 'Last active 2026-06-02',
      localUserId: '181051381515448321',
    ),
  ],
  friends: [
    FriendPreviewSeed(
      id: 'official/181051381515448321',
      localUserId: '181051381515448321',
      networkId: 'official',
      displayName: 'Avery',
      initials: 'AV',
      status: 'Online',
      detail: 'Friend',
      kind: FriendRelationshipKind.friend,
    ),
    FriendPreviewSeed(
      id: 'official/user-morgan',
      localUserId: 'user-morgan',
      networkId: 'official',
      displayName: 'Morgan',
      initials: 'MO',
      status: 'Pending',
      detail: 'Incoming request',
      kind: FriendRelationshipKind.pendingIncoming,
    ),
  ],
);

ServerSettingsData _sampleSettingsDataForNetwork({
  required String networkId,
  required ServerSettingsServer server,
}) {
  return ServerSettingsData(
    networkId: networkId,
    server: server,
    channels: _sampleSettingsData.channels,
    emojis: _sampleSettingsData.emojis,
    invites: _sampleSettingsData.invites,
    roles: _sampleSettingsData.roles,
    members: _sampleSettingsData.members,
    auditEvents: _sampleSettingsData.auditEvents,
    feeds: _sampleSettingsData.feeds,
    bots: _sampleSettingsData.bots,
    mediaPolicy: _sampleSettingsData.mediaPolicy,
  );
}

final class _FakeDirectMessagesRepository implements DirectMessagesRepository {
  _FakeDirectMessagesRepository({
    required this.data,
    List<Object?> loadDirectMessagesResults = const [],
  }) : _loadDirectMessagesResults = List<Object?>.of(loadDirectMessagesResults);

  DirectMessagesWorkspaceData data;
  final List<Object?> _loadDirectMessagesResults;
  final _realtimeControllers =
      <StreamController<DirectMessagesRealtimeEvent>>[];
  var loadCount = 0;
  var realtimeConnectCount = 0;
  var realtimeCancelCount = 0;
  final sentFriendRequests = <String>[];
  final acceptedLocalUserIds = <String>[];
  final removedLocalUserIds = <String>[];
  final openedLocalUserIds = <String>[];
  final loadedConversationChannelIds = <String>[];
  final savedHiddenChannelIds = <Set<String>>[];
  Set<String> hiddenChannelIds = const {};
  Object? loadHiddenChannelIdsFailure;
  Object? saveHiddenChannelIdsFailure;

  @override
  Future<DirectMessagesWorkspaceData> loadDirectMessages({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
  }) async {
    loadCount += 1;
    if (_loadDirectMessagesResults.isNotEmpty) {
      final result = _loadDirectMessagesResults.removeAt(0);
      if (result is Future<DirectMessagesWorkspaceData>) {
        final resolved = await result;
        return resolved.copyWith(
          currentUserName: currentUserName,
          currentUserInitials: currentUserInitials,
        );
      }
      if (result is DirectMessagesWorkspaceData) {
        return result.copyWith(
          currentUserName: currentUserName,
          currentUserInitials: currentUserInitials,
        );
      }
      if (result is DirectMessagesException) {
        throw result;
      }
      if (result is Exception) {
        throw result;
      }
    }
    return data.copyWith(
      currentUserName: currentUserName,
      currentUserInitials: currentUserInitials,
    );
  }

  @override
  Future<Set<String>> loadHiddenChannelIds() async {
    final failure = loadHiddenChannelIdsFailure;
    if (failure is Exception) {
      throw failure;
    }
    if (failure is Error) {
      throw failure;
    }
    return Set<String>.of(hiddenChannelIds);
  }

  @override
  Future<void> saveHiddenChannelIds({required Set<String> channelIds}) async {
    final failure = saveHiddenChannelIdsFailure;
    if (failure is Exception) {
      throw failure;
    }
    if (failure is Error) {
      throw failure;
    }
    hiddenChannelIds = Set<String>.of(channelIds);
    savedHiddenChannelIds.add(Set<String>.of(channelIds));
  }

  @override
  Future<void> sendFriendRequest({required String username}) async {
    final localUserId = 'user-${username.trim().toLowerCase()}';
    sentFriendRequests.add(username);
    data = data.copyWith(
      friends: [
        FriendPreviewSeed(
          id: 'official/$localUserId',
          localUserId: localUserId,
          networkId: 'official',
          displayName: username,
          initials: username.substring(0, 2).toUpperCase(),
          status: 'Sent',
          detail: 'Outgoing request',
          kind: FriendRelationshipKind.pendingOutgoing,
        ),
        ...data.friends,
      ],
    );
  }

  @override
  Future<void> acceptFriendRequest({required String localUserId}) async {
    acceptedLocalUserIds.add(localUserId);
    data = data.copyWith(
      friends: [
        for (final friend in data.friends)
          if (friend.localUserId == localUserId)
            FriendPreviewSeed(
              id: friend.id,
              localUserId: friend.localUserId,
              networkId: friend.networkId,
              displayName: friend.displayName,
              initials: friend.initials,
              status: 'Online',
              detail: 'Friend',
              kind: FriendRelationshipKind.friend,
            )
          else
            friend,
      ],
    );
  }

  @override
  Future<void> removeRelationship({required String localUserId}) async {
    removedLocalUserIds.add(localUserId);
    data = data.copyWith(
      friends: [
        for (final friend in data.friends)
          if (friend.localUserId != localUserId) friend,
      ],
    );
  }

  @override
  Future<DmConversationPreviewSeed> openDirectMessage({
    required String localUserId,
    required String currentUserId,
  }) async {
    openedLocalUserIds.add(localUserId);
    final friend = data.friends.firstWhere(
      (row) => row.localUserId == localUserId,
    );
    for (final existing in data.conversations) {
      if (existing.displayName == friend.displayName) {
        return existing;
      }
    }
    final conversation = DmConversationPreviewSeed(
      channelId: 'official/dm-${friend.localUserId}',
      localChannelId: 'dm-${friend.localUserId}',
      networkId: 'official',
      displayName: friend.displayName,
      initials: friend.initials,
      status: friend.status,
      lastMessage: 'No messages yet',
      localUserId: friend.localUserId,
    );
    data = data.copyWith(
      conversations: [
        conversation,
        for (final existing in data.conversations)
          if (existing.channelId != conversation.channelId) existing,
      ],
    );
    return conversation;
  }

  @override
  Future<DmConversationMessages> loadConversationMessages({
    required DmConversationPreviewSeed conversation,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    loadedConversationChannelIds.add(conversation.channelId);
    return DmConversationMessages(
      channelId: conversation.channelId,
      messages: [
        MessageSeed(
          id: '${conversation.channelId}/message-1',
          authorId: '${conversation.networkId}/181051381515448321',
          author: conversation.displayName,
          body: 'Hello from ${conversation.displayName}',
          initials: conversation.initials,
          time: '10:21 AM',
          isOwnMessage: false,
          reactions: const [],
        ),
      ],
    );
  }

  @override
  Stream<DirectMessagesRealtimeEvent> connectRealtime({
    required String currentUserId,
    required String currentUserName,
    required String currentUserInitials,
    required String currentUserStatus,
  }) {
    realtimeConnectCount += 1;
    late final StreamController<DirectMessagesRealtimeEvent> controller;
    controller = StreamController<DirectMessagesRealtimeEvent>(
      onCancel: () {
        realtimeCancelCount += 1;
        _realtimeControllers.remove(controller);
      },
    );
    _realtimeControllers.add(controller);
    return controller.stream;
  }

  int get activeRealtimeSubscriptions => _realtimeControllers.length;

  void emitRealtime(DirectMessagesRealtimeEvent event) {
    for (final controller in List.of(_realtimeControllers)) {
      if (!controller.isClosed) {
        controller.add(event);
      }
    }
  }
}

final class _FakeServerSettingsRepository
    implements
        ServerSettingsRepository,
        ServerSettingsCurrentUserMediaRepository,
        UserSettingsRepository {
  _FakeServerSettingsRepository({
    required ServerSettingsData data,
    this.channelMessages,
    this.listServersFuture,
    this.beforeListServers,
    List<Object?> listServersResults = const [],
    Map<String, Future<void>>? loadServerSettingsDelays,
  }) {
    _data = data;
    _listServersResults = List<Object?>.of(listServersResults);
    _loadServerSettingsDelays = loadServerSettingsDelays ?? {};
  }

  late ServerSettingsData _data;
  final List<MessageSeed>? channelMessages;
  final Future<List<ServerSettingsServer>>? listServersFuture;
  final Future<void> Function()? beforeListServers;
  late final List<Object?> _listServersResults;
  late final Map<String, Future<void>> _loadServerSettingsDelays;
  final loadedServerSettingsIds = <String>[];
  final createdServerNames = <String>[];
  final createdInviteServerIds = <String>[];
  final createdInviteMaxUses = <int?>[];
  final createdInviteExpiresIn = <Duration?>[];
  final revokedInviteCodes = <String>[];
  final leftServerIds = <String>[];
  final previewedInviteCodes = <String>[];
  final acceptedInviteCodes = <String>[];
  final uploadedAvatarFiles = <String>[];
  final uploadedProfileBannerFiles = <String>[];
  final updatedProfileBannerCrops = <BannerCrop>[];
  final uploadedMemberListBannerFiles = <String>[];
  final updatedMemberListBannerCrops = <BannerCrop>[];
  final profilePatches = <Map<String, Object?>>[];
  final setUsernames = <String>[];
  final passwordChanges = <Map<String, String>>[];
  final emailChangeStarts = <Map<String, String>>[];
  final emailChangeConfirmations = <String>[];
  final twoFactorSetupPasswords = <String>[];
  final twoFactorVerifyCodes = <String>[];
  final twoFactorDisablePayloads = <Map<String, String>>[];
  final twoFactorRegeneratePayloads = <Map<String, String>>[];
  List<UserSettingsNotificationPreference> notificationPreferences = const [
    UserSettingsNotificationPreference.globalDefault,
  ];
  TwoFactorStatus twoFactorStatus = const TwoFactorStatus(
    enabled: false,
    enabledAt: null,
    remainingBackupCodes: 0,
  );
  ServerSettingsCurrentUserMedia currentUserMedia =
      const ServerSettingsCurrentUserMedia(
        id: '42',
        username: 'boji',
        email: 'boji@example.com',
        memberListBannerUrl: null,
        memberListBannerCrop: null,
      );
  var deletedAvatarCount = 0;
  var deletedProfileBannerCount = 0;
  var deletedMemberListBannerCount = 0;

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    await beforeListServers?.call();
    if (_listServersResults.isNotEmpty) {
      final next = _listServersResults.removeAt(0);
      if (next == null) {
        return [_data.server];
      }
      if (next is ServerSettingsException) {
        throw next;
      }
      if (next is Exception) {
        throw next;
      }
      if (next is Future<List<ServerSettingsServer>>) {
        return next;
      }
      if (next is List<ServerSettingsServer>) {
        return next;
      }
      throw StateError('Unsupported listServers test result: $next');
    }
    final pending = listServersFuture;
    if (pending != null) {
      return pending;
    }
    return [_data.server];
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    loadedServerSettingsIds.add(server.id);
    final delay = _loadServerSettingsDelays[server.id];
    if (delay != null) {
      await delay;
    }
    return _data.copyWith(server: server);
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final seededMessages = channelMessages;
    if (seededMessages != null) {
      return seededMessages;
    }
    return [
      MessageSeed(
        id: '$channelId/message-1',
        authorId: currentUserId,
        author: 'Joshy',
        body: 'Server message from backend',
        initials: 'JO',
        time: '10:00 AM',
        isOwnMessage: true,
        reactions: const [],
      ),
    ];
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) async {
    createdServerNames.add(name);
    final server = _data.server.copyWith(id: 'created-server', name: name);
    _data = _data.copyWith(server: server);
    return server;
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    createdInviteServerIds.add(serverId);
    createdInviteMaxUses.add(maxUses);
    createdInviteExpiresIn.add(expiresIn);
    const invite = ServerSettingsListItemSeed(
      id: 'newcode',
      title: 'Invite newcode',
      subtitle: 'Created by Joshy',
      trailing: '0 / unlimited',
      inviteCode: 'newcode',
      inviterUsername: 'Joshy',
      inviteUses: 0,
    );
    _data = _data.copyWith(invites: [invite, ..._data.invites]);
    return invite;
  }

  @override
  Future<void> revokeInvite({
    required String serverId,
    required String code,
  }) async {
    revokedInviteCodes.add(code);
    _data = _data.copyWith(
      invites: [
        for (final invite in _data.invites)
          if ((invite.inviteCode ?? invite.id) != code) invite,
      ],
    );
  }

  @override
  Future<void> leaveServer({required String serverId}) async {
    leftServerIds.add(serverId);
  }

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) async {
    previewedInviteCodes.add(code);
    return ServerInvitePreview(
      code: code,
      server: _data.server.copyWith(id: 'joined-server', name: 'Joined Server'),
      inviterUsername: 'Avery',
      isMember: false,
    );
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) async {
    acceptedInviteCodes.add(code);
    final server = _data.server.copyWith(
      id: 'joined-server',
      name: 'Joined Server',
      memberCount: 8,
    );
    _data = _data.copyWith(server: server);
    return server;
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) async {
    final payload = patch.toJson();
    return _data.server.copyWith(
      name: payload['name'] as String? ?? _data.server.name,
      welcomeChannelId: payload.containsKey('welcomeChannelId')
          ? payload['welcomeChannelId'] as String?
          : _data.server.welcomeChannelId,
    );
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    return _data.server.copyWith(iconUrl: 'https://media.test/icon.webp');
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({
    required String serverId,
  }) async {
    return _data.server.copyWith(iconUrl: null);
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    return _data.server.copyWith(
      bannerUrl: 'https://media.test/banner.webp',
      bannerCrop: null,
    );
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) async {
    return _data.server.copyWith(bannerCrop: crop);
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({
    required String serverId,
  }) async {
    return _data.server.copyWith(bannerUrl: null, bannerCrop: null);
  }

  @override
  Future<ServerSettingsCurrentUserMedia?> loadCurrentUserMedia() async {
    return currentUserMedia;
  }

  @override
  Future<List<UserSettingsSession>> listSessions() async {
    return [
      UserSettingsSession(
        id: 'current-session',
        isCurrent: true,
        device: 'Verdant Desktop',
        createdAt: DateTime.utc(2026, 6, 15, 10),
        lastRefreshAt: DateTime.utc(2026, 6, 15, 10, 5),
      ),
    ];
  }

  @override
  Future<void> revokeSession({required String sessionId}) async {}

  @override
  Future<void> revokeAllOtherSessions() async {}

  @override
  Future<List<UserSettingsNotificationPreference>>
  listNotificationPreferences() async {
    return notificationPreferences;
  }

  @override
  Future<void> saveNotificationPreference({
    required UserSettingsNotificationPreference preference,
  }) async {
    notificationPreferences = [
      for (final existing in notificationPreferences)
        if (!existing.hasSameTarget(preference)) existing,
      preference,
    ];
  }

  @override
  Future<TwoFactorStatus> loadTwoFactorStatus() async {
    return twoFactorStatus;
  }

  @override
  Future<TwoFactorSetup> startTwoFactorSetup({
    required String currentPassword,
  }) async {
    twoFactorSetupPasswords.add(currentPassword);
    return const TwoFactorSetup(
      secret: 'otpauth-secret-not-rendered-by-default',
      qrDataUrl: 'data:image/png;base64,abc',
    );
  }

  @override
  Future<TwoFactorVerification> verifyTwoFactorSetup({
    required String code,
  }) async {
    twoFactorVerifyCodes.add(code);
    twoFactorStatus = TwoFactorStatus(
      enabled: true,
      enabledAt: DateTime.utc(2026, 6, 6),
      remainingBackupCodes: 8,
    );
    return const TwoFactorVerification(
      enabled: true,
      backupCodes: ['backup-1', 'backup-2'],
    );
  }

  @override
  Future<TwoFactorBackupCodes> regenerateTwoFactorBackupCodes({
    required String currentPassword,
    required String totpCode,
  }) async {
    twoFactorRegeneratePayloads.add({
      'currentPassword': currentPassword,
      'totpCode': totpCode,
    });
    return const TwoFactorBackupCodes(backupCodes: ['backup-3', 'backup-4']);
  }

  @override
  Future<void> disableTwoFactor({
    required String currentPassword,
    required String code,
  }) async {
    twoFactorDisablePayloads.add({
      'currentPassword': currentPassword,
      'code': code,
    });
    twoFactorStatus = const TwoFactorStatus(
      enabled: false,
      enabledAt: null,
      remainingBackupCodes: 0,
    );
  }

  @override
  Future<ServerSettingsCurrentUserMedia> updateCurrentUserProfile({
    required UserProfilePatch patch,
  }) async {
    final payload = patch.toJson();
    profilePatches.add(payload);
    currentUserMedia = currentUserMedia.copyWith(
      displayName: payload.containsKey('displayName')
          ? payload['displayName'] as String?
          : currentUserMedia.displayName,
      bio: payload.containsKey('bio')
          ? payload['bio'] as String?
          : currentUserMedia.bio,
      bannerBaseColor: payload.containsKey('bannerBaseColor')
          ? _profileHexColor(payload['bannerBaseColor'] as String?)
          : currentUserMedia.bannerBaseColor,
    );
    return currentUserMedia;
  }

  @override
  Future<ServerSettingsCurrentUserMedia> changeCurrentUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordChanges.add({
      'currentPassword': currentPassword,
      'password': newPassword,
    });
    return currentUserMedia;
  }

  @override
  Future<VerdantUser> setCurrentUsername({required String username}) async {
    setUsernames.add(username);
    currentUserMedia = currentUserMedia.copyWith(
      username: username,
      usernameSet: true,
    );
    return VerdantUser(
      id: currentUserMedia.id,
      username: username,
      displayName: currentUserMedia.displayName,
      email: currentUserMedia.email ?? '',
      avatarUrl: currentUserMedia.avatarUrl,
      bannerUrl: currentUserMedia.bannerUrl,
      memberListBannerUrl: currentUserMedia.memberListBannerUrl,
      bio: currentUserMedia.bio,
      status: currentUserMedia.status ?? 'online',
      usernameSet: true,
      emailVerified: currentUserMedia.emailVerified ?? true,
      totpEnabled: currentUserMedia.totpEnabled ?? false,
    );
  }

  @override
  Future<EmailChangeStartResult> startCurrentUserEmailChange({
    required String currentEmail,
    required String newEmail,
    required String currentPassword,
  }) async {
    emailChangeStarts.add({
      'currentEmail': currentEmail,
      'newEmail': newEmail,
      'currentPassword': currentPassword,
    });
    return const EmailChangeStartResult(codeSent: true, has2fa: false);
  }

  @override
  Future<void> confirmCurrentUserEmailChange({required String code}) async {
    emailChangeConfirmations.add(code);
  }

  @override
  Future<UserAvatarUpdate> uploadUserAvatar({
    required ServerSettingsUpload upload,
  }) async {
    uploadedAvatarFiles.add(upload.fileName);
    return const UserAvatarUpdate(avatarUrl: 'https://media.test/avatar.webp');
  }

  @override
  Future<UserAvatarUpdate> deleteUserAvatar() async {
    deletedAvatarCount += 1;
    return const UserAvatarUpdate();
  }

  @override
  Future<UserProfileBannerUpdate> uploadUserProfileBanner({
    required ServerSettingsUpload upload,
  }) async {
    uploadedProfileBannerFiles.add(upload.fileName);
    return const UserProfileBannerUpdate(
      bannerUrl: 'https://media.test/profile-banner.webp',
    );
  }

  @override
  Future<UserProfileBannerUpdate> updateUserProfileBannerCrop({
    required BannerCrop crop,
  }) async {
    updatedProfileBannerCrops.add(crop);
    return UserProfileBannerUpdate(
      bannerUrl: 'https://media.test/profile-banner.webp',
      bannerCrop: crop,
    );
  }

  @override
  Future<UserProfileBannerUpdate> deleteUserProfileBanner() async {
    deletedProfileBannerCount += 1;
    return const UserProfileBannerUpdate();
  }

  @override
  Future<UserMemberListBannerUpdate> uploadMemberListBanner({
    required ServerSettingsUpload upload,
  }) async {
    uploadedMemberListBannerFiles.add(upload.fileName);
    return const UserMemberListBannerUpdate(
      memberListBannerUrl: 'https://media.test/member-list-banner.webp',
    );
  }

  @override
  Future<UserMemberListBannerUpdate> updateMemberListBannerCrop({
    required BannerCrop crop,
  }) async {
    updatedMemberListBannerCrops.add(crop);
    return UserMemberListBannerUpdate(
      memberListBannerUrl: 'https://media.test/member-list-banner.webp',
      memberListBannerCrop: crop,
    );
  }

  @override
  Future<UserMemberListBannerUpdate> deleteMemberListBanner() async {
    deletedMemberListBannerCount += 1;
    return const UserMemberListBannerUpdate();
  }
}

Color? _profileHexColor(String? value) {
  if (value == null || !value.startsWith('#') || value.length != 7) {
    return null;
  }
  final parsed = int.tryParse(value.substring(1), radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/6Xk2kAAAAAASUVORK5CYII=',
);

final _webpBytes = base64Decode(
  'UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AA/vuUAAA=',
);

final class _FakeFederatedInvitePreviewRepository
    implements FederatedInvitePreviewRepository {
  final previewed = <({String apiOrigin, String code})>[];
  FederatedInvitePreviewException? error;

  @override
  Future<ServerInvitePreview> previewInvite({
    required String apiOrigin,
    required String code,
  }) async {
    previewed.add((apiOrigin: apiOrigin, code: code));
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return ServerInvitePreview(
      code: code,
      server: _sampleSettingsData.server.copyWith(
        id: 'federated-server',
        name: 'Federated Server',
      ),
      inviterUsername: 'Avery',
      isMember: false,
      federated: true,
      instanceId: 'host:api-test.pryzmapp.com',
      instanceMode: 'federated',
    );
  }
}

final class _FakeFederatedInviteJoinRepository
    implements FederatedInviteJoinRepository {
  _FakeFederatedInviteJoinRepository({this.credentialStore});

  final AuthCredentialStore? credentialStore;
  final joined =
      <
        ({
          String targetApiOrigin,
          String targetPeerId,
          String serverId,
          String code,
        })
      >[];

  @override
  Future<FederatedInviteJoinResult> joinInvite({
    required String targetApiOrigin,
    required String targetPeerId,
    required String serverId,
    required String code,
  }) async {
    joined.add((
      targetApiOrigin: targetApiOrigin,
      targetPeerId: targetPeerId,
      serverId: serverId,
      code: code,
    ));
    await credentialStore?.save(
      AuthCredentialBundle(
        apiOrigin: targetApiOrigin,
        accessToken: 'target-federated-access-token-not-rendered',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
        user: const VerdantUser(
          id: 'fed_129fa6f4b31ac2c4a38906be',
          username: 'fed_129fa6f4b31ac2c4a38906be',
          email: '',
          status: 'online',
          usernameSet: true,
          emailVerified: false,
          totpEnabled: false,
        ),
      ),
    );
    return const FederatedInviteJoinResult(
      status: FederatedInviteJoinStatus.queued,
      queuedEvents: 2,
    );
  }
}

FederatedClientMembership _federatedMembership({
  required String id,
  required String targetApiOrigin,
  required String targetServerId,
  required String serverName,
}) {
  return FederatedClientMembership.fromJson({
    'id': id,
    'targetPeerId': 'host:federated.example',
    'targetApiOrigin': targetApiOrigin,
    'targetServerId': targetServerId,
    'status': 'active',
    'server': {
      'id': targetServerId,
      'name': serverName,
      'iconUrl': null,
      'bannerUrl': null,
    },
  });
}

final class _FakeFederatedMembershipRepository
    implements FederatedMembershipRepository {
  _FakeFederatedMembershipRepository(this.memberships);

  final List<FederatedClientMembership> memberships;
  final refreshCalls = <String>[];
  var listCalls = 0;

  @override
  Future<List<FederatedClientMembership>> listMemberships() async {
    listCalls += 1;
    return memberships;
  }

  @override
  Future<FederatedMembershipCapabilityResult> refreshCapability({
    required String membershipId,
  }) async {
    refreshCalls.add(membershipId);
    final membership = memberships.singleWhere(
      (candidate) => candidate.id == membershipId,
    );
    return FederatedMembershipCapabilityResult.fromJson({
      'status': 'ready',
      'tokenType': 'federated_client',
      'accessToken': 'target-federated-access',
      'expiresAt': '2099-01-01T00:00:00Z',
      'serverId': membership.targetServerId,
      'user': {
        'id': 'fed_9001',
        'username': 'fed_josh',
        'email': 'fed@example.invalid',
        'status': 'online',
        'usernameSet': true,
        'emailVerified': true,
        'totpEnabled': false,
      },
    });
  }
}

final class _EmptyFederatedMembershipRepository
    implements FederatedMembershipRepository {
  const _EmptyFederatedMembershipRepository();

  @override
  Future<List<FederatedClientMembership>> listMemberships() async => const [];

  @override
  Future<FederatedMembershipCapabilityResult> refreshCapability({
    required String membershipId,
  }) {
    throw UnimplementedError();
  }
}

final class _ExpiredServerSettingsRepository
    implements ServerSettingsRepository {
  const _ExpiredServerSettingsRepository([
    this.message = 'Your session has expired. Please sign in again.',
  ]);

  final String message;

  ServerSettingsException get _error =>
      ServerSettingsException(message, isAuthExpired: true);

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    throw _error;
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    throw _error;
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) async {
    throw _error;
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    throw _error;
  }

  @override
  Future<void> revokeInvite({
    required String serverId,
    required String code,
  }) async {
    throw _error;
  }

  @override
  Future<void> leaveServer({required String serverId}) async {
    throw _error;
  }

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({
    required String serverId,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({
    required String serverId,
  }) async {
    throw _error;
  }
}

final class _NonAuthWorkspaceFailureRepository
    implements ServerSettingsRepository {
  const _NonAuthWorkspaceFailureRepository();

  static const _error = ServerSettingsException(
    'Realtime connection timed out; sign in state unknown.',
  );

  @override
  Future<List<ServerSettingsServer>> listServers() async {
    throw _error;
  }

  @override
  Future<ServerSettingsData> loadServerSettings(
    ServerSettingsServer server,
  ) async {
    throw _error;
  }

  @override
  Future<List<MessageSeed>> loadChannelMessages({
    required String channelId,
    required String currentUserId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> createServer({required String name}) async {
    throw _error;
  }

  @override
  Future<ServerSettingsListItemSeed> createInvite({
    required String serverId,
    int? maxUses,
    Duration? expiresIn,
  }) async {
    throw _error;
  }

  @override
  Future<void> revokeInvite({
    required String serverId,
    required String code,
  }) async {
    throw _error;
  }

  @override
  Future<void> leaveServer({required String serverId}) async {
    throw _error;
  }

  @override
  Future<ServerInvitePreview> previewInvite({required String code}) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> acceptInvite({required String code}) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> updateServer({
    required String serverId,
    required ServerSettingsPatch patch,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> uploadServerIcon({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> deleteServerIcon({
    required String serverId,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> uploadServerBanner({
    required String serverId,
    required ServerSettingsUpload upload,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> updateBannerCrop({
    required String serverId,
    required BannerCrop crop,
  }) async {
    throw _error;
  }

  @override
  Future<ServerSettingsServer> deleteServerBanner({
    required String serverId,
  }) async {
    throw _error;
  }
}
