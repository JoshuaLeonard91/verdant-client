import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../app/client_version.dart';
import '../../auth/auth_credentials.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_service.dart';
import '../../auth/auth_diagnostics.dart';
import '../../auth/transport_security.dart';
import '../shared/workspace_credential_refresher.dart';

enum KlipyMediaType {
  gif('GIF', 'gifs'),
  sticker('Sticker', 'stickers'),
  clip('Clip', 'clips'),
  meme('Meme', 'memes');

  const KlipyMediaType(this.label, this.endpointSegment);

  final String label;
  final String endpointSegment;
}

final class KlipyMediaItem {
  const KlipyMediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.previewUrl,
    required this.originalUrl,
    required this.width,
    required this.height,
  });

  final String id;
  final String title;
  final KlipyMediaType type;
  final String previewUrl;
  final String originalUrl;
  final int width;
  final int height;
}

final class KlipyMediaResult {
  const KlipyMediaResult({required this.items});

  final List<KlipyMediaItem> items;
}

final class KlipyMediaCategory {
  const KlipyMediaCategory({
    required this.name,
    required this.slug,
    required this.imageUrl,
  });

  final String name;
  final String slug;
  final String? imageUrl;
}

abstract interface class KlipyMediaRepository {
  Future<KlipyMediaResult> load({
    required KlipyMediaType type,
    String query = '',
    int page = 1,
  });

  Future<List<KlipyMediaCategory>> loadCategories({
    required KlipyMediaType type,
  });

  Future<String?> loadTrendingPreview({required KlipyMediaType type});
}

