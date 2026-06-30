import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../theme/verdant_theme.dart';
import '../external_link_warning.dart';
import '../workspace_link_launcher.dart';
import '../workspace_render_diagnostics.dart';
import 'workspace_youtube_embed_service.dart';
import 'workspace_youtube_playback_memory.dart';
import 'workspace_youtube_url.dart';

class WorkspaceYouTubePlayer extends StatelessWidget {
  const WorkspaceYouTubePlayer({
    required this.embedUri,
    required this.watchUri,
    required this.linkLauncher,
    this.embedService = const WorkspaceYouTubeEmbedService(),
    this.initialStartSeconds = 0,
    this.autoplay = false,
    this.keepAlive,
    this.onPlaybackUpdate,
    super.key,
  });

  final Uri embedUri;
  final Uri watchUri;
  final WorkspaceLinkLauncher linkLauncher;
  final WorkspaceYouTubeEmbedService embedService;
  final double initialStartSeconds;
  final bool autoplay;
  final InAppWebViewKeepAlive? keepAlive;
  final ValueChanged<WorkspaceYouTubePlaybackUpdate>? onPlaybackUpdate;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final mountStopwatch = Stopwatch()..start();
    final playerShellUri = embedService.playerShellUriForEmbed(
      embedUri,
      startSeconds: initialStartSeconds,
      autoplay: autoplay,
    );
    _logYouTubePlayer('build', embedUri, {
      'shellHost': playerShellUri.host.toLowerCase(),
      'keepAlive': keepAlive != null,
    });
    return DecoratedBox(
      key: const ValueKey('workspace-youtube-player-frame'),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: InAppWebView(
          key: const ValueKey('workspace-youtube-player-webview'),
          keepAlive: keepAlive,
          initialUrlRequest: URLRequest(url: WebUri(playerShellUri.toString())),
          initialSettings: InAppWebViewSettings(
            allowContentAccess: false,
            allowFileAccess: false,
            allowFileAccessFromFileURLs: false,
            allowUniversalAccessFromFileURLs: false,
            cacheEnabled: false,
            databaseEnabled: false,
            disableContextMenu: true,
            geolocationEnabled: false,
            incognito: true,
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            safeBrowsingEnabled: true,
            sharedCookiesEnabled: false,
            supportMultipleWindows: false,
            supportZoom: false,
            thirdPartyCookiesEnabled: false,
            transparentBackground: false,
            useShouldInterceptRequest: true,
            useOnDownloadStart: true,
            useShouldOverrideUrlLoading: true,
            javaScriptCanOpenWindowsAutomatically: false,
            isInspectable: false,
          ),
          onWebViewCreated: (controller) {
            _logYouTubePlayer('created', embedUri, {
              'mountMs': mountStopwatch.elapsedMilliseconds,
              'keepAlive': keepAlive != null,
            });
            controller.addJavaScriptHandler(
              handlerName: 'verdantYoutubePlayback',
              callback: (args) {
                final update = _playbackUpdateFromJavaScript(
                  embedUri,
                  args.isEmpty ? null : args.first,
                );
                if (update == null) {
                  _logYouTubePlayer('playbackUpdateRejected', embedUri, {
                    'argumentCount': args.length,
                  });
                  return null;
                }
                _logYouTubePlayer('playbackUpdate', embedUri, {
                  'state': update.state,
                  'positionSeconds': update.positionSeconds.round(),
                  'hasStarted': update.hasStarted,
                  'isPlaying': update.isPlaying,
                  if (update.isMuted != null) 'isMuted': update.isMuted,
                  if (update.volume != null) 'volume': update.volume!.round(),
                });
                onPlaybackUpdate?.call(update);
                return null;
              },
            );
          },
          onLoadStart: (controller, url) {
            _logYouTubePlayer('loadStart', embedUri, {
              ..._uriDiagnosticFields(url),
              'mountMs': mountStopwatch.elapsedMilliseconds,
            });
          },
          onLoadStop: (controller, url) {
            _logYouTubePlayer('loadStop', embedUri, {
              ..._uriDiagnosticFields(url),
              'mountMs': mountStopwatch.elapsedMilliseconds,
            });
          },
          onProgressChanged: (controller, progress) {
            _logYouTubePlayer('progress', embedUri, {
              'progress': progress,
              'mountMs': mountStopwatch.elapsedMilliseconds,
            });
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            _logYouTubePlayer('history', embedUri, {
              ..._uriDiagnosticFields(url),
              'isReload': isReload,
            });
          },
          onReceivedError: (controller, request, error) {
            _logYouTubePlayer('receivedError', embedUri, {
              ..._webResourceRequestFields(request),
              'errorType': error.type.toString(),
              'descriptionLength': error.description.length,
            });
          },
          onReceivedHttpError: (controller, request, errorResponse) {
            _logYouTubePlayer('receivedHttpError', embedUri, {
              ..._webResourceRequestFields(request),
              'statusCode': errorResponse.statusCode,
              'contentType': errorResponse.contentType,
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            _logYouTubePlayer('console', embedUri, {
              'level': consoleMessage.messageLevel.toString(),
              'messageLength': consoleMessage.message.length,
            });
          },
          onCreateWindow: (controller, createWindowAction) async {
            _logYouTubePlayer('createWindow', embedUri, {
              ..._navigationActionFields(createWindowAction),
              'action': 'openExternalWithWarning',
            });
            await openExternalLinkWithWarning(
              context: context,
              uri: watchUri,
              linkLauncher: linkLauncher,
            );
            return false;
          },
          onDownloadStartRequest: (controller, downloadStartRequest) {
            _logYouTubePlayer('downloadBlocked', embedUri, {
              ..._uriDiagnosticFields(downloadStartRequest.url),
            });
          },
          onPermissionRequest: (controller, permissionRequest) async {
            _logYouTubePlayer('permissionDenied', embedUri, {
              'resourceCount': permissionRequest.resources.length,
            });
            return PermissionResponse(
              action: PermissionResponseAction.DENY,
              resources: const [],
            );
          },
          shouldInterceptRequest: (controller, request) async {
            final requestedUri = Uri.tryParse(request.url.toString());
            if (requestedUri == null ||
                !embedService.isPlayerShellUriForEmbed(
                  requestedUri,
                  embedUri,
                )) {
              if (request.isForMainFrame == true) {
                _logYouTubePlayer('interceptPassThrough', embedUri, {
                  ..._webResourceRequestFields(request),
                });
              }
              return null;
            }
            _logYouTubePlayer('servePlayerShell', embedUri, {
              ..._webResourceRequestFields(request),
            });
            final html = embedService.buildPlayerShellHtml(
              embedUri,
              startSeconds: _startSecondsFromPlayerShellUri(requestedUri),
              autoplay: requestedUri.queryParameters['autoplay'] == '1',
            );
            return WebResourceResponse(
              contentType: 'text/html',
              contentEncoding: 'utf-8',
              data: Uint8List.fromList(utf8.encode(html)),
              headers: embedService.playerShellResponseHeaders,
              statusCode: 200,
              reasonPhrase: 'OK',
            );
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            _logYouTubePlayer('navigationDecision', embedUri, {
              ..._navigationActionFields(navigationAction),
            });
            if (!navigationAction.isForMainFrame) {
              _logYouTubePlayer('navigationAllowed', embedUri, {
                ..._navigationActionFields(navigationAction),
                'reason': 'subframe',
              });
              return NavigationActionPolicy.ALLOW;
            }
            final requestedUrl = navigationAction.request.url?.toString();
            final requestedUri = requestedUrl == null
                ? null
                : Uri.tryParse(requestedUrl);
            if (requestedUri != null &&
                embedService.isPlayerShellUriForEmbed(requestedUri, embedUri)) {
              _logYouTubePlayer('navigationAllowed', embedUri, {
                ..._navigationActionFields(navigationAction),
                'reason': 'playerShell',
              });
              return NavigationActionPolicy.ALLOW;
            }
            _logYouTubePlayer('navigationCanceledExternal', embedUri, {
              ..._navigationActionFields(navigationAction),
            });
            await openExternalLinkWithWarning(
              context: context,
              uri: watchUri,
              linkLauncher: linkLauncher,
            );
            return NavigationActionPolicy.CANCEL;
          },
        ),
      ),
    );
  }
}

