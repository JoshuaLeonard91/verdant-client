import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/auth_service.dart';

void main() {
  test('register posts account creation to the selected API origin', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/auth/register');
      expect(body['email'], 'new@example.com');
      expect(body['password'], 'correct horse battery staple');
      expect(body.containsKey('registrationKey'), isFalse);
      expect(body['termsAccepted'], isTrue);
      expect(body['privacyAccepted'], isTrue);

      request.response.statusCode = HttpStatus.created;
      return _successPayload(
        accessToken: 'register-access-secret',
        sessionToken: 'register-session-secret',
        email: 'new@example.com',
      );
    });
    final service = HttpAuthService();
    addTearDown(service.close);
    addTearDown(exchange.close);

    final outcome = await service.register(
      apiOrigin: exchange.origin,
      email: ' <b>new@example.com</b>\u202e ',
      password: 'correct horse battery staple',
      termsAccepted: true,
      privacyAccepted: true,
    );

    expect(outcome, isA<AuthLoginSuccess>());
    final success = outcome as AuthLoginSuccess;
    expect(success.credentials.apiOrigin, exchange.origin);
    expect(success.credentials.accessToken, 'register-access-secret');
    expect(success.session.apiOrigin, exchange.origin);
    expect(success.session.user.email, 'new@example.com');
  });

  test(
    'register maps generic backend failures to actionable account creation copy',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/register');
        expect(body.containsKey('registrationKey'), isFalse);

        request.response.statusCode = HttpStatus.badRequest;
        return {
          'error': 'Registration failed',
          'code': 'AUTH_REGISTRATION_FAILED',
        };
      });
      final service = HttpAuthService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      await expectLater(
        service.register(
          apiOrigin: exchange.origin,
          email: 'existing@example.com',
          password: 'correct horse battery staple',
          termsAccepted: true,
          privacyAccepted: true,
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains('Sign in if this email already has an account'),
          ),
        ),
      );
    },
  );

  test(
    'login returns a two-factor challenge without credential material',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/login');
        expect(body['email'], 'boji@example.com');
        expect(body['password'], 'password123');

        return {'requiresTwoFactor': true, 'twoFactorTicket': 'ticket-secret'};
      });
      final service = HttpAuthService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      final outcome = await service.login(
        apiOrigin: exchange.origin,
        email: ' <b>boji@example.com</b>\u200b ',
        password: 'password123',
      );

      expect(outcome, isA<AuthLoginRequiresTwoFactor>());
      expect((outcome as AuthLoginRequiresTwoFactor).ticket, 'ticket-secret');
      expect(outcome.toString(), isNot(contains('password123')));
    },
  );

  test(
    'two-factor verification posts the ticket and parses the session',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/login/2fa');
        expect(body['twoFactorTicket'], 'ticket-secret');
        expect(body['code'], '123456');

        return _successPayload(
          accessToken: 'two-factor-access-secret',
          sessionToken: 'two-factor-session-secret',
          email: 'boji@example.com',
          totpEnabled: true,
        );
      });
      final service = HttpAuthService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      final outcome = await service.submitTwoFactor(
        apiOrigin: exchange.origin,
        ticket: 'ticket-secret',
        code: ' 123456 ',
      );

      expect(outcome, isA<AuthLoginSuccess>());
      final success = outcome as AuthLoginSuccess;
      expect(success.credentials.apiOrigin, exchange.origin);
      expect(success.credentials.accessToken, 'two-factor-access-secret');
      expect(success.session.user.totpEnabled, isTrue);
    },
  );

  test(
    'refreshSession posts the saved session token and parses rotated tokens',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/refresh');
        expect(body['sessionToken'], 'session-secret');
        expect(body.containsKey('accessToken'), isFalse);

        return {
          'accessToken': 'refreshed-access-secret',
          'sessionToken': 'rotated-session-secret',
        };
      });
      final service = HttpAuthService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      final refresh = await service.refreshSession(
        apiOrigin: exchange.origin,
        sessionToken: 'session-secret',
      );

      expect(refresh.accessToken, 'refreshed-access-secret');
      expect(refresh.sessionToken, 'rotated-session-secret');
    },
  );

  test(
    'refreshSession keeps legacy refresh responses backward compatible',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/refresh');
        expect(body['sessionToken'], 'session-secret');

        return {'accessToken': 'refreshed-access-secret'};
      });
      final service = HttpAuthService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      final refresh = await service.refreshSession(
        apiOrigin: exchange.origin,
        sessionToken: 'session-secret',
      );

      expect(refresh.accessToken, 'refreshed-access-secret');
      expect(refresh.sessionToken, isNull);
    },
  );

  test('refreshSession maps revoked sessions to sign-in copy', () async {
    final exchange = await _JsonExchange.start((request, body) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/auth/refresh');

      request.response.statusCode = HttpStatus.unauthorized;
      return {'error': 'Token revoked'};
    });
    final service = HttpAuthService();
    addTearDown(service.close);
    addTearDown(exchange.close);

    await expectLater(
      service.refreshSession(
        apiOrigin: exchange.origin,
        sessionToken: 'revoked-session-secret',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Sign in again to continue',
        ),
      ),
    );
  });

  test(
    'refreshSession treats forbidden refresh as credential clearing auth failure',
    () async {
      final exchange = await _JsonExchange.start((request, body) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/refresh');

        request.response.statusCode = HttpStatus.forbidden;
        return {'error': 'Session revoked'};
      });
      final service = HttpAuthService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      await expectLater(
        service.refreshSession(
          apiOrigin: exchange.origin,
          sessionToken: 'revoked-session-secret',
        ),
        throwsA(
          isA<AuthRefreshException>()
              .having((error) => error.message, 'message', 'Session revoked')
              .having(
                (error) => error.shouldClearCredentials,
                'shouldClearCredentials',
                isTrue,
              ),
        ),
      );
    },
  );

  test(
    'refreshSession keeps malformed empty and network refresh failures non-clearing',
    () async {
      final malformed = await _RawExchange.start((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('{not-json');
      });
      final empty = await _RawExchange.start((request) async {
        request.response.statusCode = HttpStatus.ok;
      });
      final oversized = await _RawExchange.start((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('{"accessToken":"${'x' * 64}"}');
      });
      final missing = await _RawExchange.start((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': true}));
      });
      final service = HttpAuthService(maxResponseBytes: 32);
      addTearDown(service.close);
      addTearDown(malformed.close);
      addTearDown(empty.close);
      addTearDown(oversized.close);
      addTearDown(missing.close);

      for (final origin in [
        malformed.origin,
        empty.origin,
        oversized.origin,
        missing.origin,
      ]) {
        await expectLater(
          service.refreshSession(
            apiOrigin: origin,
            sessionToken: 'session-secret',
          ),
          throwsA(
            isA<AuthRefreshException>().having(
              (error) => error.shouldClearCredentials,
              'shouldClearCredentials',
              isFalse,
            ),
          ),
        );
      }
    },
  );
}

