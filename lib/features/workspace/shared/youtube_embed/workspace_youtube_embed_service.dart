import 'dart:convert';

import 'workspace_youtube_url.dart';

const _playerShellOrigin = 'https://youtube-player.verdant.invalid';
const _playerShellHost = 'youtube-player.verdant.invalid';
const _playerShellPathRoot = 'workspace-youtube-video';

final class WorkspaceYouTubeEmbed {
  const WorkspaceYouTubeEmbed({
    required this.videoId,
    required this.watchUri,
    required this.embedUri,
    required this.thumbnailUri,
  });

  final String videoId;
  final Uri watchUri;
  final Uri embedUri;
  final Uri thumbnailUri;
}

final class WorkspaceYouTubeEmbedService {
  const WorkspaceYouTubeEmbedService();

  Uri playerShellUriForEmbed(
    Uri embedUri, {
    double startSeconds = 0,
    bool autoplay = false,
  }) {
    if (!isAllowedPlayerFrameUri(embedUri)) {
      throw ArgumentError.value(
        embedUri,
        'embedUri',
        'YouTube player shell accepts only generated embed URLs',
      );
    }
    final safeStartSeconds = _safeStartSeconds(startSeconds);
    final queryParameters = <String, String>{
      if (safeStartSeconds > 0) 'start': safeStartSeconds.toString(),
      if (autoplay) 'autoplay': '1',
    };
    return Uri.https(
      _playerShellHost,
      '/$_playerShellPathRoot/${embedUri.pathSegments.last}',
      queryParameters.isEmpty ? null : queryParameters,
    );
  }

  bool isPlayerShellUriForEmbed(Uri uri, Uri embedUri) {
    if (!isAllowedPlayerFrameUri(embedUri)) {
      return false;
    }
    return uri.scheme == 'https' &&
        uri.host.toLowerCase() == _playerShellHost &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == _playerShellPathRoot &&
        uri.pathSegments.last == embedUri.pathSegments.last;
  }

  Map<String, String> get playerShellResponseHeaders => const {
    'Cache-Control': 'no-store',
    'Content-Security-Policy':
        "default-src 'none'; script-src 'unsafe-inline' https://www.youtube.com; "
        "style-src 'unsafe-inline'; "
        'frame-src https://www.youtube-nocookie.com '
        "https://youtube-nocookie.com https://www.youtube.com; "
        'child-src https://www.youtube-nocookie.com '
        "https://youtube-nocookie.com https://www.youtube.com; "
        "base-uri 'none'; form-action 'none'; object-src 'none'",
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'X-Content-Type-Options': 'nosniff',
  };

  WorkspaceYouTubeEmbed? fromUrl(String url) {
    final videoId = extractWorkspaceYouTubeVideoId(url);
    if (videoId == null) {
      return null;
    }
    return fromVideoId(videoId);
  }

  WorkspaceYouTubeEmbed fromVideoId(String videoId) {
    if (!workspaceYouTubeVideoIdPattern.hasMatch(videoId)) {
      throw ArgumentError.value(videoId, 'videoId', 'Invalid YouTube video ID');
    }
    return WorkspaceYouTubeEmbed(
      videoId: videoId,
      watchUri: Uri.https('www.youtube.com', '/watch', {'v': videoId}),
      embedUri: Uri.https('www.youtube-nocookie.com', '/embed/$videoId', {
        'autoplay': '0',
        'enablejsapi': '1',
        'origin': _playerShellOrigin,
        'rel': '0',
        'modestbranding': '1',
        'playsinline': '1',
      }),
      thumbnailUri: Uri.https('img.youtube.com', '/vi/$videoId/hqdefault.jpg'),
    );
  }

