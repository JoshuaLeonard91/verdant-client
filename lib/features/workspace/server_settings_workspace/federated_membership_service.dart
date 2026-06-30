import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/client_version.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/transport_security.dart';
import '../shared/workspace_credential_refresher.dart';

abstract interface class FederatedMembershipRepository {
  Future<List<FederatedClientMembership>> listMemberships();

  Future<FederatedMembershipCapabilityResult> refreshCapability({
    required String membershipId,
  });
}

final class FederatedClientMembership {
  const FederatedClientMembership({
    required this.id,
    required this.targetPeerId,
    required this.targetApiOrigin,
    required this.targetServerId,
    required this.status,
    required this.server,
  });

  factory FederatedClientMembership.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json['id']);
    final targetPeerId = _stringValue(json['targetPeerId']);
    final targetApiOrigin = _stringValue(json['targetApiOrigin']);
    final targetServerId = _stringValue(json['targetServerId']);
    final status = _stringValue(json['status']);
    final rawServer = json['server'];
    if (id == null ||
        targetPeerId == null ||
        targetApiOrigin == null ||
        targetServerId == null ||
        status == null ||
        rawServer is! Map) {
      throw const FederatedMembershipException(
        'Federated membership response was invalid',
      );
    }
    return FederatedClientMembership(
      id: id,
      targetPeerId: targetPeerId,
      targetApiOrigin: normalizeBackendApiOrigin(targetApiOrigin),
      targetServerId: targetServerId,
      status: status,
      server: FederatedMembershipServer.fromJson(
        Map<String, Object?>.from(rawServer),
      ),
    );
  }

  final String id;
  final String targetPeerId;
  final String targetApiOrigin;
  final String targetServerId;
  final String status;
  final FederatedMembershipServer server;

  bool get isActive => status == 'active';
}

final class FederatedMembershipServer {
  const FederatedMembershipServer({
    required this.id,
    this.name,
    this.iconUrl,
    this.bannerUrl,
  });

  factory FederatedMembershipServer.fromJson(Map<String, Object?> json) {
    final id = _stringValue(json['id']);
    if (id == null) {
      throw const FederatedMembershipException(
        'Federated membership response was invalid',
      );
    }
    return FederatedMembershipServer(
      id: id,
      name: _nullableTrimmedString(json['name']),
      iconUrl: _nullableTrimmedString(json['iconUrl']),
      bannerUrl: _nullableTrimmedString(json['bannerUrl']),
    );
  }

  final String id;
  final String? name;
  final String? iconUrl;
  final String? bannerUrl;
}

enum FederatedMembershipCapabilityStatus { ready, pending }

final class FederatedMembershipCapabilityResult {
  const FederatedMembershipCapabilityResult({
    required this.status,
    this.accessToken,
    this.expiresAt,
    this.serverId,
    this.user,
  });

  factory FederatedMembershipCapabilityResult.fromJson(
    Map<String, Object?> json,
  ) {
    final status = json['status'];
    if (status == 'pending') {
      return const FederatedMembershipCapabilityResult(
        status: FederatedMembershipCapabilityStatus.pending,
      );
    }
    if (status != 'ready' || json['tokenType'] != 'federated_client') {
      throw const FederatedMembershipException(
        'Federated membership capability response was invalid',
      );
    }
    final accessToken = _stringValue(json['accessToken']);
    final expiresAt = _dateTimeValue(json['expiresAt']);
    final serverId = _stringValue(json['serverId']);
    final rawUser = json['user'];
    if (accessToken == null ||
        expiresAt == null ||
        serverId == null ||
        rawUser is! Map) {
      throw const FederatedMembershipException(
        'Federated membership capability response was invalid',
      );
    }
    return FederatedMembershipCapabilityResult(
      status: FederatedMembershipCapabilityStatus.ready,
      accessToken: accessToken,
      expiresAt: expiresAt,
      serverId: serverId,
      user: VerdantUser.fromJson(Map<String, Object?>.from(rawUser)),
    );
  }

  final FederatedMembershipCapabilityStatus status;
  final String? accessToken;
  final DateTime? expiresAt;
  final String? serverId;
  final VerdantUser? user;

  bool get isReady => status == FederatedMembershipCapabilityStatus.ready;

  AuthCredentialBundle toCredential({required String targetApiOrigin}) {
    final token = accessToken;
    final currentUser = user;
    final expiry = expiresAt;
    if (token == null ||
        token.isEmpty ||
        currentUser == null ||
        expiry == null) {
      throw const FederatedMembershipException(
        'Federated membership capability response was invalid',
      );
    }
    return AuthCredentialBundle(
      apiOrigin: targetApiOrigin,
      accessToken: token,
      sessionToken: '',
      kind: AuthCredentialKind.federatedClient,
      user: currentUser,
      expiresAt: expiry,
    );
  }
}

