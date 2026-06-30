import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app/client_version.dart';
import 'auth_models.dart';
import 'transport_security.dart';

enum InstanceRegistrationPolicy {
  public('public'),
  invite('invite'),
  disabled('disabled'),
  unknown('unknown');

  const InstanceRegistrationPolicy(this.wireName);

  final String wireName;

  bool get allowsAccountCreation => this == InstanceRegistrationPolicy.public;

  static InstanceRegistrationPolicy fromWire(Object? value) {
    if (value is! String) {
      return InstanceRegistrationPolicy.unknown;
    }

    return switch (value.trim().toLowerCase()) {
      'public' => InstanceRegistrationPolicy.public,
      'invite' => InstanceRegistrationPolicy.invite,
      'disabled' => InstanceRegistrationPolicy.disabled,
      _ => InstanceRegistrationPolicy.unknown,
    };
  }
}

abstract interface class InstanceMetadataService {
  Future<InstanceRegistrationPolicy> fetchRegistrationPolicy({
    required String apiOrigin,
  });
}

final class HttpInstanceMetadataService implements InstanceMetadataService {
  HttpInstanceMetadataService({
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
  Future<InstanceRegistrationPolicy> fetchRegistrationPolicy({
    required String apiOrigin,
  }) async {
    try {
      final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
      await _certificatePinningPolicy.verifyPinnedHost(
        httpClient: _httpClient,
        apiOrigin: normalizedOrigin,
        timeout: timeout,
      );
      final request = await _httpClient
          .getUrl(Uri.parse('$normalizedOrigin/api/instance'))
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
      final decoded = await _decodeJsonResponse(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AuthException(
          'Could not check account creation for this network',
        );
      }
      if (decoded is! Map<String, Object?>) {
        throw const AuthException(
          'Could not check account creation for this network',
        );
      }

      final policy = InstanceRegistrationPolicy.fromWire(
        decoded['registration'],
      );
      if (policy == InstanceRegistrationPolicy.unknown) {
        throw const AuthException(
          'Could not check account creation for this network',
        );
      }
      return policy;
    } on AuthException {
      rethrow;
    } on CertificatePinningException {
      throw const AuthException('Could not verify this network connection');
    } on TimeoutException {
      throw const AuthException(
        'Could not check account creation for this network',
      );
    } on IOException {
      throw const AuthException(
        'Could not check account creation for this network',
      );
    } on FormatException {
      throw const AuthException(
        'Could not check account creation for this network',
      );
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
        throw const AuthException(
          'Could not check account creation for this network',
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
}
