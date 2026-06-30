import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_controller.dart';
import 'package:verdant_flutter/features/auth/auth_diagnostics.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/instance_identity.dart';
import 'package:verdant_flutter/features/auth/network_profile_store.dart';
import 'package:verdant_flutter/features/auth/auth_service.dart';
import 'package:verdant_flutter/features/auth/instance_metadata_service.dart';

void main() {
  test(
    'login stores credentials securely and keeps the controller redacted',
    () async {
      final credentialStore = _RecordingCredentialStore();
      final diagnostics = _RecordingDiagnostics();
      final service = _RecordingAuthService(
        AuthLoginSuccess(
          credentials: const AuthCredentialBundle(
            apiOrigin: 'https://api.verdant.chat',
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
          session: AuthSession.authenticated(
            apiOrigin: 'https://api.verdant.chat',
            user: const VerdantUser(
              id: '1',
              username: 'boji',
              email: 'boji@example.com',
              status: 'online',
              usernameSet: true,
              emailVerified: true,
              totpEnabled: false,
            ),
          ),
        ),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );
      await controller.initialize();

      await controller.login(
        email: 'boji@example.com',
        password: 'password123',
      );

      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, 'https://api.verdant.chat');
      expect(
        controller.session?.networkId,
        networkIdFromApiOrigin(officialApiOrigin),
      );
      expect(controller.session?.user.username, 'boji');
      expect(service.lastApiOrigin, 'https://api.verdant.chat');
      expect(credentialStore.saved?.apiOrigin, 'https://api.verdant.chat');
      expect(credentialStore.saved?.accessToken, 'access-secret');
      expect(controller.toString(), isNot(contains('access-secret')));
      expect(controller.toString(), isNot(contains('session-secret')));
      expect(controller.session.toString(), contains('redacted'));
      expect(diagnostics.events, contains('auth.signin.start'));
      expect(diagnostics.events, contains('credential.write.success'));
      expect(diagnostics.rendered, isNot(contains('access-secret')));
      expect(diagnostics.rendered, isNot(contains('session-secret')));
    },
  );

  test(
    'initialize refreshes saved credentials before restoring the session',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _RecordingCredentialStore(
        initial: const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
          user: VerdantUser(
            id: '1',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final service = _RefreshRecordingAuthService(
        const AuthRefreshResult(
          accessToken: 'refreshed-access-secret',
          sessionToken: 'rotated-session-secret',
        ),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, 'https://api.verdant.chat');
      expect(
        controller.session?.networkId,
        networkIdFromApiOrigin(officialApiOrigin),
      );
      expect(controller.session?.user.username, 'boji');
      expect(service.lastRefreshApiOrigin, 'https://api.verdant.chat');
      expect(service.lastRefreshSessionToken, 'session-secret');
      expect(credentialStore.saved?.accessToken, 'refreshed-access-secret');
      expect(credentialStore.saved?.sessionToken, 'rotated-session-secret');
      expect(controller.toString(), isNot(contains('access-secret')));
      expect(controller.toString(), isNot(contains('refreshed-access-secret')));
      expect(controller.toString(), isNot(contains('session-secret')));
      expect(controller.toString(), isNot(contains('rotated-session-secret')));
      expect(diagnostics.events, contains('credential.restore.refresh.start'));
      expect(
        diagnostics.events,
        contains('credential.restore.refresh.success'),
      );
      expect(diagnostics.events, contains('credential.restore.success'));
      expect(diagnostics.rendered, isNot(contains('access-secret')));
      expect(diagnostics.rendered, isNot(contains('refreshed-access-secret')));
      expect(diagnostics.rendered, isNot(contains('session-secret')));
      expect(diagnostics.rendered, isNot(contains('rotated-session-secret')));
      expect(diagnostics.rendered, isNot(contains('boji@example.com')));
    },
  );

  test(
    'initialize does not use lone federated client credentials as app auth',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _RecordingCredentialStore(
        initial: const AuthCredentialBundle(
          apiOrigin: selfHostOrigin,
          accessToken: 'federated-access-secret',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: '189385678105911296',
            username: 'Joshy',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final profileStore = NetworkProfileStore.memory();
      await profileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      await profileStore.selectProfile(selfHostOrigin);
      final service = _ThrowingAuthService(
        const AuthException('federated credentials must not refresh'),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: profileStore,
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.selectedNetworkProfile.apiOrigin, officialApiOrigin);
      expect(credentialStore.saved?.kind, AuthCredentialKind.federatedClient);
      expect(credentialStore.saved?.accessToken, 'federated-access-secret');
      expect(
        diagnostics.events,
        isNot(contains('credential.restore.refresh.start')),
      );
      expect(
        diagnostics.events,
        contains('credential.restore.federated.root.skip'),
      );
      expect(
        diagnostics.events,
        isNot(contains('credential.restore.federated.success')),
      );
      expect(diagnostics.rendered, isNot(contains('federated-access-secret')));
    },
  );

  test(
    'initialize restores another saved network when selected credentials are missing',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      await networkProfileStore.selectProfile(selfHostOrigin);
      final service = _RefreshRecordingAuthService(
        const AuthRefreshResult(
          accessToken: 'refreshed-official-access-secret',
          sessionToken: 'rotated-official-session-secret',
        ),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, officialApiOrigin);
      expect(controller.selectedNetworkProfile.apiOrigin, officialApiOrigin);
      expect(service.lastRefreshApiOrigin, officialApiOrigin);
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(await credentialStore.contains(selfHostOrigin), isFalse);
      expect(diagnostics.events, contains('credential.restore.empty'));
      expect(diagnostics.events, contains('credential.restore.success'));
      expect(diagnostics.rendered, isNot(contains('official-access-secret')));
      expect(diagnostics.rendered, isNot(contains('official-session-secret')));
    },
  );

  test(
    'activates a saved network session without clearing another network',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'selfhost-access-secret',
          sessionToken: 'selfhost-session-secret',
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
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      final service = _RefreshRecordingAuthService(
        const AuthRefreshResult(
          accessToken: 'refreshed-selfhost-access-secret',
          sessionToken: 'rotated-selfhost-session-secret',
        ),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: diagnostics,
      );
      await controller.initialize();

      final activated = await controller.activateNetworkSession(selfHostOrigin);

      expect(activated.opened, isTrue);
      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, selfHostOrigin);
      expect(
        controller.session?.networkId,
        networkIdFromApiOrigin(selfHostOrigin),
      );
      expect(controller.session?.user.username, 'community_josh');
      expect(service.lastRefreshApiOrigin, selfHostOrigin);
      expect(service.lastRefreshSessionToken, 'selfhost-session-secret');
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(await credentialStore.contains(selfHostOrigin), isTrue);
      expect(
        (await credentialStore.read(selfHostOrigin))?.accessToken,
        'refreshed-selfhost-access-secret',
      );
      expect(diagnostics.events, contains('network.session.activate.success'));
      expect(diagnostics.rendered, isNot(contains('official-access-secret')));
      expect(diagnostics.rendered, isNot(contains('selfhost-access-secret')));
      expect(diagnostics.rendered, isNot(contains('selfhost-session-secret')));
    },
  );

  test(
    'activates federated invite credentials without target account refresh',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'federated-access-secret',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: '189385678105911296',
            username: 'Joshy',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      final service = _PerOriginRefreshAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: diagnostics,
      );
      await controller.initialize();

      final activated = await controller.activateNetworkSession(selfHostOrigin);

      expect(activated.opened, isTrue);
      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, selfHostOrigin);
      expect(controller.session?.hasAccessToken, isTrue);
      expect(controller.session?.hasSessionToken, isFalse);
      expect(
        controller.session?.credentialKind,
        AuthCredentialKind.federatedClient,
      );
      expect(controller.session?.user.username, 'Joshy');
      expect(service.refreshOrigins, [officialApiOrigin]);
      expect(
        (await credentialStore.read(selfHostOrigin))?.kind,
        AuthCredentialKind.federatedClient,
      );
      expect(
        (await credentialStore.read(selfHostOrigin))?.accessToken,
        'federated-access-secret',
      );
      expect(diagnostics.events, contains('network.session.activate.success'));
      expect(diagnostics.rendered, isNot(contains('federated-access-secret')));
    },
  );

  test(
    'activating a federated network persists the target startup profile',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'federated-access-secret',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: '189385678105911296',
            username: 'Joshy',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      final controller = LoginController(
        authService: _PerOriginRefreshAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();
      expect(controller.session?.apiOrigin, officialApiOrigin);

      final activated = await controller.activateNetworkSession(selfHostOrigin);

      expect(activated.opened, isTrue);
      expect(controller.session?.apiOrigin, selfHostOrigin);
      expect(
        (await networkProfileStore.load()).selectedApiOrigin,
        selfHostOrigin,
      );

      final restartedController = LoginController(
        authService: _PerOriginRefreshAuthService(),
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await restartedController.initialize();

      expect(restartedController.session?.apiOrigin, officialApiOrigin);
      expect(
        (await networkProfileStore.load()).selectedApiOrigin,
        officialApiOrigin,
      );
      expect(await credentialStore.contains(selfHostOrigin), isTrue);
    },
  );

  test(
    'startup keeps home session when selected profile is federated',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'federated-access-secret',
          sessionToken: '',
          kind: AuthCredentialKind.federatedClient,
          user: VerdantUser(
            id: '189385678105911296',
            username: 'Joshy',
            email: '',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      await networkProfileStore.selectProfile(selfHostOrigin);
      final diagnostics = _RecordingDiagnostics();
      final service = _PerOriginRefreshAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.session?.apiOrigin, officialApiOrigin);
      expect(
        controller.session?.credentialKind,
        AuthCredentialKind.userSession,
      );
      expect(controller.selectedNetworkProfile.apiOrigin, officialApiOrigin);
      expect(
        (await networkProfileStore.load()).selectedApiOrigin,
        officialApiOrigin,
      );
      expect(await credentialStore.contains(selfHostOrigin), isTrue);
      expect(service.refreshOrigins, [officialApiOrigin]);
      expect(
        diagnostics.events,
        contains('credential.restore.federated.root.skip'),
      );
    },
  );

  test(
    'activateNetworkSession treats retained refresh failures as unavailable',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _MapCredentialStore();
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'selfhost-access-secret',
          sessionToken: 'selfhost-session-secret',
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
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      final service = _PerOriginRefreshAuthService(
        failures: {
          selfHostOrigin: const AuthRefreshException(
            'Could not verify saved session',
            shouldClearCredentials: false,
          ),
        },
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: diagnostics,
      );
      await controller.initialize();

      final activated = await controller.activateNetworkSession(selfHostOrigin);

      expect(activated.status, NetworkSessionActivationStatus.unavailable);
      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, officialApiOrigin);
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(await credentialStore.contains(selfHostOrigin), isTrue);
      expect(service.refreshOrigins, [officialApiOrigin, selfHostOrigin]);
      expect(diagnostics.events, contains('network.session.activate.failure'));
      expect(diagnostics.events, isNot(contains('credential.clear.success')));
      expect(diagnostics.rendered, isNot(contains('official-access-secret')));
      expect(diagnostics.rendered, isNot(contains('selfhost-access-secret')));
      expect(diagnostics.rendered, isNot(contains('selfhost-session-secret')));
    },
  );

  test(
    'network session activation does not expose login submission state',
    () async {
      final credentialStore = _MapCredentialStore();
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'selfhost-access-secret',
          sessionToken: 'selfhost-session-secret',
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
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      final service = _DelayedRefreshAuthService(selfHostOrigin);
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();
      expect(controller.session?.apiOrigin, officialApiOrigin);

      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });
      final activation = controller.activateNetworkSession(selfHostOrigin);
      await service.refreshStarted;

      expect(controller.isSubmitting, isFalse);
      expect(controller.isActivatingNetworkSession, isTrue);
      expect(notifications, 0);

      service.completeRefresh();
      final activated = await activation;

      expect(activated.opened, isTrue);
      expect(controller.session?.apiOrigin, selfHostOrigin);
      expect(controller.isSubmitting, isFalse);
      expect(controller.isActivatingNetworkSession, isFalse);
      expect(notifications, 1);
    },
  );

  test(
    'initialize clears stale saved credentials after refresh auth rejection',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _RecordingCredentialStore(
        initial: const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'expired-access-secret',
          sessionToken: 'expired-session-secret',
          user: VerdantUser(
            id: '1',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final service = _RefreshThrowingAuthService(
        const AuthRefreshException(
          'Sign in again to continue',
          shouldClearCredentials: true,
        ),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.error, 'Sign in again to continue');
      expect(service.lastRefreshApiOrigin, 'https://api.verdant.chat');
      expect(service.lastRefreshSessionToken, 'expired-session-secret');
      expect(credentialStore.saved, isNull);
      expect(
        diagnostics.events,
        contains('credential.restore.refresh.failure'),
      );
      expect(diagnostics.events, contains('credential.clear.success'));
      expect(diagnostics.events, isNot(contains('credential.restore.success')));
      expect(diagnostics.rendered, isNot(contains('expired-access-secret')));
      expect(diagnostics.rendered, isNot(contains('expired-session-secret')));
      expect(diagnostics.rendered, isNot(contains('boji@example.com')));
    },
  );

  test(
    'initialize retains saved credentials when restore refresh has a non-auth error',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _RecordingCredentialStore(
        initial: const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'retained-access-secret',
          sessionToken: 'retained-session-secret',
          user: VerdantUser(
            id: '1',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final service = _RefreshThrowingAuthService(
        const AuthException('Could not verify saved session'),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.error, 'Could not verify saved session');
      expect(credentialStore.saved?.accessToken, 'retained-access-secret');
      expect(
        diagnostics.events,
        contains('credential.restore.refresh.failure'),
      );
      expect(diagnostics.events, isNot(contains('credential.clear.success')));
      expect(diagnostics.events, isNot(contains('credential.restore.success')));
      expect(diagnostics.rendered, isNot(contains('retained-access-secret')));
      expect(diagnostics.rendered, isNot(contains('retained-session-secret')));
      expect(diagnostics.rendered, isNot(contains('boji@example.com')));
    },
  );

  test(
    'initialize keeps retained credentials visible as a failed restore',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _RecordingCredentialStore(
        initial: const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'retained-access-secret',
          sessionToken: 'retained-session-secret',
          user: VerdantUser(
            id: '1',
            username: 'boji',
            email: 'boji@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );
      final service = _RefreshThrowingAuthService(
        const AuthRefreshException(
          'Could not verify saved session',
          shouldClearCredentials: false,
        ),
      );
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.error, 'Could not verify saved session');
      expect(credentialStore.saved?.accessToken, 'retained-access-secret');
      expect(
        diagnostics.events,
        contains('credential.restore.refresh.failure'),
      );
      expect(diagnostics.events, isNot(contains('credential.clear.success')));
      expect(diagnostics.events, isNot(contains('credential.restore.success')));
      expect(diagnostics.rendered, isNot(contains('retained-access-secret')));
      expect(diagnostics.rendered, isNot(contains('retained-session-secret')));
      expect(diagnostics.rendered, isNot(contains('boji@example.com')));
    },
  );

  test(
    'initialize clears token-only legacy credentials instead of restoring them',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final credentialStore = _RecordingCredentialStore(
        initial: const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'access-secret',
          sessionToken: 'session-secret',
        ),
      );
      final controller = LoginController(
        authService: _ThrowingAuthService(
          const AuthException('network should not be called'),
        ),
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );

      await controller.initialize();

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(credentialStore.saved, isNull);
      expect(diagnostics.events, contains('credential.restore.incomplete'));
      expect(diagnostics.rendered, isNot(contains('access-secret')));
      expect(diagnostics.rendered, isNot(contains('session-secret')));
    },
  );

  test(
    'rejects auth success when returned credentials target another network',
    () async {
      final credentialStore = _RecordingCredentialStore();
      final diagnostics = _RecordingDiagnostics();
      final controller = LoginController(
        authService: _RecordingAuthService(
          AuthLoginSuccess(
            credentials: const AuthCredentialBundle(
              apiOrigin: 'https://evil.example.com',
              accessToken: 'access-secret',
              sessionToken: 'session-secret',
            ),
            session: AuthSession.authenticated(
              apiOrigin: 'https://evil.example.com',
              user: const VerdantUser(
                id: '1',
                username: 'boji',
                email: 'boji@example.com',
                status: 'online',
                usernameSet: true,
                emailVerified: true,
                totpEnabled: false,
              ),
            ),
          ),
        ),
        credentialStore: credentialStore,
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );
      await controller.initialize();

      await controller.login(
        apiOrigin: 'https://api.verdant.chat',
        email: 'boji@example.com',
        password: 'password123',
      );

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.error, 'Auth response origin did not match network');
      expect(credentialStore.saved, isNull);
      expect(diagnostics.events, isNot(contains('credential.write.success')));
      expect(diagnostics.rendered, isNot(contains('access-secret')));
      expect(diagnostics.rendered, isNot(contains('session-secret')));
    },
  );

  test(
    'credential write failure keeps the user on the login surface',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final controller = LoginController(
        authService: _RecordingAuthService(
          AuthLoginSuccess(
            credentials: const AuthCredentialBundle(
              apiOrigin: 'https://api.verdant.chat',
              accessToken: 'access-secret',
              sessionToken: 'session-secret',
            ),
            session: AuthSession.authenticated(
              apiOrigin: 'https://api.verdant.chat',
              user: const VerdantUser(
                id: '1',
                username: 'boji',
                email: 'boji@example.com',
                status: 'online',
                usernameSet: true,
                emailVerified: true,
                totpEnabled: false,
              ),
            ),
          ),
        ),
        credentialStore: _ThrowingCredentialStore(),
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: diagnostics,
      );
      await controller.initialize();

      await controller.login(
        apiOrigin: 'https://api.verdant.chat',
        email: 'boji@example.com',
        password: 'password123',
      );

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.error, 'Could not save credentials securely');
      expect(diagnostics.events, contains('credential.write.failure'));
      expect(diagnostics.events, isNot(contains('credential.write.success')));
    },
  );

  test('missing two-factor ticket fails closed before code entry', () async {
    final controller = LoginController(
      authService: _RecordingAuthService(
        const AuthLoginRequiresTwoFactor(ticket: ''),
      ),
      credentialStore: _RecordingCredentialStore(),
      networkProfileStore: NetworkProfileStore.memory(),
      diagnostics: const SilentAuthDiagnostics(),
    );
    await controller.initialize();

    await controller.login(
      apiOrigin: 'https://api.verdant.chat',
      email: 'boji@example.com',
      password: 'password123',
    );

    expect(controller.step, LoginStep.credentials);
    expect(controller.error, 'Two-factor challenge was missing');
  });

  test('redacting diagnostics strips nested secret material', () {
    final diagnostics = _RecordingDiagnostics();
    final redacting = RedactingAuthDiagnostics(diagnostics);

    redacting.record('auth.debug', {
      'apiOrigin': 'https://api.verdant.chat',
      'password': 'password123',
      'email': 'boji@example.com',
      'nested': {
        'Authorization': 'Bearer access-secret',
        'sessionToken': 'session-secret',
        'safe': 'kept',
      },
      'items': [
        {'ticket': 'two-factor-ticket'},
      ],
      'reason':
          'invalid Bearer embedded-token and jwt abcdefghi.abcdefghi.abcdefghi for boji@example.com',
    });

    final rendered = diagnostics.rendered.toString();
    expect(rendered, contains('https://api.verdant.chat'));
    expect(rendered, contains('kept'));
    expect(rendered, contains('Bearer redacted'));
    expect(rendered, isNot(contains('password123')));
    expect(rendered, isNot(contains('boji@example.com')));
    expect(rendered, isNot(contains('access-secret')));
    expect(rendered, isNot(contains('session-secret')));
    expect(rendered, isNot(contains('embedded-token')));
    expect(rendered, isNot(contains('abcdefghi.abcdefghi.abcdefghi')));
    expect(rendered, isNot(contains('two-factor-ticket')));
  });

  test('debug diagnostics prints sanitized rail busy-ignore events', () {
    final previousDebugPrint = debugPrint;
    final lines = <String>[];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        lines.add(message);
      }
    };

    try {
      const DebugPrintAuthDiagnostics(
        enabled: true,
      ).record('workspace.rail.select.busy_ignore', {
        'networkId': 'origin:https%3A%2F%2Fapi-test.pryzmapp.com',
        'server': 'selfhost-server',
        'reason': 'pending_activation',
        'sessionToken': 'session-secret-not-rendered',
      });
    } finally {
      debugPrint = previousDebugPrint;
    }

    expect(lines, hasLength(1));
    expect(
      lines.single,
      startsWith('verdant.auth workspace.rail.select.busy_ignore '),
    );
    expect(lines.single, contains('pending_activation'));
    expect(lines.single, contains('selfhost-server'));
    expect(lines.single, isNot(contains('session-secret-not-rendered')));
  });

  test(
    'failed login returns to credentials with a safe user-facing error',
    () async {
      final controller = LoginController(
        authService: _ThrowingAuthService(AuthException('Invalid credentials')),
        credentialStore: _RecordingCredentialStore(),
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();

      await controller.login(
        apiOrigin: 'https://api.verdant.chat',
        email: 'boji@example.com',
        password: 'wrong-password',
      );

      expect(controller.step, LoginStep.credentials);
      expect(controller.error, 'Invalid credentials');
      expect(controller.isSubmitting, isFalse);
    },
  );

  test(
    'logout clears the in-memory session and returns to credentials',
    () async {
      final controller = LoginController(
        credentialStore: _RecordingCredentialStore(),
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: const SilentAuthDiagnostics(),
        authService: _RecordingAuthService(
          AuthLoginSuccess(
            credentials: const AuthCredentialBundle(
              apiOrigin: 'https://api.verdant.chat',
              accessToken: 'access-secret',
              sessionToken: 'session-secret',
            ),
            session: AuthSession.authenticated(
              apiOrigin: 'https://api.verdant.chat',
              user: const VerdantUser(
                id: '1',
                username: 'boji',
                email: 'boji@example.com',
                status: 'online',
                usernameSet: true,
                emailVerified: true,
                totpEnabled: false,
              ),
            ),
          ),
        ),
      );
      await controller.initialize();

      await controller.login(
        apiOrigin: 'https://api.verdant.chat',
        email: 'boji@example.com',
        password: 'password123',
      );

      await controller.logout();

      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(controller.error, isNull);
    },
  );

  test(
    'logout restores another saved network instead of dropping the workspace',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'selfhost-access-secret',
          sessionToken: 'selfhost-session-secret',
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
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      await networkProfileStore.selectProfile(selfHostOrigin);
      final service = _PerOriginRefreshAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();
      expect(controller.session?.apiOrigin, selfHostOrigin);

      await controller.logout();

      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, officialApiOrigin);
      expect(controller.selectedNetworkProfile.apiOrigin, officialApiOrigin);
      expect(await credentialStore.contains(selfHostOrigin), isFalse);
      expect(await credentialStore.contains(officialApiOrigin), isTrue);
      expect(service.refreshOrigins, [selfHostOrigin, officialApiOrigin]);
    },
  );

  test(
    'home logout preserves unrelated target federated credentials',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      final credentialStore = _MapCredentialStore();
      await credentialStore.save(
        const AuthCredentialBundle(
          apiOrigin: officialApiOrigin,
          accessToken: 'official-access-secret',
          sessionToken: 'official-session-secret',
          user: VerdantUser(
            id: '1',
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
          apiOrigin: selfHostOrigin,
          accessToken: 'target-federated-access-secret',
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
      final networkProfileStore = NetworkProfileStore.memory();
      await networkProfileStore.saveProfile(
        name: 'Pryzm Test Self-Host',
        apiOrigin: selfHostOrigin,
      );
      final service = _PerOriginRefreshAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: networkProfileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();
      expect(controller.session?.apiOrigin, officialApiOrigin);

      await controller.logout();

      expect(await credentialStore.contains(officialApiOrigin), isFalse);
      expect(await credentialStore.contains(selfHostOrigin), isTrue);
      expect(controller.step, LoginStep.credentials);
      expect(controller.session, isNull);
      expect(service.refreshOrigins, [officialApiOrigin]);
    },
  );

  test(
    'adding a network profile normalizes and selects the API origin',
    () async {
      final profileStore = NetworkProfileStore.memory();
      final controller = LoginController(
        authService: _ThrowingAuthService(const AuthException('not used')),
        credentialStore: _RecordingCredentialStore(),
        networkProfileStore: profileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();

      await controller.addNetworkProfile(
        name: 'Local dev',
        apiOrigin: 'localhost:3000',
      );

      expect(controller.selectedNetworkProfile.name, 'Local dev');
      expect(
        controller.selectedNetworkProfile.apiOrigin,
        'https://localhost:3000',
      );
      expect(
        controller.networkProfiles.map((profile) => profile.name),
        containsAllInOrder(['Official', 'Local dev']),
      );

      final reloaded = await profileStore.load();
      expect(reloaded.selectedProfile.name, 'Local dev');
      expect(reloaded.selectedProfile.apiOrigin, 'https://localhost:3000');
    },
  );

  test(
    'saving a network records self-reported identity against actual origin',
    () async {
      final diagnostics = _RecordingDiagnostics();
      final storage = MemoryNetworkProfileStorage();
      final profileStore = NetworkProfileStore(storage: storage);
      final identityStore = InstanceIdentityStore(storage: storage);
      final manifestService = _StaticInstanceIdentityManifestService(
        InstanceManifestIdentity.fromJson({
          'instanceId': 'host:fake.example',
          'registryTrust': 'self_reported',
          'name': 'Official Verdant',
          'domain': 'api.verdant.chat',
          'mode': 'official',
          'apiUrl': officialApiOrigin,
          'publicKeyFingerprint': 'sha256:${'f' * 64}',
        }),
      );
      final controller = LoginController(
        authService: _ThrowingAuthService(const AuthException('not used')),
        credentialStore: _RecordingCredentialStore(),
        networkProfileStore: profileStore,
        instanceIdentityStore: identityStore,
        instanceIdentityManifestService: manifestService,
        diagnostics: diagnostics,
      );
      await controller.initialize();

      final profile = await controller.addNetworkProfile(
        name: 'Official Verdant',
        apiOrigin: 'https://real.community.example',
      );

      final identity = controller.instanceIdentityFor(profile);
      expect(manifestService.lastApiOrigin, 'https://real.community.example');
      expect(identity?.apiOrigin, 'https://real.community.example');
      expect(identity?.networkId, profile.networkId);
      expect(identity?.trustStatus, InstanceTrustStatus.warning);
      expect(
        identity?.warnings,
        contains(InstanceIdentityWarning.apiOriginMismatch),
      );
      expect(
        identity?.warnings,
        contains(InstanceIdentityWarning.fakeOfficialClaim),
      );
      expect(diagnostics.events, contains('network.identity.recorded'));
      expect(diagnostics.rendered, isNot(contains('access-secret')));
      expect(diagnostics.rendered, isNot(contains('session-secret')));
    },
  );

  test(
    'register creates an account on the selected network and stores credentials',
    () async {
      final profileStore = NetworkProfileStore.memory();
      final credentialStore = _RecordingCredentialStore();
      final service = _RecordingRegistrationAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: profileStore,
        diagnostics: const SilentAuthDiagnostics(),
        instanceMetadataService: const _StaticInstanceMetadataService(
          InstanceRegistrationPolicy.public,
        ),
      );
      await controller.initialize();
      await controller.addNetworkProfile(
        name: 'Self-host',
        apiOrigin: 'https://api.example.com',
      );

      await controller.register(
        email: 'new@example.com',
        password: 'correct horse battery staple',
        termsAccepted: true,
        privacyAccepted: true,
      );

      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, 'https://api.example.com');
      expect(
        controller.session?.networkId,
        networkIdFromApiOrigin('https://api.example.com'),
      );
      expect(service.lastApiOrigin, 'https://api.example.com');
      expect(service.lastEmail, 'new@example.com');
      expect(service.lastTermsAccepted, isTrue);
      expect(service.lastPrivacyAccepted, isTrue);
      expect(credentialStore.saved?.apiOrigin, 'https://api.example.com');
      expect(credentialStore.saved?.accessToken, 'register-access-secret');
      expect(controller.toString(), isNot(contains('register-access-secret')));
      expect(controller.toString(), isNot(contains('register-session-secret')));
    },
  );

  test(
    'register stops before auth when the selected network is invite-only',
    () async {
      final service = _RecordingRegistrationAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: _RecordingCredentialStore(),
        networkProfileStore: NetworkProfileStore.memory(),
        diagnostics: const SilentAuthDiagnostics(),
        instanceMetadataService: const _StaticInstanceMetadataService(
          InstanceRegistrationPolicy.invite,
        ),
      );
      await controller.initialize();

      await controller.register(
        email: 'new@example.com',
        password: 'correct horse battery staple',
        termsAccepted: true,
        privacyAccepted: true,
      );

      expect(controller.step, LoginStep.credentials);
      expect(controller.error, 'This network is invite-only for new accounts');
      expect(service.lastApiOrigin, isNull);
    },
  );

  test(
    'two factor sign-in stores credentials only after the code succeeds',
    () async {
      final profileStore = NetworkProfileStore.memory();
      final credentialStore = _RecordingCredentialStore();
      final service = _TwoFactorAuthService();
      final controller = LoginController(
        authService: service,
        credentialStore: credentialStore,
        networkProfileStore: profileStore,
        diagnostics: const SilentAuthDiagnostics(),
      );
      await controller.initialize();
      await controller.addNetworkProfile(
        name: 'Self-host',
        apiOrigin: 'https://api.example.com',
      );

      await controller.login(
        email: 'boji@example.com',
        password: 'password123',
      );

      expect(controller.step, LoginStep.twoFactor);
      expect(controller.session, isNull);
      expect(credentialStore.saved, isNull);

      await controller.submitCode('123456');

      expect(controller.step, LoginStep.authenticated);
      expect(controller.session?.apiOrigin, 'https://api.example.com');
      expect(service.lastTwoFactorApiOrigin, 'https://api.example.com');
      expect(service.lastTicket, 'ticket-secret');
      expect(service.lastCode, '123456');
      expect(credentialStore.saved?.apiOrigin, 'https://api.example.com');
      expect(credentialStore.saved?.accessToken, 'two-factor-access-secret');
    },
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

final class _StaticInstanceIdentityManifestService
    implements InstanceIdentityManifestService {
  _StaticInstanceIdentityManifestService(this.manifest);

  final InstanceManifestIdentity? manifest;
  String? lastApiOrigin;

  @override
  Future<InstanceManifestIdentity?> fetchManifest({
    required String apiOrigin,
  }) async {
    lastApiOrigin = apiOrigin;
    return manifest;
  }
}

final class _RecordingAuthService implements AuthService {
  _RecordingAuthService(this.outcome);

  final AuthLoginOutcome outcome;
  String? lastApiOrigin;

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
    lastApiOrigin = apiOrigin;
    return outcome;
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
  }) => throw UnimplementedError();
}