final class HttpFederatedMembershipService
    implements FederatedMembershipRepository {
  HttpFederatedMembershipService({
    required String apiOrigin,
    required AuthCredentialStore credentialStore,
    AuthService? authService,
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 128 * 1024,
  }) : apiOrigin = normalizeBackendApiOrigin(apiOrigin),
       _certificatePinningPolicy =
           certificatePinningPolicy ??
           CertificatePinningPolicy.fromEnvironment(),
       _httpClient =
           httpClient ??
           (certificatePinningPolicy ??
                   CertificatePinningPolicy.fromEnvironment())
               .createHttpClient(),
       _credentialRefresher = WorkspaceCredentialRefresher(
         apiOrigin: apiOrigin,
         credentialStore: credentialStore,
         authService: authService,
         certificatePinningPolicy: certificatePinningPolicy,
         timeout: timeout,
       );

  final String apiOrigin;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final WorkspaceCredentialRefresher _credentialRefresher;
  final Duration timeout;
  final int maxResponseBytes;

  @override
  Future<List<FederatedClientMembership>> listMemberships() async {
    final decoded = await _authenticatedJsonRequest(
      'GET',
      '/api/federation/memberships',
    );
    if (decoded is! Map<String, Object?>) {
      throw const FederatedMembershipException(
        'Federated membership response was invalid',
      );
    }
    final rawMemberships = decoded['memberships'];
    if (rawMemberships is! List) {
      throw const FederatedMembershipException(
        'Federated membership response was invalid',
      );
    }
    return [
      for (final rawMembership in rawMemberships)
        if (rawMembership is Map)
          FederatedClientMembership.fromJson(
            Map<String, Object?>.from(rawMembership),
          ),
    ];
  }

  @override
  Future<FederatedMembershipCapabilityResult> refreshCapability({
    required String membershipId,
  }) async {
    final safeMembershipId = _safeMembershipId(membershipId);
    final decoded = await _authenticatedJsonRequest(
      'POST',
      '/api/federation/memberships/${Uri.encodeComponent(safeMembershipId)}/capability',
      body: const <String, Object?>{},
    );
    if (decoded is! Map<String, Object?>) {
      throw const FederatedMembershipException(
        'Federated membership capability response was invalid',
      );
    }
    return FederatedMembershipCapabilityResult.fromJson(decoded);
  }

  Future<Object?> _authenticatedJsonRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    var credentials = await _readCredentials();
    var refreshedCredentials = false;
    while (true) {
      final request = await _openRequest(method, path, credentials);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      _certificatePinningPolicy.verifyResponseCertificate(
        apiOrigin: apiOrigin,
        response: response,
      );
      final decoded = await _decodeJsonResponse(response);
      if (response.statusCode == HttpStatus.unauthorized &&
          !refreshedCredentials) {
        refreshedCredentials = true;
        credentials = await _refreshCredentials(credentials);
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = _errorPayload(decoded);
        throw FederatedMembershipException(
          error.message,
          code: error.code,
          statusCode: response.statusCode,
          isAuthExpired: response.statusCode == HttpStatus.unauthorized,
        );
      }
      return decoded;
    }
  }

  Future<HttpClientRequest> _openRequest(
    String method,
    String path,
    AuthCredentialBundle credentials,
  ) async {
    _assertApiPath(path);
    await _certificatePinningPolicy.verifyPinnedHost(
      httpClient: _httpClient,
      apiOrigin: apiOrigin,
      timeout: timeout,
    );
    final request = await _httpClient
        .openUrl(method, Uri.parse('$apiOrigin$path'))
        .timeout(timeout);
    request.followRedirects = false;
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${credentials.accessToken}',
    );
    request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
    request.headers.set('X-Client-Version', verdantClientVersion);
    return request;
  }

  Future<AuthCredentialBundle> _readCredentials() async {
    try {
      return await _credentialRefresher.readCredentials();
    } on WorkspaceCredentialRefreshException catch (error) {
      throw FederatedMembershipException(
        error.message,
        isAuthExpired: error.isAuthExpired,
      );
    }
  }

  Future<AuthCredentialBundle> _refreshCredentials(
    AuthCredentialBundle stale,
  ) async {
    try {
      return await _credentialRefresher.refresh(stale);
    } on WorkspaceCredentialRefreshException catch (error) {
      throw FederatedMembershipException(
        error.message,
        isAuthExpired: error.isAuthExpired,
      );
    }
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const FederatedMembershipException(
          'Server response was too large',
        );
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
      throw const FederatedMembershipException(
        'Federated membership response was invalid',
      );
    }
  }

  void close() {
    _httpClient.close(force: true);
    _credentialRefresher.close();
  }
}

final class FederatedMembershipException implements Exception {
  const FederatedMembershipException(
    this.message, {
    this.code,
    this.statusCode,
    this.isAuthExpired = false,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final bool isAuthExpired;

  @override
  String toString() => message;
}

String? _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  if (value is int) {
    return value.toString();
  }
  return null;
}

String? _nullableTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim())?.toUtc();
}

({String message, String? code}) _errorPayload(Object? decoded) {
  if (decoded is Map<String, Object?>) {
    final message = decoded['error'];
    final code = decoded['code'];
    return (
      message: message is String && message.trim().isNotEmpty
          ? message
          : 'Federated membership unavailable',
      code: code is String && code.trim().isNotEmpty ? code : null,
    );
  }
  return (message: 'Federated membership unavailable', code: null);
}

String _safeMembershipId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.length > 64 ||
      !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(trimmed)) {
    throw const FederatedMembershipException(
      'Federated membership was invalid',
    );
  }
  return trimmed;
}

void _assertApiPath(String path) {
  if (!path.startsWith('/api/') ||
      path.contains('..') ||
      path.contains('\\') ||
      path.contains('\r') ||
      path.contains('\n')) {
    throw const FederatedMembershipException('Request path was invalid');
  }
}
