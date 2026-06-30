import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/local_storage_namespace.dart';

const _defaultWorkspaceTextScale = 1.25;
const _minWorkspaceTextScale = 1.0;
const _maxWorkspaceTextScale = 1.5;
const workspaceTextScaleOptions = <WorkspaceTextScaleOption>[
  WorkspaceTextScaleOption(value: 1.0, label: '100%'),
  WorkspaceTextScaleOption(value: 1.125, label: '112%'),
  WorkspaceTextScaleOption(value: 1.25, label: '125%'),
  WorkspaceTextScaleOption(value: 1.375, label: '137%'),
  WorkspaceTextScaleOption(value: 1.5, label: '150%'),
];

final class WorkspaceTextScaleOption {
  const WorkspaceTextScaleOption({required this.value, required this.label});

  final double value;
  final String label;
}

final class WorkspaceAccessibilitySettings {
  const WorkspaceAccessibilitySettings({this.textScaleFactor = 1.25});

  factory WorkspaceAccessibilitySettings.fromJson(Map<String, Object?> json) {
    return WorkspaceAccessibilitySettings(
      textScaleFactor: normalizeWorkspaceTextScale(json['textScaleFactor']),
    );
  }

  final double textScaleFactor;

  Map<String, Object?> toJson() {
    return {'textScaleFactor': textScaleFactor};
  }

  WorkspaceAccessibilitySettings copyWith({double? textScaleFactor}) {
    return WorkspaceAccessibilitySettings(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }
}

abstract interface class WorkspaceAccessibilitySettingsStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

final class SharedPreferencesWorkspaceAccessibilityStorage
    implements WorkspaceAccessibilitySettingsStorage {
  SharedPreferencesWorkspaceAccessibilityStorage({
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

final class MemoryWorkspaceAccessibilitySettingsStorage
    implements WorkspaceAccessibilitySettingsStorage {
  final _values = <String, String>{};

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

final class WorkspaceAccessibilitySettingsStore {
  WorkspaceAccessibilitySettingsStore({
    WorkspaceAccessibilitySettingsStorage? storage,
    String storageNamespace = '',
  }) : _storage = storage ?? SharedPreferencesWorkspaceAccessibilityStorage(),
       _storageKey = namespacedLocalStorageKey(
         _baseStorageKey,
         storageNamespace,
       );

  factory WorkspaceAccessibilitySettingsStore.memory() {
    return WorkspaceAccessibilitySettingsStore(
      storage: MemoryWorkspaceAccessibilitySettingsStorage(),
    );
  }

  static const _baseStorageKey = 'verdant:flutter:workspace_accessibility';

  final WorkspaceAccessibilitySettingsStorage _storage;
  final String _storageKey;

  Future<WorkspaceAccessibilitySettings> load() async {
    final raw = await _storage.readString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const WorkspaceAccessibilitySettings();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return WorkspaceAccessibilitySettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return WorkspaceAccessibilitySettings.fromJson(
          Map<String, Object?>.from(decoded),
        );
      }
    } catch (_) {
      return const WorkspaceAccessibilitySettings();
    }
    return const WorkspaceAccessibilitySettings();
  }

  Future<void> save(WorkspaceAccessibilitySettings settings) {
    return _storage.writeString(_storageKey, jsonEncode(settings.toJson()));
  }
}

double normalizeWorkspaceTextScale(Object? value) {
  final numeric = switch (value) {
    double v => v,
    int v => v.toDouble(),
    String v => double.tryParse(v) ?? _defaultWorkspaceTextScale,
    _ => _defaultWorkspaceTextScale,
  };
  final clamped = numeric
      .clamp(_minWorkspaceTextScale, _maxWorkspaceTextScale)
      .toDouble();
  return nearestWorkspaceTextScale(clamped);
}

double nearestWorkspaceTextScale(double value) {
  var nearest = workspaceTextScaleOptions.first.value;
  var nearestDistance = (value - nearest).abs();
  for (final option in workspaceTextScaleOptions.skip(1)) {
    final distance = (value - option.value).abs();
    if (distance < nearestDistance) {
      nearest = option.value;
      nearestDistance = distance;
    }
  }
  return nearest;
}

String workspaceTextScaleLabel(double value) {
  final normalized = nearestWorkspaceTextScale(value);
  for (final option in workspaceTextScaleOptions) {
    if (option.value == normalized) {
      return option.label;
    }
  }
  return '${(normalized * 100).round()}%';
}