final class _RecordingRegistrationAuthService implements AuthService {
  String? lastApiOrigin;
  String? lastEmail;
  bool? lastTermsAccepted;
  bool? lastPrivacyAccepted;

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    lastApiOrigin = apiOrigin;
    lastEmail = email;
    lastTermsAccepted = termsAccepted;
    lastPrivacyAccepted = privacyAccepted;
    return AuthLoginSuccess(
      credentials: AuthCredentialBundle(
        apiOrigin: apiOrigin,
        accessToken: 'register-access-secret',
        sessionToken: 'register-session-secret',
      ),
      session: AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: const VerdantUser(
          id: '7',
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
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) => throw UnimplementedError();

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
  }) => throw UnimplementedError();
}

final class _TwoFactorAuthService implements AuthService {
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
        accessToken: 'two-factor-access-secret',
        sessionToken: 'two-factor-session-secret',
      ),
      session: AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: const VerdantUser(
          id: '8',
          username: 'twofactor',
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

final class _RefreshRecordingAuthService implements AuthService {
  _RefreshRecordingAuthService(this.refresh);

  final AuthRefreshResult refresh;
  String? lastRefreshApiOrigin;
  String? lastRefreshSessionToken;

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
  }) => throw UnimplementedError();

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
    lastRefreshApiOrigin = apiOrigin;
    lastRefreshSessionToken = sessionToken;
    return refresh;
  }
}

