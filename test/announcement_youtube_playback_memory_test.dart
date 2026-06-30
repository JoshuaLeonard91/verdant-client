import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_youtube_playback_memory.dart';

void main() {
  test('youtube playback memory stores position and active playback state', () {
    final memory = AnnouncementYouTubePlaybackMemory();

    memory.record(
      const AnnouncementYouTubePlaybackUpdate(
        videoId: 'k1_ODDevbY8',
        positionSeconds: 61.7,
        state: 1,
        hasStarted: true,
        isPlaying: true,
      ),
    );

    var snapshot = memory.snapshotFor('k1_ODDevbY8');
    expect(snapshot.positionSeconds, 61.7);
    expect(snapshot.hasStarted, isTrue);
    expect(snapshot.isPlaying, isTrue);
    expect(snapshot.hasResumePosition, isTrue);

    memory.markStopped('k1_ODDevbY8');

    snapshot = memory.snapshotFor('k1_ODDevbY8');
    expect(snapshot.positionSeconds, 61.7);
    expect(snapshot.hasStarted, isTrue);
    expect(snapshot.isPlaying, isFalse);
  });

  test('youtube playback memory resets ended videos to the beginning', () {
    final memory = AnnouncementYouTubePlaybackMemory();

    memory.record(
      const AnnouncementYouTubePlaybackUpdate(
        videoId: 'k1_ODDevbY8',
        positionSeconds: 120,
        state: 1,
        hasStarted: true,
        isPlaying: true,
      ),
    );
    memory.record(
      const AnnouncementYouTubePlaybackUpdate(
        videoId: 'k1_ODDevbY8',
        positionSeconds: 121,
        state: 0,
        hasStarted: true,
        isPlaying: false,
      ),
    );

    final snapshot = memory.snapshotFor('k1_ODDevbY8');
    expect(snapshot.positionSeconds, 0);
    expect(snapshot.hasStarted, isTrue);
    expect(snapshot.isPlaying, isFalse);
    expect(snapshot.hasResumePosition, isFalse);
  });

  test(
    'youtube playback memory keeps playing through unknown iframe state',
    () {
      final memory = AnnouncementYouTubePlaybackMemory();

      memory.record(
        const AnnouncementYouTubePlaybackUpdate(
          videoId: 'k1_ODDevbY8',
          positionSeconds: 12,
          state: 1,
          hasStarted: true,
          isPlaying: true,
        ),
      );
      memory.record(
        const AnnouncementYouTubePlaybackUpdate(
          videoId: 'k1_ODDevbY8',
          positionSeconds: 13,
          state: -1,
          hasStarted: false,
          isPlaying: false,
        ),
      );

      final snapshot = memory.snapshotFor('k1_ODDevbY8');
      expect(snapshot.positionSeconds, 13);
      expect(snapshot.hasStarted, isTrue);
      expect(snapshot.isPlaying, isTrue);
    },
  );
}
