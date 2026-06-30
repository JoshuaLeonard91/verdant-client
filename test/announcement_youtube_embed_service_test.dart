import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/features/workspace/chat_workspace/announcement_feed/announcement_youtube_embed_service.dart';

void main() {
  test('youtube embed service constructs only canonical player urls', () {
    const service = AnnouncementYouTubeEmbedService();

    final embed = service.fromUrl(
      'https://www.youtube.com/watch?v=k1_ODDevbY8',
    );

    expect(embed, isNotNull);
    expect(embed!.videoId, 'k1_ODDevbY8');
    expect(
      embed.watchUri,
      Uri.parse('https://www.youtube.com/watch?v=k1_ODDevbY8'),
    );
    expect(embed.embedUri.scheme, 'https');
    expect(embed.embedUri.host, 'www.youtube-nocookie.com');
    expect(embed.embedUri.path, '/embed/k1_ODDevbY8');
    expect(
      embed.embedUri.queryParameters['origin'],
      'https://youtube-player.verdant.invalid',
    );
    expect(embed.embedUri.queryParameters['autoplay'], '0');
    expect(embed.embedUri.queryParameters.containsKey('mute'), isFalse);
    expect(embed.thumbnailUri.host, 'img.youtube.com');
    expect(embed.embedUri.toString(), isNot(contains('verdant.chat')));
  });

  test('youtube embed service builds a stable local player shell route', () {
    const service = AnnouncementYouTubeEmbedService();
    final embed = service.fromVideoId('k1_ODDevbY8');

    final shellUri = service.playerShellUriForEmbed(embed.embedUri);
    final resumedShellUri = service.playerShellUriForEmbed(
      embed.embedUri,
      startSeconds: 42.8,
    );
    final autoplayShellUri = service.playerShellUriForEmbed(
      embed.embedUri,
      autoplay: true,
    );

    expect(
      shellUri,
      Uri.parse(
        'https://youtube-player.verdant.invalid/workspace-youtube-video/k1_ODDevbY8',
      ),
    );
    expect(
      resumedShellUri,
      Uri.parse(
        'https://youtube-player.verdant.invalid/workspace-youtube-video/k1_ODDevbY8?start=42',
      ),
    );
    expect(
      autoplayShellUri,
      Uri.parse(
        'https://youtube-player.verdant.invalid/workspace-youtube-video/k1_ODDevbY8?autoplay=1',
      ),
    );
    expect(shellUri.toString(), isNot(contains('verdant.chat')));
    expect(service.isPlayerShellUriForEmbed(shellUri, embed.embedUri), isTrue);
    expect(
      service.isPlayerShellUriForEmbed(resumedShellUri, embed.embedUri),
      isTrue,
    );
    expect(
      service.isPlayerShellUriForEmbed(autoplayShellUri, embed.embedUri),
      isTrue,
    );
    expect(
      service.isPlayerShellUriForEmbed(
        Uri.parse('https://www.youtube.com/watch?v=k1_ODDevbY8'),
        embed.embedUri,
      ),
      isFalse,
    );
  });

  test('youtube embed service rejects invalid ids and player origins', () {
    const service = AnnouncementYouTubeEmbedService();

    expect(
      () => service.fromVideoId('"><script>alert(1)</script>'),
      throwsArgumentError,
    );
    expect(
      service.isAllowedPlayerFrameUri(
        Uri.parse('https://www.youtube-nocookie.com/embed/k1_ODDevbY8'),
      ),
      isTrue,
    );
    expect(
      service.isAllowedPlayerFrameUri(
        Uri.parse('https://www.youtube.com/watch?v=k1_ODDevbY8'),
      ),
      isFalse,
    );
    expect(
      service.isAllowedPlayerFrameUri(
        Uri.parse('https://evil.example/embed/k1_ODDevbY8'),
      ),
      isFalse,
    );
    expect(
      service.isAllowedPlayerFrameUri(
        Uri.parse('file:///C:/Users/Bojji/token.txt'),
      ),
      isFalse,
    );
  });

  test('youtube player shell is escaped and uses strict referrer policy', () {
    const service = AnnouncementYouTubeEmbedService();
    final embed = service.fromVideoId('k1_ODDevbY8');

    final html = service.buildPlayerShellHtml(
      embed.embedUri,
      startSeconds: 12.4,
    );

    expect(html, contains('referrerpolicy="strict-origin-when-cross-origin"'));
    expect(html, contains('Referrer-Policy'));
    expect(
      html,
      contains('sandbox="allow-scripts allow-same-origin allow-presentation"'),
    );
    expect(html, contains('allowfullscreen'));
    expect(
      html,
      contains(
        'https://www.youtube-nocookie.com/embed/k1_ODDevbY8?autoplay=0&amp;enablejsapi=1&amp;origin=https%3A%2F%2Fyoutube-player.verdant.invalid&amp;rel=0&amp;modestbranding=1&amp;playsinline=1&amp;start=12',
      ),
    );
    expect(html, isNot(contains('verdant.chat')));
    expect(
      service.playerShellResponseHeaders['Referrer-Policy'],
      'strict-origin-when-cross-origin',
    );
    expect(
      service.playerShellResponseHeaders['Content-Security-Policy'],
      contains("default-src 'none'"),
    );
    expect(
      service.playerShellResponseHeaders['Content-Security-Policy'],
      contains("script-src 'unsafe-inline' https://www.youtube.com"),
    );
    expect(html, isNot(contains("func: 'playVideo'")));
    expect(html, contains('https://www.youtube.com/iframe_api'));
    expect(html, contains("window.flutter_inappwebview.callHandler"));
    expect(html, contains("'verdantYoutubePlayback'"));
    expect(html, contains('player.seekTo(initialStartSeconds, true)'));
    expect(
      html,
      contains(
        'allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"',
      ),
    );
    expect(html, contains("window.__verdantYouTubeVideoId = 'k1_ODDevbY8'"));
    expect(html, isNot(contains('clipboard-write')));
    expect(html, isNot(contains('allow-popups')));
    expect(html, isNot(contains('allow-top-navigation')));
  });

  test('youtube player shell refuses non-generated iframe urls', () {
    const service = AnnouncementYouTubeEmbedService();

    expect(
      () => service.buildPlayerShellHtml(
        Uri.parse('https://www.youtube.com/watch?v=k1_ODDevbY8'),
      ),
      throwsArgumentError,
    );
  });

  test('youtube player shell never forces audible autoplay', () {
    const service = AnnouncementYouTubeEmbedService();
    final embed = service.fromVideoId('k1_ODDevbY8');

    final html = service.buildPlayerShellHtml(embed.embedUri, autoplay: true);

    expect(html, contains('autoplay=1'));
    expect(html, contains('mute=1'));
    expect(html, contains('player.mute();'));
    expect(html, contains('var shouldAutoplay = true;'));
    expect(html, contains('player.playVideo();'));
    expect(html, isNot(contains('player.unMute();')));
    expect(html, isNot(contains('player.setVolume(100);')));
    expect(html, isNot(contains('audio-request')));
  });
}
