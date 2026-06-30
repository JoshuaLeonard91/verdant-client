import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/verdant_app_profile.dart';
import 'package:verdant_flutter/features/auth/auth_credentials.dart';
import 'package:verdant_flutter/features/auth/auth_models.dart';
import 'package:verdant_flutter/features/auth/network_profile_store.dart';

void main() {
  test('network ids are derived from every API origin', () {
    final officialId = networkIdFromApiOrigin(officialApiOrigin);
    final selfHostId = networkIdFromApiOrigin('https://api-test.pryzmapp.com');

    expect(officialId, 'origin:https%3A%2F%2Fapi.verdant.chat');
    expect(officialId, isNot('official'));
    expect(selfHostId, 'origin:https%3A%2F%2Fapi-test.pryzmapp.com');
    expect(apiOriginFromNetworkId(officialId), officialApiOrigin);
    expect(apiOriginFromNetworkId('official'), officialApiOrigin);
    expect(apiOriginFromNetworkId(selfHostId), 'https://api-test.pryzmapp.com');
  });

  test(
    'secure credential store round-trips backend-scoped credentials',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const secureStorage = FlutterSecureStorage();
      final store = FlutterSecureAuthCredentialStore(
        secureStorage: secureStorage,
      );

      const credentials = AuthCredentialBundle(
        apiOrigin: 'https://api.verdant.chat',
        accessToken: 'access-secret',
        sessionToken: 'session-secret',
        user: VerdantUser(
          id: '42',
          username: 'boji',
          email: 'boji@example.com',
          avatarUrl: 'https://cdn.example.com/media/avatars/boji.webp',
          bannerUrl: 'https://cdn.example.com/media/banners/boji.webp',
          memberListBannerUrl:
              'https://cdn.example.com/media/member-list-banners/boji.webp',
          status: 'online',
          usernameSet: true,
          emailVerified: true,
          totpEnabled: false,
        ),
      );

      await store.save(credentials);

      expect(await store.contains('api.verdant.chat'), isTrue);
      final restored = await store.read('https://api.verdant.chat');
      expect(restored?.apiOrigin, 'https://api.verdant.chat');
      expect(restored?.networkId, networkIdFromApiOrigin(officialApiOrigin));
      expect(restored?.accessToken, 'access-secret');
      expect(restored?.sessionToken, 'session-secret');
      expect(restored?.user?.username, 'boji');
      expect(restored?.user?.email, 'boji@example.com');
      expect(restored?.user?.avatarUrl, contains('/avatars/boji.webp'));
      expect(restored?.user?.bannerUrl, contains('/banners/boji.webp'));
      expect(
        restored?.user?.memberListBannerUrl,
        contains('/member-list-banners/boji.webp'),
      );
      expect(restored.toString(), contains('redacted'));
      expect(restored.toString(), isNot(contains('access-secret')));
      expect(restored.toString(), isNot(contains('boji@example.com')));

      await store.clear('https://api.verdant.chat');
      expect(await store.read('https://api.verdant.chat'), isNull);
    },
  );

  test(
    'secondary app profile cannot read primary secure credentials',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const secureStorage = FlutterSecureStorage();
      final primaryStore = FlutterSecureAuthCredentialStore(
        secureStorage: secureStorage,
        keyPrefix: VerdantAppProfile.primary.credentialKeyPrefix,
      );
      final secondaryStore = FlutterSecureAuthCredentialStore(
        secureStorage: secureStorage,
        keyPrefix: VerdantAppProfile.secondary.credentialKeyPrefix,
      );

      await primaryStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'primary-access-secret',
          sessionToken: 'primary-session-secret',
          user: VerdantUser(
            id: '42',
            username: 'primary-user',
            email: 'primary@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      expect(await secondaryStore.read('https://api.verdant.chat'), isNull);

      await secondaryStore.save(
        const AuthCredentialBundle(
          apiOrigin: 'https://api.verdant.chat',
          accessToken: 'secondary-access-secret',
          sessionToken: 'secondary-session-secret',
          user: VerdantUser(
            id: '43',
            username: 'secondary-user',
            email: 'secondary@example.com',
            status: 'online',
            usernameSet: true,
            emailVerified: true,
            totpEnabled: false,
          ),
        ),
      );

      final primary = await primaryStore.read('https://api.verdant.chat');
      final secondary = await secondaryStore.read('https://api.verdant.chat');
      expect(primary?.user?.username, 'primary-user');
      expect(secondary?.user?.username, 'secondary-user');
      expect(primary?.accessToken, 'primary-access-secret');
      expect(secondary?.accessToken, 'secondary-access-secret');
    },
  );

  test(
    'secure credential store restores legacy official hosted credentials',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'verdant.flutter.auth.v1.aHR0cHM6Ly9hcGkudmVyZGFudC5jaGF0': jsonEncode({
          'apiOrigin': officialApiOrigin,
          'networkId': 'official',
          'accessToken': 'legacy-access-secret',
          'sessionToken': 'legacy-session-secret',
          'user': {
            'id': '42',
            'username': 'boji',
            'email': 'boji@example.com',
            'status': 'online',
            'usernameSet': true,
            'emailVerified': true,
            'totpEnabled': false,
          },
        }),
      });
      const secureStorage = FlutterSecureStorage();
      final store = FlutterSecureAuthCredentialStore(
        secureStorage: secureStorage,
      );

      final restored = await store.read(officialApiOrigin);

      expect(restored, isNotNull);
      expect(restored?.networkId, networkIdFromApiOrigin(officialApiOrigin));
      expect(restored?.accessToken, 'legacy-access-secret');
      expect(restored?.sessionToken, 'legacy-session-secret');
      expect(restored?.user?.username, 'boji');
    },
  );

  test(
    'secure credential store restores legacy federated client credentials',
    () async {
      const selfHostOrigin = 'https://api-test.pryzmapp.com';
      FlutterSecureStorage.setMockInitialValues({
        _credentialStorageKey(selfHostOrigin): jsonEncode({
          'apiOrigin': selfHostOrigin,
          'networkId': networkIdFromApiOrigin(selfHostOrigin),
          'tokenType': 'federated_client',
          'accessToken': 'federated-access-secret',
          'sessionToken': '',
          'user': {
            'id': 'fed_129fa6f4b31ac2c4a38906be',
            'username': 'fed_129fa6f4b31ac2c4a38906be',
            'email': '',
            'status': 'online',
            'usernameSet': true,
            'emailVerified': false,
            'totpEnabled': false,
          },
        }),
      });
      const secureStorage = FlutterSecureStorage();
      final store = FlutterSecureAuthCredentialStore(
        secureStorage: secureStorage,
      );

      final restored = await store.read(selfHostOrigin);

      expect(restored, isNotNull);
      expect(restored?.kind, AuthCredentialKind.federatedClient);
      expect(restored?.accessToken, 'federated-access-secret');
      expect(restored?.sessionToken, isEmpty);
      expect(restored?.user?.id, 'fed_129fa6f4b31ac2c4a38906be');
      expect(restored.toString(), isNot(contains('federated-access-secret')));
    },
  );

  test(
    'secure credential store rejects invalid serialized credentials',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'verdant.flutter.auth.v1.aHR0cHM6Ly9hcGkudmVyZGFudC5jaGF0': 'not json',
      });
      const secureStorage = FlutterSecureStorage();
      final store = FlutterSecureAuthCredentialStore(
        secureStorage: secureStorage,
      );

      expect(
        store.read('https://api.verdant.chat'),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test(
    'network profiles persist metadata without credential material',
    () async {
      final storage = MemoryNetworkProfileStorage();
      final store = NetworkProfileStore(storage: storage);

      final saved = await store.saveProfile(
        name: 'Self host',
        apiOrigin: 'https://chat.example.com',
      );
      await store.selectProfile(saved.apiOrigin);

      final state = await store.load();
      expect(state.selectedProfile.name, 'Self host');
      expect(
        state.selectedProfile.networkId,
        networkIdFromApiOrigin(saved.apiOrigin),
      );
      expect(state.profiles.first.apiOrigin, officialApiOrigin);
      expect(storage.debugValues.toString(), isNot(contains('token')));
      expect(storage.debugValues.toString(), isNot(contains('password')));
    },
  );

  test(
    'secondary app profile uses isolated network profile metadata',
    () async {
      final storage = MemoryNetworkProfileStorage();
      final primaryStore = NetworkProfileStore(
        storage: storage,
        storageNamespace: VerdantAppProfile.primary.storageNamespace,
      );
      final secondaryStore = NetworkProfileStore(
        storage: storage,
        storageNamespace: VerdantAppProfile.secondary.storageNamespace,
      );

      final primaryProfile = await primaryStore.saveProfile(
        name: 'Primary Network',
        apiOrigin: 'https://primary.example.com',
      );
      await primaryStore.selectProfile(primaryProfile.apiOrigin);

      final secondaryProfile = await secondaryStore.saveProfile(
        name: 'Secondary Network',
        apiOrigin: 'https://secondary.example.com',
      );
      await secondaryStore.selectProfile(secondaryProfile.apiOrigin);

      final primaryState = await primaryStore.load();
      final secondaryState = await secondaryStore.load();
      expect(primaryState.selectedProfile.name, 'Primary Network');
      expect(secondaryState.selectedProfile.name, 'Secondary Network');
      expect(
        primaryState.profiles.map((profile) => profile.name),
        isNot(contains('Secondary Network')),
      );
      expect(
        secondaryState.profiles.map((profile) => profile.name),
        isNot(contains('Primary Network')),
      );
    },
  );

  test('saving an existing network profile preserves custom order', () async {
    final store = NetworkProfileStore.memory();
    final first = await store.saveProfile(
      name: 'First Network',
      apiOrigin: 'https://first.example.com',
    );
    final second = await store.saveProfile(
      name: 'Second Network',
      apiOrigin: 'https://second.example.com',
    );

    final updatedFirst = await store.saveProfile(
      name: 'First Network Updated',
      apiOrigin: first.apiOrigin,
    );

    final state = await store.load();
    expect(state.profiles.map((profile) => profile.apiOrigin), [
      officialApiOrigin,
      updatedFirst.apiOrigin,
      second.apiOrigin,
    ]);
    expect(state.profiles[1].name, 'First Network Updated');
  });

  test(
    'network profile removal deletes only the target custom profile',
    () async {
      final storage = MemoryNetworkProfileStorage();
      final store = NetworkProfileStore(storage: storage);
      final community = await store.saveProfile(
        name: 'Community',
        apiOrigin: 'https://api.community.example',
      );
      final staging = await store.saveProfile(
        name: 'Staging',
        apiOrigin: 'https://staging.example.com',
      );
      await store.selectProfile(staging.apiOrigin);

      await store.removeProfile(community.apiOrigin);

      var state = await store.load();
      expect(state.profiles.map((profile) => profile.apiOrigin), [
        officialApiOrigin,
        staging.apiOrigin,
      ]);
      expect(state.selectedProfile.apiOrigin, staging.apiOrigin);

      await store.removeProfile(staging.apiOrigin);

      state = await store.load();
      expect(state.profiles.map((profile) => profile.apiOrigin), [
        officialApiOrigin,
      ]);
      expect(state.selectedProfile.apiOrigin, officialApiOrigin);
      expect(storage.debugValues.toString(), isNot(contains('access-secret')));
      expect(storage.debugValues.toString(), isNot(contains('session-secret')));
    },
  );

  test('network profile removal keeps the official profile', () async {
    final store = NetworkProfileStore.memory();

    await store.removeProfile(officialApiOrigin);

    final state = await store.load();
    expect(state.profiles, hasLength(1));
    expect(state.selectedProfile.apiOrigin, officialApiOrigin);
  });

  test('network profile store ignores corrupted local metadata', () async {
    final storage = MemoryNetworkProfileStorage();
    await storage.writeString('verdant.flutter.networkProfiles.v1', 'not json');
    await storage.writeString(
      'verdant.flutter.selectedApiOrigin.v1',
      'https://api.example.com/path',
    );
    final store = NetworkProfileStore(storage: storage);

    final state = await store.load();

    expect(state.profiles, hasLength(1));
    expect(state.selectedProfile.apiOrigin, officialApiOrigin);
  });
}

String _credentialStorageKey(String apiOrigin) {
  final encoded = base64Url
      .encode(utf8.encode(normalizeBackendApiOrigin(apiOrigin)))
      .replaceAll('=', '');
  return 'verdant.flutter.auth.v1.$encoded';
}
