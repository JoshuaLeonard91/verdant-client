import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/client_version.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/transport_security.dart';
import '../shared/workspace_credential_refresher.dart';
import 'federated_membership_service.dart';
import 'server_settings_models.dart';

abstract interface class FederatedInvitePreviewRepository {
  Future<ServerInvitePreview> previewInvite({
    required String apiOrigin,
    required String code,
  });
}

abstract interface class FederatedInviteJoinRepository {
  Future<FederatedInviteJoinResult> joinInvite({
    required String targetApiOrigin,
    required String targetPeerId,
    required String serverId,
    required String code,
  });
}

enum FederatedInviteJoinStatus { queued }

final class FederatedInviteJoinResult {
  const FederatedInviteJoinResult({
    required this.status,
    required this.queuedEvents,
    this.duplicateEvents = 0,
    this.membership,
    this.credentialIssued = false,
  });

  factory FederatedInviteJoinResult.fromJson(Map<String, Object?> json) {
    final status = json['status'];
    final rawMembership = json['membership'];
    return FederatedInviteJoinResult(
      status: status == 'queued'
          ? FederatedInviteJoinStatus.queued
          : FederatedInviteJoinStatus.queued,
      queuedEvents: _intValue(json['queuedEvents']),
      duplicateEvents: _intValue(json['duplicateEvents']),
      membership: rawMembership is Map<String, Object?>
          ? FederatedClientMembership.fromJson(rawMembership)
          : rawMembership is Map
          ? FederatedClientMembership.fromJson(
              Map<String, Object?>.from(rawMembership),
            )
          : null,
    );
  }

  final FederatedInviteJoinStatus status;
  final int queuedEvents;
  final int duplicateEvents;
  final FederatedClientMembership? membership;
  final bool credentialIssued;

  FederatedInviteJoinResult withCredentialIssued() {
    return FederatedInviteJoinResult(
      status: status,
      queuedEvents: queuedEvents,
      duplicateEvents: duplicateEvents,
      membership: membership,
      credentialIssued: true,
    );
  }
}

