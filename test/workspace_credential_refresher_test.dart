import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/auth_service.dart';
import 'package:verdant_flutter/features/workspace/shared/workspace_credential_refresher.dart';

void main() {
  test('persists rotated session token returned by refresh', () async {
    const origin = 'https://api.verdant.chat';
    final credentials = _credentials(origin, accessToken: 'stale-access');
    final store = _ScopedCredentialStore([credentials]);
    final refresher = WorkspaceCredentialRefresher(
      apiOrigin: origin,
      credentialStore: store,
      authService: _RefreshOnlyAuthService(
        (_, _) async => const AuthRefreshResult(
          accessToken: 'fresh-access',
          sessionToken: 'rotated-session-secret',
        ),
      ),
    );

    final refreshed = await refresher.refresh(credentials);

    expect(refreshed.accessToken, 'fresh-access');
    expect(refreshed.sessionToken, 'rotated-session-secret');
    expect((await store.read(origin))?.accessToken, 'fresh-access');
    expect((await store.read(origin))?.sessionToken, 'rotated-session-secret');
    expect(refreshed.toString(), isNot(contains('rotated-session-secret')));
  });

  test(
    'keeps backend credentials when refresh fails without real auth rejection',
    () async {
      const origin = 'https://api.verdant.chat';
      final credentials = _credentials(origin, accessToken: 'stale-access');
      final store = _ScopedCredentialStore([credentials]);
      final refresher = WorkspaceCredentialRefresher(
        apiOrigin: origin,
        credentialStore: store,
        authService: _RefreshOnlyAuthService(
          (_, _) async => throw const AuthRefreshException(
            'Could not verify saved session',
            shouldClearCredentials: false,
          ),
        ),
      );

      await expectLater(
        refresher.refresh(credentials),
        throwsA(
          isA<WorkspaceCredentialRefreshException>()
              .having((error) => error.isAuthExpired, 'isAuthExpired', isFalse)
              .having(
                (error) => error.message,
                'message',
                'Could not verify saved session',
              ),
        ),
      );

      expect(store.clearOrigins, isEmpty);
      expect((await store.read(origin))?.accessToken, 'stale-access');
    },
  );

  test(
    'clears only the matching backend credential for real refresh auth failure',
    () async {
      const origin = 'https://api.verdant.chat';
      const otherOrigin = 'https://selfhost.example';
      final credentials = _credentials(origin, accessToken: 'stale-access');
      final store = _ScopedCredentialStore([
        credentials,
        _credentials(otherOrigin, accessToken: 'other-access'),
      ]);
      final refresher = WorkspaceCredentialRefresher(
        apiOrigin: origin,
        credentialStore: store,
        authService: _RefreshOnlyAuthService(
          (_, _) async => throw const AuthRefreshException(
            'Sign in again to continue',
            shouldClearCredentials: true,
          ),
        ),
      );

      await expectLater(
        refresher.refresh(credentials),
        throwsA(
          isA<WorkspaceCredentialRefreshException>()
              .having((error) => error.isAuthExpired, 'isAuthExpired', isTrue)
              .having(
                (error) => error.message,
                'message',
                'Sign in again to continue',
              ),
        ),
      );

      expect(store.clearOrigins, [origin]);
      expect(await store.read(origin), isNull);
      expect((await store.read(otherOrigin))?.accessToken, 'other-access');
    },
  );

  test(
    'keeps newer stored credentials when a stale refresh loses rotation race',
    () async {
      const origin = 'https://api.verdant.chat';
      final stale = _credentials(
        origin,
        accessToken: 'stale-access',
        sessionToken: 'stale-session-secret',
      );
      final rotated = _credentials(
        origin,
        accessToken: 'fresh-access',
        sessionToken: 'rotated-session-secret',
      );
      final store = _ScopedCredentialStore([stale]);
      final refresher = WorkspaceCredentialRefresher(
        apiOrigin: origin,
        credentialStore: store,
        authService: _RefreshOnlyAuthService((_, sessionToken) async {
          expect(sessionToken, 'stale-session-secret');
          await store.save(rotated);
          throw const AuthRefreshException(
            'Sign in again to continue',
            shouldClearCredentials: true,
          );
        }),
      );

      final refreshed = await refresher.refresh(stale);

      expect(refreshed.accessToken, 'fresh-access');
      expect(refreshed.sessionToken, 'rotated-session-secret');
      expect(store.clearOrigins, isEmpty);
      expect(
        (await store.read(origin))?.sessionToken,
        'rotated-session-secret',
      );
    },
  );

  test('coalesces concurrent refreshes for the same backend origin', () async {
    const origin = 'https://api.verdant.chat';
    final stale = _credentials(
      origin,
      accessToken: 'stale-access',
      sessionToken: 'stale-session-secret',
    );
    final store = _ScopedCredentialStore([stale]);
    final refreshGate = Completer<void>();
    final refreshSessionTokens = <String>[];
    final authService = _RefreshOnlyAuthService((_, sessionToken) async {
      refreshSessionTokens.add(sessionToken);
      await refreshGate.future;
      return const AuthRefreshResult(
        accessToken: 'fresh-access',
        sessionToken: 'rotated-session-secret',
      );
    });
    final serverSettingsRefresher = WorkspaceCredentialRefresher(
      apiOrigin: origin,
      credentialStore: store,
      authService: authService,
    );
    final directMessagesRefresher = WorkspaceCredentialRefresher(
      apiOrigin: origin,
      credentialStore: store,
      authService: authService,
    );

    final serverRefresh = serverSettingsRefresher.refresh(stale);
    final dmRefresh = directMessagesRefresher.refresh(stale);
    refreshGate.complete();

    final results = await Future.wait([serverRefresh, dmRefresh]);

    expect(refreshSessionTokens, ['stale-session-secret']);
    expect(results.map((bundle) => bundle.accessToken), [
      'fresh-access',
      'fresh-access',
    ]);
    expect(results.map((bundle) => bundle.sessionToken), [
      'rotated-session-secret',
      'rotated-session-secret',
    ]);
    expect(store.clearOrigins, isEmpty);
  });

  test('rejects cross-network refresh bundles before backend egress', () async {
    const origin = 'https://api.verdant.chat';
    const otherOrigin = 'https://selfhost.example';
    final credentials = _credentials(otherOrigin, accessToken: 'other-access');
    var refreshCalls = 0;
    final refresher = WorkspaceCredentialRefresher(
      apiOrigin: origin,
      credentialStore: _ScopedCredentialStore([credentials]),
      authService: _RefreshOnlyAuthService((_, _) async {
        refreshCalls += 1;
        return const AuthRefreshResult(accessToken: 'fresh-access');
      }),
    );

    await expectLater(
      refresher.refresh(credentials),
      throwsA(
        isA<WorkspaceCredentialRefreshException>()
            .having((error) => error.isAuthExpired, 'isAuthExpired', isTrue)
            .having(
              (error) => error.message,
              'message',
              'Stored credentials did not match network',
            ),
      ),
    );

    expect(refreshCalls, 0);
  });

  test(
    'federated client credentials are access-only and are not cleared by refresh',
    () async {
      const origin = 'https://api.selfhost.example';
      final credentials = _credentials(
        origin,
        accessToken: 'federated-access',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
      );
      final store = _ScopedCredentialStore([credentials]);
      var refreshCalls = 0;
      final refresher = WorkspaceCredentialRefresher(
        apiOrigin: origin,
        credentialStore: store,
        authService: _RefreshOnlyAuthService((_, _) async {
          refreshCalls += 1;
          return const AuthRefreshResult(accessToken: 'fresh-access');
        }),
      );

      await expectLater(
        refresher.refresh(credentials),
        throwsA(
          isA<WorkspaceCredentialRefreshException>()
              .having((error) => error.isAuthExpired, 'isAuthExpired', isTrue)
              .having(
                (error) => error.message,
                'message',
                'Federated access expired. Rejoin the server invite to continue.',
              ),
        ),
      );

      expect(refreshCalls, 0);
      expect(store.clearOrigins, isEmpty);
      expect((await store.read(origin))?.accessToken, 'federated-access');
    },
  );

  test(
    'keeps newer federated client credentials when an expired token loses race',
    () async {
      const origin = 'https://api.selfhost.example';
      final stale = _credentials(
        origin,
        accessToken: 'stale-federated-access',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
      );
      final fresh = _credentials(
        origin,
        accessToken: 'fresh-federated-access',
        sessionToken: '',
        kind: AuthCredentialKind.federatedClient,
      );
      final store = _ScopedCredentialStore([stale]);
      final refresher = WorkspaceCredentialRefresher(
        apiOrigin: origin,
        credentialStore: store,
        authService: _RefreshOnlyAuthService((_, _) async {
          await store.save(fresh);
          return const AuthRefreshResult(accessToken: 'unused');
        }),
      );
      await store.save(fresh);

      final result = await refresher.refresh(stale);

      expect(result.accessToken, 'fresh-federated-access');
      expect(result.sessionToken, isEmpty);
      expect(store.clearOrigins, isEmpty);
    },
  );
}

