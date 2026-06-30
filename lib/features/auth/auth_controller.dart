import 'package:flutter/foundation.dart';

import '../../shared/verdant_input_sanitizer.dart';
import 'auth_credentials.dart';
import 'auth_models.dart';
import 'auth_diagnostics.dart';
import 'network_profile_store.dart';
import 'auth_service.dart';
import 'instance_metadata_service.dart';
import 'instance_identity.dart';

enum LoginStep { credentials, twoFactor, verification, authenticated }

final class LoginController extends ChangeNotifier {
  static const _recentRefreshReuseWindow = Duration(seconds: 30);

  LoginController({
    required this.authService,
    AuthCredentialStore? credentialStore,
    NetworkProfileStore? networkProfileStore,
    InstanceMetadataService? instanceMetadataService,
    InstanceIdentityStore? instanceIdentityStore,
    InstanceIdentityManifestService? instanceIdentityManifestService,
    AuthDiagnostics? diagnostics,
  }) : credentialStore = credentialStore ?? FlutterSecureAuthCredentialStore(),
       networkProfileStore = networkProfileStore ?? NetworkProfileStore(),
       instanceMetadataService =
           instanceMetadataService ?? HttpInstanceMetadataService(),
       instanceIdentityStore =
           instanceIdentityStore ??
           InstanceIdentityStore(storage: MemoryNetworkProfileStorage()),
       instanceIdentityManifestService =
           instanceIdentityManifestService ??
           const NoopInstanceIdentityManifestService(),
       diagnostics = RedactingAuthDiagnostics(
         diagnostics ?? const DebugPrintAuthDiagnostics(),
       );

  final AuthService authService;
  final AuthCredentialStore credentialStore;
  final NetworkProfileStore networkProfileStore;
  final InstanceMetadataService instanceMetadataService;
  final InstanceIdentityStore instanceIdentityStore;
  final InstanceIdentityManifestService instanceIdentityManifestService;
  final AuthDiagnostics diagnostics;

  LoginStep _step = LoginStep.credentials;
  bool _isInitializing = true;
  bool _isSubmitting = false;
  bool _isActivatingNetworkSession = false;
  final Map<String, DateTime> _recentRefreshSuccessByOrigin =
      <String, DateTime>{};
  String? _error;
  AuthSession? _session;
  List<NetworkProfile> _networkProfiles = [NetworkProfile.official()];
  NetworkProfile _selectedNetworkProfile = NetworkProfile.official();
  Map<String, InstanceIdentity> _instanceIdentities = const {};
  String? _pendingApiOrigin;
  String? _twoFactorTicket;
  String? _verificationSessionToken;

  LoginStep get step => _step;
  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  bool get isActivatingNetworkSession => _isActivatingNetworkSession;
  String? get error => _error;
  AuthSession? get session => _session;
  List<NetworkProfile> get networkProfiles =>
      List.unmodifiable(_networkProfiles);
  List<InstanceIdentity> get instanceIdentities =>
      List.unmodifiable(_instanceIdentities.values);
  NetworkProfile get selectedNetworkProfile => _selectedNetworkProfile;
  bool get isCodeStep =>
      _step == LoginStep.twoFactor || _step == LoginStep.verification;

  InstanceIdentity? instanceIdentityFor(NetworkProfile profile) {
    return _instanceIdentities[profile.apiOrigin];
  }

  Future<void> initialize() async {
    final watch = Stopwatch()..start();
    _error = null;
    diagnostics.record('auth.initialize.start', {
      'selectedNetworkId': _selectedNetworkProfile.networkId,
      'selectedApiOrigin': _selectedNetworkProfile.apiOrigin,
      'profileCount': _networkProfiles.length,
    });
    try {
      await _reloadNetworkProfiles();
      await _reloadInstanceIdentities();
      final restored = await _restoreAppHomeSession();
      diagnostics.record('auth.initialize.restore.result', {
        'restored': restored,
        'selectedNetworkId': _selectedNetworkProfile.networkId,
        'selectedApiOrigin': _selectedNetworkProfile.apiOrigin,
        'profileCount': _networkProfiles.length,
        'hasSession': _session != null,
        'step': _step.name,
      });
    } on AuthException catch (error) {
      _error = error.message;
      diagnostics.record('auth.initialize.failure', {
        'errorType': error.runtimeType.toString(),
        'message': error.message,
      });
    } catch (_) {
      _error = 'Could not load saved networks';
      diagnostics.record('auth.initialize.failure', {
        'errorType': 'unexpected',
        'message': _error,
      });
    } finally {
      _isInitializing = false;
      diagnostics.record('auth.initialize.complete', {
        'ms': watch.elapsedMilliseconds,
        'selectedNetworkId': _selectedNetworkProfile.networkId,
        'selectedApiOrigin': _selectedNetworkProfile.apiOrigin,
        'profileCount': _networkProfiles.length,
        'hasSession': _session != null,
        'step': _step.name,
        'hasError': _error != null,
      });
      notifyListeners();
    }
  }

