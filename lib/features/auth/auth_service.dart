import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app/client_version.dart';
import '../../shared/verdant_input_sanitizer.dart';
import 'auth_models.dart';
import 'transport_security.dart';

abstract interface class AuthService {
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  });

  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  });

  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  });

  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  });

  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  });
}

final class HttpAuthService implements AuthService {
  HttpAuthService({
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 64 * 1024,
  }) : _certificatePinningPolicy =
           certificatePinningPolicy ??
           CertificatePinningPolicy.fromEnvironment(),
       _httpClient =
           httpClient ??
           (certificatePinningPolicy ??
                   CertificatePinningPolicy.fromEnvironment())
               .createHttpClient();

  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final Duration timeout;
  final int maxResponseBytes;

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    return _authRequest(
      apiOrigin: apiOrigin,
      path: '/api/auth/register',
      defaultFailureMessage: 'Account creation failed',
      body: {
        'email': sanitizeEmailInput(email),
        'password': password,
        'termsAccepted': termsAccepted,
        'privacyAccepted': privacyAccepted,
      },
    );
  }

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) async {
    return _authRequest(
      apiOrigin: apiOrigin,
      path: '/api/auth/login',
      defaultFailureMessage: 'Login failed',
      body: {'email': sanitizeEmailInput(email), 'password': password},
    );
  }

  @override
  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  }) {
    return _authRequest(
      apiOrigin: apiOrigin,
      path: '/api/auth/login/2fa',
      defaultFailureMessage: 'Verification failed',
      body: {'twoFactorTicket': ticket, 'code': code.trim()},
    );
  }

  @override
  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  }) {
    return _authRequest(
      apiOrigin: apiOrigin,
      path: '/api/auth/verify-session',
      defaultFailureMessage: 'Verification failed',
      body: {'sessionToken': sessionToken, 'code': code.trim()},
    );
  }

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    final _JsonAuthResponse response;
    try {
      response = await _jsonRequest(
        apiOrigin: normalizedOrigin,
        path: '/api/auth/refresh',
        body: {'sessionToken': sessionToken},
      );
    } on AuthRefreshException {
      rethrow;
    } on CertificatePinningException catch (error) {
      throw AuthRefreshException(error.message, shouldClearCredentials: false);
    } on AuthException catch (error) {
      throw AuthRefreshException(error.message, shouldClearCredentials: false);
    }

    if (response.statusCode == HttpStatus.unauthorized) {
      throw const AuthRefreshException(
        'Sign in again to continue',
        shouldClearCredentials: true,
      );
    }
    if (response.statusCode == HttpStatus.forbidden) {
      throw AuthRefreshException(
        _errorMessage(
          response.statusCode,
          response.decoded,
          'Sign in again to continue',
        ),
        shouldClearCredentials: true,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthRefreshException(
        _errorMessage(
          response.statusCode,
          response.decoded,
          'Could not verify saved session',
        ),
        shouldClearCredentials: false,
      );
    }
    final decoded = response.decoded;
    if (decoded is! Map<String, Object?>) {
      throw const AuthRefreshException(
        'Invalid auth response',
        shouldClearCredentials: false,
      );
    }
    final accessToken = decoded['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthRefreshException(
        'Auth response was missing access token',
        shouldClearCredentials: false,
      );
    }
    final rotatedSessionToken = decoded['sessionToken'];
    return AuthRefreshResult(
      accessToken: accessToken,
      sessionToken:
          rotatedSessionToken is String && rotatedSessionToken.isNotEmpty
          ? rotatedSessionToken
          : null,
    );
  }

  void close() {
    _httpClient.close(force: true);
  }

  Future<AuthLoginOutcome> _authRequest({
    required String apiOrigin,
    required String path,
    required String defaultFailureMessage,
    required Map<String, Object?> body,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    final _JsonAuthResponse response;
    try {
      response = await _jsonRequest(
        apiOrigin: normalizedOrigin,
        path: path,
        body: body,
      );
    } on CertificatePinningException catch (error) {
      throw AuthException(error.message);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _errorMessage(
          response.statusCode,
          response.decoded,
          defaultFailureMessage,
        ),
      );
    }
    final decoded = response.decoded;
    if (decoded is! Map<String, Object?>) {
      throw const AuthException('Invalid auth response');
    }

    return _parseAuthOutcome(normalizedOrigin, decoded);
  }

  Future<_JsonAuthResponse> _jsonRequest({
    required String apiOrigin,
    required String path,
    required Map<String, Object?> body,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    await _certificatePinningPolicy.verifyPinnedHost(
      httpClient: _httpClient,
      apiOrigin: normalizedOrigin,
      timeout: timeout,
    );
    final request = await _httpClient
        .postUrl(Uri.parse('$normalizedOrigin$path'))
        .timeout(timeout);

    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
    request.headers.set('X-Client-Version', verdantClientVersion);
    request.write(jsonEncode(body));

    final response = await request.close().timeout(timeout);
    _certificatePinningPolicy.verifyResponseCertificate(
      apiOrigin: normalizedOrigin,
      response: response,
    );
    final decoded = await _decodeJsonResponse(response);
    return _JsonAuthResponse(statusCode: response.statusCode, decoded: decoded);
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const AuthException('Auth response was too large');
      }
      buffer.write(chunk);
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(text);
    } on FormatException {
      if (response.statusCode >= 400) {
        return {'error': text.trim()};
      }
      throw const AuthException('Invalid server response');
    }
  }

  AuthLoginOutcome _parseAuthOutcome(
    String apiOrigin,
    Map<String, Object?> json,
  ) {
    if (json['requiresTwoFactor'] == true) {
      final ticket = json['twoFactorTicket'];
      if (ticket is String && ticket.isNotEmpty) {
        return AuthLoginRequiresTwoFactor(ticket: ticket);
      }
      throw const AuthException('Two-factor challenge was missing');
    }

    if (json['requiresVerification'] == true) {
      final sessionToken = json['sessionToken'];
      if (sessionToken is String && sessionToken.isNotEmpty) {
        return AuthLoginRequiresVerification(sessionToken: sessionToken);
      }
      throw const AuthException('Verification session was missing');
    }

    final accessToken = json['accessToken'];
    final sessionToken = json['sessionToken'];
    final user = json['user'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthException('Auth response was missing access token');
    }
    if (sessionToken is! String || sessionToken.isEmpty) {
      throw const AuthException('Auth response was missing session token');
    }
    if (user is! Map<String, Object?>) {
      throw const AuthException('Auth response was missing user');
    }

    return AuthLoginSuccess(
      accountRestored: json['accountRestored'] == true,
      credentials: AuthCredentialBundle(
        apiOrigin: apiOrigin,
        accessToken: accessToken,
        sessionToken: sessionToken,
      ),
      session: AuthSession.authenticated(
        apiOrigin: apiOrigin,
        user: VerdantUser.fromJson(user),
      ),
    );
  }

  String _errorMessage(
    int statusCode,
    Object? decoded,
    String defaultFailureMessage,
  ) {
    if (decoded is Map<String, Object?>) {
      final code = decoded['code'];
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        if (code == 'AUTH_REGISTRATION_FAILED' &&
            error.trim() == 'Registration failed') {
          return 'Account creation failed. Sign in if this email already has '
              'an account, or use a different email.';
        }
        return error;
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return switch (statusCode) {
      401 => 'Invalid credentials',
      429 => 'Too many attempts. Try again shortly.',
      _ => defaultFailureMessage,
    };
  }
}

final class _JsonAuthResponse {
  const _JsonAuthResponse({required this.statusCode, required this.decoded});

  final int statusCode;
  final Object? decoded;
}
