import 'package:flutter/foundation.dart';

enum MediaResidencyKind {
  image,
  animatedImage,
  linkPreviewMetadata,
  linkPreviewImage,
  youtubeThumbnail,
  youtubePlayer,
}

@immutable
final class MediaResidencyKey {
  const MediaResidencyKey({
    required this.networkId,
    required this.routeId,
    required this.kind,
    required this.identity,
    required this.variant,
  });

  final String networkId;
  final String routeId;
  final MediaResidencyKind kind;
  final String identity;
  final String variant;

  bool get isPlayer => kind == MediaResidencyKind.youtubePlayer;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MediaResidencyKey &&
            networkId == other.networkId &&
            routeId == other.routeId &&
            kind == other.kind &&
            identity == other.identity &&
            variant == other.variant;
  }

  @override
  int get hashCode => Object.hash(networkId, routeId, kind, identity, variant);
}

@immutable
final class MediaResidencySnapshot {
  const MediaResidencySnapshot({
    required this.entryCount,
    required this.residentBytes,
  });

  final int entryCount;
  final int residentBytes;
}

final class MediaResidencyService {
  MediaResidencyService({
    DateTime Function()? clock,
    this.ttl = const Duration(minutes: 3),
    this.maxEntries = 192,
    this.maxBytes = 64 * 1024 * 1024,
  }) : assert(ttl >= Duration.zero),
       assert(maxEntries > 0),
       assert(maxBytes > 0),
       _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration ttl;
  final int maxEntries;
  final int maxBytes;
  final _entries = <MediaResidencyKey, _MediaResidencyEntry>{};
  int _residentBytes = 0;

  void markVisible(MediaResidencyKey key, {required int estimatedBytes}) {
    markVisibleWithEviction(key, estimatedBytes: estimatedBytes);
  }

  void markVisibleWithEviction(
    MediaResidencyKey key, {
    required int estimatedBytes,
    VoidCallback? onEvict,
  }) {
    final now = _clock();
    final existing = _entries.remove(key);
    if (existing != null) {
      _residentBytes -= existing.estimatedBytes;
    }
    final normalizedBytes = estimatedBytes < 0 ? 0 : estimatedBytes;
    _entries[key] = _MediaResidencyEntry(
      estimatedBytes: normalizedBytes,
      visible: true,
      active: existing?.active ?? false,
      onEvict: onEvict ?? existing?.onEvict,
      lastVisibleAt: now,
      lastTouchedAt: now,
    );
    _residentBytes += normalizedBytes;
    _evictToBudget();
  }

  void markNotVisible(MediaResidencyKey key) {
    final entry = _entries.remove(key);
    if (entry == null) {
      return;
    }
    _entries[key] = entry.copyWith(visible: false, lastTouchedAt: _clock());
  }

  void markActive(MediaResidencyKey key, {required bool active}) {
    final entry = _entries.remove(key);
    if (entry == null) {
      return;
    }
    _entries[key] = entry.copyWith(active: active, lastTouchedAt: _clock());
  }

  bool shouldRemainResident(MediaResidencyKey key) {
    final entry = _entries[key];
    if (entry == null) {
      return false;
    }
    if (entry.visible || entry.active) {
      return true;
    }
    return _clock().difference(entry.lastVisibleAt) <= ttl;
  }

  Duration? timeUntilExpiry(MediaResidencyKey key) {
    final entry = _entries[key];
    if (entry == null || entry.visible || entry.active) {
      return null;
    }
    final elapsed = _clock().difference(entry.lastVisibleAt);
    if (elapsed >= ttl) {
      return Duration.zero;
    }
    return ttl - elapsed;
  }

  void clearRoute(String routeId, {bool clearNonPlayerMedia = true}) {
    final keys = _entries.keys
        .where(
          (key) =>
              key.routeId == routeId && (clearNonPlayerMedia || key.isPlayer),
        )
        .toList(growable: false);
    for (final key in keys) {
      _removeEntry(key, notifyEviction: true);
    }
  }

  void clearNetwork(String networkId) {
    final keys = _entries.keys
        .where((key) => key.networkId == networkId)
        .toList(growable: false);
    for (final key in keys) {
      _removeEntry(key, notifyEviction: true);
    }
  }

  void clear() {
    for (final entry in _entries.values.toList(growable: false)) {
      _notifyEvicted(entry);
    }
    _entries.clear();
    _residentBytes = 0;
  }

  void pruneExpired() {
    final keys = _entries.entries
        .where((entry) => !shouldRemainResident(entry.key))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in keys) {
      _removeEntry(key, notifyEviction: true);
    }
  }

  MediaResidencySnapshot debugSnapshot() {
    return MediaResidencySnapshot(
      entryCount: _entries.length,
      residentBytes: _residentBytes,
    );
  }

  void _evictToBudget() {
    while (_entries.length > maxEntries || _residentBytes > maxBytes) {
      final key = _entries.keys.first;
      if (!_removeEntry(key, notifyEviction: true)) {
        break;
      }
    }
  }

  bool _removeEntry(MediaResidencyKey key, {required bool notifyEviction}) {
    final removed = _entries.remove(key);
    if (removed == null) {
      return false;
    }
    _residentBytes -= removed.estimatedBytes;
    if (notifyEviction) {
      _notifyEvicted(removed);
    }
    return true;
  }

  void _notifyEvicted(_MediaResidencyEntry entry) {
    final onEvict = entry.onEvict;
    if (onEvict == null) {
      return;
    }
    try {
      onEvict();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'verdant media residency',
          context: ErrorDescription('while evicting resident media'),
        ),
      );
    }
  }
}

@immutable
final class _MediaResidencyEntry {
  const _MediaResidencyEntry({
    required this.estimatedBytes,
    required this.visible,
    required this.active,
    required this.onEvict,
    required this.lastVisibleAt,
    required this.lastTouchedAt,
  });

  final int estimatedBytes;
  final bool visible;
  final bool active;
  final VoidCallback? onEvict;
  final DateTime lastVisibleAt;
  final DateTime lastTouchedAt;

  _MediaResidencyEntry copyWith({
    bool? visible,
    bool? active,
    DateTime? lastTouchedAt,
  }) {
    final nextVisible = visible ?? this.visible;
    final nextTouchedAt = lastTouchedAt ?? this.lastTouchedAt;
    return _MediaResidencyEntry(
      estimatedBytes: estimatedBytes,
      visible: nextVisible,
      active: active ?? this.active,
      onEvict: onEvict,
      lastVisibleAt: nextVisible ? nextTouchedAt : lastVisibleAt,
      lastTouchedAt: nextTouchedAt,
    );
  }
}
