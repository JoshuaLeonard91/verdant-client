import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/local_storage_namespace.dart';

enum UserSettingsThemePreference {
  dark(value: 'dark', label: 'Dark'),
  light(value: 'light', label: 'Light');

  const UserSettingsThemePreference({required this.value, required this.label});

  final String value;
  final String label;

  static UserSettingsThemePreference fromValue(Object? value) {
    for (final option in values) {
      if (option.value == value) {
        return option;
      }
    }
    return dark;
  }
}

enum UserSettingsDensityPreference {
  comfortable(value: 'comfortable', label: 'Comfortable'),
  compact(value: 'compact', label: 'Compact');

  const UserSettingsDensityPreference({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  static UserSettingsDensityPreference fromValue(Object? value) {
    for (final option in values) {
      if (option.value == value) {
        return option;
      }
    }
    return comfortable;
  }
}

final class UserSettingsPreferences {
  const UserSettingsPreferences({
    this.theme = UserSettingsThemePreference.dark,
    this.density = UserSettingsDensityPreference.comfortable,
    this.closeToTray = true,
    this.desktopNotifications = true,
    this.notificationSounds = true,
    this.voiceInputDeviceId = '',
    this.voiceOutputDeviceId = '',
    this.voiceInputVolume = 100,
    this.pushToTalk = false,
    this.pushToTalkKey = 'V',
    this.noiseSuppression = true,
    this.echoCancellation = true,
    this.profileBannerBaseColor,
  });

  factory UserSettingsPreferences.fromJson(Map<String, Object?> json) {
    return UserSettingsPreferences(
      theme: UserSettingsThemePreference.fromValue(json['theme']),
      density: UserSettingsDensityPreference.fromValue(json['density']),
      closeToTray: _boolValue(json['closeToTray'], fallback: true),
      desktopNotifications: _boolValue(
        json['desktopNotifications'],
        fallback: true,
      ),
      notificationSounds: _boolValue(
        json['notificationSounds'],
        fallback: true,
      ),
      voiceInputDeviceId: _stringValue(
        json['voiceInputDeviceId'],
        fallback: '',
      ),
      voiceOutputDeviceId: _stringValue(
        json['voiceOutputDeviceId'],
        fallback: '',
      ),
      voiceInputVolume: _volumeValue(json['voiceInputVolume']),
      pushToTalk: _boolValue(json['pushToTalk'], fallback: false),
      pushToTalkKey: _stringValue(json['pushToTalkKey'], fallback: 'V'),
      noiseSuppression: _boolValue(json['noiseSuppression'], fallback: true),
      echoCancellation: _boolValue(json['echoCancellation'], fallback: true),
      profileBannerBaseColor: _colorValue(json['profileBannerBaseColor']),
    );
  }

  final UserSettingsThemePreference theme;
  final UserSettingsDensityPreference density;
  final bool closeToTray;
  final bool desktopNotifications;
  final bool notificationSounds;
  final String voiceInputDeviceId;
  final String voiceOutputDeviceId;
  final int voiceInputVolume;
  final bool pushToTalk;
  final String pushToTalkKey;
  final bool noiseSuppression;
  final bool echoCancellation;
  final int? profileBannerBaseColor;

  Map<String, Object?> toJson() {
    return {
      'theme': theme.value,
      'density': density.value,
      'closeToTray': closeToTray,
      'desktopNotifications': desktopNotifications,
      'notificationSounds': notificationSounds,
      'voiceInputDeviceId': voiceInputDeviceId,
      'voiceOutputDeviceId': voiceOutputDeviceId,
      'voiceInputVolume': voiceInputVolume,
      'pushToTalk': pushToTalk,
      'pushToTalkKey': pushToTalkKey,
      'noiseSuppression': noiseSuppression,
      'echoCancellation': echoCancellation,
      if (profileBannerBaseColor != null)
        'profileBannerBaseColor': profileBannerBaseColor,
    };
  }

  UserSettingsPreferences copyWith({
    UserSettingsThemePreference? theme,
    UserSettingsDensityPreference? density,
    bool? closeToTray,
    bool? desktopNotifications,
    bool? notificationSounds,
    String? voiceInputDeviceId,
    String? voiceOutputDeviceId,
    int? voiceInputVolume,
    bool? pushToTalk,
    String? pushToTalkKey,
    bool? noiseSuppression,
    bool? echoCancellation,
    Object? profileBannerBaseColor = _sentinel,
  }) {
    return UserSettingsPreferences(
      theme: theme ?? this.theme,
      density: density ?? this.density,
      closeToTray: closeToTray ?? this.closeToTray,
      desktopNotifications: desktopNotifications ?? this.desktopNotifications,
      notificationSounds: notificationSounds ?? this.notificationSounds,
      voiceInputDeviceId: voiceInputDeviceId ?? this.voiceInputDeviceId,
      voiceOutputDeviceId: voiceOutputDeviceId ?? this.voiceOutputDeviceId,
      voiceInputVolume: voiceInputVolume ?? this.voiceInputVolume,
      pushToTalk: pushToTalk ?? this.pushToTalk,
      pushToTalkKey: pushToTalkKey ?? this.pushToTalkKey,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      echoCancellation: echoCancellation ?? this.echoCancellation,
      profileBannerBaseColor: identical(profileBannerBaseColor, _sentinel)
          ? this.profileBannerBaseColor
          : profileBannerBaseColor as int?,
    );
  }
}

const Object _sentinel = Object();

abstract interface class UserSettingsPreferencesStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

final class SharedPreferencesUserSettingsPreferencesStorage
    implements UserSettingsPreferencesStorage {
  SharedPreferencesUserSettingsPreferencesStorage({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) {
    return _preferences.setString(key, value);
  }
}

final class MemoryUserSettingsPreferencesStorage
    implements UserSettingsPreferencesStorage {
  final _values = <String, String>{};

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

final class UserSettingsPreferencesStore {
  UserSettingsPreferencesStore({
    UserSettingsPreferencesStorage? storage,
    String storageNamespace = '',
  }) : _storage = storage ?? SharedPreferencesUserSettingsPreferencesStorage(),
       _storageKey = namespacedLocalStorageKey(
         _baseStorageKey,
         storageNamespace,
       );

  factory UserSettingsPreferencesStore.memory() {
    return UserSettingsPreferencesStore(
      storage: MemoryUserSettingsPreferencesStorage(),
    );
  }

  static const _baseStorageKey = 'verdant:flutter:user_settings_preferences';

  final UserSettingsPreferencesStorage _storage;
  final String _storageKey;

  Future<UserSettingsPreferences> load() async {
    final raw = await _storage.readString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const UserSettingsPreferences();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return UserSettingsPreferences.fromJson(decoded);
      }
      if (decoded is Map) {
        return UserSettingsPreferences.fromJson(
          Map<String, Object?>.from(decoded),
        );
      }
    } catch (_) {
      return const UserSettingsPreferences();
    }
    return const UserSettingsPreferences();
  }

  Future<void> save(UserSettingsPreferences preferences) {
    return _storage.writeString(_storageKey, jsonEncode(preferences.toJson()));
  }
}

bool _boolValue(Object? value, {required bool fallback}) {
  return value is bool ? value : fallback;
}

String _stringValue(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

int _volumeValue(Object? value) {
  final numeric = switch (value) {
    int v => v,
    double v => v.round(),
    String v => int.tryParse(v) ?? 100,
    _ => 100,
  };
  return numeric.clamp(0, 200);
}

int? _colorValue(Object? value) {
  final numeric = switch (value) {
    int v => v,
    String v => int.tryParse(v),
    _ => null,
  };
  if (numeric == null) {
    return null;
  }
  return numeric & 0xFFFFFFFF;
}