final class KlipyMediaException implements Exception {
  const KlipyMediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class HttpKlipyMediaRepository implements KlipyMediaRepository {
  HttpKlipyMediaRepository({
    required String apiOrigin,
    required this.credentialStore,
    AuthService? authService,
    HttpClient? httpClient,
    CertificatePinningPolicy? certificatePinningPolicy,
    this.timeout = const Duration(seconds: 12),
    this.maxResponseBytes = 1024 * 1024,
    this.cacheTtl = const Duration(seconds: 60),
  }) : apiOrigin = normalizeBackendApiOrigin(apiOrigin),
       _certificatePinningPolicy =
           certificatePinningPolicy ??
           CertificatePinningPolicy.fromEnvironment(),
       _credentialRefresher = WorkspaceCredentialRefresher(
         apiOrigin: apiOrigin,
         credentialStore: credentialStore,
         authService: authService,
         certificatePinningPolicy: certificatePinningPolicy,
         timeout: timeout,
       ),
       _httpClient =
           httpClient ??
           (certificatePinningPolicy ??
                   CertificatePinningPolicy.fromEnvironment())
               .createHttpClient();

  final String apiOrigin;
  final AuthCredentialStore credentialStore;
  final HttpClient _httpClient;
  final CertificatePinningPolicy _certificatePinningPolicy;
  final WorkspaceCredentialRefresher _credentialRefresher;
  final Duration timeout;
  final int maxResponseBytes;
  final Duration cacheTtl;
  final _resultCache = <String, _KlipyCacheEntry<KlipyMediaResult>>{};
  final _categoryCache =
      <KlipyMediaType, _KlipyCacheEntry<List<KlipyMediaCategory>>>{};
  final _trendingPreviewCache = <KlipyMediaType, _KlipyCacheEntry<String?>>{};

  @override
  Future<KlipyMediaResult> load({
    required KlipyMediaType type,
    String query = '',
    int page = 1,
  }) async {
    final trimmedQuery = query.trim();
    final normalizedPage = page.clamp(1, 5);
    final cacheKey =
        '${type.name}|${trimmedQuery.toLowerCase()}|$normalizedPage';
    final cached = _resultCache[cacheKey];
    if (_cacheFresh(cached, ttl: cacheTtl)) {
      return cached!.value;
    }
    final endpoint = trimmedQuery.isEmpty ? 'trending' : 'search';
    final params = <String, String>{
      'limit': '20',
      'page': normalizedPage.toString(),
      if (trimmedQuery.isNotEmpty) 'q': trimmedQuery,
    };
    final path =
        '/api/${type.endpointSegment}/$endpoint?${Uri(queryParameters: params).query}';
    final decoded = await _jsonRequest('GET', path);
    final map = _mapValue(decoded);
    final results = map?['results'];
    if (results is! List) {
      return const KlipyMediaResult(items: []);
    }
    final result = KlipyMediaResult(
      items: [
        for (final item in results)
          if (_mapValue(item) case final row?)
            ?_itemFromJson(row, fallbackType: type),
      ],
    );
    _resultCache[cacheKey] = _KlipyCacheEntry(result);
    return result;
  }

  @override
  Future<List<KlipyMediaCategory>> loadCategories({
    required KlipyMediaType type,
  }) async {
    final cached = _categoryCache[type];
    if (_cacheFresh(cached, ttl: cacheTtl)) {
      return cached!.value;
    }
    final decoded = await _jsonRequest(
      'GET',
      '/api/${type.endpointSegment}/categories',
    );
    final categories = _mapValue(decoded)?['categories'];
    if (categories is! List) {
      return const [];
    }
    final result = [
      for (final item in categories)
        if (_mapValue(item) case final row?) ?_categoryFromJson(row),
    ];
    _categoryCache[type] = _KlipyCacheEntry(result);
    return result;
  }

  @override
  Future<String?> loadTrendingPreview({required KlipyMediaType type}) async {
    final cached = _trendingPreviewCache[type];
    if (_cacheFresh(cached, ttl: cacheTtl)) {
      return cached!.value;
    }
    final result = await load(type: type);
    final preview = result.items.isEmpty ? null : result.items.first.previewUrl;
    _trendingPreviewCache[type] = _KlipyCacheEntry(preview);
    return preview;
  }

  void close() {
    _httpClient.close(force: true);
    _credentialRefresher.close();
  }

  Future<Object?> _jsonRequest(String method, String path) async {
    _assertApiPath(path);
    final totalWatch = Stopwatch()..start();
    final endpoint = _diagnosticEndpoint(path);
    var credentials = await _readCredentials();
    var refreshedCredentials = false;
    var retriedRateLimit = false;
    var attempt = 0;
    while (true) {
      attempt += 1;
      final attemptWatch = Stopwatch()..start();
      try {
        await _certificatePinningPolicy.verifyPinnedHost(
          httpClient: _httpClient,
          apiOrigin: apiOrigin,
          timeout: timeout,
        );
        final request = await _httpClient
            .openUrl(method, Uri.parse('$apiOrigin$path'))
            .timeout(timeout);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${credentials.accessToken}',
        );
        request.headers.set(
          HttpHeaders.userAgentHeader,
          verdantFlutterUserAgent,
        );
        request.headers.set('X-Client-Version', verdantClientVersion);

        final response = await request.close().timeout(timeout);
        _certificatePinningPolicy.verifyResponseCertificate(
          apiOrigin: apiOrigin,
          response: response,
        );
        final decoded = await _decodeJsonResponse(response);
        if (response.statusCode == HttpStatus.unauthorized &&
            !refreshedCredentials) {
          _recordKlipyDiagnostic('request.retry', {
            'method': method,
            'endpoint': endpoint,
            'reason': 'unauthorized',
            'attempt': attempt,
            'ms': attemptWatch.elapsedMilliseconds,
          });
          refreshedCredentials = true;
          credentials = await _refreshCredentials(credentials);
          continue;
        }
        if (method.toUpperCase() == 'GET' &&
            response.statusCode == HttpStatus.tooManyRequests &&
            !retriedRateLimit) {
          _recordKlipyDiagnostic('request.retry', {
            'method': method,
            'endpoint': endpoint,
            'reason': 'rate_limited',
            'attempt': attempt,
            'ms': attemptWatch.elapsedMilliseconds,
          });
          retriedRateLimit = true;
          await Future<void>.delayed(_rateLimitRetryDelay(response, decoded));
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _recordKlipyDiagnostic('request.result', {
            'method': method,
            'endpoint': endpoint,
            'status': 'failed',
            'statusCode': response.statusCode,
            'attempt': attempt,
            'ms': totalWatch.elapsedMilliseconds,
          });
          throw KlipyMediaException(
            _errorMessage(response.statusCode, decoded, 'Klipy request failed'),
          );
        }
        _recordKlipyDiagnostic('request.result', {
          'method': method,
          'endpoint': endpoint,
          'status': 'ok',
          'statusCode': response.statusCode,
          'attempt': attempt,
          'ms': totalWatch.elapsedMilliseconds,
        });
        return decoded;
      } on KlipyMediaException {
        rethrow;
      } on TimeoutException {
        _recordKlipyDiagnostic('request.result', {
          'method': method,
          'endpoint': endpoint,
          'status': 'failed',
          'reason': 'timeout',
          'attempt': attempt,
          'ms': totalWatch.elapsedMilliseconds,
        });
        throw const KlipyMediaException('Klipy request timed out');
      } on SocketException {
        _recordKlipyDiagnostic('request.result', {
          'method': method,
          'endpoint': endpoint,
          'status': 'failed',
          'reason': 'network',
          'attempt': attempt,
          'ms': totalWatch.elapsedMilliseconds,
        });
        throw const KlipyMediaException('Could not reach Klipy media');
      } on HandshakeException {
        _recordKlipyDiagnostic('request.result', {
          'method': method,
          'endpoint': endpoint,
          'status': 'failed',
          'reason': 'tls',
          'attempt': attempt,
          'ms': totalWatch.elapsedMilliseconds,
        });
        throw const KlipyMediaException('Could not verify Klipy media');
      } on CertificatePinningException {
        _recordKlipyDiagnostic('request.result', {
          'method': method,
          'endpoint': endpoint,
          'status': 'failed',
          'reason': 'certificate_pinning',
          'attempt': attempt,
          'ms': totalWatch.elapsedMilliseconds,
        });
        throw const KlipyMediaException('Could not verify Klipy media');
      } on HttpException {
        _recordKlipyDiagnostic('request.result', {
          'method': method,
          'endpoint': endpoint,
          'status': 'failed',
          'reason': 'http',
          'attempt': attempt,
          'ms': totalWatch.elapsedMilliseconds,
        });
        throw const KlipyMediaException('Could not load Klipy media');
      }
    }
  }

