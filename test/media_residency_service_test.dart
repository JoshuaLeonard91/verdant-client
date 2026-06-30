import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/shared/media_residency_service.dart';

void main() {
  test('keeps one resident entry per scoped media key', () {
    final clock = _FakeClock(DateTime.utc(2026, 6, 14));
    final service = MediaResidencyService(
      clock: clock.now,
      ttl: const Duration(minutes: 3),
      maxEntries: 8,
      maxBytes: 1024,
    );
    final key = MediaResidencyKey(
      networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
      routeId: 'channel:general',
      kind: MediaResidencyKind.image,
      identity: 'avatars/1.webp',
      variant: '96x96',
    );

    service.markVisible(key, estimatedBytes: 128);
    service.markVisible(key, estimatedBytes: 128);

    expect(service.debugSnapshot().entryCount, 1);
    expect(service.debugSnapshot().residentBytes, 128);
    expect(service.shouldRemainResident(key), isTrue);
  });

  test('expires non-visible entries after ttl', () {
    final clock = _FakeClock(DateTime.utc(2026, 6, 14));
    final service = MediaResidencyService(
      clock: clock.now,
      ttl: const Duration(minutes: 3),
      maxEntries: 8,
      maxBytes: 1024,
    );
    final key = MediaResidencyKey(
      networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
      routeId: 'channel:general',
      kind: MediaResidencyKind.image,
      identity: 'avatars/1.webp',
      variant: '96x96',
    );

    service.markVisible(key, estimatedBytes: 128);
    service.markNotVisible(key);
    clock.advance(const Duration(minutes: 1));

    expect(service.timeUntilExpiry(key), const Duration(minutes: 2));

    clock.advance(const Duration(minutes: 4));
    service.pruneExpired();

    expect(service.shouldRemainResident(key), isFalse);
    expect(service.debugSnapshot().entryCount, 0);
  });

  test(
    'clears active player entries for a route without clearing thumbnails',
    () {
      final service = MediaResidencyService(
        ttl: const Duration(minutes: 3),
        maxEntries: 8,
        maxBytes: 1024,
      );
      final player = MediaResidencyKey(
        networkId: 'origin:https%3A%2F%2Fapi.verdant.chat',
        routeId: 'feed:announcements',
        kind: MediaResidencyKind.youtubePlayer,
        identity: 'k1_ODDevbY8',
        variant: 'iframe',
      );
      final thumbnail = MediaResidencyKey(
        networkId: 'external:youtube',
        routeId: 'feed:announcements',
        kind: MediaResidencyKind.youtubeThumbnail,
        identity: 'k1_ODDevbY8',
        variant: 'hqdefault',
      );

      service.markVisible(player, estimatedBytes: 1);
      service.markVisible(thumbnail, estimatedBytes: 1);
      service.clearRoute('feed:announcements', clearNonPlayerMedia: false);

      expect(service.shouldRemainResident(player), isFalse);
      expect(service.shouldRemainResident(thumbnail), isTrue);
    },
  );

  test('clears youtube thumbnail entries and notifies image eviction', () {
    final service = MediaResidencyService(
      ttl: const Duration(minutes: 3),
      maxEntries: 8,
      maxBytes: 1024 * 1024,
    );
    var evictions = 0;
    final thumbnail = MediaResidencyKey(
      networkId: 'external:youtube',
      routeId: 'feed:announcements',
      kind: MediaResidencyKind.youtubeThumbnail,
      identity: 'k1_ODDevbY8',
      variant: 'thumbnail',
    );

    service.markVisibleWithEviction(
      thumbnail,
      estimatedBytes: 480 * 360 * 4,
      onEvict: () => evictions += 1,
    );
    service.clearRoute('feed:announcements');

    expect(service.shouldRemainResident(thumbnail), isFalse);
    expect(service.debugSnapshot().entryCount, 0);
    expect(evictions, 1);
  });

  test('prunes expired youtube thumbnails and notifies eviction once', () {
    final clock = _FakeClock(DateTime.utc(2026, 6, 14));
    final service = MediaResidencyService(
      clock: clock.now,
      ttl: const Duration(minutes: 3),
      maxEntries: 8,
      maxBytes: 1024 * 1024,
    );
    var evictions = 0;
    final thumbnail = MediaResidencyKey(
      networkId: 'external:youtube',
      routeId: 'feed:announcements',
      kind: MediaResidencyKind.youtubeThumbnail,
      identity: 'k1_ODDevbY8',
      variant: 'thumbnail',
    );

    service.markVisibleWithEviction(
      thumbnail,
      estimatedBytes: 480 * 360 * 4,
      onEvict: () => evictions += 1,
    );
    service.markVisibleWithEviction(
      thumbnail,
      estimatedBytes: 480 * 360 * 4,
      onEvict: () => evictions += 1,
    );
    service.markNotVisible(thumbnail);
    clock.advance(const Duration(minutes: 4));
    service.pruneExpired();

    expect(service.shouldRemainResident(thumbnail), isFalse);
    expect(service.debugSnapshot().entryCount, 0);
    expect(evictions, 1);
  });

  test('evicts oldest entries when byte budget is exceeded', () {
    final service = MediaResidencyService(
      ttl: const Duration(minutes: 3),
      maxEntries: 10,
      maxBytes: 200,
    );
    service.markVisible(
      const MediaResidencyKey(
        networkId: 'n',
        routeId: 'r',
        kind: MediaResidencyKind.image,
        identity: 'a',
        variant: 'v',
      ),
      estimatedBytes: 150,
    );
    service.markVisible(
      const MediaResidencyKey(
        networkId: 'n',
        routeId: 'r',
        kind: MediaResidencyKind.image,
        identity: 'b',
        variant: 'v',
      ),
      estimatedBytes: 150,
    );

    expect(service.debugSnapshot().entryCount, 1);
    expect(service.debugSnapshot().residentBytes, 150);
  });
}

final class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime now() => value;

  void advance(Duration duration) => value = value.add(duration);
}
