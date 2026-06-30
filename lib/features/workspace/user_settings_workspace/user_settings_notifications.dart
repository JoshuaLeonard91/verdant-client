import 'package:flutter/foundation.dart';

abstract interface class UserSettingsNotificationsRepository {
  Future<List<UserSettingsNotificationPreference>>
  listNotificationPreferences();

  Future<void> saveNotificationPreference({
    required UserSettingsNotificationPreference preference,
  });
}

enum UserSettingsNotificationTargetType {
  global('global'),
  server('server'),
  channel('channel');

  const UserSettingsNotificationTargetType(this.value);

  final String value;

  static UserSettingsNotificationTargetType fromValue(Object? value) {
    return switch (value) {
      'global' => UserSettingsNotificationTargetType.global,
      'server' => UserSettingsNotificationTargetType.server,
      'channel' => UserSettingsNotificationTargetType.channel,
      _ => throw const FormatException('Unknown notification target type'),
    };
  }
}

final class UserSettingsNotificationPreference {
  const UserSettingsNotificationPreference({
    required this.targetType,
    required this.targetId,
    required this.muted,
    required this.desktopEnabled,
  });

  factory UserSettingsNotificationPreference.fromJson(
    Map<String, Object?> json,
  ) {
    final targetType = UserSettingsNotificationTargetType.fromValue(
      json['targetType'] ?? json['target_type'],
    );
    final targetId = _stringValue(json['targetId'] ?? json['target_id']);
    return UserSettingsNotificationPreference(
      targetType: targetType,
      targetId:
          targetId.isEmpty &&
              targetType == UserSettingsNotificationTargetType.global
          ? '0'
          : targetId,
      muted: json['muted'] == true,
      desktopEnabled:
          json['desktopEnabled'] != false && json['desktop_enabled'] != false,
    );
  }

  static const globalDefault = UserSettingsNotificationPreference(
    targetType: UserSettingsNotificationTargetType.global,
    targetId: '0',
    muted: false,
    desktopEnabled: true,
  );

  final UserSettingsNotificationTargetType targetType;
  final String targetId;
  final bool muted;
  final bool desktopEnabled;

  bool hasSameTarget(UserSettingsNotificationPreference other) {
    return targetType == other.targetType && targetId == other.targetId;
  }

  Map<String, Object?> toJson() {
    return {
      'targetType': targetType.value,
      'targetId': targetId,
      'muted': muted,
      'desktopEnabled': desktopEnabled,
    };
  }

  UserSettingsNotificationPreference copyWith({
    bool? muted,
    bool? desktopEnabled,
  }) {
    return UserSettingsNotificationPreference(
      targetType: targetType,
      targetId: targetId,
      muted: muted ?? this.muted,
      desktopEnabled: desktopEnabled ?? this.desktopEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserSettingsNotificationPreference &&
        other.targetType == targetType &&
        other.targetId == targetId &&
        other.muted == muted &&
        other.desktopEnabled == desktopEnabled;
  }

  @override
  int get hashCode => Object.hash(targetType, targetId, muted, desktopEnabled);

  @override
  String toString() {
    return 'UserSettingsNotificationPreference('
        'targetType: ${targetType.value}, '
        'targetId: $targetId, '
        'muted: $muted, '
        'desktopEnabled: $desktopEnabled'
        ')';
  }
}

final class UserSettingsNotificationsController extends ChangeNotifier {
  UserSettingsNotificationsController({required this.repository});

  final UserSettingsNotificationsRepository? repository;

  List<UserSettingsNotificationPreference> _preferences = const [];
  String? _error;
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  int _loadGeneration = 0;

  List<UserSettingsNotificationPreference> get preferences => _preferences;

  String? get error => _error;

  bool get loading => _loading;

  bool get saving => _saving;

  UserSettingsNotificationPreference get globalPreference {
    for (final preference in _preferences) {
      if (preference.targetType == UserSettingsNotificationTargetType.global) {
        return preference;
      }
    }
    return UserSettingsNotificationPreference.globalDefault;
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }

  Future<void> load() async {
    final activeRepository = repository;
    final generation = ++_loadGeneration;
    if (activeRepository == null) {
      _preferences = const [];
      _error = 'Notifications are unavailable until this network is connected.';
      _loading = false;
      _notifyIfAlive();
      return;
    }

    _loading = true;
    _error = null;
    _notifyIfAlive();
    try {
      final loadedPreferences = await activeRepository
          .listNotificationPreferences();
      if (!_isCurrentLoad(generation)) {
        return;
      }
      _preferences = loadedPreferences;
      _error = null;
    } catch (_) {
      if (!_isCurrentLoad(generation)) {
        return;
      }
      _error = 'Notification preferences could not be loaded';
    } finally {
      if (_isCurrentLoad(generation)) {
        _loading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<void> updateGlobalPreference({
    bool? muted,
    bool? desktopEnabled,
  }) async {
    final activeRepository = repository;
    if (activeRepository == null || _saving) {
      return;
    }
    final previousPreferences = _preferences;
    final nextPreference = globalPreference.copyWith(
      muted: muted,
      desktopEnabled: desktopEnabled,
    );
    _preferences = _upsertPreference(_preferences, nextPreference);
    _saving = true;
    _error = null;
    _notifyIfAlive();
    try {
      await activeRepository.saveNotificationPreference(
        preference: nextPreference,
      );
    } catch (_) {
      if (_disposed) {
        return;
      }
      _preferences = previousPreferences;
      _error = 'Notification preference could not be saved';
    } finally {
      if (!_disposed) {
        _saving = false;
        _notifyIfAlive();
      }
    }
  }

  bool _isCurrentLoad(int generation) {
    return !_disposed && generation == _loadGeneration;
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

List<UserSettingsNotificationPreference> _upsertPreference(
  List<UserSettingsNotificationPreference> preferences,
  UserSettingsNotificationPreference preference,
) {
  return [
    for (final existing in preferences)
      if (!existing.hasSameTarget(preference)) existing,
    preference,
  ];
}

String _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return '';
}