  Future<AuthCredentialBundle> _readCredentials() async {
    try {
      return await _credentialRefresher.readCredentials();
    } on WorkspaceCredentialRefreshException catch (error) {
      throw KlipyMediaException(
        error.isAuthExpired ? 'Sign in again to use Klipy' : error.message,
      );
    }
  }

  Future<AuthCredentialBundle> _refreshCredentials(
    AuthCredentialBundle credentials,
  ) async {
    try {
      return await _credentialRefresher.refresh(credentials);
    } on WorkspaceCredentialRefreshException catch (error) {
      throw KlipyMediaException(
        error.isAuthExpired ? 'Sign in again to use Klipy' : error.message,
      );
    }
  }

  Future<Object?> _decodeJsonResponse(HttpClientResponse response) async {
    final buffer = StringBuffer();
    var length = 0;
    await for (final chunk in utf8.decoder.bind(response)) {
      length += chunk.length;
      if (length > maxResponseBytes) {
        throw const KlipyMediaException('Klipy response was too large');
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
      throw const KlipyMediaException('Invalid Klipy response');
    }
  }

  void _assertApiPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null ||
        !path.startsWith('/api/') ||
        uri.hasScheme ||
        uri.host.isNotEmpty ||
        uri.hasFragment ||
        path.contains('\\') ||
        path.contains('\u0000')) {
      throw const KlipyMediaException('Invalid Klipy API path');
    }
  }

  String _errorMessage(int statusCode, Object? decoded, String fallback) {
    if (decoded is Map<String, Object?>) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return switch (statusCode) {
      401 => 'Sign in again to use Klipy',
      403 => 'Klipy is not available for this account',
      429 => 'Too many Klipy requests. Try again shortly.',
      _ => fallback,
    };
  }

  Duration _rateLimitRetryDelay(HttpClientResponse response, Object? decoded) {
    final retryAfter = response.headers.value(HttpHeaders.retryAfterHeader);
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter.trim());
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(1, 5));
      }
    }
    if (decoded is Map<String, Object?>) {
      final retryAfterMs = decoded['retryAfterMs'];
      if (retryAfterMs is num && retryAfterMs > 0) {
        return Duration(milliseconds: retryAfterMs.clamp(100, 5000).toInt());
      }
    }
    return const Duration(milliseconds: 650);
  }

  String _diagnosticEndpoint(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || uri.path.isEmpty) {
      return '/api/klipy';
    }
    return uri.path;
  }

  void _recordKlipyDiagnostic(String event, Map<String, Object?> fields) {
    debugPrint(
      'verdant.http klipy.$event ${sanitizeAuthDiagnosticFields(fields)}',
    );
  }

  @override
  String toString() {
    return 'HttpKlipyMediaRepository(apiOrigin: $apiOrigin, token: redacted)';
  }
}

final class SeededKlipyMediaRepository implements KlipyMediaRepository {
  const SeededKlipyMediaRepository();