WorkspaceYouTubePlaybackUpdate? _playbackUpdateFromJavaScript(
  Uri embedUri,
  Object? payload,
) {
  if (payload is! Map) {
    return null;
  }
  final expectedVideoId = _videoIdForDiagnostic(embedUri);
  if (payload['videoId'] != expectedVideoId) {
    return null;
  }
  final currentTime = payload['currentTime'];
  final state = payload['state'];
  if (currentTime is! num || state is! num) {
    return null;
  }
  final stateValue = state.toInt();
  final positionSeconds = currentTime.toDouble();
  final muted = payload['muted'];
  final volume = payload['volume'];
  final volumeSeconds = volume is num ? volume.toDouble() : null;
  return WorkspaceYouTubePlaybackUpdate(
    videoId: expectedVideoId,
    positionSeconds: positionSeconds.isFinite && positionSeconds >= 0
        ? positionSeconds
        : 0,
    state: stateValue,
    hasStarted:
        stateValue == 1 ||
        stateValue == 2 ||
        stateValue == 3 ||
        stateValue == 0,
    isPlaying: stateValue == 1 || stateValue == 3,
    isMuted: muted is bool ? muted : null,
    volume: volumeSeconds != null && volumeSeconds.isFinite
        ? volumeSeconds.clamp(0, 100).toDouble()
        : null,
  );
}