final class _RefreshThrowingAuthService implements AuthService {
  _RefreshThrowingAuthService(this.error);

  final Object error;
  String? lastRefreshApiOrigin;
  String? lastRefreshSessionToken;

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
  }) => throw UnimplementedError();

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
    lastRefreshApiOrigin = apiOrigin;
    lastRefreshSessionToken = sessionToken;
    throw error;
  }
}

final class _DelayedRefreshAuthService implements AuthService {
  _DelayedRefreshAuthService(this.delayedOrigin);

  final String delayedOrigin;
  final _refreshStarted = Completer<void>();
  final _refreshResult = Completer<AuthRefreshResult>();

  Future<void> get refreshStarted => _refreshStarted.future;

  void completeRefresh() {
    if (!_refreshResult.isCompleted) {
      _refreshResult.complete(
        AuthRefreshResult(
          accessToken: 'refreshed-${Uri.encodeComponent(delayedOrigin)}',
        ),
      );
    }
  }

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
  }) => throw UnimplementedError();

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
  }) {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    if (normalizedOrigin != delayedOrigin) {
      return Future.value(
        AuthRefreshResult(
          accessToken: 'refreshed-${Uri.encodeComponent(normalizedOrigin)}',
        ),
      );
    }
    if (!_refreshStarted.isCompleted) {
      _refreshStarted.complete();
    }
    return _refreshResult.future;
  }
}

