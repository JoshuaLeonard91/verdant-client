import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_models.dart';

final class CertificatePinningException implements Exception {
  const CertificatePinningException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class CertificatePinningPolicy {
  CertificatePinningPolicy({
    Map<String, Iterable<String>> pinsByApiOrigin = const {},
  }) : _pinsByApiOrigin = _normalizePinsByOrigin(pinsByApiOrigin);

  factory CertificatePinningPolicy.fromEnvironment() {
    const officialPins = String.fromEnvironment(
      'VERDANT_OFFICIAL_CERT_SHA256_PINS',
    );
    if (officialPins.trim().isEmpty) {
      return CertificatePinningPolicy.disabled;
    }
    return CertificatePinningPolicy(
      pinsByApiOrigin: {
        officialApiOrigin: officialPins
            .split(',')
            .map((pin) => pin.trim())
            .where((pin) => pin.isNotEmpty),
      },
    );
  }

  static final disabled = CertificatePinningPolicy();

  final Map<String, Set<String>> _pinsByApiOrigin;

  bool hasPinsForApiOrigin(String apiOrigin) {
    return _pinsForApiOrigin(apiOrigin).isNotEmpty;
  }

  HttpClient createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = _acceptPinnedBadCertificate;
    return client;
  }

  Future<void> verifyPinnedHost({
    required HttpClient httpClient,
    required String apiOrigin,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final pins = _pinsForApiOrigin(apiOrigin);
    if (pins.isEmpty) {
      return;
    }
    final origin = Uri.parse(normalizeBackendApiOrigin(apiOrigin));
    if (origin.scheme != 'https') {
      throw const CertificatePinningException(
        'Certificate pinning requires HTTPS',
      );
    }
    final request = await httpClient
        .openUrl('HEAD', origin.replace(path: '/health'))
        .timeout(timeout);
    request.followRedirects = false;
    final response = await request.close().timeout(timeout);
    try {
      verifyResponseCertificate(apiOrigin: apiOrigin, response: response);
    } finally {
      await response.drain<void>();
    }
  }

  WebSocketChannel connectWebSocket(
    Uri uri, {
    Map<String, dynamic>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) {
    final client = createHttpClient();
    final socket =
        verifyPinnedHost(
          httpClient: client,
          apiOrigin: _httpsOriginFromWebSocketUri(uri),
          timeout: timeout,
        ).then(
          (_) => WebSocket.connect(
            uri.toString(),
            headers: headers,
            customClient: client,
          ),
        );
    return IOWebSocketChannel(socket);
  }

  void verifyResponseCertificate({
    required String apiOrigin,
    required HttpClientResponse response,
  }) {
    final pins = _pinsForApiOrigin(apiOrigin);
    if (pins.isEmpty) {
      return;
    }
    final cert = response.certificate;
    if (cert == null) {
      throw const CertificatePinningException(
        'Pinned TLS connection did not expose a certificate',
      );
    }
    _verifyCertificate(apiOrigin: apiOrigin, cert: cert, pins: pins);
  }

  bool acceptsCertificate({
    required String apiOrigin,
    required X509Certificate cert,
  }) {
    final pins = _pinsForApiOrigin(apiOrigin);
    if (pins.isEmpty) {
      return true;
    }
    return pins.contains(certificateSha256Fingerprint(cert));
  }

  void requireMatchingCertificate({
    required String apiOrigin,
    required X509Certificate cert,
  }) {
    final pins = _pinsForApiOrigin(apiOrigin);
    if (pins.isEmpty) {
      return;
    }
    _verifyCertificate(apiOrigin: apiOrigin, cert: cert, pins: pins);
  }

  bool _acceptPinnedBadCertificate(
    X509Certificate cert,
    String host,
    int port,
  ) {
    final origin = _httpsOriginFromHostPort(host, port);
    final pins = _pinsForApiOrigin(origin);
    if (pins.isEmpty) {
      return false;
    }
    return pins.contains(certificateSha256Fingerprint(cert));
  }

  void _verifyCertificate({
    required String apiOrigin,
    required X509Certificate cert,
    required Set<String> pins,
  }) {
    final fingerprint = certificateSha256Fingerprint(cert);
    if (!pins.contains(fingerprint)) {
      throw CertificatePinningException(
        'Pinned TLS certificate mismatch for ${_safeOrigin(apiOrigin)}',
      );
    }
  }

  Set<String> _pinsForApiOrigin(String apiOrigin) {
    final normalized = normalizeBackendApiOrigin(apiOrigin);
    return _pinsByApiOrigin[normalized] ?? const <String>{};
  }

  static Map<String, Set<String>> _normalizePinsByOrigin(
    Map<String, Iterable<String>> pinsByApiOrigin,
  ) {
    final normalized = <String, Set<String>>{};
    for (final entry in pinsByApiOrigin.entries) {
      final apiOrigin = normalizeBackendApiOrigin(entry.key);
      final pins = <String>{};
      for (final pin in entry.value) {
        final normalizedPin = normalizeCertificateSha256Pin(pin);
        if (normalizedPin != null) {
          pins.add(normalizedPin);
        }
      }
      if (pins.isNotEmpty) {
        normalized[apiOrigin] = pins;
      }
    }
    return Map.unmodifiable(normalized);
  }
}

String certificateSha256Fingerprint(X509Certificate cert) {
  return sha256.convert(cert.der).toString();
}

String? normalizeCertificateSha256Pin(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('sha256/')) {
    try {
      final bytes = base64.decode(trimmed.substring('sha256/'.length));
      if (bytes.length == 32) {
        return _hex(bytes);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  final withoutPrefix = lower.startsWith('sha256:')
      ? lower.substring('sha256:'.length)
      : lower;
  final hex = withoutPrefix.replaceAll(RegExp(r'[\s:-]'), '');
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hex)) {
    return null;
  }
  return hex;
}

String _hex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

String _httpsOriginFromHostPort(String host, int port) {
  final wrappedHost = host.contains(':') && !host.startsWith('[')
      ? '[$host]'
      : host;
  final portSuffix = port == 443 ? '' : ':$port';
  return 'https://$wrappedHost$portSuffix';
}

String _httpsOriginFromWebSocketUri(Uri uri) {
  final scheme = switch (uri.scheme) {
    'wss' => 'https',
    'ws' => 'http',
    _ => uri.scheme,
  };
  final wrappedHost = uri.host.contains(':') && !uri.host.startsWith('[')
      ? '[${uri.host}]'
      : uri.host;
  final defaultPort =
      (scheme == 'https' && uri.port == 443) ||
      (scheme == 'http' && uri.port == 80);
  final port = defaultPort || !uri.hasPort ? '' : ':${uri.port}';
  return '$scheme://$wrappedHost$port';
}

String _safeOrigin(String apiOrigin) {
  try {
    final uri = Uri.parse(normalizeBackendApiOrigin(apiOrigin));
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  } on AuthException {
    return 'configured host';
  }
}