  Future<void> selectNetworkProfile(NetworkProfile profile) async {
    await networkProfileStore.selectProfile(profile.apiOrigin);
    await _reloadNetworkProfiles();
    await _reloadInstanceIdentities();
    diagnostics.record('network.profile.selected', {
      'networkId': profile.networkId,
      'apiOrigin': profile.apiOrigin,
    });
    notifyListeners();
  }

  Future<NetworkProfile> addNetworkProfile({
    required String name,
    required String apiOrigin,
  }) async {
    final profile = await networkProfileStore.saveProfile(
      name: sanitizeDisplayNameInput(name, maxLength: 64),
      apiOrigin: sanitizeUrlInput(apiOrigin),
    );
    await _recordInstanceIdentity(profile.apiOrigin);
    await networkProfileStore.selectProfile(profile.apiOrigin);
    await _reloadNetworkProfiles();
    await _reloadInstanceIdentities();
    diagnostics.record('network.profile.saved', {
      'networkId': profile.networkId,
      'apiOrigin': profile.apiOrigin,
    });
    notifyListeners();
    return profile;
  }

  Future<NetworkSessionActivationResult> activateNetworkSession(
    String apiOrigin,
  ) async {
    if (_isSubmitting || _isActivatingNetworkSession) {
      return const NetworkSessionActivationResult.busy(
        'Another network is still opening',
      );
    }
    final normalizedOrigin = normalizeBackendApiOrigin(
      sanitizeUrlInput(apiOrigin),
    );
    if (_session?.apiOrigin == normalizedOrigin) {
      diagnostics.record('network.session.activate.noop', {
        'networkId': networkIdFromApiOrigin(normalizedOrigin),
        'apiOrigin': normalizedOrigin,
        'reason': 'already_active',
      });
      return const NetworkSessionActivationResult.opened();
    }

    final watch = Stopwatch()..start();
    _isActivatingNetworkSession = true;
    _error = null;
    final networkId = networkIdFromApiOrigin(normalizedOrigin);
    diagnostics.record('network.session.activate.start', {
      'networkId': networkId,
      'apiOrigin': normalizedOrigin,
      'currentNetworkId': _session?.networkId,
      'currentApiOrigin': _session?.apiOrigin,
      'currentCredentialKind': _session?.credentialKind.wireName,
      'isSubmitting': _isSubmitting,
      'isNetworkActivating': _isActivatingNetworkSession,
    });

    try {
      await _reloadNetworkProfiles();
      diagnostics.record('network.session.activate.profile_check', {
        'networkId': networkId,
        'apiOrigin': normalizedOrigin,
        'ms': watch.elapsedMilliseconds,
        'profileCount': _networkProfiles.length,
      });
      final profileExists = _networkProfiles.any(
        (profile) => profile.apiOrigin == normalizedOrigin,
      );
      if (!profileExists) {
        _error = 'Save this network before opening it';
        _recordNetworkActivationFailure(
          networkId: networkId,
          apiOrigin: normalizedOrigin,
        );
        return const NetworkSessionActivationResult.unavailable(
          'Save this network before opening it',
        );
      }

      final credentials = await credentialStore.read(normalizedOrigin);
      diagnostics.record('network.session.activate.credentials_check', {
        'networkId': networkId,
        'apiOrigin': normalizedOrigin,
        'ms': watch.elapsedMilliseconds,
        'hasCredentials': credentials != null,
        'credentialKind': credentials?.kind.wireName,
      });
      if (credentials == null) {
        _error = 'Sign in to this network before opening it';
        _recordNetworkActivationFailure(
          networkId: networkId,
          apiOrigin: normalizedOrigin,
        );
        return const NetworkSessionActivationResult.requiresAuth(
          'Sign in to this network before opening it',
        );
      }
      if (credentials.normalizedApiOrigin != normalizedOrigin ||
          credentials.networkId != networkId) {
        await _clearStoredCredentials(
          normalizedOrigin,
          reason: 'network_mismatch',
        );
        _error = 'Stored credentials did not match network';
        _recordNetworkActivationFailure(
          networkId: networkId,
          apiOrigin: normalizedOrigin,
          clearCredentials: true,
        );
        return const NetworkSessionActivationResult.requiresAuth(
          'Stored credentials did not match network',
        );
      }
      final user = credentials.user;
      if (user == null) {
        await _clearStoredCredentials(
          normalizedOrigin,
          reason: 'incomplete_bundle',
        );
        _error = 'Sign in to this network before opening it';
        _recordNetworkActivationFailure(
          networkId: networkId,
          apiOrigin: normalizedOrigin,
          clearCredentials: true,
        );
        return const NetworkSessionActivationResult.requiresAuth(
          'Sign in to this network before opening it',
        );
      }

      final refreshResult = credentials.isFederatedClient
          ? _StoredCredentialRefreshResult.success(credentials.accessToken)
          : await _refreshStoredCredentials(
              apiOrigin: normalizedOrigin,
              networkId: networkId,
              credentials: credentials,
              user: user,
            );
      diagnostics.record('network.session.activate.refresh_result', {
        'networkId': networkId,
        'apiOrigin': normalizedOrigin,
        'ms': watch.elapsedMilliseconds,
        'credentialKind': credentials.kind.wireName,
        'refreshRequired': !credentials.isFederatedClient,
        'status': refreshResult.accessToken == null ? 'failed' : 'ok',
        'requiresAuth': refreshResult.requiresAuth,
      });
      if (refreshResult.accessToken == null) {
        _recordNetworkActivationFailure(
          networkId: networkId,
          apiOrigin: normalizedOrigin,
          clearCredentials: refreshResult.requiresAuth,
        );
        return refreshResult.requiresAuth
            ? NetworkSessionActivationResult.requiresAuth(refreshResult.message)
            : NetworkSessionActivationResult.unavailable(refreshResult.message);
      }

      await networkProfileStore.selectProfile(normalizedOrigin);
      await _reloadNetworkProfiles();
      _session = AuthSession.authenticated(
        apiOrigin: normalizedOrigin,
        user: user,
        hasAccessToken: refreshResult.accessToken!.isNotEmpty,
        hasSessionToken: credentials.hasSessionToken,
        credentialKind: credentials.kind,
      );
      _step = LoginStep.authenticated;
      _pendingApiOrigin = null;
      _twoFactorTicket = null;
      _verificationSessionToken = null;
      diagnostics.record('network.session.activate.success', {
        'networkId': networkId,
        'apiOrigin': normalizedOrigin,
        'ms': watch.elapsedMilliseconds,
        'hasAccessToken': refreshResult.accessToken!.isNotEmpty,
        'hasSessionToken': credentials.hasSessionToken,
      });
      return const NetworkSessionActivationResult.opened();
    } on AuthException catch (error) {
      _error = error.message;
      _recordNetworkActivationFailure(
        networkId: networkId,
        apiOrigin: normalizedOrigin,
      );
      return NetworkSessionActivationResult.unavailable(error.message);
    } catch (_) {
      _error = 'Could not open this network';
      _recordNetworkActivationFailure(
        networkId: networkId,
        apiOrigin: normalizedOrigin,
      );
      return const NetworkSessionActivationResult.unavailable(
        'Could not open this network',
      );
    } finally {
      _isActivatingNetworkSession = false;
      diagnostics.record('network.session.activate.finish', {
        'networkId': networkId,
        'apiOrigin': normalizedOrigin,
        'ms': watch.elapsedMilliseconds,
        'isSubmitting': _isSubmitting,
        'isNetworkActivating': _isActivatingNetworkSession,
        'currentNetworkId': _session?.networkId,
        'currentApiOrigin': _session?.apiOrigin,
        'currentCredentialKind': _session?.credentialKind.wireName,
      });
      notifyListeners();
    }
  }