final class FederatedInvitePreviewException implements Exception {
  const FederatedInvitePreviewException(
    this.message, {
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  bool get federationDisabled => code == 'FEDERATION_INVITES_DISABLED';

  @override
  String toString() => message;
}

final class HttpFederatedInvitePreviewService
    implements FederatedInvitePreviewRepository {
  HttpFederatedInvitePreviewService({
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 128 * 1024,
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
  Future<ServerInvitePreview> previewInvite({
    required String apiOrigin,
    required String code,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    final inviteCode = _safeInviteCode(code);
    final path =
        '/api/federation/invites/${Uri.encodeComponent(inviteCode)}/preview';
    final decoded = await _publicJsonRequest(normalizedOrigin, path);
    if (decoded is! Map<String, Object?>) {
      throw const FederatedInvitePreviewException(
        'Invite response was invalid',
      );
    }
    try {
      return ServerInvitePreview.fromJson(decoded);
    } on FormatException {
      throw const FederatedInvitePreviewException(
        'Invite response was invalid',
      );
    }
  }

  void close() {
    _httpClient.close(force: true);
  }

  Future<Object?> _publicJsonRequest(String apiOrigin, String path) async {
    await _certificatePinningPolicy.verifyPinnedHost(
      httpClient: _httpClient,
      apiOrigin: apiOrigin,
      timeout: timeout,
    );
    final request = await _httpClient
        .getUrl(Uri.parse('$apiOrigin$path'))
        .timeout(timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
    request.headers.set('X-Client-Version', verdantClientVersion);

    final response = await request.close().timeout(timeout);
    _certificatePinningPolicy.verifyResponseCertificate(
      apiOrigin: apiOrigin,
      response: response,
    );
    final decoded = await _decodeJsonResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _errorPayload(decoded);
      throw FederatedInvitePreviewException(
        error.message,
        code: error.code,
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const FederatedInvitePreviewException(
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
      throw const FederatedInvitePreviewException(
        'Server response was invalid',
      );
    }
  }
}

final class HttpFederatedInviteJoinService
    implements FederatedInviteJoinRepository {
  HttpFederatedInviteJoinService({
    required String apiOrigin,
    required AuthCredentialStore credentialStore,
    AuthService? authService,
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 128 * 1024,
    this.capabilityPollAttempts = 20,
    this.capabilityPollDelay = const Duration(milliseconds: 500),
  }) : apiOrigin = normalizeBackendApiOrigin(apiOrigin),
       _credentialStore = credentialStore,
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
  final AuthCredentialStore _credentialStore;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final WorkspaceCredentialRefresher _credentialRefresher;
  final Duration timeout;
  final int maxResponseBytes;
  final int capabilityPollAttempts;
  final Duration capabilityPollDelay;

  @override
  Future<FederatedInviteJoinResult> joinInvite({
    required String targetApiOrigin,
    required String targetPeerId,
    required String serverId,
    required String code,
  }) async {
    final normalizedTargetApiOrigin = normalizeBackendApiOrigin(
      targetApiOrigin,
    );
    final safeTargetPeerId = _safePeerId(targetPeerId);
    final safeServerId = _safeServerId(serverId);
    final safeCode = _safeInviteCode(code);
    final decoded = await _authenticatedJsonRequest(
      'POST',
      '/api/federation/invites/join',
      body: {
        'targetApiOrigin': normalizedTargetApiOrigin,
        'targetPeerId': safeTargetPeerId,
        'serverId': safeServerId,
        'code': safeCode,
      },
    );
    if (decoded is! Map<String, Object?>) {
      throw const FederatedInviteJoinException(
        'Federated invite join response was invalid',
      );
    }
    final result = FederatedInviteJoinResult.fromJson(decoded);
    final membership = result.membership;
    if (membership == null ||
        membership.targetApiOrigin != normalizedTargetApiOrigin ||
        membership.targetPeerId != safeTargetPeerId ||
        membership.targetServerId != safeServerId) {
      throw const FederatedInviteJoinException(
        'Federated invite join response was missing membership',
      );
    }
    for (var attempt = 0; attempt < capabilityPollAttempts; attempt += 1) {
      final credentialIssued = await _refreshFederatedMembershipOnce(
        membership: membership,
        expectedServerId: safeServerId,
      );
      if (credentialIssued) {
        return result.withCredentialIssued();
      }
      if (attempt + 1 < capabilityPollAttempts) {
        await Future<void>.delayed(capabilityPollDelay);
      }
    }
    throw const FederatedInviteJoinException(
      'Federated membership is still pending',
    );
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
        throw FederatedInviteJoinException(
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

  Future<bool> _refreshFederatedMembershipOnce({
    required FederatedClientMembership membership,
    required String expectedServerId,
  }) async {
    final decoded = await _authenticatedJsonRequest(
      'POST',
      '/api/federation/memberships/${Uri.encodeComponent(membership.id)}/capability',
      body: const <String, Object?>{},
    );
    if (decoded is! Map<String, Object?>) {
      throw const FederatedInviteJoinException(
        'Federated membership capability response was invalid',
      );
    }
    final capability = FederatedMembershipCapabilityResult.fromJson(decoded);
    if (capability.status == FederatedMembershipCapabilityStatus.pending) {
      return false;
    }
    if (capability.serverId != expectedServerId) {
      throw const FederatedInviteJoinException(
        'Federated membership capability response was invalid',
      );
    }
    await _credentialStore.save(
      capability.toCredential(targetApiOrigin: membership.targetApiOrigin),
    );
    return true;
  }

  Future<AuthCredentialBundle> _readCredentials() async {
    try {
      return await _credentialRefresher.readCredentials();
    } on WorkspaceCredentialRefreshException catch (error) {
      throw FederatedInviteJoinException(
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
      throw FederatedInviteJoinException(
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
        throw const FederatedInviteJoinException(
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
      throw const FederatedInviteJoinException(
        'Federated invite join response was invalid',
      );
    }
  }

  void close() {
    _httpClient.close(force: true);
    _credentialRefresher.close();
  }
}

final class FederatedInviteJoinException implements Exception {
  const FederatedInviteJoinException(
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

({String message, String? code}) _errorPayload(Object? decoded) {
  if (decoded is Map<String, Object?>) {
    final message = decoded['error'];
    final code = decoded['code'];
    return (
      message: message is String && message.trim().isNotEmpty
          ? message
          : 'Invite unavailable',
      code: code is String && code.trim().isNotEmpty ? code : null,
    );
  }
  return (message: 'Invite unavailable', code: null);
}

String _safeInviteCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.length > 64 ||
      !RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) {
    throw const FederatedInvitePreviewException('Enter a valid invite code');
  }
  return trimmed;
}

String _safeServerId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.length > 64 ||
      !RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
    throw const FederatedInviteJoinException('Invite server was invalid');
  }
  return trimmed;
}

String _safePeerId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.length > 253 ||
      !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(trimmed)) {
    throw const FederatedInviteJoinException('Federated backend was invalid');
  }
  return trimmed;
}

void _assertApiPath(String path) {
  if (!path.startsWith('/api/') ||
      path.contains('..') ||
      path.contains('\\') ||
      path.contains('\r') ||
      path.contains('\n')) {
    throw const FederatedInviteJoinException('Request path was invalid');
  }
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite) {
    return value.toInt();
  }
  return 0;
}
