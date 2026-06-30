import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/local_storage_namespace.dart';
import '../../shared/verdant_input_sanitizer.dart';
import 'auth_models.dart';

final class NetworkProfile {
  NetworkProfile({required String name, required String apiOrigin})
    : name = _normalizeNetworkName(name),
      apiOrigin = normalizeBackendApiOrigin(sanitizeUrlInput(apiOrigin)),
      networkId = networkIdFromApiOrigin(sanitizeUrlInput(apiOrigin));

  factory NetworkProfile.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final apiOrigin = json['apiOrigin'];
    if (name is! String || name.trim().isEmpty) {
      throw const AuthException('Network name is required');
    }
    if (apiOrigin is! String || apiOrigin.trim().isEmpty) {
      throw const AuthException('Network API origin is required');
    }
    return NetworkProfile(name: name.trim(), apiOrigin: apiOrigin);
  }

  factory NetworkProfile.official() {
    return NetworkProfile(name: 'Official', apiOrigin: officialApiOrigin);
  }

  final String name;
  final String apiOrigin;
  final String networkId;

  bool get isOfficial => apiOrigin == officialApiOrigin;

  Map<String, Object?> toJson() {
    return {'name': name, 'apiOrigin': apiOrigin, 'networkId': networkId};
  }
}

final class NetworkProfileState {
  const NetworkProfileState({
    required this.profiles,
    required this.selectedApiOrigin,
  });

  final List<NetworkProfile> profiles;
  final String selectedApiOrigin;

  NetworkProfile get selectedProfile {
    return profiles.firstWhere(
      (profile) => profile.apiOrigin == selectedApiOrigin,
      orElse: NetworkProfile.official,
    );
  }
}

abstract interface class NetworkProfileStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

final class SharedPreferencesNetworkProfileStorage
    implements NetworkProfileStorage {
  SharedPreferencesNetworkProfileStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) {
    return _preferences.setString(key, value);
  }
}

final class MemoryNetworkProfileStorage implements NetworkProfileStorage {
  final _values = <String, String>{};

  Map<String, String> get debugValues => Map.unmodifiable(_values);

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

final class NetworkProfileStore {
  NetworkProfileStore({
    NetworkProfileStorage? storage,
    String storageNamespace = '',
  }) : _storage = storage ?? SharedPreferencesNetworkProfileStorage(),
       _profilesKey = namespacedLocalStorageKey(
         _profilesBaseKey,
         storageNamespace,
       ),
       _selectedKey = namespacedLocalStorageKey(
         _selectedBaseKey,
         storageNamespace,
       );

  factory NetworkProfileStore.memory() {
    return NetworkProfileStore(storage: MemoryNetworkProfileStorage());
  }

  static const _profilesBaseKey = 'verdant.flutter.networkProfiles.v1';
  static const _selectedBaseKey = 'verdant.flutter.selectedApiOrigin.v1';

  final NetworkProfileStorage _storage;
  final String _profilesKey;
  final String _selectedKey;

  Future<NetworkProfileState> load() async {
    final customProfiles = await _loadCustomProfiles();
    final profilesByOrigin = <String, NetworkProfile>{
      officialApiOrigin: NetworkProfile.official(),
    };

    for (final profile in customProfiles) {
      if (profile.isOfficial) {
        continue;
      }
      profilesByOrigin[profile.apiOrigin] = profile;
    }

    final profiles = profilesByOrigin.values.toList(growable: false);
    final selected = await _loadSelectedProfile(profiles);
    return NetworkProfileState(
      profiles: profiles,
      selectedApiOrigin: selected.apiOrigin,
    );
  }

  Future<NetworkProfile> saveProfile({
    required String name,
    required String apiOrigin,
  }) async {
    final profile = NetworkProfile(name: name, apiOrigin: apiOrigin);
    if (profile.isOfficial) {
      return NetworkProfile.official();
    }

    final state = await load();
    final customProfiles = <NetworkProfile>[];
    var replaced = false;
    for (final existing in state.profiles) {
      if (existing.isOfficial) {
        continue;
      }
      if (existing.apiOrigin == profile.apiOrigin) {
        customProfiles.add(profile);
        replaced = true;
      } else {
        customProfiles.add(existing);
      }
    }
    if (!replaced) {
      customProfiles.add(profile);
    }
    await _saveCustomProfiles(customProfiles);
    return profile;
  }

  Future<void> selectProfile(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    final state = await load();
    final exists = state.profiles.any(
      (profile) => profile.apiOrigin == normalizedOrigin,
    );
    if (!exists) {
      throw const AuthException('Save this network before selecting it');
    }
    await _storage.writeString(_selectedKey, normalizedOrigin);
  }

  Future<void> removeProfile(String apiOrigin) async {
    final normalizedOrigin = normalizeBackendApiOrigin(apiOrigin);
    if (normalizedOrigin == officialApiOrigin) {
      return;
    }

    final state = await load();
    final customProfiles = [
      for (final profile in state.profiles)
        if (!profile.isOfficial && profile.apiOrigin != normalizedOrigin)
          profile,
    ];
    await _saveCustomProfiles(customProfiles);
    if (state.selectedProfile.apiOrigin == normalizedOrigin) {
      await _storage.writeString(_selectedKey, officialApiOrigin);
    }
  }

  Future<List<NetworkProfile>> _loadCustomProfiles() async {
    final raw = await _storage.readString(_profilesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List<Object?>) {
      return const [];
    }

    final profiles = <NetworkProfile>[];
    for (final item in decoded) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      try {
        profiles.add(NetworkProfile.fromJson(item));
      } on AuthException {
        continue;
      }
    }
    return profiles;
  }

  Future<void> _saveCustomProfiles(List<NetworkProfile> profiles) async {
    final encoded = jsonEncode([
      for (final profile in profiles) profile.toJson(),
    ]);
    await _storage.writeString(_profilesKey, encoded);
  }

  Future<NetworkProfile> _loadSelectedProfile(
    List<NetworkProfile> profiles,
  ) async {
    final rawSelected = await _storage.readString(_selectedKey);
    if (rawSelected == null || rawSelected.trim().isEmpty) {
      return NetworkProfile.official();
    }

    final String selected;
    try {
      selected = normalizeBackendApiOrigin(rawSelected);
    } on AuthException {
      return NetworkProfile.official();
    }
    return profiles.firstWhere(
      (profile) => profile.apiOrigin == selected,
      orElse: NetworkProfile.official,
    );
  }
}

String _normalizeNetworkName(String name) {
  final trimmed = sanitizeDisplayNameInput(name, maxLength: 64);
  if (trimmed.isEmpty) {
    throw const AuthException('Enter a network name');
  }
  return trimmed;
}