  Future<void> register({
    String? apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    if (_isSubmitting) {
      return;
    }

    _beginSubmit();
    try {
      if (!termsAccepted || !privacyAccepted) {
        throw const AuthException(
          'Review and accept Terms and Privacy before creating an account',
        );
      }
      final normalizedOrigin = await _prepareSelectedAuthOrigin(
        apiOrigin == null ? null : sanitizeUrlInput(apiOrigin),
      );
      final sanitizedEmail = sanitizeEmailInput(email);
      final registrationPolicy = await instanceMetadataService
          .fetchRegistrationPolicy(apiOrigin: normalizedOrigin);
      diagnostics.record('auth.register.policy', {
        'networkId': networkIdFromApiOrigin(normalizedOrigin),
        'apiOrigin': normalizedOrigin,
        'registration': registrationPolicy.wireName,
      });
      if (!registrationPolicy.allowsAccountCreation) {
        throw AuthException(_accountCreationBlockedMessage(registrationPolicy));
      }
      diagnostics.record('auth.register.start', {
        'networkId': networkIdFromApiOrigin(normalizedOrigin),
        'apiOrigin': normalizedOrigin,
        'path': '/api/auth/register',
      });
      final outcome = await authService.register(
        apiOrigin: normalizedOrigin,
        email: sanitizedEmail,
        password: password,
        termsAccepted: termsAccepted,
        privacyAccepted: privacyAccepted,
      );
      await _applyOutcome(outcome, normalizedOrigin, flow: 'register');
    } on AuthException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Registration failed');
    }
  }

