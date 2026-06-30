import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/klipy_media_repository.dart';

void main() {
  test(
    'http klipy repository uses authenticated backend search route',
    () async {
      final exchange = await _JsonExchange.start((request, body) {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/gifs/search');
        expect(request.uri.queryParameters['q'], 'tree');
        expect(request.uri.queryParameters['limit'], '20');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access',
        );
        return {
          'results': [
            {
              'id': 'gif-live',
              'title': 'Live GIF',
              'type': 'gif',
              'images': {
                'original': {
                  'url': 'https://static.klipy.com/i/live.gif',
                  'width': 320,
                  'height': 180,
                },
                'tinygif': {
                  'url': 'https://static.klipy.com/i/live-preview.webp',
                  'width': 160,
                  'height': 90,
                },
              },
            },
          ],
        };
      });
      addTearDown(exchange.close);

      final repository = HttpKlipyMediaRepository(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(exchange.origin),
      );
      addTearDown(repository.close);

      final result = await repository.load(
        type: KlipyMediaType.gif,
        query: 'tree',
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.id, 'gif-live');
      expect(
        result.items.single.originalUrl,
        'https://static.klipy.com/i/live.gif',
      );
      expect(
        result.items.single.previewUrl,
        'https://static.klipy.com/i/live-preview.webp',
      );
    },
  );

  test(
    'http klipy repository loads categories from selected media type',
    () async {
      final exchange = await _JsonExchange.start((request, body) {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/stickers/categories');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access',
        );
        return {
          'categories': [
            {
              'name': 'Reactions',
              'slug': 'reactions',
              'image': 'https://static.klipy.com/i/category.webp',
            },
          ],
        };
      });
      addTearDown(exchange.close);

      final repository = HttpKlipyMediaRepository(
        apiOrigin: exchange.origin,
        credentialStore: _MemoryCredentialStore(exchange.origin),
      );
      addTearDown(repository.close);

      final categories = await repository.loadCategories(
        type: KlipyMediaType.sticker,
      );

      expect(categories, hasLength(1));
      expect(categories.single.name, 'Reactions');
      expect(categories.single.slug, 'reactions');
      expect(
        categories.single.imageUrl,
        'https://static.klipy.com/i/category.webp',
      );
    },
  );

  test('http klipy repository reuses fresh category cache', () async {
    var requests = 0;
    final exchange = await _JsonExchange.start((request, body) {
      requests += 1;
      expect(request.uri.path, '/api/gifs/categories');
      return {
        'categories': [
          {
            'name': 'Reactions',
            'slug': 'reactions',
            'image': 'https://static.klipy.com/i/category.webp',
          },
        ],
      };
    });
    addTearDown(exchange.close);

    final repository = HttpKlipyMediaRepository(
      apiOrigin: exchange.origin,
      credentialStore: _MemoryCredentialStore(exchange.origin),
    );
    addTearDown(repository.close);

    final first = await repository.loadCategories(type: KlipyMediaType.gif);
    final second = await repository.loadCategories(type: KlipyMediaType.gif);

    expect(first.single.slug, 'reactions');
    expect(second.single.slug, 'reactions');
    expect(requests, 1);
  });

  test(
    'http klipy repository refreshes credentials after unauthorized response',
    () async {
      var mediaRequests = 0;
      var refreshRequests = 0;
      late final _MemoryCredentialStore credentials;
      final exchange = await _JsonExchange.start((request, body) {
        if (request.uri.path == '/api/auth/refresh') {
          refreshRequests += 1;
          expect(body, isA<Map<String, Object?>>());
          expect((body as Map<String, Object?>)['sessionToken'], 'session');
          return {
            'accessToken': 'refreshed-access',
            'sessionToken': 'rotated-session',
          };
        }

        expect(request.uri.path, '/api/gifs/trending');
        mediaRequests += 1;
        if (mediaRequests == 1) {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer access',
          );
          return {'__status': 401, 'error': 'Unauthorized'};
        }

        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer refreshed-access',
        );
        return {
          'results': [
            {
              'id': 'gif-refreshed',
              'title': 'Refreshed GIF',
              'type': 'gif',
              'images': {
                'original': {
                  'url': 'https://static.klipy.com/i/refreshed.gif',
                  'width': 320,
                  'height': 180,
                },
                'tinygif': {
                  'url': 'https://static.klipy.com/i/refreshed.webp',
                  'width': 160,
                  'height': 90,
                },
              },
            },
          ],
        };
      });
      addTearDown(exchange.close);
      credentials = _MemoryCredentialStore(exchange.origin);

      final repository = HttpKlipyMediaRepository(
        apiOrigin: exchange.origin,
        credentialStore: credentials,
      );
      addTearDown(repository.close);

      final result = await repository.load(type: KlipyMediaType.gif);

      expect(result.items.single.id, 'gif-refreshed');
      expect(mediaRequests, 2);
      expect(refreshRequests, 1);
      expect(
        (await credentials.read(exchange.origin))!.accessToken,
        'refreshed-access',
      );
    },
  );

  test('http klipy repository wraps transport failures safely', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    await server.close(force: true);

    final repository = HttpKlipyMediaRepository(
      apiOrigin: origin,
      credentialStore: _MemoryCredentialStore(origin),
      timeout: const Duration(milliseconds: 500),
    );
    addTearDown(repository.close);

    await expectLater(
      repository.load(type: KlipyMediaType.gif),
      throwsA(
        isA<KlipyMediaException>().having(
          (error) => error.message,
          'message',
          isIn(const [
            'Could not reach Klipy media',
            'Klipy request timed out',
          ]),
        ),
      ),
    );
  });
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  _MemoryCredentialStore(
    this.apiOrigin, {
    String accessToken = 'access',
    String sessionToken = 'session',
  }) : _credentials = AuthCredentialBundle(
         apiOrigin: apiOrigin,
         accessToken: accessToken,
         sessionToken: sessionToken,
       );

  final String apiOrigin;
  AuthCredentialBundle _credentials;

  @override
  Future<void> clear(String apiOrigin) async {}

  @override
  Future<bool> contains(String apiOrigin) async => true;

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    if (normalizeBackendApiOrigin(apiOrigin) !=
        normalizeBackendApiOrigin(this.apiOrigin)) {
      return null;
    }
    return _credentials;
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    _credentials = credentials;
  }
}

final class _JsonExchange {
  _JsonExchange._(this._server, this.origin);

  final HttpServer _server;
  final String origin;

  static Future<_JsonExchange> start(
    FutureOr<Map<String, Object?>> Function(HttpRequest request, Object? body)
    handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    unawaited(_handle(server, handler));
    return _JsonExchange._(server, origin);
  }

  static Future<void> _handle(
    HttpServer server,
    FutureOr<Map<String, Object?>> Function(HttpRequest request, Object? body)
    handler,
  ) async {
    await for (final request in server) {
      final bytes = await request.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      final body = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
      try {
        final payload = Map<String, Object?>.from(await handler(request, body));
        final status = payload.remove('__status');
        if (status is int) {
          request.response.statusCode = status;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(payload));
      } finally {
        await request.response.close();
      }
    }
  }

  Future<void> close() => _server.close(force: true);
}
