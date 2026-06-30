import 'dart:ffi';
import 'dart:io' show Platform, pid;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;
import 'package:window_manager/window_manager.dart';

typedef WindowFocusProbeLogger =
    void Function(String event, Map<String, Object?> fields);

Future<bool> desktopWindowOrProcessIsFocused({
  WindowFocusProbeLogger? log,
}) async {
  final windowFocused = await windowManager.isFocused();
  if (windowFocused) {
    _log(log, 'verifier.windowFocused');
    return true;
  }
  if (!Platform.isWindows) {
    _log(log, 'verifier.windowUnfocused', {'platform': 'nonWindows'});
    return false;
  }

  final foregroundWindow = win32.GetForegroundWindow();
  if (foregroundWindow.address == 0) {
    _log(log, 'verifier.foregroundMissing');
    return false;
  }

  final processId = calloc<Uint32>();
  try {
    win32.GetWindowThreadProcessId(foregroundWindow, processId);
    final sameProcess = processId.value == pid;
    _log(log, 'verifier.foregroundProcess', {
      'sameProcess': sameProcess,
      'hasForegroundWindow': true,
    });
    return sameProcess;
  } finally {
    calloc.free(processId);
  }
}

void _log(
  WindowFocusProbeLogger? log,
  String event, [
  Map<String, Object?> fields = const {},
]) {
  log?.call(event, fields);
}
