import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/instance_metadata_service.dart';

void main() {
  test('fetches public registration policy from instance metadata', () async {
    final exchange = await _JsonExchange.start((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/instance');

      return {'registration': 'public'};
    });
    final service = HttpInstanceMetadataService();
    addTearDown(service.close);
    addTearDown(exchange.close);

    final policy = await service.fetchRegistrationPolicy(
      apiOrigin: exchange.origin,
    );

    expect(policy, InstanceRegistrationPolicy.public);
    expect(policy.allowsAccountCreation, isTrue);
  });

  test('treats invite registration as not publicly creatable', () async {
    final exchange = await _JsonExchange.start((request) async {
      expect(request.uri.path, '/api/instance');
      return {'registration': 'invite'};
    });
    final service = HttpInstanceMetadataService();
    addTearDown(service.close);
    addTearDown(exchange.close);

    final policy = await service.fetchRegistrationPolicy(
      apiOrigin: exchange.origin,
    );

    expect(policy, InstanceRegistrationPolicy.invite);
    expect(policy.allowsAccountCreation, isFalse);
  });

  test('fails closed when instance metadata is unavailable', () async {
    final exchange = await _JsonExchange.start((request) async {
      request.response.statusCode = HttpStatus.notFound;
      return {'error': 'Not found'};
    });
    final service = HttpInstanceMetadataService();
    addTearDown(service.close);
    addTearDown(exchange.close);

    await expectLater(
      service.fetchRegistrationPolicy(apiOrigin: exchange.origin),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Could not check account creation for this network',
        ),
      ),
    );
  });
}

final class _JsonExchange {
  _JsonExchange._(this._server, this.origin);

  final HttpServer _server;
  final String origin;

  static Future<_JsonExchange> start(
    FutureOr<Map<String, Object?>> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    unawaited(_handleOne(server, handler));
    return _JsonExchange._(server, origin);
  }

  static Future<void> _handleOne(
    HttpServer server,
    FutureOr<Map<String, Object?>> Function(HttpRequest request) handler,
  ) async {
    final request = await server.first;
    try {
      final payload = await handler(request);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(payload));
    } finally {
      await request.response.close();
    }
  }

  Future<void> close() => _server.close(force: true);
}
