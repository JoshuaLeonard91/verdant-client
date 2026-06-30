import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/local_storage_namespace.dart';
import '../../auth/auth_models.dart';
import 'direct_messages_models.dart';

abstract interface class DirectMessagesPreferenceStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

final class SharedPreferencesDirectMessagesStorage
    implements DirectMessagesPreferenceStorage {
  SharedPreferencesDirectMessagesStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) {
    return _preferences.setString(key, value);
  }
}

final class MemoryDirectMessagesPreferenceStorage
    implements DirectMessagesPreferenceStorage {
  final _values = <String, String>{};

  Map<String, String> get debugValues => Map.unmodifiable(_values);

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

final class DirectMessagesPreferences {
  DirectMessagesPreferences({
    DirectMessagesPreferenceStorage? storage,
    String storageNamespace = '',
  }) : _hiddenDmsPrefix = namespacedLocalStorageKey(
         _hiddenDmsBasePrefix,
         storageNamespace,
       ),
       _currentUserStatusPrefix = namespacedLocalStorageKey(
         _currentUserStatusBasePrefix,
         storageNamespace,
       ) {
    _storage = storage;
  }

  factory DirectMessagesPreferences.memory() {
    return DirectMessagesPreferences(
      storage: MemoryDirectMessagesPreferenceStorage(),
    );
  }

  static const _hiddenDmsBasePrefix = 'verdant.flutter.hiddenDmChannelIds.v1';
  static const _currentUserStatusBasePrefix =
      'verdant.flutter.currentUserStatus.v1';

  DirectMessagesPreferenceStorage? _storage;
  final String _hiddenDmsPrefix;
  final String _currentUserStatusPrefix;

  DirectMessagesPreferenceStorage get _effectiveStorage {
    return _storage ??= SharedPreferencesDirectMessagesStorage();
  }

  Future<Set<String>> loadHiddenChannelIds({
    required String networkId,
    required String userId,
  }) async {
    String? raw;
    try {
      for (final keyNetworkId in _networkIdsForPreferenceRead(networkId)) {
        raw = await _effectiveStorage.readString(
          _hiddenDmsKey(keyNetworkId, userId),
        );
        if (raw != null && raw.trim().isNotEmpty) {
          break;
        }
      }
    } on StateError {
      return {};
    }
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return {};
      }
      return {
        for (final item in decoded)
          if (item is String &&
              _isSafeScopedChannelId(item, networkId: networkId))
            item,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveHiddenChannelIds({
    required String networkId,
    required String userId,
    required Set<String> channelIds,
  }) {
    final sorted =
        channelIds
            .where((channelId) {
              return _isSafeScopedChannelId(channelId, networkId: networkId);
            })
            .toList(growable: false)
          ..sort();
    try {
      return _effectiveStorage.writeString(
        _hiddenDmsKey(_networkIdForPreferenceWrite(networkId), userId),
        jsonEncode(sorted),
      );
    } on StateError {
      return Future.value();
    }
  }

  String _hiddenDmsKey(String networkId, String userId) {
    return '$_hiddenDmsPrefix.$networkId.$userId';
  }

  Future<String?> loadCurrentUserStatus({
    required String networkId,
    required String userId,
  }) async {
    String? raw;
    try {
      for (final keyNetworkId in _networkIdsForPreferenceRead(networkId)) {
        raw = await _effectiveStorage.readString(
          _currentUserStatusKey(keyNetworkId, userId),
        );
        if (raw != null && raw.trim().isNotEmpty) {
          break;
        }
      }
    } on StateError {
      return null;
    }
    return _canonicalCurrentUserStatus(raw);
  }

  Future<void> saveCurrentUserStatus({
    required String networkId,
    required String userId,
    required String status,
  }) {
    final canonical = _canonicalCurrentUserStatus(status);
    if (canonical == null) {
      return Future.value();
    }
    try {
      return _effectiveStorage.writeString(
        _currentUserStatusKey(_networkIdForPreferenceWrite(networkId), userId),
        canonical,
      );
    } on StateError {
      return Future.value();
    }
  }

  String _currentUserStatusKey(String networkId, String userId) {
    return '$_currentUserStatusPrefix.$networkId.$userId';
  }

  String _networkIdForPreferenceWrite(String networkId) {
    final apiOrigin = apiOriginFromNetworkId(networkId);
    if (apiOrigin == null) {
      return networkId.trim();
    }
    return networkIdFromApiOrigin(apiOrigin);
  }

  List<String> _networkIdsForPreferenceRead(String networkId) {
    final trimmed = networkId.trim();
    final ids = <String>[];
    void add(String value) {
      final candidate = value.trim();
      if (candidate.isNotEmpty && !ids.contains(candidate)) {
        ids.add(candidate);
      }
    }

    final apiOrigin = apiOriginFromNetworkId(trimmed);
    if (apiOrigin != null) {
      add(networkIdFromApiOrigin(apiOrigin));
    }
    add(trimmed);
    if (apiOrigin == officialApiOrigin) {
      add(legacyOfficialNetworkId);
    }
    return ids;
  }
}

bool _isSafeScopedChannelId(String value, {required String networkId}) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty &&
      trimmed.length <= 160 &&
      isSafeScopedWorkspaceId(trimmed, networkId: networkId);
}

String? _canonicalCurrentUserStatus(String? rawStatus) {
  final normalized = rawStatus?.toLowerCase().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('online')) {
    return 'online';
  }
  if (normalized.contains('idle')) {
    return 'idle';
  }
  if (normalized.contains('dnd') || normalized.contains('busy')) {
    return 'dnd';
  }
  if (normalized.contains('offline') || normalized.contains('invisible')) {
    return 'offline';
  }
  return null;
}
