import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/workspace/shared/inactive_backend_runtime.dart';
import 'package:verdant_flutter/features/workspace/shared/sync_summary_service.dart';

void main() {
  const official = JoinedBackendRuntimeProfile(
    networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
    apiOrigin: 'https://api.verdant.chat',
    authenticated: true,
    available: true,
  );
  const selfHost = JoinedBackendRuntimeProfile(
    networkId: 'origin:https%3A%2F%2Fapi.example.test',
    apiOrigin: 'https://api.example.test',
    authenticated: true,
    available: true,
  );

  test(
    'runtime lifecycle transitions active to warm to cold and reconnects',
    () async {
      final delegate = _FakeRuntimeDelegate();
      final manager = InactiveBackendRuntimeManager(
        delegate: delegate,
        idleTimeout: const Duration(minutes: 5),
        coldTimeout: const Duration(minutes: 30),
        warmPollInterval: const Duration(seconds: 15),
        coldPollInterval: const Duration(minutes: 2),
      );

      final start = DateTime.utc(2026, 6, 21, 12);
      manager.register(official, now: start);
      await manager.setActiveNetwork(official.networkId, now: start);

      expect(
        manager.stateOf(official.networkId),
        BackendRuntimeLifecycleState.active,
      );
      expect(delegate.connected, [official.networkId]);

      await manager.setActiveNetwork(
        null,
        now: start.add(const Duration(minutes: 1)),
      );
      await manager.advance(start.add(const Duration(minutes: 6)));

      expect(
        manager.stateOf(official.networkId),
        BackendRuntimeLifecycleState.warm,
      );
      expect(delegate.disconnected, [official.networkId]);

      await manager.advance(start.add(const Duration(minutes: 31)));
      expect(
        manager.stateOf(official.networkId),
        BackendRuntimeLifecycleState.cold,
      );

      await manager.setActiveNetwork(
        official.networkId,
        now: start.add(const Duration(minutes: 32)),
      );
      expect(
        manager.stateOf(official.networkId),
        BackendRuntimeLifecycleState.active,
      );
      expect(delegate.connected, [official.networkId, official.networkId]);
    },
  );

  test(
    'inactive polling uses owning backend origin and never active backend origin',
    () async {
      final delegate = _FakeRuntimeDelegate();
      final manager = InactiveBackendRuntimeManager(
        delegate: delegate,
        idleTimeout: const Duration(minutes: 5),
        coldTimeout: const Duration(minutes: 30),
        warmPollInterval: const Duration(seconds: 15),
        coldPollInterval: const Duration(minutes: 2),
      );

      final start = DateTime.utc(2026, 6, 21, 12);
      manager
        ..register(official, now: start)
        ..register(selfHost, now: start);
      await manager.setActiveNetwork(official.networkId, now: start);

      await manager.advance(start);

      expect(delegate.polledOrigins, [selfHost.apiOrigin]);
      expect(delegate.polledOrigins, isNot(contains(official.apiOrigin)));
    },
  );

  test('signed-out and unavailable networks do not poll', () async {
    final delegate = _FakeRuntimeDelegate();
    final manager = InactiveBackendRuntimeManager(
      delegate: delegate,
      idleTimeout: const Duration(minutes: 5),
      coldTimeout: const Duration(minutes: 30),
      warmPollInterval: const Duration(seconds: 15),
      coldPollInterval: const Duration(minutes: 2),
    );

    final start = DateTime.utc(2026, 6, 21, 12);
    manager
      ..register(
        const JoinedBackendRuntimeProfile(
          networkId: 'origin:https%3A%2F%2Fsigned-out.example.test',
          apiOrigin: 'https://signed-out.example.test',
          authenticated: false,
          available: true,
        ),
        now: start,
      )
      ..register(
        const JoinedBackendRuntimeProfile(
          networkId: 'origin:https%3A%2F%2Funavailable.example.test',
          apiOrigin: 'https://unavailable.example.test',
          authenticated: true,
          available: false,
        ),
        now: start,
      );

    await manager.advance(start);

    expect(delegate.polledOrigins, isEmpty);
  });

  test('summary badges update only the owning network snapshot', () async {
    final delegate = _FakeRuntimeDelegate(
      summaries: {
        selfHost.networkId: const SyncSummarySnapshot(
          cursor: '1800000000000',
          servers: [
            SyncServerSummary(
              serverId: '10',
              unreadCount: 4,
              mentionCount: 1,
              lastActivityAt: '2026-06-21T12:00:00Z',
            ),
          ],
          dms: [],
          notifications: [],
          requiresReconnect: false,
        ),
      },
    );
    final manager = InactiveBackendRuntimeManager(
      delegate: delegate,
      idleTimeout: const Duration(minutes: 5),
      coldTimeout: const Duration(minutes: 30),
      warmPollInterval: const Duration(seconds: 15),
      coldPollInterval: const Duration(minutes: 2),
    );

    final start = DateTime.utc(2026, 6, 21, 12);
    manager
      ..register(official, now: start)
      ..register(selfHost, now: start);
    await manager.setActiveNetwork(official.networkId, now: start);
    await manager.advance(start);

    expect(
      manager.summaryOf(selfHost.networkId)?.servers.single.unreadCount,
      4,
    );
    expect(manager.summaryOf(official.networkId), isNull);
  });

  test(
    'http summary client uses owning origin, cursor, and stored bearer token',
    () async {
      late final String origin;
      final exchange = await _JsonExchange.start((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/sync/summary');
        expect(request.uri.queryParameters['since'], '1800000000000');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer access-secret',
        );
        expect(
          request.headers.value(HttpHeaders.cacheControlHeader),
          'no-cache',
        );
        expect(request.headers.value(HttpHeaders.pragmaHeader), 'no-cache');
        final expectedOrigin = Uri.parse(origin);
        expect(request.headers.host, expectedOrigin.host);
        expect(request.headers.port, expectedOrigin.port);

        return {
          'cursor': '1800000000100',
          'servers': [
            {
              'serverId': '42',
              'unreadCount': 2,
              'mentionCount': 1,
              'lastActivityAt': '2026-06-21T12:00:00Z',
            },
          ],
          'dms': [],
          'notifications': [],
          'requiresReconnect': false,
        };
      });
      origin = exchange.origin;
      addTearDown(exchange.close);

      final profile = JoinedBackendRuntimeProfile(
        networkId: networkIdFromApiOrigin(origin),
        apiOrigin: origin,
        authenticated: true,
        available: true,
      );
      final client = HttpSyncSummaryClient(
        credentialStore: _MemoryCredentialStore({
          origin: AuthCredentialBundle(
            apiOrigin: origin,
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
        }),
      );
      addTearDown(client.close);

      final snapshot = await client.fetchSummary(
        profile,
        since: '1800000000000',
      );

      expect(snapshot.cursor, '1800000000100');
      expect(snapshot.servers.single.serverId, '42');
      expect(snapshot.servers.single.unreadCount, 2);
    },
  );

  test(
    'http summary client fails closed on mismatched network id and api origin',
    () async {
      var requests = 0;
      final exchange = await _JsonExchange.start((request) async {
        requests += 1;
        return {'cursor': '1800000000000'};
      });
      addTearDown(exchange.close);

      final client = HttpSyncSummaryClient(
        credentialStore: _MemoryCredentialStore({
          exchange.origin: AuthCredentialBundle(
            apiOrigin: exchange.origin,
            accessToken: 'access-secret',
            sessionToken: 'session-secret',
          ),
        }),
      );
      addTearDown(client.close);

      await expectLater(
        client.fetchSummary(
          JoinedBackendRuntimeProfile(
            networkId: networkIdFromApiOrigin('https://wrong.example.test'),
            apiOrigin: exchange.origin,
            authenticated: true,
            available: true,
          ),
        ),
        throwsA(
          isA<SyncSummaryClientException>().having(
            (error) => error.message,
            'message',
            'Invalid backend profile',
          ),
        ),
      );
      expect(requests, 0);
    },
  );

  test('http summary client fails closed without stored credentials', () async {
    var requests = 0;
    final exchange = await _JsonExchange.start((request) async {
      requests += 1;
      return {'cursor': '1800000000000'};
    });
    addTearDown(exchange.close);

    final client = HttpSyncSummaryClient(
      credentialStore: _MemoryCredentialStore(),
    );
    addTearDown(client.close);

    await expectLater(
      client.fetchSummary(
        JoinedBackendRuntimeProfile(
          networkId: networkIdFromApiOrigin(exchange.origin),
          apiOrigin: exchange.origin,
          authenticated: true,
          available: true,
        ),
      ),
      throwsA(
        isA<SyncSummaryClientException>().having(
          (error) => error.isAuthExpired,
          'isAuthExpired',
          isTrue,
        ),
      ),
    );
    expect(requests, 0);
  });
}

