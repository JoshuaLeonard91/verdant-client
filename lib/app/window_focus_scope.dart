import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'window_focus_service.dart';

typedef WindowFocusVerifier = Future<bool> Function();

class WindowFocusController extends ChangeNotifier
    with WidgetsBindingObserver, WindowListener {
  WindowFocusController({
    bool initialFocused = true,
    this.desktopBlurGracePeriod = const Duration(milliseconds: 250),
  }) : _isFocused = initialFocused;

  bool _isFocused;
  final Duration desktopBlurGracePeriod;
  WindowFocusVerifier? _desktopFocusVerifier;
  Timer? _desktopBlurTimer;
  var _desktopBlurGeneration = 0;
  bool _attachedToBinding = false;
  bool _attachedToWindowManager = false;
  bool _disposed = false;

  bool get isFocused => _isFocused;

  void attach({bool listenToWindowManager = true}) {
    if (!_attachedToBinding) {
      WidgetsBinding.instance.addObserver(this);
      _attachedToBinding = true;
      _logWindowFocus('bindingAttached');
    }
    if (listenToWindowManager &&
        !_attachedToWindowManager &&
        _supportsDesktopWindowEvents) {
      windowManager.addListener(this);
      _attachedToWindowManager = true;
      _desktopFocusVerifier ??= () =>
          desktopWindowOrProcessIsFocused(log: _logWindowFocus);
      _logWindowFocus('windowManagerAttached');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _logWindowFocus('dispose', {'focused': _isFocused});
    _cancelDesktopBlurTimer(reason: 'dispose');
    if (_attachedToBinding) {
      WidgetsBinding.instance.removeObserver(this);
      _attachedToBinding = false;
    }
    if (_attachedToWindowManager) {
      windowManager.removeListener(this);
      _attachedToWindowManager = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logWindowFocus('lifecycle', {'state': state.name, 'focused': _isFocused});
    switch (state) {
      case AppLifecycleState.resumed:
        _cancelDesktopBlurTimer(reason: 'lifecycle.resumed');
        _setFocused(true, reason: 'lifecycle.resumed');
      case AppLifecycleState.inactive:
        _scheduleDesktopBlur(reason: 'lifecycle.inactive');
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cancelDesktopBlurTimer(reason: 'lifecycle.${state.name}');
        _setFocused(false, reason: 'lifecycle.${state.name}');
    }
  }

  @override
  void onWindowFocus() {
    _logWindowFocus('windowFocus', {'focused': _isFocused});
    _cancelDesktopBlurTimer(reason: 'windowFocus');
    _setFocused(true, reason: 'windowFocus');
  }

  @override
  void onWindowBlur() {
    _logWindowFocus('windowBlur', {'focused': _isFocused});
    _scheduleDesktopBlur(reason: 'windowBlur');
  }

  void _scheduleDesktopBlur({required String reason}) {
    if (!_isFocused) {
      _logWindowFocus('blurSkipped', {
        'reason': reason,
        'focused': _isFocused,
        'generation': _desktopBlurGeneration,
      });
      return;
    }
    if (_desktopBlurTimer?.isActive == true) {
      _logWindowFocus('blurAlreadyScheduled', {
        'reason': reason,
        'generation': _desktopBlurGeneration,
      });
      return;
    }
    final generation = _desktopBlurGeneration + 1;
    _desktopBlurGeneration = generation;
    _logWindowFocus('blurScheduled', {
      'reason': reason,
      'generation': generation,
      'delayMs': desktopBlurGracePeriod.inMilliseconds,
    });
    _desktopBlurTimer = Timer(desktopBlurGracePeriod, () {
      _desktopBlurTimer = null;
      unawaited(_verifyAndApplyDesktopBlur(generation));
    });
  }

  Future<void> _verifyAndApplyDesktopBlur(int generation) async {
    _logWindowFocus('blurVerifyStart', {
      'generation': generation,
      'hasVerifier': _desktopFocusVerifier != null,
    });
    final verifier = _desktopFocusVerifier;
    if (verifier != null) {
      try {
        final stillFocused = await verifier();
        if (_disposed || generation != _desktopBlurGeneration) {
          _logWindowFocus('blurVerifyStale', {
            'generation': generation,
            'currentGeneration': _desktopBlurGeneration,
            'disposed': _disposed,
          });
          return;
        }
        _logWindowFocus('blurVerifyResult', {
          'generation': generation,
          'stillFocused': stillFocused,
        });
        if (stillFocused) {
          return;
        }
      } catch (error) {
        if (_disposed || generation != _desktopBlurGeneration) {
          _logWindowFocus('blurVerifyErrorStale', {
            'generation': generation,
            'currentGeneration': _desktopBlurGeneration,
            'disposed': _disposed,
            'errorType': error.runtimeType.toString(),
          });
          return;
        }
        _logWindowFocus('blurVerifyError', {
          'generation': generation,
          'errorType': error.runtimeType.toString(),
        });
      }
    }
    if (_disposed || generation != _desktopBlurGeneration) {
      _logWindowFocus('blurApplyStale', {
        'generation': generation,
        'currentGeneration': _desktopBlurGeneration,
        'disposed': _disposed,
      });
      return;
    }
    _setFocused(false, reason: 'blurVerified');
  }

  @visibleForTesting
  void debugSetFocused(bool value) {
    _setFocused(value, reason: 'debugSetFocused');
  }

  @visibleForTesting
  void debugSetDesktopFocusVerifier(WindowFocusVerifier? verifier) {
    _desktopFocusVerifier = verifier;
  }

  void _setFocused(bool value, {required String reason}) {
    if (_isFocused == value) {
      _logWindowFocus('focusUnchanged', {
        'reason': reason,
        'focused': value,
        'generation': _desktopBlurGeneration,
      });
      return;
    }
    _logWindowFocus('focusChanged', {
      'reason': reason,
      'from': _isFocused,
      'to': value,
      'generation': _desktopBlurGeneration,
    });
    _isFocused = value;
    notifyListeners();
  }

  void _cancelDesktopBlurTimer({required String reason}) {
    final hadTimer = _desktopBlurTimer?.isActive == true;
    _desktopBlurGeneration += 1;
    _desktopBlurTimer?.cancel();
    _desktopBlurTimer = null;
    _logWindowFocus('blurCanceled', {
      'reason': reason,
      'hadTimer': hadTimer,
      'generation': _desktopBlurGeneration,
    });
  }
}

class WindowFocusScope extends InheritedWidget {
  const WindowFocusScope({
    required this.focused,
    required super.child,
    super.key,
  });

  final bool focused;

  static bool isFocusedOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<WindowFocusScope>()
            ?.focused ??
        true;
  }

  @override
  bool updateShouldNotify(WindowFocusScope oldWidget) {
    return focused != oldWidget.focused;
  }
}

bool get _supportsDesktopWindowEvents {
  if (kIsWeb) {
    return false;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.iOS:
      return false;
  }
}

void _logWindowFocus(String event, [Map<String, Object?> fields = const {}]) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('verdant.focus $event $fields');
}