double _startSecondsFromPlayerShellUri(Uri uri) {
  final raw = uri.queryParameters['start'];
  if (raw == null) {
    return 0;
  }
  final parsed = double.tryParse(raw);
  if (parsed == null || !parsed.isFinite || parsed < 0) {
    return 0;
  }
  return parsed;
}

void _logYouTubePlayer(
  String event,
  Uri embedUri, [
  Map<String, Object?> fields = const {},
]) {
  logWorkspaceRender('youtube.player.$event', {
    'videoId': _videoIdForDiagnostic(embedUri),
    'embedHost': embedUri.host.toLowerCase(),
    ...fields,
  });
}

Map<String, Object?> _navigationActionFields(NavigationAction action) {
  return {
    ..._uriDiagnosticFields(action.request.url),
    'isForMainFrame': action.isForMainFrame,
    'hasGesture': action.hasGesture,
    'isRedirect': action.isRedirect,
    'navigationType': action.navigationType?.toString(),
    'method': action.request.method,
  };
}

Map<String, Object?> _webResourceRequestFields(WebResourceRequest request) {
  return {
    ..._uriDiagnosticFields(request.url),
    'isForMainFrame': request.isForMainFrame,
    'hasGesture': request.hasGesture,
    'isRedirect': request.isRedirect,
    'method': request.method,
  };
}

Map<String, Object?> _uriDiagnosticFields(Object? value) {
  final raw = value?.toString();
  final uri = raw == null ? null : Uri.tryParse(raw);
  if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
    return {'urlAccepted': false};
  }
  return {
    'urlAccepted': true,
    'origin': _originForDiagnostic(uri),
    'pathRoot': _pathRootForDiagnostic(uri),
    'videoId': _videoIdForDiagnostic(uri),
    'queryKeys': _queryKeysForDiagnostic(uri),
  };
}

String _originForDiagnostic(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://$host$port';
}

String _pathRootForDiagnostic(Uri uri) {
  for (final segment in uri.pathSegments) {
    if (segment.isNotEmpty) {
      return segment.toLowerCase();
    }
  }
  return 'none';
}

String _videoIdForDiagnostic(Uri uri) {
  if (uri.pathSegments.length == 2 &&
      (uri.pathSegments.first == 'embed' ||
          uri.pathSegments.first == 'workspace-youtube-video')) {
    return uri.pathSegments.last;
  }
  final v = uri.queryParameters['v'];
  if (v != null && workspaceYouTubeVideoIdPattern.hasMatch(v)) {
    return v;
  }
  return 'none';
}

String _queryKeysForDiagnostic(Uri uri) {
  if (uri.queryParameters.isEmpty) {
    return 'none';
  }
  final keys =
      uri.queryParameters.keys
          .map((key) => key.toLowerCase())
          .where((key) => key.isNotEmpty)
          .toList(growable: false)
        ..sort();
  return keys.take(8).join(',');
}
