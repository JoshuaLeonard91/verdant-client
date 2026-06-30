import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../app/client_version.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/transport_security.dart';
import '../shared/workspace_credential_refresher.dart';

abstract interface class MessageLinkPreviewService {
  Future<MessageLinkPreviewMetadata?> loadPreview(Uri uri);

  Future<Uint8List?> loadPreviewImage(String imageProxyUrl);
}

final class MessageLinkPreviewMetadata {
  const MessageLinkPreviewMetadata({
    required this.url,
    required this.title,
    this.description,
    this.siteName,
    this.imageProxyUrl,
  });

  factory MessageLinkPreviewMetadata.fromJson(Map<String, Object?> json) {
    final url = json['url'];
    final title = json['title'];
    if (url is! String || title is! String) {
      throw const FormatException('Invalid link preview payload');
    }
    return MessageLinkPreviewMetadata(
      url: Uri.parse(url),
      title: title,
      description: _stringOrNull(json['description']),
      siteName: _stringOrNull(json['siteName']),
      imageProxyUrl: _stringOrNull(json['imageProxyUrl']),
    );
  }

  final Uri url;
  final String title;
  final String? description;
  final String? siteName;
  final String? imageProxyUrl;
}

final class LinkPreviewException implements Exception {
  const LinkPreviewException(this.message, {this.isAuthExpired = false});

  final String message;
  final bool isAuthExpired;

  @override
  String toString() => message;
}

final class HttpMessageLinkPreviewService implements MessageLinkPreviewService {
  HttpMessageLinkPreviewService({
    required String apiOrigin,
    required this.credentialStore,
    AuthService? authService,
    CertificatePinningPolicy? certificatePinningPolicy,
    HttpClient? httpClient,
    this.timeout = const Duration(seconds: 15),
    this.maxJsonBytes = 64 * 1024,
    this.maxImageBytes = 2 * 1024 * 1024,
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
  final AuthCredentialStore credentialStore;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final WorkspaceCredentialRefresher _credentialRefresher;
  final Duration timeout;
  final int maxJsonBytes;
  final int maxImageBytes;

  @override
  Future<MessageLinkPreviewMetadata?> loadPreview(Uri uri) async {
    try {
      final decoded = await _jsonRequest(
        'POST',
        '/api/link-previews/',
        body: {'url': uri.toString()},
      );
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return MessageLinkPreviewMetadata.fromJson(decoded);
    } on LinkPreviewException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Uint8List?> loadPreviewImage(String imageProxyUrl) async {
    final path = _safeImageProxyPath(imageProxyUrl);
    if (path == null) {
      return null;
    }
    try {
      return await _bytesRequest('GET', path);
    } on LinkPreviewException {
      return null;
    }
  }

  void close() {
    _httpClient.close(force: true);
    _credentialRefresher.close();
  }

  Future<Object?> _jsonRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    var credentials = await _readCredentials();
    for (var attempt = 0; attempt < 2; attempt += 1) {
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
      if (response.statusCode == HttpStatus.unauthorized && attempt == 0) {
        credentials = await _refreshCredentials(credentials);
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw LinkPreviewException(
          _errorMessage(response.statusCode, decoded),
          isAuthExpired: response.statusCode == HttpStatus.unauthorized,
        );
      }
      return decoded;
    }
    throw const LinkPreviewException('Link preview request failed');
  }

  Future<Uint8List> _bytesRequest(String method, String path) async {
    var credentials = await _readCredentials();
    for (var attempt = 0; attempt < 2; attempt += 1) {
      final request = await _openRequest(method, path, credentials);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'image/png,image/jpeg,image/gif,image/webp',
      );
      final response = await request.close().timeout(timeout);
      _certificatePinningPolicy.verifyResponseCertificate(
        apiOrigin: apiOrigin,
        response: response,
      );
      if (response.statusCode == HttpStatus.unauthorized && attempt == 0) {
        await response.drain<void>();
        credentials = await _refreshCredentials(credentials);
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw const LinkPreviewException('Link preview image failed');
      }
      if (!_allowedImageContentType(response.headers.contentType)) {
        await response.drain<void>();
        throw const LinkPreviewException('Link preview image was not allowed');
      }
      return _readBytes(response, maxImageBytes);
    }
    throw const LinkPreviewException('Link preview image failed');
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
      throw LinkPreviewException(
        error.message,
        isAuthExpired: error.isAuthExpired,
      );
    }
  }

  Future<AuthCredentialBundle> _refreshCredentials(
    AuthCredentialBundle credentials,
  ) async {
    try {
      return await _credentialRefresher.refresh(credentials);
    } on WorkspaceCredentialRefreshException catch (error) {
      throw LinkPreviewException(
        error.message,
        isAuthExpired: error.isAuthExpired,
      );
    }
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final bytes = await _readBytes(response, maxJsonBytes);
    if (bytes.isEmpty) {
      return null;
    }
    return jsonDecode(utf8.decode(bytes));
  }

  Future<Uint8List> _readBytes(Stream<List<int>> stream, int maxBytes) async {
    final builder = BytesBuilder(copy: false);
    var received = 0;
    await for (final chunk in stream.timeout(timeout)) {
      received += chunk.length;
      if (received > maxBytes) {
        throw const LinkPreviewException('Link preview response was too large');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

String? _safeImageProxyPath(String imageProxyUrl) {
  if (imageProxyUrl.isEmpty ||
      imageProxyUrl.contains('\\') ||
      imageProxyUrl.contains('\u0000')) {
    return null;
  }
  final uri = Uri.tryParse(imageProxyUrl);
  if (uri == null ||
      uri.hasScheme ||
      uri.host.isNotEmpty ||
      uri.path != '/api/link-previews/image' ||
      !uri.queryParameters.containsKey('url') ||
      uri.hasFragment) {
    return null;
  }
  return uri.toString();
}

void _assertApiPath(String path) {
  final uri = Uri.tryParse(path);
  if (uri == null ||
      path.contains('\\') ||
      path.contains('\u0000') ||
      uri.hasScheme ||
      uri.host.isNotEmpty ||
      uri.hasFragment ||
      !uri.path.startsWith('/api/')) {
    throw const LinkPreviewException('Invalid API path');
  }
}

bool _allowedImageContentType(ContentType? contentType) {
  if (contentType == null) {
    return false;
  }
  final value = '${contentType.primaryType}/${contentType.subType}'
      .toLowerCase();
  return value == 'image/jpeg' ||
      value == 'image/png' ||
      value == 'image/gif' ||
      value == 'image/webp';
}

String _errorMessage(int statusCode, Object? decoded) {
  if (decoded is Map<String, Object?>) {
    final error = decoded['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
  }
  return 'Link preview request failed: HTTP $statusCode';
}

String? _stringOrNull(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
