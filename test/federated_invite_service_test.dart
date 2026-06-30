import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/auth_service.dart';
import 'package:verdant_flutter/features/workspace/server_settings_workspace/federated_invite_service.dart';

void main() {
  test(
    'join asks home backend to refresh membership and stores federated credential',
    () async {
      final homeServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final homeOrigin = 'http://${homeServer.address.host}:${homeServer.port}';
      const targetOrigin = 'https://api.target.example';
      final requests = <({String method, String path, String? auth})>[];
      final store = _MemoryCredentialStore();
      await store.save(
        AuthCredentialBundle(
          apiOrigin: homeOrigin,
          accessToken: 'home-access',
          sessionToken: 'home-session',
        ),
      );
      expect(await store.read(targetOrigin), isNull);

      final homeServing = homeServer.listen((request) async {
        requests.add((
          method: request.method,
          path: request.uri.path,
          auth: request.headers.value(HttpHeaders.authorizationHeader),
        ));
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/federation/invites/join') {
          await utf8.decoder.bind(request).join();
          request.response.statusCode = HttpStatus.accepted;
          request.response.write(
            jsonEncode({
              'status': 'queued',
              'queuedEvents': 2,
              'duplicateEvents': 0,
              'membership': _membershipJson(targetOrigin: targetOrigin),
            }),
          );
        } else if (request.uri.path ==
            '/api/federation/memberships/mem-1/capability') {
          await utf8.decoder.bind(request).join();
          request.response.write(
            jsonEncode(_readyCapabilityJson(serverId: '123')),
          );
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'not found'}));
        }
        await request.response.close();
      });

      final service = HttpFederatedInviteJoinService(
        apiOrigin: homeOrigin,
        credentialStore: store,
        authService: const _UnusedAuthService(),
        capabilityPollAttempts: 1,
      );
      addTearDown(() {
        service.close();
        unawaited(homeServing.cancel());
        unawaited(homeServer.close(force: true));
      });

      final result = await service.joinInvite(
        targetApiOrigin: targetOrigin,
        targetPeerId: 'host:target.example',
        serverId: '123',
        code: 'Invite123',
      );

      expect(result.credentialIssued, isTrue);
      expect(result.membership?.id, 'mem-1');
      expect(requests.map((request) => request.path), [
        '/api/federation/invites/join',
        '/api/federation/memberships/mem-1/capability',
      ]);
      expect(
        requests.every((request) => request.auth == 'Bearer home-access'),
        isTrue,
      );

      final targetCredentials = await store.read(targetOrigin);
      expect(targetCredentials?.accessToken, 'target-federated-access');
      expect(targetCredentials?.sessionToken, isEmpty);
      expect(targetCredentials?.kind, AuthCredentialKind.federatedClient);
      expect(targetCredentials?.user?.id, '9001');
    },
  );

  test(
    'join polls home membership refresh while membership is pending',
    () async {
      final homeServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final homeOrigin = 'http://${homeServer.address.host}:${homeServer.port}';
      const targetOrigin = 'https://api.target.example';
      var joinRequests = 0;
      var refreshRequests = 0;
      final store = _MemoryCredentialStore();
      await store.save(
        AuthCredentialBundle(
          apiOrigin: homeOrigin,
          accessToken: 'home-access',
          sessionToken: 'home-session',
        ),
      );

      final homeServing = homeServer.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/federation/invites/join') {
          joinRequests += 1;
          await utf8.decoder.bind(request).join();
          request.response.statusCode = HttpStatus.accepted;
          request.response.write(
            jsonEncode({
              'status': 'queued',
              'queuedEvents': 2,
              'duplicateEvents': 0,
              'membership': _membershipJson(targetOrigin: targetOrigin),
            }),
          );
        } else if (request.uri.path ==
            '/api/federation/memberships/mem-1/capability') {
          refreshRequests += 1;
          await utf8.decoder.bind(request).join();
          if (refreshRequests == 1) {
            request.response.write(
              jsonEncode({'status': 'pending', 'reason': 'membership_pending'}),
            );
          } else {
            request.response.write(
              jsonEncode(_readyCapabilityJson(serverId: '123')),
            );
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'not found'}));
        }
        await request.response.close();
      });

      final service = HttpFederatedInviteJoinService(
        apiOrigin: homeOrigin,
        credentialStore: store,
        authService: const _UnusedAuthService(),
        capabilityPollAttempts: 2,
        capabilityPollDelay: Duration.zero,
      );
      addTearDown(() {
        service.close();
        unawaited(homeServing.cancel());
        unawaited(homeServer.close(force: true));
      });

      final result = await service.joinInvite(
        targetApiOrigin: targetOrigin,
        targetPeerId: 'host:target.example',
        serverId: '123',
        code: 'Invite123',
      );

      expect(result.credentialIssued, isTrue);
      expect(joinRequests, 1);
      expect(refreshRequests, 2);
      expect(
        (await store.read(targetOrigin))?.kind,
        AuthCredentialKind.federatedClient,
      );
    },
  );

  test('join ignores legacy client-forwarded capability material', () async {
    final homeServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final targetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final homeOrigin = 'http://${homeServer.address.host}:${homeServer.port}';
    final targetOrigin =
        'http://${targetServer.address.host}:${targetServer.port}';
    final targetRequests = <String>[];
    final store = _MemoryCredentialStore();
    await store.save(
      AuthCredentialBundle(
        apiOrigin: homeOrigin,
        accessToken: 'home-access',
        sessionToken: 'home-session',
      ),
    );

    final homeServing = homeServer.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/federation/invites/join') {
        await utf8.decoder.bind(request).join();
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(
          jsonEncode({
            'status': 'queued',
            'queuedEvents': 2,
            'duplicateEvents': 0,
            'membership': _membershipJson(targetOrigin: targetOrigin),
            'capabilityClaim': {
              'method': 'POST',
              'path': '/api/federation/invites/capability',
              'targetPeerId': 'host:target.example',
              'bodyJson': {'serverId': '123'},
              'headers': {'authorization': 'Bearer injected'},
            },
          }),
        );
      } else if (request.uri.path ==
          '/api/federation/memberships/mem-1/capability') {
        await utf8.decoder.bind(request).join();
        request.response.write(
          jsonEncode(_readyCapabilityJson(serverId: '123')),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'error': 'not found'}));
      }
      await request.response.close();
    });
    final targetServing = targetServer.listen((request) async {
      targetRequests.add(request.uri.path);
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'status': 'pending'}));
      await request.response.close();
    });

    final service = HttpFederatedInviteJoinService(
      apiOrigin: homeOrigin,
      credentialStore: store,
      authService: const _UnusedAuthService(),
      capabilityPollAttempts: 1,
    );
    addTearDown(() {
      service.close();
      unawaited(homeServing.cancel());
      unawaited(targetServing.cancel());
      unawaited(homeServer.close(force: true));
      unawaited(targetServer.close(force: true));
    });

    await service.joinInvite(
      targetApiOrigin: targetOrigin,
      targetPeerId: 'host:target.example',
      serverId: '123',
      code: 'Invite123',
    );
    expect(targetRequests, isEmpty);
  });
}