Map<String, Object?> _successPayload({
  required String accessToken,
  required String sessionToken,
  required String email,
  bool totpEnabled = false,
}) {
  return {
    'accessToken': accessToken,
    'sessionToken': sessionToken,
    'user': {
      'id': '42',
      'username': 'boji',
      'email': email,
      'status': 'online',
      'usernameSet': true,
      'emailVerified': true,
      'totpEnabled': totpEnabled,
    },
  };
}

final class _JsonExchange {
  _JsonExchange._(this._server, this.origin);

  final HttpServer _server;
  final String origin;

  static Future<_JsonExchange> start(
    FutureOr<Map<String, Object?>> Function(
      HttpRequest request,
      Map<String, Object?> body,
    )
    handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    unawaited(_handleOne(server, handler));
    return _JsonExchange._(server, origin);
  }

  static Future<void> _handleOne(
    HttpServer server,
    FutureOr<Map<String, Object?>> Function(
      HttpRequest request,
      Map<String, Object?> body,
    )
    handler,
  ) async {
    final request = await server.first;
    final text = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(text);
    final body = decoded is Map<String, Object?>
        ? decoded
        : Map<String, Object?>.from(decoded as Map);

    try {
      final payload = await handler(request, body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(payload));
    } finally {
      await request.response.close();
    }
  }

  Future<void> close() => _server.close(force: true);
}

final class _RawExchange {
  _RawExchange._(this._server, this.origin);

  final HttpServer _server;
  final String origin;

  static Future<_RawExchange> start(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    unawaited(_handleOne(server, handler));
    return _RawExchange._(server, origin);
  }

  static Future<void> _handleOne(
    HttpServer server,
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    final request = await server.first;
    await utf8.decoder.bind(request).join();

    try {
      await handler(request);
    } finally {
      await request.response.close();
    }
  }

  Future<void> close() => _server.close(force: true);
}
