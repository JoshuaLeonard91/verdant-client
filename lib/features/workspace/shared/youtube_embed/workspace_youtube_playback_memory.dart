import 'package:flutter/foundation.dart';

@immutable
final class WorkspaceYouTubePlaybackSnapshot {
  const WorkspaceYouTubePlaybackSnapshot({
    this.positionSeconds = 0,
    this.hasStarted = false,
    this.isPlaying = false,
  });

  final double positionSeconds;
  final bool hasStarted;
  final bool isPlaying;

  bool get hasResumePosition => positionSeconds >= 1;
}

@immutable
final class WorkspaceYouTubePlaybackUpdate {
  const WorkspaceYouTubePlaybackUpdate({
    required this.videoId,
    required this.positionSeconds,
    required this.state,
    required this.hasStarted,
    required this.isPlaying,
    this.isMuted,
    this.volume,
  });

  final String videoId;
  final double positionSeconds;
  final int state;
  final bool hasStarted;
  final bool isPlaying;
  final bool? isMuted;
  final double? volume;
}

final class WorkspaceYouTubePlaybackMemory {
  static const _maxRememberedPositionSeconds = 60 * 60 * 12;

  final Map<String, WorkspaceYouTubePlaybackSnapshot> _snapshots = {};

  WorkspaceYouTubePlaybackSnapshot snapshotFor(String videoId) {
    return _snapshots[videoId] ?? const WorkspaceYouTubePlaybackSnapshot();
  }

  void record(WorkspaceYouTubePlaybackUpdate update) {
    final previous = snapshotFor(update.videoId);
    final isUnknownState = update.state < 0;
    _snapshots[update.videoId] = WorkspaceYouTubePlaybackSnapshot(
      positionSeconds: update.state == 0
          ? 0
          : _clampPosition(update.positionSeconds),
      hasStarted: previous.hasStarted || update.hasStarted || update.isPlaying,
      isPlaying: isUnknownState ? previous.isPlaying : update.isPlaying,
    );
  }

  void markAllStopped() {
    for (final entry in _snapshots.entries.toList()) {
      _snapshots[entry.key] = WorkspaceYouTubePlaybackSnapshot(
        positionSeconds: entry.value.positionSeconds,
        hasStarted: entry.value.hasStarted,
        isPlaying: false,
      );
    }
  }

  void markStopped(String videoId) {
    final previous = _snapshots[videoId];
    if (previous == null) {
      return;
    }
    _snapshots[videoId] = WorkspaceYouTubePlaybackSnapshot(
      positionSeconds: previous.positionSeconds,
      hasStarted: previous.hasStarted,
      isPlaying: false,
    );
  }

  void clear() {
    _snapshots.clear();
  }

  double _clampPosition(double positionSeconds) {
    if (!positionSeconds.isFinite || positionSeconds < 0) {
      return 0;
    }
    if (positionSeconds > _maxRememberedPositionSeconds) {
      return _maxRememberedPositionSeconds.toDouble();
    }
    return positionSeconds;
  }
}

final defaultWorkspaceYouTubePlaybackMemory = WorkspaceYouTubePlaybackMemory();
