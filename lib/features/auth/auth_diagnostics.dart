import 'package:flutter/foundation.dart';

import 'auth_diagnostics_file_service.dart';

const bool verdantClientDiagnosticsEnabled = bool.fromEnvironment(
  'VERDANT_CLIENT_DIAGNOSTICS',
  defaultValue: kDebugMode,
);

const bool verdantClientMediaUrlDiagnosticsEnabled = bool.fromEnvironment(
  'VERDANT_CLIENT_MEDIA_URL_DIAGNOSTICS',
);

abstract interface class AuthDiagnostics {
  void record(String event, Map<String, Object?> fields);
}

final class RedactingAuthDiagnostics implements AuthDiagnostics {
  const RedactingAuthDiagnostics(this.delegate);

  final AuthDiagnostics delegate;

  @override
  void record(String event, Map<String, Object?> fields) {
    delegate.record(event, sanitizeAuthDiagnosticFields(fields));
  }
}

final class TaggedAuthDiagnostics implements AuthDiagnostics {
  const TaggedAuthDiagnostics({required this.delegate, required this.fields});

  final AuthDiagnostics delegate;
  final Map<String, Object?> fields;

  @override
  void record(String event, Map<String, Object?> fields) {
    delegate.record(event, {...this.fields, ...fields});
  }
}

final class SilentAuthDiagnostics implements AuthDiagnostics {
  const SilentAuthDiagnostics();

  @override
  void record(String event, Map<String, Object?> fields) {}
}

final class DebugPrintAuthDiagnostics implements AuthDiagnostics {
  const DebugPrintAuthDiagnostics({
    this.enabled = verdantClientDiagnosticsEnabled,
  });

  final bool enabled;

  @override
  void record(String event, Map<String, Object?> fields) {
    if (!enabled) {
      return;
    }

    writeVerdantDiagnosticLine(
      'verdant.auth $event ${sanitizeAuthDiagnosticFields(fields)}',
    );
  }
}

void writeVerdantDiagnosticLine(String line) {
  writeVerdantDiagnosticLineToSink(line);
}

String get verdantReleaseDiagnosticsPath => verdantReleaseDiagnosticsFilePath;

Map<String, Object?> sanitizeAuthDiagnosticFields(Map<String, Object?> fields) {
  return fields.map(
    (key, value) => MapEntry(key, _safeDiagnosticValue(key, value)),
  );
}

Object? _safeDiagnosticValue(String key, Object? value) {
  final lowerKey = key.toLowerCase();
  const sensitiveFragments = [
    'authorization',
    'bearer',
    'cookie',
    'email',
    'password',
    'secret',
    'session',
    'ticket',
    'token',
  ];
  if (sensitiveFragments.any(lowerKey.contains)) {
    return 'redacted';
  }
  if (value is Map) {
    return value.map(
      (nestedKey, nestedValue) => MapEntry(
        nestedKey,
        _safeDiagnosticValue(nestedKey.toString(), nestedValue),
      ),
    );
  }
  if (value is Iterable) {
    return [
      for (final item in value)
        _safeDiagnosticValue(key, item is Object ? item : item?.toString()),
    ];
  }
  if (value is String) {
    if (_looksSensitiveDiagnosticString(value)) {
      return 'redacted';
    }
    final sanitized = _redactSensitiveDiagnosticFragments(value);
    if (sanitized.length > 160) {
      return '${sanitized.substring(0, 157)}...';
    }
    return sanitized;
  }
  return value;
}

bool _looksSensitiveDiagnosticString(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (RegExp(r'^Bearer\s+\S+$', caseSensitive: false).hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(
    r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
  ).hasMatch(trimmed)) {
    return true;
  }
  return false;
}

String _redactSensitiveDiagnosticFragments(String value) {
  var sanitized = value.replaceAllMapped(
    RegExp(r'Bearer\s+\S+', caseSensitive: false),
    (_) => 'Bearer redacted',
  );
  sanitized = sanitized.replaceAll(
    RegExp(r'\b[^@\s]+@[^@\s]+\.[^@\s]+\b'),
    'redacted',
  );
  sanitized = sanitized.replaceAll(
    RegExp(r'\b[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b'),
    'redacted',
  );
  return sanitized;
}
