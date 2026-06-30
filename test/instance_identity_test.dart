import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/instance_identity.dart';
import 'package:verdant_flutter/features/auth/instance_identity_service.dart';
import 'package:verdant_flutter/features/auth/network_profile_store.dart';

void main() {
  test('self-reported manifest is keyed by the connected API origin', () async {
    final storage = MemoryNetworkProfileStorage();
    final store = InstanceIdentityStore(storage: storage);

    final identity = await store.recordSelfReportedManifest(
      connectedApiOrigin: 'https://real.community.example',
      manifest: InstanceManifestIdentity.fromJson({
        'instanceId': 'host:fake.example',
        'registryTrust': 'self_reported',
        'name': 'Official Verdant',
        'domain': 'api.verdant.chat',
        'mode': 'official',
        'apiUrl': 'https://api.verdant.chat',
        'publicKeyFingerprint': 'sha256:${'a' * 64}',
      }),
    );

    expect(identity.apiOrigin, 'https://real.community.example');
    expect(identity.networkId, networkIdFromApiOrigin(identity.apiOrigin));
    expect(identity.instanceId, 'host:fake.example');
    expect(identity.instanceMode, 'official');
    expect(identity.trustStatus, InstanceTrustStatus.warning);
    expect(identity.trustSource, InstanceTrustSource.selfReported);
    expect(
      identity.warnings,
      contains(InstanceIdentityWarning.apiOriginMismatch),
    );
    expect(
      identity.warnings,
      contains(InstanceIdentityWarning.fakeOfficialClaim),
    );
    expect(storage.debugValues.toString(), isNot(contains('Official Verdant')));
  });

  test(
    'fingerprint changes move a previously seen instance to warning',
    () async {
      final store = InstanceIdentityStore(
        storage: MemoryNetworkProfileStorage(),
      );
      final first = InstanceManifestIdentity.fromJson({
        'instanceId': 'host:community.example',
        'registryTrust': 'self_reported',
        'name': 'Community',
        'domain': 'community.example',
        'mode': 'federated',
        'apiUrl': 'https://community.example',
        'publicKeyFingerprint': 'sha256:${'a' * 64}',
      });
      final second = InstanceManifestIdentity.fromJson({
        'instanceId': 'host:community.example',
        'registryTrust': 'self_reported',
        'name': 'Community',
        'domain': 'community.example',
        'mode': 'federated',
        'apiUrl': 'https://community.example',
        'publicKeyFingerprint': 'sha256:${'b' * 64}',
      });

      final initial = await store.recordSelfReportedManifest(
        connectedApiOrigin: 'https://community.example',
        manifest: first,
      );
      final changed = await store.recordSelfReportedManifest(
        connectedApiOrigin: 'https://community.example',
        manifest: second,
      );

      expect(initial.trustStatus, InstanceTrustStatus.unverified);
      expect(initial.instanceMode, 'federated');
      expect(changed.trustStatus, InstanceTrustStatus.warning);
      expect(changed.instanceMode, 'federated');
      expect(
        changed.warnings,
        contains(InstanceIdentityWarning.publicKeyFingerprintChanged),
      );
      expect(changed.firstSeenAtMs, initial.firstSeenAtMs);
      expect(changed.lastSeenAtMs, greaterThanOrEqualTo(initial.lastSeenAtMs));
    },
  );

  test('official trust requires the actual official API origin', () async {
    final store = InstanceIdentityStore(storage: MemoryNetworkProfileStorage());
    final fakeOfficial = InstanceManifestIdentity.fromJson({
      'instanceId': 'host:evil.example',
      'registryTrust': 'self_reported',
      'name': 'Verdant',
      'domain': 'api.verdant.chat',
      'mode': 'official',
      'apiUrl': 'https://api.verdant.chat',
      'publicKeyFingerprint': 'sha256:${'c' * 64}',
    });

    final identity = await store.recordSelfReportedManifest(
      connectedApiOrigin: 'https://api.verdant.chat.evil.example',
      manifest: fakeOfficial,
    );

    expect(identity.trustStatus, InstanceTrustStatus.warning);
    expect(identity.trustSource, InstanceTrustSource.selfReported);
    expect(
      identity.warnings,
      contains(InstanceIdentityWarning.lookalikeDomain),
    );
    expect(
      identity.warnings,
      contains(InstanceIdentityWarning.fakeOfficialClaim),
    );
  });

  test('origin safety warns on IDN and official lookalike domains', () {
    final idn = assessNetworkOriginSafety('https://vеrdant.chat');
    final nested = assessNetworkOriginSafety(
      'https://api.verdant.chat.evil.com',
    );

    expect(idn.warnings, contains(InstanceIdentityWarning.idnDomain));
    expect(nested.warnings, contains(InstanceIdentityWarning.lookalikeDomain));
    expect(nested.displayHost, 'api.verdant.chat.evil.com');
  });

  test(
    'stored identities are non-secret and recover corrupted cache safely',
    () async {
      final storage = MemoryNetworkProfileStorage();
      final store = InstanceIdentityStore(storage: storage);

      await store.recordSelfReportedManifest(
        connectedApiOrigin: 'https://community.example',
        manifest: InstanceManifestIdentity.fromJson({
          'instanceId': 'host:community.example',
          'registryTrust': 'self_reported',
          'name': 'Community',
          'domain': 'community.example',
          'mode': 'federated',
          'apiUrl': 'https://community.example',
          'publicKeyFingerprint': 'sha256:${'d' * 64}',
        }),
      );

      expect(jsonEncode(storage.debugValues), isNot(contains('accessToken')));
      expect(jsonEncode(storage.debugValues), isNot(contains('sessionToken')));
      expect(jsonEncode(storage.debugValues), isNot(contains('password')));

      await storage.writeString(
        'verdant.flutter.instanceIdentities.v1',
        'not json',
      );
      expect(await store.load(), isEmpty);
    },
  );

  test(
    'fetches federation manifest identity from the connected origin',
    () async {
      final exchange = await _JsonExchange.start((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/api/federation/manifest');
        return {
          'instanceId': 'host:community.example',
          'registryTrust': 'self_reported',
          'name': 'Community',
          'domain': 'community.example',
          'mode': 'federated',
          'apiUrl': exchangeOrigin(request),
          'publicKeyFingerprint': 'sha256:${'e' * 64}',
        };
      });
      final service = HttpInstanceIdentityManifestService();
      addTearDown(service.close);
      addTearDown(exchange.close);

      final manifest = await service.fetchManifest(apiOrigin: exchange.origin);

      expect(manifest?.instanceId, 'host:community.example');
      expect(manifest?.apiUrl, exchange.origin);
      expect(manifest?.registryTrust, 'self_reported');
    },
  );

  test('manifest unavailability records a warning identity', () async {
    final storage = MemoryNetworkProfileStorage();
    final store = InstanceIdentityStore(storage: storage);

    final identity = await store.recordManifestUnavailable(
      connectedApiOrigin: 'https://api.verdant.chat.evil.example',
    );

    expect(identity.apiOrigin, 'https://api.verdant.chat.evil.example');
    expect(identity.trustStatus, InstanceTrustStatus.warning);
    expect(
      identity.warnings,
      contains(InstanceIdentityWarning.manifestUnavailable),
    );
    expect(
      identity.warnings,
      contains(InstanceIdentityWarning.lookalikeDomain),
    );
  });
}

String exchangeOrigin(HttpRequest request) {
  return request.requestedUri.origin;
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
