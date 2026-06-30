import 'dart:async';
import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class UserSettingsNotificationSoundPreview {
  Future<void> play();
}

@visibleForTesting
String debugWindowsNotificationSoundLibraryPath() =>
    _WindowsNotificationSoundPlayer.libraryPath();

final class SystemUserSettingsNotificationSoundPreview
    implements UserSettingsNotificationSoundPreview {
  const SystemUserSettingsNotificationSoundPreview();

  @override
  Future<void> play() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final played = _WindowsNotificationSoundPlayer.play(
          _VerdantNotificationChime.wavBytes,
          _VerdantNotificationChime.duration,
        );
        if (played) {
          return Future<void>.value();
        }
      } catch (_) {
        // Fall through to Flutter's local fallback if native playback is unavailable.
      }
    }
    return SystemSound.play(SystemSoundType.click);
  }
}

final class _WindowsNotificationSoundPlayer {
  const _WindowsNotificationSoundPlayer._();

  static const _sndAsync = 0x0001;
  static const _sndNodefault = 0x0002;
  static const _sndMemory = 0x0004;
  static final _retainedBuffers = <Pointer<Uint8>>[];

  static final _playSound = _loadWinmm()
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>, Uint32),
        int Function(Pointer<Void>, Pointer<Void>, int)
      >('PlaySoundW');

  static DynamicLibrary _loadWinmm() {
    return DynamicLibrary.open(libraryPath());
  }

  static String libraryPath() => '${_Kernel32.systemDirectory()}\\winmm.dll';

  static bool play(Uint8List wavBytes, Duration duration) {
    final buffer = malloc<Uint8>(wavBytes.length);
    buffer.asTypedList(wavBytes.length).setAll(0, wavBytes);
    final ok = _playSound(
      buffer.cast<Void>(),
      nullptr,
      _sndAsync | _sndNodefault | _sndMemory,
    );
    if (ok == 0) {
      malloc.free(buffer);
      return false;
    }
    _retainedBuffers.add(buffer);
    Timer(duration + const Duration(milliseconds: 250), () {
      _retainedBuffers.remove(buffer);
      malloc.free(buffer);
    });
    return true;
  }
}

final class _Kernel32 {
  const _Kernel32._();

  static const _maxSystemDirectoryLength = 32767;

  static final _getSystemDirectory = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<
        Uint32 Function(Pointer<Utf16>, Uint32),
        int Function(Pointer<Utf16>, int)
      >('GetSystemDirectoryW');

  static String systemDirectory() {
    final buffer = malloc<Uint16>(_maxSystemDirectoryLength + 1);
    try {
      final length = _getSystemDirectory(
        buffer.cast<Utf16>(),
        _maxSystemDirectoryLength,
      );
      if (length <= 0 || length > _maxSystemDirectoryLength) {
        throw StateError('System directory unavailable');
      }
      return buffer.cast<Utf16>().toDartString(length: length);
    } finally {
      malloc.free(buffer);
    }
  }
}

final class _VerdantNotificationChime {
  const _VerdantNotificationChime._();

  static const duration = Duration(milliseconds: 440);
  static final wavBytes = _buildWav();

  static Uint8List _buildWav() {
    const sampleRate = 44100;
    const maxAmplitude = 32767;
    final sampleCount =
        (sampleRate * duration.inMicroseconds / Duration.microsecondsPerSecond)
            .round();
    final pcm = BytesBuilder(copy: false);
    for (var i = 0; i < sampleCount; i += 1) {
      final seconds = i / sampleRate;
      final note = seconds < 0.19
          ? (frequency: 784.0, start: 0.0, end: 0.19, gain: 0.20)
          : (frequency: 1174.66, start: 0.19, end: 0.44, gain: 0.16);
      final local = ((seconds - note.start) / (note.end - note.start)).clamp(
        0.0,
        1.0,
      );
      final envelope = _attackReleaseEnvelope(local);
      final fundamental = math.sin(2 * math.pi * note.frequency * seconds);
      final shimmer = math.sin(2 * math.pi * note.frequency * 2 * seconds);
      final sample =
          (fundamental * 0.86 + shimmer * 0.14) * note.gain * envelope;
      _writeInt16(pcm, (sample * maxAmplitude).round());
    }
    return _wrapPcmAsWav(pcm.takeBytes(), sampleRate);
  }

  static double _attackReleaseEnvelope(double local) {
    final attack = (local / 0.12).clamp(0.0, 1.0);
    final release = ((1 - local) / 0.72).clamp(0.0, 1.0);
    return math.sin(attack * math.pi / 2) * math.sin(release * math.pi / 2);
  }

  static Uint8List _wrapPcmAsWav(Uint8List pcm, int sampleRate) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final output = BytesBuilder(copy: false)
      ..add('RIFF'.codeUnits)
      ..add(_uint32Bytes(36 + pcm.length))
      ..add('WAVE'.codeUnits)
      ..add('fmt '.codeUnits)
      ..add(_uint32Bytes(16))
      ..add(_uint16Bytes(1))
      ..add(_uint16Bytes(channels))
      ..add(_uint32Bytes(sampleRate))
      ..add(_uint32Bytes(byteRate))
      ..add(_uint16Bytes(blockAlign))
      ..add(_uint16Bytes(bitsPerSample))
      ..add('data'.codeUnits)
      ..add(_uint32Bytes(pcm.length))
      ..add(pcm);
    return output.takeBytes();
  }

  static void _writeInt16(BytesBuilder builder, int value) {
    final clamped = value.clamp(-32768, 32767).toInt();
    builder.add([clamped & 0xFF, (clamped >> 8) & 0xFF]);
  }

  static List<int> _uint16Bytes(int value) => [
    value & 0xFF,
    (value >> 8) & 0xFF,
  ];

  static List<int> _uint32Bytes(int value) => [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}