AuthCredentialBundle _credentials(
  String apiOrigin, {
  required String accessToken,
  String sessionToken = 'session-secret',
  AuthCredentialKind kind = AuthCredentialKind.userSession,
}) {
  return AuthCredentialBundle(
    apiOrigin: apiOrigin,
    accessToken: accessToken,
    sessionToken: sessionToken,
    kind: kind,
  );
}

final class _RefreshOnlyAuthService implements AuthService {
  const _RefreshOnlyAuthService(this._refresh);

  final Future<AuthRefreshResult> Function(
    String apiOrigin,
    String sessionToken,
  )
  _refresh;

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) {
    return _refresh(apiOrigin, sessionToken);
  }

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  }) {
    throw UnimplementedError();
  }
}

final class _ScopedCredentialStore implements AuthCredentialStore {
  _ScopedCredentialStore(Iterable<AuthCredentialBundle> credentials) {
    for (final credential in credentials) {
      _credentials[credential.normalizedApiOrigin] = credential;
    }
  }

  final _credentials = <String, AuthCredentialBundle>{};
  final clearOrigins = <String>[];

  @override
  Future<void> clear(String apiOrigin) async {
    final normalized = normalizeBackendApiOrigin(apiOrigin);
    clearOrigins.add(normalized);
    _credentials.remove(normalized);
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
