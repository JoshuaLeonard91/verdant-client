import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../workspace_render_diagnostics.dart';

typedef WorkspaceYouTubeKeepAliveDisposer =
    Future<void> Function(InAppWebViewKeepAlive keepAlive);

@immutable
final class WorkspaceYouTubeWebViewLease {
  const WorkspaceYouTubeWebViewLease._({
    required this.poolKey,
    required this.videoId,
    required this.keepAlive,
    required this.reusedExistingPlayer,
  });

  final String poolKey;
  final String videoId;
  final InAppWebViewKeepAlive keepAlive;
  final bool reusedExistingPlayer;
}

final class WorkspaceYouTubeWebViewPool {
  WorkspaceYouTubeWebViewPool({
    int maxKeepAlivePlayers = 3,
    WorkspaceYouTubeKeepAliveDisposer? disposeKeepAlive,
  }) : _maxKeepAlivePlayers = maxKeepAlivePlayers < 1 ? 1 : maxKeepAlivePlayers,
       _disposeKeepAlive =
           disposeKeepAlive ?? InAppWebViewController.disposeKeepAlive;

  final int _maxKeepAlivePlayers;
  final WorkspaceYouTubeKeepAliveDisposer _disposeKeepAlive;
  final LinkedHashMap<String, _PooledYouTubeWebView> _entries =
      LinkedHashMap<String, _PooledYouTubeWebView>();

  WorkspaceYouTubeWebViewLease acquire(String poolKey, {String? videoId}) {
    final diagnosticVideoId = videoId ?? poolKey;
    final existing = _entries.remove(poolKey);
    if (existing != null) {
      existing.activeLeases += 1;
      existing.lastUsedAt = DateTime.now();
      _entries[poolKey] = existing;
      _logYouTubeWebViewPool('lease.reused', diagnosticVideoId, {
        'activeLeases': existing.activeLeases,
        'entries': _entries.length,
      });
      return WorkspaceYouTubeWebViewLease._(
        poolKey: poolKey,
        videoId: diagnosticVideoId,
        keepAlive: existing.keepAlive,
        reusedExistingPlayer: true,
      );
    }

    final entry = _PooledYouTubeWebView(
      keepAlive: InAppWebViewKeepAlive(),
      activeLeases: 1,
      lastUsedAt: DateTime.now(),
    );
    _entries[poolKey] = entry;
    _logYouTubeWebViewPool('lease.created', diagnosticVideoId, {
      'activeLeases': entry.activeLeases,
      'entries': _entries.length,
    });
    unawaited(_evictIdleEntriesIfNeeded());
    return WorkspaceYouTubeWebViewLease._(
      poolKey: poolKey,
      videoId: diagnosticVideoId,
      keepAlive: entry.keepAlive,
      reusedExistingPlayer: false,
    );
  }

  Future<void> release(WorkspaceYouTubeWebViewLease lease) async {
    final entry = _entries[lease.poolKey];
    if (entry == null || !identical(entry.keepAlive, lease.keepAlive)) {
      _logYouTubeWebViewPool('lease.releaseIgnored', lease.videoId, {
        'entries': _entries.length,
      });
      return;
    }
    if (entry.activeLeases > 0) {
      entry.activeLeases -= 1;
    }
    entry.lastUsedAt = DateTime.now();
    _logYouTubeWebViewPool('lease.released', lease.videoId, {
      'activeLeases': entry.activeLeases,
      'entries': _entries.length,
    });
    await _evictIdleEntriesIfNeeded();
  }

  Future<void> clear() async {
    final evictions = List<MapEntry<String, _PooledYouTubeWebView>>.from(
      _entries.entries,
    );
    _entries.clear();
    for (final eviction in evictions) {
      await _disposeEntry(eviction.key, eviction.value, reason: 'clear');
    }
  }

  Future<void> _evictIdleEntriesIfNeeded() async {
    while (_entries.length > _maxKeepAlivePlayers) {
      final eviction = _oldestIdleEntry();
      if (eviction == null) {
        _logYouTubeWebViewPool('evict.deferred', 'none', {
          'entries': _entries.length,
          'maxEntries': _maxKeepAlivePlayers,
        });
        return;
      }
      _entries.remove(eviction.key);
      await _disposeEntry(eviction.key, eviction.value, reason: 'capacity');
    }
  }

  MapEntry<String, _PooledYouTubeWebView>? _oldestIdleEntry() {
    MapEntry<String, _PooledYouTubeWebView>? oldest;
    for (final entry in _entries.entries) {
      if (entry.value.activeLeases > 0) {
        continue;
      }
      if (oldest == null ||
          entry.value.lastUsedAt.isBefore(oldest.value.lastUsedAt)) {
        oldest = entry;
      }
    }
    return oldest;
  }

  Future<void> _disposeEntry(
    String videoId,
    _PooledYouTubeWebView entry, {
    required String reason,
  }) async {
    _logYouTubeWebViewPool('evict.start', videoId, {
      'reason': reason,
      'activeLeases': entry.activeLeases,
      'entries': _entries.length,
    });
    try {
      await _disposeKeepAlive(entry.keepAlive);
      _logYouTubeWebViewPool('evict.done', videoId, {'reason': reason});
    } catch (error) {
      _logYouTubeWebViewPool('evict.error', videoId, {
        'reason': reason,
        'errorType': error.runtimeType.toString(),
      });
    }
  }
}

final defaultWorkspaceYouTubeWebViewPool = WorkspaceYouTubeWebViewPool();

final class _PooledYouTubeWebView {
  _PooledYouTubeWebView({
    required this.keepAlive,
    required this.activeLeases,
    required this.lastUsedAt,
  });

  final InAppWebViewKeepAlive keepAlive;
  int activeLeases;
  DateTime lastUsedAt;
}

void _logYouTubeWebViewPool(
  String event,
  String videoId, [
  Map<String, Object?> fields = const {},
]) {
  logWorkspaceRender('youtube.webviewPool.$event', {
    'videoId': videoId,
    ...fields,
  });
}
