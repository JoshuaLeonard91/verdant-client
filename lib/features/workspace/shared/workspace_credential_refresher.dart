import 'dart:async';

import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/transport_security.dart';

final class WorkspaceCredentialRefreshException implements Exception {
  const WorkspaceCredentialRefreshException(
    this.message, {
    required this.isAuthExpired,
  });

  final String message;
  final bool isAuthExpired;

  @override
  String toString() => message;
}

final class WorkspaceCredentialRefresher {
  WorkspaceCredentialRefresher({
    required String apiOrigin,
    required this.credentialStore,
    AuthService? authService,
    CertificatePinningPolicy? certificatePinningPolicy,
    Duration timeout = const Duration(seconds: 15),
  }) : _apiOrigin = normalizeBackendApiOrigin(apiOrigin),
       _authService =
           authService ??
           HttpAuthService(
             timeout: timeout,
             certificatePinningPolicy: certificatePinningPolicy,
           ),
       _ownsAuthService = authService == null;

  final String _apiOrigin;
  final AuthCredentialStore credentialStore;
  final AuthService _authService;
  final bool _ownsAuthService;
  static final _refreshLocks = <String, Future<void>>{};

  Future<AuthCredentialBundle> readCredentials() async {
    final credentials = await credentialStore.read(_apiOrigin);
    if (credentials == null || credentials.accessToken.isEmpty) {
      throw const WorkspaceCredentialRefreshException(
        'Sign in again to continue',
        isAuthExpired: true,
      );
    }
    if (credentials.normalizedApiOrigin != _apiOrigin) {
      throw const WorkspaceCredentialRefreshException(
        'Stored credentials did not match network',
        isAuthExpired: true,
      );
    }
    return credentials;
  }

  Future<AuthCredentialBundle> refresh(AuthCredentialBundle stale) async {
    if (stale.normalizedApiOrigin != _apiOrigin) {
      throw const WorkspaceCredentialRefreshException(
        'Stored credentials did not match network',
        isAuthExpired: true,
      );
    }
    return _withRefreshLock(() async {
      final latestBeforeRefresh = await credentialStore.read(_apiOrigin);
      if (_hasNewerStoredCredentials(stale, latestBeforeRefresh)) {
        return latestBeforeRefresh!;
      }
      if (stale.isFederatedClient) {
        throw const WorkspaceCredentialRefreshException(
          'Federated access expired. Rejoin the server invite to continue.',
          isAuthExpired: true,
        );
      }
      if (stale.sessionToken.isEmpty) {
        await credentialStore.clear(_apiOrigin);
        throw const WorkspaceCredentialRefreshException(
          'Sign in again to continue',
          isAuthExpired: true,
        );
      }

      try {
        final refresh = await _authService.refreshSession(
          apiOrigin: _apiOrigin,
          sessionToken: stale.sessionToken,
        );
        final refreshed = AuthCredentialBundle(
          apiOrigin: _apiOrigin,
          accessToken: refresh.accessToken,
          sessionToken: refresh.sessionTokenOr(stale.sessionToken),
          user: stale.user,
          kind: stale.kind,
        );
        await credentialStore.save(refreshed);
        return refreshed;
      } on AuthRefreshException catch (error) {
        if (error.shouldClearCredentials) {
          final latestAfterRejection = await credentialStore.read(_apiOrigin);
          if (_hasNewerStoredCredentials(stale, latestAfterRejection)) {
            return latestAfterRejection!;
          }
          await credentialStore.clear(_apiOrigin);
        }
        throw WorkspaceCredentialRefreshException(
          error.message,
          isAuthExpired: error.shouldClearCredentials,
        );
      } on AuthException catch (error) {
        throw WorkspaceCredentialRefreshException(
          error.message,
          isAuthExpired: false,
        );
      } catch (_) {
        throw const WorkspaceCredentialRefreshException(
          'Could not verify saved session',
          isAuthExpired: false,
        );
      }
    });
  }

  Future<T> _withRefreshLock<T>(Future<T> Function() action) async {
    final previous = _refreshLocks[_apiOrigin];
    final gate = Completer<void>();
    final current = gate.future;
    _refreshLocks[_apiOrigin] = current;
    if (previous != null) {
      await previous.catchError((_) {});
    }
    try {
      return await action();
    } finally {
      if (identical(_refreshLocks[_apiOrigin], current)) {
        _refreshLocks.remove(_apiOrigin);
      }
      gate.complete();
    }
  }

  bool _hasNewerStoredCredentials(
    AuthCredentialBundle stale,
    AuthCredentialBundle? stored,
  ) {
    return stored != null &&
        stored.normalizedApiOrigin == _apiOrigin &&
        stored.accessToken.isNotEmpty &&
        stored.kind == stale.kind &&
        ((stored.isFederatedClient &&
                stored.accessToken != stale.accessToken) ||
            (stored.sessionToken.isNotEmpty &&
                stored.sessionToken != stale.sessionToken));
  }

  void close() {
    if (_ownsAuthService) {
      final service = _authService;
      if (service is HttpAuthService) {
        service.close();
      }
    }
  }
}
