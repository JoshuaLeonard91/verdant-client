import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_loader.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/server_media_url_policy.dart';

void main() {
  test(
    'loads bounded raster media from an allowed local backend origin',
    () async {
      final exchange = await _MediaExchange.start((request) async {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(_pngBytes);
        await request.response.close();
      });
      addTearDown(exchange.close);

      final loader = ServerMediaLoader(maxBytes: 1024);
      addTearDown(loader.close);
      final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

      final bytes = await loader.load(
        Uri.parse('${exchange.origin}/server-icons/123/icon.png'),
        policy: policy,
      );

      expect(bytes, _pngBytes);
    },
  );

  test('follows bounded redirects that stay inside media policy', () async {
    final exchange = await _MediaExchange.start((request) async {
      if (request.uri.path.endsWith('/redirect.png')) {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          '/server-icons/123/icon.png',
        );
      } else {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(_pngBytes);
      }
      await request.response.close();
    });
    addTearDown(exchange.close);

    final loader = ServerMediaLoader(maxBytes: 1024);
    addTearDown(loader.close);
    final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

    final bytes = await loader.load(
      Uri.parse('${exchange.origin}/server-icons/123/redirect.png'),
      policy: policy,
    );

    expect(bytes, _pngBytes);
  });

  test(
    'reuses one HTTP client for repeated loads under the same policy',
    () async {
      final exchange = await _MediaExchange.start((request) async {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add(_pngBytes);
        await request.response.close();
      });
      addTearDown(exchange.close);
      var clientCreations = 0;
      final loader = ServerMediaLoader(
        maxBytes: 1024,
        httpClientFactory: () {
          clientCreations += 1;
          return HttpClient();
        },
      );
      addTearDown(loader.close);
      final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

      await loader.load(
        Uri.parse('${exchange.origin}/server-icons/123/icon.png'),
        policy: policy,
      );
      await loader.load(
        Uri.parse('${exchange.origin}/avatars/456/avatar.png'),
        policy: policy,
      );

      expect(clientCreations, 1);
    },
  );

  test('applies the timeout to the full media body load', () async {
    final exchange = await _MediaExchange.start((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(_pngBytes.take(8).toList(growable: false));
      await request.response.flush();
      for (final byte in _pngBytes.skip(8)) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
        request.response.add([byte]);
        await request.response.flush();
      }
      await request.response.close();
    });
    addTearDown(exchange.close);
    final loader = ServerMediaLoader(
      maxBytes: 1024,
      timeout: const Duration(milliseconds: 120),
    );
    addTearDown(loader.close);
    final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

    final stopwatch = Stopwatch()..start();
    await expectLater(
      loader.load(
        Uri.parse('${exchange.origin}/server-icons/123/icon.png'),
        policy: policy,
      ),
      throwsA(
        isA<ServerMediaLoadException>().having(
          (error) => error.message,
          'message',
          'Media request timed out',
        ),
      ),
    );

    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
  });

  test('rejects media redirects outside public media policy', () async {
    final exchange = await _MediaExchange.start((request) async {
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        '/api/media/attachments/42',
      );
      await request.response.close();
    });
    addTearDown(exchange.close);

    final loader = ServerMediaLoader(maxBytes: 1024);
    addTearDown(loader.close);
    final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

    await expectLater(
      loader.load(
        Uri.parse('${exchange.origin}/server-icons/123/icon.png'),
        policy: policy,
      ),
      throwsA(
        isA<ServerMediaLoadException>().having(
          (error) => error.message,
          'message',
          'Media redirect URL is not allowed',
        ),
      ),
    );
  });

  test('rejects non-raster media content', () async {
    final exchange = await _MediaExchange.start((request) async {
      request.response.headers.contentType = ContentType('image', 'svg+xml');
      request.response.write('<svg xmlns="http://www.w3.org/2000/svg"></svg>');
      await request.response.close();
    });
    addTearDown(exchange.close);

    final loader = ServerMediaLoader(maxBytes: 1024);
    addTearDown(loader.close);
    final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

    await expectLater(
      loader.load(
        Uri.parse('${exchange.origin}/server-icons/123/icon.svg'),
        policy: policy,
      ),
      throwsA(isA<ServerMediaLoadException>()),
    );
  });

  test('rejects media responses over the configured byte cap', () async {
    final exchange = await _MediaExchange.start((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add([..._pngBytes, ...List<int>.filled(32, 1)]);
      await request.response.close();
    });
    addTearDown(exchange.close);

    final loader = ServerMediaLoader(maxBytes: _pngBytes.length);
    addTearDown(loader.close);
    final policy = ServerMediaPolicy.fromOrigins(apiOrigin: exchange.origin);

    await expectLater(
      loader.load(
        Uri.parse('${exchange.origin}/server-icons/123/icon.png'),
        policy: policy,
      ),
      throwsA(isA<ServerMediaLoadException>()),
    );
  });

  test('opens HTTPS media through a validated resolved address', () async {
    final resolvedAddress = InternetAddress('93.184.216.34');
    InternetAddress? connectedAddress;
    String? connectedHost;
    int? connectedPort;
    bool? connectedSecure;
    final loader = ServerMediaLoader(
      addressResolver: (_) async => [resolvedAddress],
      socketConnector: (address, host, port, secure, timeout) {
        connectedAddress = address;
        connectedHost = host;
        connectedPort = port;
        connectedSecure = secure;
        throw const ServerMediaLoadException('stop after validated connect');
      },
    );
    addTearDown(loader.close);
    final policy = ServerMediaPolicy.fromOrigins(
      apiOrigin: 'https://api.example.com',
      cdnUrl: 'https://media.example.test',
    );

    await expectLater(
      loader.load(
        Uri.parse('https://media.example.test/server-icons/123/icon.png'),
        policy: policy,
      ),
      throwsA(isA<ServerMediaLoadException>()),
    );

    expect(connectedAddress, resolvedAddress);
    expect(connectedHost, 'media.example.test');
    expect(connectedPort, 443);
    expect(connectedSecure, isTrue);
  });

  test('rejects private resolved media addresses before connecting', () async {
    for (final address in [
      '192.168.1.10',
      '100.64.0.1',
      '198.18.0.1',
      '::ffff:127.0.0.1',
      '::ffff:10.0.0.1',
      '::ffff:192.168.1.10',
    ]) {
      var connected = false;
      final loader = ServerMediaLoader(
        addressResolver: (_) async => [InternetAddress(address)],
        socketConnector: (address, host, port, secure, timeout) {
          connected = true;
          throw const ServerMediaLoadException('should not connect');
        },
      );
      addTearDown(loader.close);
      final policy = ServerMediaPolicy.fromOrigins(
        apiOrigin: 'https://api.example.com',
        cdnUrl: 'https://media.example.test',
      );

      await expectLater(
        loader.load(
          Uri.parse('https://media.example.test/server-icons/123/icon.png'),
          policy: policy,
        ),
        throwsA(isA<ServerMediaLoadException>()),
        reason: address,
      );

      expect(connected, isFalse, reason: address);
    }
  });

  test(
    'rejects mixed public and private resolved media addresses before request',
    () async {
      var connected = false;
      final loader = ServerMediaLoader(
        addressResolver: (_) async => [
          InternetAddress('104.21.89.2'),
          InternetAddress('192.168.1.10'),
        ],
        socketConnector: (address, host, port, secure, timeout) {
          connected = true;
          throw const ServerMediaLoadException('should not connect');
        },
      );
      addTearDown(loader.close);
      final policy = ServerMediaPolicy.fromOrigins(
        apiOrigin: 'https://api.example.com',
        cdnUrl: 'https://media.example.test',
      );

      await expectLater(
        loader.load(
          Uri.parse('https://media.example.test/server-icons/123/icon.png'),
          policy: policy,
        ),
        throwsA(
          isA<ServerMediaLoadException>().having(
            (error) => error.message,
            'message',
            'Media host resolved to a private address',
          ),
        ),
      );
      expect(connected, isFalse);
    },
  );
}

const _pngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
];

typedef _MediaHandler = Future<void> Function(HttpRequest request);

final class _MediaExchange {
  const _MediaExchange._(this._server, this.origin);

  final HttpServer _server;
  final String origin;

  static Future<_MediaExchange> start(_MediaHandler handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handler);
    return _MediaExchange._(server, 'http://127.0.0.1:${server.port}');
  }

  Future<void> close() => _server.close(force: true);
}
