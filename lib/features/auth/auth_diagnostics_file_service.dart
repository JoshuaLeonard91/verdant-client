import 'dart:io';

import 'package:flutter/foundation.dart';

void writeVerdantDiagnosticLineToSink(String line) {
  if (kDebugMode) {
    debugPrint(line);
    return;
  }
  try {
    _releaseDiagnosticsFile.writeAsStringSync(
      '${DateTime.now().toUtc().toIso8601String()} $line\n',
      mode: FileMode.append,
      flush: false,
    );
  } catch (_) {
    debugPrint(line);
  }
}

String get verdantReleaseDiagnosticsFilePath => _releaseDiagnosticsFile.path;

File get _releaseDiagnosticsFile {
  final base = Platform.environment['TEMP']?.trim().isNotEmpty == true
      ? Platform.environment['TEMP']!.trim()
      : Directory.systemTemp.path;
  return File('$base${Platform.pathSeparator}verdant_flutter_diagnostics.log');
}
