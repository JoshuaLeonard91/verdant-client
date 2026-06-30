import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/local_storage_namespace.dart';
import 'auth_models.dart';

export 'auth_models.dart' show AuthCredentialBundle;

abstract interface class AuthCredentialStore {
  Future<void> save(AuthCredentialBundle credentials);

  Future<AuthCredentialBundle?> read(String apiOrigin);

  Future<bool> contains(String apiOrigin);

  Future<void> clear(String apiOrigin);
}

final class FlutterSecureAuthCredentialStore implements AuthCredentialStore {
  FlutterSecureAuthCredentialStore({
    FlutterSecureStorage? secureStorage,
    String keyPrefix = _defaultKeyPrefix,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _keyPrefix = _normalizeKeyPrefix(keyPrefix);

  static const _defaultKeyPrefix = 'verdant.flutter.auth.v1';

  final FlutterSecureStorage _secureStorage;
  final String _keyPrefix;

  @override
  Future<void> save(AuthCredentialBundle credentials) async {
    await _secureStorage.write(
      key: _keyForApiOrigin(credentials.normalizedApiOrigin),
      value: jsonEncode(credentials.toJson()),
    );
  }

  @override
  Future<AuthCredentialBundle?> read(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    final raw = await _secureStorage.read(
      key: _keyForApiOrigin(normalizedOrigin),
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const AuthException('Stored credentials were invalid');
    }
    if (decoded is! Map<String, Object?>) {
      throw const AuthException('Stored credentials were invalid');
    }

    final credentials = AuthCredentialBundle.fromJson(decoded);
    if (credentials.normalizedApiOrigin != normalizedOrigin) {
      return null;
    }

    final storedNetworkId = decoded['networkId'];
    if (storedNetworkId is String &&
        !_storedNetworkIdMatchesCredentials(storedNetworkId, credentials)) {
      return null;
    }

    return credentials;
  }

  @override
  Future<bool> contains(String apiOrigin) async {
    return read(apiOrigin).then((credentials) => credentials != null);
  }

  @override
  Future<void> clear(String apiOrigin) async {
    await _secureStorage.delete(
      key: _keyForApiOrigin(normalizeBackendApiOrigin(apiOrigin)),
    );
  }

  String _keyForApiOrigin(String apiOrigin) {
    final encoded = base64Url
        .encode(utf8.encode(normalizeBackendApiOrigin(apiOrigin)))
        .replaceAll('=', '');
    return '$_keyPrefix.$encoded';
  }

  bool _storedNetworkIdMatchesCredentials(
    String storedNetworkId,
    AuthCredentialBundle credentials,
  ) {
    if (storedNetworkId == credentials.networkId) {
      return true;
    }
    final storedOrigin = apiOriginFromNetworkId(storedNetworkId);
    return storedOrigin == credentials.normalizedApiOrigin;
  }
}

String _normalizeKeyPrefix(String keyPrefix) {
  final trimmed = keyPrefix.trim();
  const defaultKeyPrefix = FlutterSecureAuthCredentialStore._defaultKeyPrefix;
  if (trimmed.isEmpty || trimmed == defaultKeyPrefix) {
    return defaultKeyPrefix;
  }
  if (trimmed.startsWith('$defaultKeyPrefix.')) {
    return trimmed;
  }
  return namespacedLocalStorageKey(defaultKeyPrefix, trimmed);
}