Map<String, Object?> _membershipJson({required String targetOrigin}) {
  return {
    'id': 'mem-1',
    'targetPeerId': 'host:target.example',
    'targetApiOrigin': targetOrigin,
    'targetServerId': '123',
    'status': 'active',
    'server': {
      'id': '123',
      'name': 'Remote Community',
      'iconUrl': null,
      'bannerUrl': null,
    },
  };
}

Map<String, Object?> _readyCapabilityJson({required String serverId}) {
  return {
    'status': 'ready',
    'tokenType': 'federated_client',
    'accessToken': 'target-federated-access',
    'expiresAt': '2026-06-22T20:00:00Z',
    'serverId': serverId,
    'user': {
      'id': '9001',
      'username': 'remote_joshy',
      'email': 'remote@example.invalid',
      'status': 'offline',
      'usernameSet': true,
      'emailVerified': false,
      'totpEnabled': false,
    },
  };
}

final class _MemoryCredentialStore implements AuthCredentialStore {
  final _credentials = <String, AuthCredentialBundle>{};

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

final class _UnusedAuthService implements AuthService {
  const _UnusedAuthService();

  @override
  Future<AuthLoginOutcome> login({
    required String apiOrigin,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthRefreshResult> refreshSession({
    required String apiOrigin,
    required String sessionToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthLoginOutcome> register({
    required String apiOrigin,
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthLoginOutcome> submitTwoFactor({
    required String apiOrigin,
    required String ticket,
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthLoginOutcome> verifySession({
    required String apiOrigin,
    required String sessionToken,
    required String code,
  }) {
    throw UnimplementedError();
  }
}