  @override
  Future<KlipyMediaResult> load({
    required KlipyMediaType type,
    String query = '',
    int page = 1,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final categoryQuery = _seededKlipyCategories.any(
      (category) => category.slug == normalizedQuery,
    );
    final rows = _seededKlipyItems
        .where((item) {
          if (item.type != type) {
            return false;
          }
          return normalizedQuery.isEmpty ||
              categoryQuery ||
              item.title.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    return KlipyMediaResult(items: rows);
  }

  @override
  Future<List<KlipyMediaCategory>> loadCategories({
    required KlipyMediaType type,
  }) async {
    return _seededKlipyCategories;
  }

  @override
  Future<String?> loadTrendingPreview({required KlipyMediaType type}) async {
    final result = await load(type: type);
    return result.items.isEmpty ? null : result.items.first.previewUrl;
  }
}

final class _KlipyCacheEntry<T> {
  _KlipyCacheEntry(this.value) : createdAt = DateTime.now();

  final T value;
  final DateTime createdAt;
}

bool _cacheFresh<T>(_KlipyCacheEntry<T>? entry, {Duration? ttl}) {
  if (entry == null) {
    return false;
  }
  final maxAge = ttl ?? const Duration(seconds: 60);
  return DateTime.now().difference(entry.createdAt) < maxAge;
}

KlipyMediaItem? _itemFromJson(
  Map<String, Object?> json, {
  required KlipyMediaType fallbackType,
}) {
  final images = _mapValue(json['images']);
  final original = _mapValue(images?['original']);
  final tinygif = _mapValue(images?['tinygif']);
  final originalUrl = _nullableString(original?['url']);
  final previewUrl = _nullableString(tinygif?['url']) ?? originalUrl;
  if (originalUrl == null || previewUrl == null) {
    return null;
  }
  return KlipyMediaItem(
    id: _stringValue(json['id'], fallback: originalUrl),
    title: _stringValue(json['title'], fallback: fallbackType.label),
    type: _mediaTypeFromJson(json['type'], fallback: fallbackType),
    previewUrl: previewUrl,
    originalUrl: originalUrl,
    width: _intValue(original?['width'], fallback: 320),
    height: _intValue(original?['height'], fallback: 240),
  );
}

KlipyMediaCategory? _categoryFromJson(Map<String, Object?> json) {
  final slug = _nullableString(json['slug']);
  final name = _nullableString(json['name']);
  if (slug == null || name == null) {
    return null;
  }
  return KlipyMediaCategory(
    name: name,
    slug: slug,
    imageUrl: _nullableString(json['image']),
  );
}

KlipyMediaType _mediaTypeFromJson(
  Object? value, {
  required KlipyMediaType fallback,
}) {
  if (value is! String) {
    return fallback;
  }
  for (final type in KlipyMediaType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return fallback;
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}

String _stringValue(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

int _intValue(Object? value, {required int fallback}) {
  return value is num ? value.toInt() : fallback;
}

const _klipyWebp =
    'https://static.klipy.com/ii/d7aec6f6171607374b2065c836f92f4/ec/f3/UKQXellq.webp';

const _seededKlipyItems = [
  KlipyMediaItem(
    id: 'gif-verdant-spark',
    title: 'Verdant spark',
    type: KlipyMediaType.gif,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 320,
    height: 240,
  ),
  KlipyMediaItem(
    id: 'gif-glow',
    title: 'Glow reaction',
    type: KlipyMediaType.gif,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 320,
    height: 240,
  ),
  KlipyMediaItem(
    id: 'gif-party',
    title: 'Party loop',
    type: KlipyMediaType.gif,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 320,
    height: 240,
  ),
  KlipyMediaItem(
    id: 'sticker-wave',
    title: 'Wave sticker',
    type: KlipyMediaType.sticker,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 256,
    height: 256,
  ),
  KlipyMediaItem(
    id: 'sticker-thanks',
    title: 'Thanks sticker',
    type: KlipyMediaType.sticker,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 256,
    height: 256,
  ),
  KlipyMediaItem(
    id: 'clip-ok',
    title: 'OK clip',
    type: KlipyMediaType.clip,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 360,
    height: 240,
  ),
  KlipyMediaItem(
    id: 'clip-hype',
    title: 'Hype clip',
    type: KlipyMediaType.clip,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 360,
    height: 240,
  ),
  KlipyMediaItem(
    id: 'meme-ship',
    title: 'Ship it',
    type: KlipyMediaType.meme,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 360,
    height: 240,
  ),
  KlipyMediaItem(
    id: 'meme-debug',
    title: 'Debug moment',
    type: KlipyMediaType.meme,
    previewUrl: _klipyWebp,
    originalUrl: _klipyWebp,
    width: 360,
    height: 240,
  ),
];

const _seededKlipyCategories = [
  KlipyMediaCategory(
    name: 'Reactions',
    slug: 'reactions',
    imageUrl: _klipyWebp,
  ),
  KlipyMediaCategory(name: 'Excited', slug: 'excited', imageUrl: _klipyWebp),
  KlipyMediaCategory(name: 'Gaming', slug: 'gaming', imageUrl: _klipyWebp),
  KlipyMediaCategory(name: 'Cute', slug: 'cute', imageUrl: _klipyWebp),
  KlipyMediaCategory(name: 'Memes', slug: 'memes', imageUrl: _klipyWebp),
  KlipyMediaCategory(
    name: 'Celebration',
    slug: 'celebration',
    imageUrl: _klipyWebp,
  ),
];