final class _FakeRuntimeDelegate implements InactiveBackendRuntimeDelegate {
  _FakeRuntimeDelegate({this.summaries = const {}});

  final Map<String, SyncSummarySnapshot> summaries;
  final connected = <String>[];
  final disconnected = <String>[];
  final polledOrigins = <String>[];

  @override
  Future<void> connect(JoinedBackendRuntimeProfile profile) async {
    connected.add(profile.networkId);
  }

  @override
  Future<void> disconnect(JoinedBackendRuntimeProfile profile) async {
    disconnected.add(profile.networkId);
  }

  @override
  Future<SyncSummarySnapshot> fetchSummary(
    JoinedBackendRuntimeProfile profile, {
    String? since,
  }) async {
    polledOrigins.add(profile.apiOrigin);
    return summaries[profile.networkId] ??
        const SyncSummarySnapshot(
          cursor: '1800000000000',
          servers: [],
          dms: [],
          notifications: [],
          requiresReconnect: false,
        );
  }
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  _MemoryCredentialStore([Map<String, AuthCredentialBundle>? initial])
    : _credentials = {
        for (final entry in (initial ?? const {}).entries)
          normalizeBackendApiOrigin(entry.key): entry.value,
      };

  final Map<String, AuthCredentialBundle> _credentials;

  @override
  Future<void> clear(String apiOrigin) async {
    _credentials.remove(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<bool> contains(String apiOrigin) async {
    return _credentials.containsKey(normalizeBackendApiOrigin(apiOrigin));
  }

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    return _credentials[normalizeBackendApiOrigin(apiOrigin)];
  }

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    _credentials[credentials.normalizedApiOrigin] = credentials;
  }
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
    unawaited(_handle(server, handler));
    return _JsonExchange._(server, origin);
  }

  static Future<void> _handle(
    HttpServer server,
    FutureOr<Map<String, Object?>> Function(HttpRequest request) handler,
  ) async {
    await for (final request in server) {
      try {
        final payload = await handler(request);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(payload));
      } finally {
        await request.response.close();
      }
    }
  }

  Future<void> close() => _server.close(force: true);
}
