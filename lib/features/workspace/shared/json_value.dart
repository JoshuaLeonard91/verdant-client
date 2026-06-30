import 'dart:convert';
import 'dart:ui';

bool jsonBool(Object? value) => value is bool && value;

bool? jsonNullableBool(Object? value) => value is bool ? value : null;

int jsonInt(Object? value, {required int fallback}) {
  return value is num ? value.toInt() : fallback;
}

int? jsonNullableNonNegativeInt(Object? value) {
  if (value is int && value >= 0) {
    return value;
  }
  if (value is num && value >= 0) {
    return value.round();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0) {
      return parsed;
    }
  }
  return null;
}

String jsonString(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? jsonNullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : value;
}

Map<String, Object?>? jsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}

Map<String, Object?>? jsonObjectFromString(String value) {
  try {
    return jsonMap(jsonDecode(value));
  } catch (_) {
    return null;
  }
}

Color? jsonHexColor(Object? value) {
  if (value is! String || !value.startsWith('#') || value.length != 7) {
    return null;
  }
  final parsed = int.tryParse(value.substring(1), radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}