  String buildPlayerShellHtml(
    Uri embedUri, {
    double startSeconds = 0,
    bool autoplay = false,
  }) {
    if (!isAllowedPlayerFrameUri(embedUri)) {
      throw ArgumentError.value(
        embedUri,
        'embedUri',
        'YouTube player shell accepts only generated embed URLs',
      );
    }
    final safeStartSeconds = _safeStartSeconds(startSeconds);
    final playerEmbedUri = safeStartSeconds > 0 || autoplay
        ? embedUri.replace(
            queryParameters: {
              ...embedUri.queryParameters,
              if (safeStartSeconds > 0) 'start': safeStartSeconds.toString(),
              if (autoplay) 'autoplay': '1',
              if (autoplay) 'mute': '1',
            },
          )
        : embedUri;
    final escapedEmbedUri = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(playerEmbedUri.toString());
    final escapedVideoId = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(embedUri.pathSegments.last);
    final escapedStartSeconds = safeStartSeconds.toString();
    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <meta http-equiv="Referrer-Policy" content="strict-origin-when-cross-origin">
  <style>
    html, body, iframe {
      width: 100%;
      height: 100%;
      margin: 0;
      border: 0;
      background: #000;
      overflow: hidden;
    }
    iframe {
      display: block;
    }
  </style>
</head>
<body>
  <iframe
    id="youtube-player"
    src="$escapedEmbedUri"
    title="YouTube video player"
    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
    sandbox="allow-scripts allow-same-origin allow-presentation"
    referrerpolicy="strict-origin-when-cross-origin"
    allowfullscreen>
  </iframe>
  <script>
    (function () {
      window.__verdantYouTubeVideoId = '$escapedVideoId';
      var initialStartSeconds = $escapedStartSeconds;
      var shouldAutoplay = ${autoplay ? 'true' : 'false'};
      var player = null;
      var pollTimer = null;
      var lastState = -1;

      function safeNumber(value) {
        return typeof value === 'number' && isFinite(value) ? value : 0;
      }

      function currentTime() {
        try {
          return player && typeof player.getCurrentTime === 'function'
            ? safeNumber(player.getCurrentTime())
            : 0;
        } catch (_) {
          return 0;
        }
      }

      function currentVolume() {
        try {
          return player && typeof player.getVolume === 'function'
            ? safeNumber(player.getVolume())
            : null;
        } catch (_) {
          return null;
        }
      }

      function currentMuted() {
        try {
          return player && typeof player.isMuted === 'function'
            ? !!player.isMuted()
            : null;
        } catch (_) {
          return null;
        }
      }

      function post(type) {
        var payload = {
          type: type,
          videoId: window.__verdantYouTubeVideoId,
          state: lastState,
          currentTime: currentTime(),
          muted: currentMuted(),
          volume: currentVolume()
        };
        try {
          if (
            window.flutter_inappwebview &&
            typeof window.flutter_inappwebview.callHandler === 'function'
          ) {
            window.flutter_inappwebview.callHandler(
              'verdantYoutubePlayback',
              payload
            );
          }
        } catch (_) {
          // Telemetry is best-effort. Player controls must keep working.
        }
      }

      function stopPolling() {
        if (pollTimer !== null) {
          clearInterval(pollTimer);
          pollTimer = null;
        }
      }

      function startPolling() {
        if (pollTimer !== null) {
          return;
        }
        pollTimer = setInterval(function () {
          post('time');
        }, 1000);
      }

      function requestAutoplay() {
        try {
          player.mute();
        } catch (_) {
          // Browser policy allows muted autoplay. Audible playback needs a
          // user gesture inside the YouTube player.
        }
        try {
          player.playVideo();
        } catch (_) {
          // The iframe autoplay query is the primary play path.
        }
        setTimeout(function () {
          if (lastState === 1 || lastState === 3) {
            return;
          }
          try {
            player.playVideo();
          } catch (_) {
            // If the embed still refuses playback, the user can press play.
          }
        }, 250);
      }

      window.onYouTubeIframeAPIReady = function () {
        player = new YT.Player('youtube-player', {
          events: {
            onReady: function () {
              if (initialStartSeconds > 0) {
                try {
                  player.seekTo(initialStartSeconds, true);
                } catch (_) {
                  // The iframe start query is the primary resume path.
                }
              }
              if (shouldAutoplay) {
                requestAutoplay();
              }
              post('ready');
            },
            onStateChange: function (event) {
              lastState = event && typeof event.data === 'number'
                ? event.data
                : -1;
              post('state');
              if (lastState === 1 || lastState === 3) {
                startPolling();
              } else {
                post('time');
                stopPolling();
              }
            }
          }
        });
      };

      window.addEventListener('beforeunload', function () {
        post('unload');
        stopPolling();
      });
    })();
  </script>
  <script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>
''';
  }

  bool isAllowedPlayerFrameUri(Uri uri) {
    if (uri.scheme != 'https') {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (host != 'www.youtube-nocookie.com' && host != 'youtube-nocookie.com') {
      return false;
    }
    if (uri.pathSegments.length != 2 || uri.pathSegments.first != 'embed') {
      return false;
    }
    return workspaceYouTubeVideoIdPattern.hasMatch(uri.pathSegments.last);
  }

  bool isAllowedPlayerNavigation(Uri uri) {
    return isAllowedPlayerFrameUri(uri);
  }

  int _safeStartSeconds(double startSeconds) {
    if (!startSeconds.isFinite || startSeconds < 1) {
      return 0;
    }
    if (startSeconds > 60 * 60 * 12) {
      return 60 * 60 * 12;
    }
    return startSeconds.floor();
  }
}
