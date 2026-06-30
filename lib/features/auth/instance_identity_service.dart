import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app/client_version.dart';
import 'auth_models.dart';
import 'instance_identity.dart';
import 'transport_security.dart';

final class HttpInstanceIdentityManifestService
    implements InstanceIdentityManifestService {
  HttpInstanceIdentityManifestService({
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
  Future<InstanceManifestIdentity?> fetchManifest({
    required String apiOrigin,
  }) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    try {
      await _certificatePinningPolicy.verifyPinnedHost(
        httpClient: _httpClient,
        apiOrigin: normalizedOrigin,
        timeout: timeout,
      );
      final request = await _httpClient
          .getUrl(Uri.parse('$normalizedOrigin/api/federation/manifest'))
          .timeout(timeout);

      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
      request.headers.set('X-Client-Version', verdantClientVersion);

      final response = await request.close().timeout(timeout);
      _certificatePinningPolicy.verifyResponseCertificate(
        apiOrigin: normalizedOrigin,
        response: response,
      );
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain<void>();
        return null;
      }
      final decoded = await _decodeJsonResponse(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AuthException('Could not verify this network identity');
      }
      if (decoded is! Map<String, Object?>) {
        throw const AuthException('Could not verify this network identity');
      }
      return InstanceManifestIdentity.fromJson(decoded);
    } on AuthException {
      rethrow;
    } on CertificatePinningException {
      throw const AuthException('Could not verify this network connection');
    } on TimeoutException {
      throw const AuthException('Could not verify this network identity');
    } on IOException {
      throw const AuthException('Could not verify this network identity');
    } on FormatException {
      throw const AuthException('Could not verify this network identity');
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
        throw const AuthException('Could not verify this network identity');
      }
      buffer.write(chunk);
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      return null;
    }
    return jsonDecode(text);
  }
}