  Future<void> login({
    String? apiOrigin,
    required String email,
    required String password,
  }) async {
    if (_isSubmitting) {
      return;
    }

    _beginSubmit();
    try {
      final normalizedOrigin = await _prepareSelectedAuthOrigin(
        apiOrigin == null ? null : sanitizeUrlInput(apiOrigin),
      );
      final sanitizedEmail = sanitizeEmailInput(email);
      diagnostics.record('auth.signin.start', {
        'networkId': networkIdFromApiOrigin(normalizedOrigin),
        'apiOrigin': normalizedOrigin,
        'path': '/api/auth/login',
      });
      final outcome = await authService.login(
        apiOrigin: normalizedOrigin,
        email: sanitizedEmail,
        password: password,
      );
      await _applyOutcome(outcome, normalizedOrigin, flow: 'signin');
    } on AuthException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Login failed');
    }
  }

  Future<void> submitCode(String code) async {
    if (_isSubmitting) {
      return;
    }

    final normalizedOrigin = _pendingApiOrigin;
    if (normalizedOrigin == null) {
      _fail('Sign in again to continue');
      return;
    }

    _beginSubmit();
    try {
      final outcome = switch (_step) {
        LoginStep.twoFactor => await authService.submitTwoFactor(
          apiOrigin: normalizedOrigin,
          ticket: _twoFactorTicket ?? '',
          code: code,
        ),
        LoginStep.verification => await authService.verifySession(
          apiOrigin: normalizedOrigin,
          sessionToken: _verificationSessionToken ?? '',
          code: code,
        ),
        _ => throw const AuthException('No verification is pending'),
      };
      await _applyOutcome(outcome, normalizedOrigin, flow: 'signin');
    } on AuthException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Verification failed');
    }
  }

  void backToCredentials() {
    _step = LoginStep.credentials;
    _error = null;
    _pendingApiOrigin = null;
    _twoFactorTicket = null;
    _verificationSessionToken = null;
    _isSubmitting = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final apiOrigin = _session?.apiOrigin ?? _selectedNetworkProfile.apiOrigin;
    _isSubmitting = false;
    _error = null;
    _session = null;
    _pendingApiOrigin = null;
    _twoFactorTicket = null;
    _verificationSessionToken = null;

    try {
      await _clearStoredCredentials(apiOrigin);
    } catch (_) {}

    try {
      await _reloadNetworkProfiles();
      final restored = await _restoreAvailableSession(
        excludedApiOrigins: {apiOrigin},
        throwOnSelectedMismatch: false,
        restoreFederatedCredentials: false,
      );
      if (restored) {
        notifyListeners();
        return;
      }
    } catch (_) {}

    _step = LoginStep.credentials;
    notifyListeners();
  }

  void _beginSubmit() {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
  }

  Future<void> _applyOutcome(
    AuthLoginOutcome outcome,
    String apiOrigin, {
    required String flow,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    switch (outcome) {
      case AuthLoginSuccess(:final session, :final credentials):
        _assertSuccessMatchesNetwork(normalizedOrigin, session, credentials);
        diagnostics.record('auth.$flow.response', {
          'networkId': session.networkId,
          'apiOrigin': session.apiOrigin,
          'hasAccessToken': credentials.hasAccessToken,
          'hasSessionToken': credentials.hasSessionToken,
          'requires2fa': false,
          'requiresVerification': false,
        });
        diagnostics.record('credential.write.start', {
          'networkId': session.networkId,
          'apiOrigin': session.apiOrigin,
        });
        try {
          await credentialStore.save(credentials.withUser(session.user));
          _markRecentCredentialRefresh(session.apiOrigin);
        } catch (_) {
          diagnostics.record('credential.write.failure', {
            'networkId': session.networkId,
            'apiOrigin': session.apiOrigin,
          });
          throw const AuthException('Could not save credentials securely');
        }
        diagnostics.record('credential.write.success', {
          'networkId': session.networkId,
          'apiOrigin': session.apiOrigin,
        });
        _session = session.withCredentialKind(credentials.kind);
        _step = LoginStep.authenticated;
        _pendingApiOrigin = null;
        _twoFactorTicket = null;
        _verificationSessionToken = null;
      case AuthLoginRequiresTwoFactor(:final ticket):
        if (ticket.trim().isEmpty) {
          throw const AuthException('Two-factor challenge was missing');
        }
        diagnostics.record('auth.$flow.response', {
          'networkId': networkIdFromApiOrigin(normalizedOrigin),
          'apiOrigin': normalizedOrigin,
          'requires2fa': true,
          'requiresVerification': false,
        });
        _step = LoginStep.twoFactor;
        _pendingApiOrigin = normalizedOrigin;
        _twoFactorTicket = ticket;
        _verificationSessionToken = null;
      case AuthLoginRequiresVerification(:final sessionToken):
        if (sessionToken.trim().isEmpty) {
          throw const AuthException('Verification session was missing');
        }
        diagnostics.record('auth.$flow.response', {
          'networkId': networkIdFromApiOrigin(normalizedOrigin),
          'apiOrigin': normalizedOrigin,
          'requires2fa': false,
          'requiresVerification': true,
        });
        _step = LoginStep.verification;
        _pendingApiOrigin = normalizedOrigin;
        _verificationSessionToken = sessionToken;
        _twoFactorTicket = null;
    }

    _isSubmitting = false;
    _error = null;
    notifyListeners();
  }

  void _assertSuccessMatchesNetwork(
    String apiOrigin,
    AuthSession session,
    AuthCredentialBundle credentials,
  ) {
    if (session.apiOrigin != apiOrigin ||
        credentials.normalizedApiOrigin != apiOrigin ||
        session.networkId != credentials.networkId ||
        session.networkId != networkIdFromApiOrigin(apiOrigin)) {
      throw const AuthException('Auth response origin did not match network');
    }
  }

  Future<bool> _restoreAvailableSession({
    Set<String> excludedApiOrigins = const {},
    bool throwOnSelectedMismatch = true,
    bool restoreFederatedCredentials = true,
  }) async {
    final excludedOrigins = <String>{
      for (final origin in excludedApiOrigins)
        normalizeBackendApiOrigin(origin),
    };
    final selectedProfile = _selectedNetworkProfile;
    final selectedHasFederatedCredentials =
        !excludedOrigins.contains(selectedProfile.apiOrigin) &&
        await _hasFederatedClientCredentials(selectedProfile);
    if (!restoreFederatedCredentials && selectedHasFederatedCredentials) {
      diagnostics.record('credential.restore.federated.root.skip', {
        'networkId': selectedProfile.networkId,
        'apiOrigin': selectedProfile.apiOrigin,
        'reason': 'federated_client_not_app_session',
      });
    }
    String? selectedError;
    if (!excludedOrigins.contains(selectedProfile.apiOrigin) &&
        (restoreFederatedCredentials || !selectedHasFederatedCredentials)) {
      final restored = await _restoreSessionForProfile(
        selectedProfile,
        throwOnMismatch: throwOnSelectedMismatch,
      );
      if (restored) {
        return true;
      }
      selectedError = _error;
    }

    for (final profile in _networkProfiles) {
      if (profile.apiOrigin == selectedProfile.apiOrigin ||
          excludedOrigins.contains(profile.apiOrigin)) {
        continue;
      }
      if (!restoreFederatedCredentials &&
          await _hasFederatedClientCredentials(profile)) {
        diagnostics.record('credential.restore.federated.root.skip', {
          'networkId': profile.networkId,
          'apiOrigin': profile.apiOrigin,
          'reason': 'federated_client_not_app_session',
        });
        continue;
      }
      final restored = await _restoreSessionForProfile(
        profile,
        throwOnMismatch: false,
      );
      if (!restored) {
        continue;
      }
      await networkProfileStore.selectProfile(profile.apiOrigin);
      await _reloadNetworkProfiles();
      _error = null;
      return true;
    }

    if (selectedError != null) {
      _error = selectedError;
    }
    if (selectedHasFederatedCredentials && !selectedProfile.isOfficial) {
      await networkProfileStore.selectProfile(officialApiOrigin);
      await _reloadNetworkProfiles();
      _error = null;
    }
    return false;
  }

  Future<bool> _restoreAppHomeSession() {
    return _restoreAvailableSession(restoreFederatedCredentials: false);
  }

  Future<bool> _hasFederatedClientCredentials(NetworkProfile profile) async {
    try {
      final credentials = await credentialStore.read(profile.apiOrigin);
      return credentials?.isFederatedClient ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _restoreSessionForProfile(
    NetworkProfile profile, {
    required bool throwOnMismatch,
  }) async {
    final apiOrigin = profile.apiOrigin;
    final networkId = networkIdFromApiOrigin(apiOrigin);
    diagnostics.record('credential.restore.start', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
    });

    final credentials = await credentialStore.read(apiOrigin);
    if (credentials == null) {
      diagnostics.record('credential.restore.empty', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
      });
      return false;
    }

    if (credentials.normalizedApiOrigin != apiOrigin ||
        credentials.networkId != networkId) {
      await _clearStoredCredentials(apiOrigin, reason: 'network_mismatch');
      if (throwOnMismatch) {
        throw const AuthException('Stored credentials did not match network');
      }
      _error = 'Stored credentials did not match network';
      return false;
    }

    final user = credentials.user;
    if (user == null) {
      await _clearStoredCredentials(apiOrigin, reason: 'incomplete_bundle');
      diagnostics.record('credential.restore.incomplete', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hasAccessToken': credentials.hasAccessToken,
        'hasSessionToken': credentials.hasSessionToken,
      });
      return false;
    }

    if (credentials.isFederatedClient) {
      _session = AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: user,
        hasAccessToken: credentials.hasAccessToken,
        hasSessionToken: false,
        credentialKind: credentials.kind,
      );
      _step = LoginStep.authenticated;
      diagnostics.record('credential.restore.federated.success', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hasAccessToken': credentials.hasAccessToken,
        'hasSessionToken': false,
        'credentialKind': credentials.kind.wireName,
      });
      return true;
    }

    diagnostics.record('credential.restore.refresh.start', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
      'hasSessionToken': credentials.hasSessionToken,
    });
    final refreshResult = await _refreshStoredCredentials(
      apiOrigin: apiOrigin,
      networkId: networkId,
      credentials: credentials,
      user: user,
    );
    final refreshedAccessToken = refreshResult.accessToken;
    if (refreshedAccessToken == null) {
      return false;
    }

    _session = AuthSession.authenticated(
      apiOrigin: apiOrigin,
      user: user,
      hasAccessToken: refreshedAccessToken.isNotEmpty,
      hasSessionToken: credentials.hasSessionToken,
      credentialKind: credentials.kind,
    );
    _step = LoginStep.authenticated;
    diagnostics.record('credential.restore.success', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
      'hasAccessToken': credentials.hasAccessToken,
      'hasSessionToken': credentials.hasSessionToken,
    });
    return true;
  }

  Future<_StoredCredentialRefreshResult> _refreshStoredCredentials({
    required String apiOrigin,
    required String networkId,
    required AuthCredentialBundle credentials,
    required VerdantUser user,
  }) async {
    if (_canReuseRecentCredentialRefresh(apiOrigin, credentials)) {
      diagnostics.record('credential.restore.refresh.reuse', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'windowMs': _recentRefreshReuseWindow.inMilliseconds,
      });
      return _StoredCredentialRefreshResult.success(credentials.accessToken);
    }

    try {
      final refresh = await authService.refreshSession(
        apiOrigin: apiOrigin,
        sessionToken: credentials.sessionToken,
      );
      await credentialStore.save(
        AuthCredentialBundle(
          apiOrigin: apiOrigin,
          accessToken: refresh.accessToken,
          sessionToken: refresh.sessionTokenOr(credentials.sessionToken),
          user: user,
          kind: credentials.kind,
        ),
      );
      _markRecentCredentialRefresh(apiOrigin);
      diagnostics.record('credential.restore.refresh.success', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'hasAccessToken': refresh.accessToken.isNotEmpty,
        'hasSessionToken': refresh
            .sessionTokenOr(credentials.sessionToken)
            .isNotEmpty,
      });
      return _StoredCredentialRefreshResult.success(refresh.accessToken);
    } on AuthRefreshException catch (error) {
      diagnostics.record('credential.restore.refresh.failure', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'clearCredentials': error.shouldClearCredentials,
      });
      if (error.shouldClearCredentials) {
        await _clearStoredCredentials(
          apiOrigin,
          reason: 'refresh_auth_rejected',
        );
      }
      _error = error.message;
      return _StoredCredentialRefreshResult.failure(
        message: error.message,
        requiresAuth: error.shouldClearCredentials,
      );
    } on AuthException catch (error) {
      diagnostics.record('credential.restore.refresh.failure', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'clearCredentials': false,
      });
      _error = error.message;
      return _StoredCredentialRefreshResult.failure(message: error.message);
    } catch (_) {
      diagnostics.record('credential.restore.refresh.failure', {
        'networkId': networkId,
        'apiOrigin': apiOrigin,
        'clearCredentials': false,
      });
      _error = 'Could not verify saved session';
      return _StoredCredentialRefreshResult.failure(
        message: 'Could not verify saved session',
      );
    }
  }

  void _recordNetworkActivationFailure({
    required String networkId,
    required String apiOrigin,
    bool clearCredentials = false,
  }) {
    diagnostics.record('network.session.activate.failure', {
      'networkId': networkId,
      'apiOrigin': apiOrigin,
      'clearCredentials': clearCredentials,
    });
  }

  Future<void> _clearStoredCredentials(
    String apiOrigin, {
    String reason = 'explicit_logout',
  }) async {
    try {
      _recentRefreshSuccessByOrigin.remove(
        normalizeBackendApiOrigin(apiOrigin),
      );
      await credentialStore.clear(apiOrigin);
      diagnostics.record('credential.clear.success', {
        'networkId': networkIdFromApiOrigin(apiOrigin),
        'apiOrigin': apiOrigin,
        'reason': reason,
      });
    } catch (_) {
      diagnostics.record('credential.clear.failure', {
        'networkId': networkIdFromApiOrigin(apiOrigin),
        'apiOrigin': apiOrigin,
        'reason': reason,
      });
      rethrow;
    }
  }

  bool _canReuseRecentCredentialRefresh(
    String apiOrigin,
    AuthCredentialBundle credentials,
  ) {
    if (credentials.isFederatedClient || credentials.accessToken.isEmpty) {
      return false;
    }
    final refreshedAt = _recentRefreshSuccessByOrigin[apiOrigin];
    if (refreshedAt == null) {
      return false;
    }
    final age = DateTime.now().toUtc().difference(refreshedAt);
    return !age.isNegative && age <= _recentRefreshReuseWindow;
  }

  void _markRecentCredentialRefresh(String apiOrigin) {
    _recentRefreshSuccessByOrigin[normalizeBackendApiOrigin(apiOrigin)] =
        DateTime.now().toUtc();
  }

  Future<String> _prepareSelectedAuthOrigin(String? apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(
      apiOrigin ?? _selectedNetworkProfile.apiOrigin,
    );
    final profileExists = _networkProfiles.any(
      (profile) => profile.apiOrigin == normalizedOrigin,
    );
    if (!profileExists) {
      throw const AuthException('Save this network before signing in');
    }
    await networkProfileStore.selectProfile(normalizedOrigin);
    return normalizedOrigin;
  }

  void _fail(String message) {
    _isSubmitting = false;
    _error = message;
    if (_session == null && !isCodeStep) {
      _step = LoginStep.credentials;
    }
    notifyListeners();
  }

  String _accountCreationBlockedMessage(InstanceRegistrationPolicy policy) {
    return switch (policy) {
      InstanceRegistrationPolicy.invite =>
        'This network is invite-only for new accounts',
      InstanceRegistrationPolicy.disabled =>
        'Account creation is disabled on this network',
      InstanceRegistrationPolicy.unknown =>
        'Could not check account creation for this network',
      InstanceRegistrationPolicy.public => 'Account creation failed',
    };
  }

  Future<void> _reloadNetworkProfiles() async {
    final state = await networkProfileStore.load();
    _networkProfiles = state.profiles;
    _selectedNetworkProfile = state.selectedProfile;
  }

  Future<void> _reloadInstanceIdentities() async {
    final identities = await instanceIdentityStore.load();
    _instanceIdentities = {
      for (final identity in identities) identity.apiOrigin: identity,
    };
  }

  Future<void> _recordInstanceIdentity(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    try {
      final manifest = await instanceIdentityManifestService.fetchManifest(
        apiOrigin: normalizedOrigin,
      );
      final identity = manifest == null
          ? await instanceIdentityStore.recordManifestUnavailable(
              connectedApiOrigin: normalizedOrigin,
            )
          : await instanceIdentityStore.recordSelfReportedManifest(
              connectedApiOrigin: normalizedOrigin,
              manifest: manifest,
            );
      diagnostics.record('network.identity.recorded', {
        'networkId': identity.networkId,
        'apiOrigin': identity.apiOrigin,
        'trustStatus': identity.trustStatus.name,
        'trustSource': identity.trustSource.name,
        'warnings': [for (final warning in identity.warnings) warning.name],
      });
    } on AuthException catch (error) {
      final identity = await instanceIdentityStore.recordManifestUnavailable(
        connectedApiOrigin: normalizedOrigin,
      );
      diagnostics.record('network.identity.warning', {
        'networkId': identity.networkId,
        'apiOrigin': identity.apiOrigin,
        'trustStatus': identity.trustStatus.name,
        'reason': error.message,
      });
    } catch (_) {
      final identity = await instanceIdentityStore.recordManifestUnavailable(
        connectedApiOrigin: normalizedOrigin,
      );
      diagnostics.record('network.identity.warning', {
        'networkId': identity.networkId,
        'apiOrigin': identity.apiOrigin,
        'trustStatus': identity.trustStatus.name,
        'reason': 'unavailable',
      });
    }
  }

  @override
  String toString() {
    return 'LoginController(step: $_step, isSubmitting: $_isSubmitting, '
        'selectedNetwork: ${_selectedNetworkProfile.networkId}, '
        'session: ${_session == null ? 'none' : 'redacted'})';
  }
}

final class _StoredCredentialRefreshResult {
  const _StoredCredentialRefreshResult._({
    this.accessToken,
    this.message,
    this.requiresAuth = false,
  });

  const _StoredCredentialRefreshResult.success(String accessToken)
    : this._(accessToken: accessToken);

  const _StoredCredentialRefreshResult.failure({
    String? message,
    bool requiresAuth = false,
  }) : this._(message: message, requiresAuth: requiresAuth);

  final String? accessToken;
  final String? message;
  final bool requiresAuth;
}