final class _PerOriginRefreshAuthService implements AuthService {
  _PerOriginRefreshAuthService({this.failures = const {}});

  final Map<String, Object> failures;
  final refreshOrigins = <String>[];

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
  }) => throw UnimplementedError();

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
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    refreshOrigins.add(normalizedOrigin);
    final failure = failures[normalizedOrigin];
    if (failure != null) {
      throw failure;
    }
    return AuthRefreshResult(
      accessToken: 'refreshed-${Uri.encodeComponent(normalizedOrigin)}',
    );
  }
}

final class _ThrowingAuthService implements AuthService {
  _ThrowingAuthService(this.error);

  final Object error;

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    throw error;
  }

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) async {
    throw error;
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
    throw error;
  }
}

final class _RecordingCredentialStore implements AuthCredentialStore {
  _RecordingCredentialStore({AuthCredentialBundle? initial}) : saved = initial;

  AuthCredentialBundle? saved;

  @override
  Future<void> clear(String apiOrigin) async {
    if (saved?.apiOrigin == normalizeBackendApiOrigin(apiOrigin)) {
      saved = null;
    }
  }

  @override
  Future<bool> contains(String apiOrigin) async =>
      saved?.apiOrigin == normalizeBackendApiOrigin(apiOrigin);

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async =>
      saved?.apiOrigin == normalizeBackendApiOrigin(apiOrigin) ? saved : null;

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    saved = credentials;
  }
}

final class _MapCredentialStore implements AuthCredentialStore {
  final _credentials = <String, AuthCredentialBundle>{};

  @override
  Future<void> clear(String apiOrigin) async {
    _credentials.remove(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<bool> contains(String apiOrigin) async {
    return _credentials.containsKey(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    return _credentials[normalizeBackendApiOrigin(apiOrigin)];
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    _credentials[credentials.normalizedApiOrigin] = credentials;
  }
}

final class _ThrowingCredentialStore implements AuthCredentialStore {
  @override
  Future<void> clear(String apiOrigin) async {}

  @override
  Future<bool> contains(String apiOrigin) async => false;

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async => null;

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    throw StateError('secure storage unavailable');
  }
}

final class _RecordingDiagnostics implements AuthDiagnostics {
  final events = <String>[];
  final rendered = StringBuffer();

  @override
  void record(String event, Map<String, Object?> fields) {
    events.add(event);
    rendered.write(event);
    rendered.write(fields);
  }
}
