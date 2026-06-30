import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/client_version.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/transport_security.dart';
import 'inactive_backend_runtime.dart';

final class HttpSyncSummaryClient implements SyncSummaryClient {
  HttpSyncSummaryClient({
    required this.credentialStore,
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

  final AuthCredentialStore credentialStore;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final Duration timeout;
  final int maxResponseBytes;

  @override
  Future<SyncSummarySnapshot> fetchSummary(
    JoinedBackendRuntimeProfile profile, {
    String? since,
  }) async {
    try {
      final apiOrigin = normalizeBackendApiOrigin(profile.apiOrigin);
      final profileOrigin = apiOriginFromNetworkId(profile.networkId);
      if (profileOrigin != null && profileOrigin != apiOrigin) {
        throw const SyncSummaryClientException('Invalid backend profile');
      }
      final credentials = await credentialStore.read(apiOrigin);
      if (credentials == null || !credentials.hasAccessToken) {
        throw const SyncSummaryClientException(
          'Sign in again to continue',
          isAuthExpired: true,
        );
      }
      if (credentials.normalizedApiOrigin != apiOrigin) {
        throw const SyncSummaryClientException(
          'Sign in again to continue',
          isAuthExpired: true,
        );
      }

      await _certificatePinningPolicy.verifyPinnedHost(
        httpClient: _httpClient,
        apiOrigin: apiOrigin,
        timeout: timeout,
      );
      final uri = Uri.parse('$apiOrigin/api/sync/summary').replace(
        queryParameters: since == null || since.trim().isEmpty
            ? null
            : {'since': since.trim()},
      );
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${credentials.accessToken}',
      );
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.pragmaHeader, 'no-cache');
      request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
      request.headers.set('X-Client-Version', verdantClientVersion);

      final response = await request.close().timeout(timeout);
      _certificatePinningPolicy.verifyResponseCertificate(
        apiOrigin: apiOrigin,
        response: response,
      );
      final decoded = await _decodeJsonResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SyncSummaryClientException(
          _summaryErrorMessage(response.statusCode, decoded),
          isAuthExpired: response.statusCode == HttpStatus.unauthorized,
        );
      }
      if (decoded is! Map<String, Object?>) {
        throw const SyncSummaryClientException('Invalid sync summary response');
      }
      return SyncSummarySnapshot.fromJson(decoded);
    } on SyncSummaryClientException {
      rethrow;
    } on AuthException catch (error) {
      throw SyncSummaryClientException(error.message);
    } on CertificatePinningException {
      throw const SyncSummaryClientException(
        'Could not verify this network connection',
      );
    } on TimeoutException {
      throw const SyncSummaryClientException('Sync summary request timed out');
    } on IOException {
      throw const SyncSummaryClientException('Could not fetch sync summary');
    } on FormatException {
      throw const SyncSummaryClientException('Invalid sync summary response');
    }
  }

  void close() {
    _httpClient.close(force: true);
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const SyncSummaryClientException(
          'Sync summary response was too large',
        );
      }
      buffer.write(chunk);
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      return null;
    }
    return jsonDecode(text);
  }

  String _summaryErrorMessage(int statusCode, Object? decoded) {
    if (decoded is Map<String, Object?>) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return switch (statusCode) {
      401 => 'Sign in again to continue',
      403 => 'You do not have permission to sync this network',
      429 => 'Too many requests. Try again shortly.',
      _ => 'Could not fetch sync summary',
    };
  }
}
