import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/window_focus_scope.dart';
import '../../../theme/verdant_theme.dart';
import '../shared/external_link_warning.dart';
import '../shared/workspace_link_launcher.dart';
import '../shared/youtube_embed/workspace_youtube_embed_service.dart';
import '../shared/youtube_embed/workspace_youtube_playback_memory.dart';
import '../shared/youtube_embed/workspace_youtube_preview.dart';
import 'link_preview_service.dart';

const _maxMessageLinkPreviews = 3;
const _legacyPreviewCacheScope = 'legacy';
final _messageLinkPreviewAutoLoadGate = _MessageLinkPreviewAutoLoadGate();

final _messageUrlPattern = RegExp(
  r'''https://[^\s<>"{}|\\^`\[\]]+''',
  caseSensitive: false,
);

enum MessageLinkPreviewKind { generic, youtube }

final class MessageLinkPreviewData {
  const MessageLinkPreviewData({
    required this.kind,
    required this.uri,
    this.youtubeEmbed,
  });

  final MessageLinkPreviewKind kind;
  final Uri uri;
  final WorkspaceYouTubeEmbed? youtubeEmbed;

  String get hostLabel => uri.host.toLowerCase();
}

@visibleForTesting
void debugResetMessageLinkPreviewAutoLoadGate() {
  _messageLinkPreviewAutoLoadGate.debugReset();
}

@visibleForTesting
void debugConfigureMessageLinkPreviewAutoLoadGate({
  DateTime Function()? clock,
  Duration? cacheTtl,
}) {
  _messageLinkPreviewAutoLoadGate.debugConfigure(
    clock: clock,
    cacheTtl: cacheTtl,
  );
}

List<MessageLinkPreviewData> extractMessageLinkPreviews(String body) {
  final previews = <MessageLinkPreviewData>[];
  final seen = <String>{};
  const youtubeService = WorkspaceYouTubeEmbedService();

  for (final match in _messageUrlPattern.allMatches(body)) {
    if (previews.length >= _maxMessageLinkPreviews) {
      break;
    }
    final raw = _trimUrlToken(match.group(0) ?? '');
    final uri = _safePreviewUri(raw);
    if (uri == null) {
      continue;
    }
    final normalized = uri.toString();
    if (!seen.add(normalized)) {
      continue;
    }
    final youtubeEmbed = youtubeService.fromUrl(normalized);
    previews.add(
      MessageLinkPreviewData(
        kind: youtubeEmbed == null
            ? MessageLinkPreviewKind.generic
            : MessageLinkPreviewKind.youtube,
        uri: uri,
        youtubeEmbed: youtubeEmbed,
      ),
    );
  }

  return previews;
}

String removePreviewedLinksFromMessageBody(
  String body,
  List<MessageLinkPreviewData> previews,
) {
  if (body.isEmpty || previews.isEmpty) {
    return body.trim();
  }
  final previewUrls = {for (final preview in previews) preview.uri.toString()};
  final buffer = StringBuffer();
  var cursor = 0;
  for (final match in _messageUrlPattern.allMatches(body)) {
    final raw = _trimUrlToken(match.group(0) ?? '');
    final uri = _safePreviewUri(raw);
    if (uri == null || !previewUrls.contains(uri.toString())) {
      continue;
    }
    buffer.write(body.substring(cursor, match.start));
    cursor = match.end;
  }
  buffer.write(body.substring(cursor));
  return _normalizeBodyAfterLinkRemoval(buffer.toString());
}

class MessageLinkPreviews extends StatelessWidget {
  const MessageLinkPreviews({
    required this.messageId,
    required this.previews,
    this.cacheScope = _legacyPreviewCacheScope,
    this.linkPreviewService,
    this.youtubePlayerBuilder,
    this.youtubePlaybackMemory,
    this.onYoutubePlaybackChanged,
    this.onLayoutSettled,
    this.linkLauncher = const WorkspaceLinkLauncher(),
    super.key,
  });

  final String messageId;
  final List<MessageLinkPreviewData> previews;
  final String cacheScope;
  final MessageLinkPreviewService? linkPreviewService;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onYoutubePlaybackChanged;
  final VoidCallback? onLayoutSettled;
  final WorkspaceLinkLauncher linkLauncher;

  @override
  Widget build(BuildContext context) {
    if (previews.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      key: ValueKey('message-link-preview-list-$messageId'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < previews.length; index += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == previews.length - 1 ? 0 : 8,
            ),
            child: _MessageLinkPreviewCard(
              key: ValueKey('message-link-preview-card-$messageId-$index'),
              messageId: messageId,
              index: index,
              preview: previews[index],
              cacheScope: cacheScope,
              linkLauncher: linkLauncher,
              linkPreviewService: linkPreviewService,
              youtubePlayerBuilder: youtubePlayerBuilder,
              youtubePlaybackMemory: youtubePlaybackMemory,
              onYoutubePlaybackChanged: onYoutubePlaybackChanged,
              onLayoutSettled: onLayoutSettled,
            ),
          ),
      ],
    );
  }
}

class _MessageLinkPreviewCard extends StatelessWidget {
  const _MessageLinkPreviewCard({
    required this.messageId,
    required this.index,
    required this.preview,
    required this.cacheScope,
    required this.linkLauncher,
    required this.linkPreviewService,
    required this.youtubePlayerBuilder,
    required this.youtubePlaybackMemory,
    required this.onYoutubePlaybackChanged,
    required this.onLayoutSettled,
    super.key,
  });

  final String messageId;
  final int index;
  final MessageLinkPreviewData preview;
  final String cacheScope;
  final WorkspaceLinkLauncher linkLauncher;
  final MessageLinkPreviewService? linkPreviewService;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onYoutubePlaybackChanged;
  final VoidCallback? onLayoutSettled;

  @override
  Widget build(BuildContext context) {
    final youtubeEmbed = preview.youtubeEmbed;
    if (youtubeEmbed != null) {
      return _MessageYouTubePreview(
        key: ValueKey('message-link-preview-youtube-$messageId-$index'),
        embed: youtubeEmbed,
        messageId: messageId,
        index: index,
        linkLauncher: linkLauncher,
        youtubePlayerBuilder: youtubePlayerBuilder,
        youtubePlaybackMemory: youtubePlaybackMemory,
        onYoutubePlaybackChanged: onYoutubePlaybackChanged,
      );
    }
    return _MessageGenericLinkPreview(
      key: ValueKey('message-link-preview-generic-$messageId-$index'),
      preview: preview,
      cacheScope: cacheScope,
      linkLauncher: linkLauncher,
      linkPreviewService: linkPreviewService,
      onLayoutSettled: onLayoutSettled,
    );
  }
}

class _MessageGenericLinkPreview extends StatefulWidget {
  const _MessageGenericLinkPreview({
    required this.preview,
    required this.cacheScope,
    required this.linkLauncher,
    required this.linkPreviewService,
    required this.onLayoutSettled,
    super.key,
  });

  final MessageLinkPreviewData preview;
  final String cacheScope;
  final WorkspaceLinkLauncher linkLauncher;
  final MessageLinkPreviewService? linkPreviewService;
  final VoidCallback? onLayoutSettled;

  @override
  State<_MessageGenericLinkPreview> createState() =>
      _MessageGenericLinkPreviewState();
}

class _MessageGenericLinkPreviewState
    extends State<_MessageGenericLinkPreview> {
  var _hovered = false;
  var _loading = false;
  var _loadFailed = false;
  MessageLinkPreviewMetadata? _metadata;
  Uint8List? _imageBytes;
  Uri? _loadedUri;
  _MessageLinkPreviewAutoLoadTicket? _autoLoadTicket;
  bool? _automaticLoadsVisible;

  @override
  void initState() {
    super.initState();
    _notifyLayoutSettled();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible =
        TickerMode.valuesOf(context).enabled &&
        WindowFocusScope.isFocusedOf(context);
    if (_automaticLoadsVisible == visible) {
      if (visible) {
        _startPreviewLoad();
      }
      return;
    }
    _automaticLoadsVisible = visible;
    if (visible) {
      _startPreviewLoad();
    } else {
      _cancelAutomaticLoads(resetLoading: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MessageGenericLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preview.uri != widget.preview.uri ||
        oldWidget.cacheScope != widget.cacheScope ||
        !identical(oldWidget.linkPreviewService, widget.linkPreviewService)) {
      _cancelAutomaticLoads();
      _metadata = null;
      _imageBytes = null;
      _loadedUri = null;
      _loading = false;
      _loadFailed = false;
      _notifyLayoutSettled();
      _startPreviewLoad();
    }
  }

  @override
  void dispose() {
    _cancelAutomaticLoads();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final metadata = _metadata;
    final title = metadata?.title.trim();
    final description = metadata?.description?.trim();
    final siteName = metadata?.siteName?.trim();
    final imageBytes = _imageBytes;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Semantics(
            button: true,
            label: 'Open external link to ${widget.preview.hostLabel}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                unawaited(
                  openExternalLinkWithWarning(
                    context: context,
                    uri: widget.preview.uri,
                    linkLauncher: widget.linkLauncher,
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hovered
                      ? colors.panelHover.withValues(alpha: 0.74)
                      : colors.panel.withValues(alpha: 0.74),
                  border: Border.all(
                    color: _hovered
                        ? colors.accentStrong.withValues(alpha: 0.58)
                        : colors.border,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: imageBytes == null ? 38 : 92,
                        height: imageBytes == null ? 38 : 58,
                        child: imageBytes == null
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: _hovered
                                        ? colors.accentStrong.withValues(
                                            alpha: 0.56,
                                          )
                                        : colors.border,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _loading
                                      ? PhosphorIcons.circleNotch
                                      : PhosphorIcons.linkSimpleHorizontal,
                                  size: 18,
                                  color: colors.accentStrong,
                                ),
                              )
                            : Image.memory(
                                imageBytes,
                                key: ValueKey(
                                  'message-link-preview-image-${widget.preview.uri}',
                                ),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                              ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title?.isNotEmpty == true
                                ? title!
                                : widget.preview.hostLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: VerdantFontWeights.black,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            description?.isNotEmpty == true
                                ? description!
                                : _fallbackDescription(),
                            maxLines: description?.isNotEmpty == true ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                          if (siteName?.isNotEmpty == true) ...[
                            const SizedBox(height: 5),
                            Text(
                              siteName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.accentStrong),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadMetadata({
    bool automatic = false,
    _MessageLinkPreviewAutoLoadTicket? ticket,
  }) async {
    if (_loading || _metadata != null) {
      return;
    }
    if (automatic && ticket?.isCanceled == true) {
      return;
    }
    final service = widget.linkPreviewService;
    if (service == null) {
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final uri = widget.preview.uri;
    _loadedUri = uri;
    final metadata = await _loadPreviewMetadata(
      uri: uri,
      cacheScope: widget.cacheScope,
      service: service,
      automatic: automatic,
      ticket: ticket,
    );
    if (!mounted ||
        _loadedUri != uri ||
        metadata == null ||
        ticket?.isCanceled == true) {
      if (mounted && _loadedUri == uri && ticket?.isCanceled != true) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
        _notifyLayoutSettled();
      }
      return;
    }
    setState(() {
      _metadata = metadata;
      _loading = false;
    });
    _notifyLayoutSettled();
    final imageProxyUrl = metadata.imageProxyUrl;
    if (imageProxyUrl == null || imageProxyUrl.isEmpty) {
      return;
    }
    if (ticket?.isCanceled == true) {
      return;
    }
    final imageBytes = await _loadPreviewImageBytes(
      imageProxyUrl: imageProxyUrl,
      cacheScope: widget.cacheScope,
      service: service,
      automatic: automatic,
      ticket: ticket,
    );
    if (!mounted ||
        _loadedUri != uri ||
        imageBytes == null ||
        ticket?.isCanceled == true) {
      return;
    }
    setState(() => _imageBytes = imageBytes);
    _notifyLayoutSettled();
  }

  void _startPreviewLoad() {
    if (_automaticLoadsVisible != true ||
        widget.linkPreviewService == null ||
        _autoLoadTicket != null ||
        _loading ||
        _metadata != null ||
        _loadFailed) {
      return;
    }
    final ticket = _MessageLinkPreviewAutoLoadTicket();
    _autoLoadTicket = ticket;
    unawaited(_loadMetadata(automatic: true, ticket: ticket));
  }

  void _cancelAutomaticLoads({bool resetLoading = false}) {
    _autoLoadTicket?.cancel();
    _autoLoadTicket = null;
    if (!resetLoading) {
      return;
    }
    _loading = false;
    _loadedUri = null;
    _notifyLayoutSettled();
  }

  String _fallbackDescription() {
    if (_loading) {
      return 'Loading preview...';
    }
    if (_loadFailed) {
      return widget.preview.uri.toString();
    }
    return widget.preview.uri.toString();
  }

  void _notifyLayoutSettled() {
    final callback = widget.onLayoutSettled;
    if (callback == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback();
      }
    });
  }
}

class _MessageYouTubePreview extends StatefulWidget {
  const _MessageYouTubePreview({
    required this.embed,
    required this.messageId,
    required this.index,
    required this.linkLauncher,
    required this.youtubePlayerBuilder,
    required this.youtubePlaybackMemory,
    required this.onYoutubePlaybackChanged,
    super.key,
  });

  final WorkspaceYouTubeEmbed embed;
  final String messageId;
  final int index;
  final WorkspaceLinkLauncher linkLauncher;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onYoutubePlaybackChanged;

  @override
  State<_MessageYouTubePreview> createState() => _MessageYouTubePreviewState();
}

class _MessageYouTubePreviewState extends State<_MessageYouTubePreview> {
  @override
  Widget build(BuildContext context) {
    return WorkspaceYouTubePreview(
      key: ValueKey(
        'message-link-preview-youtube-player-${widget.messageId}-${widget.index}',
      ),
      url: widget.embed.watchUri.toString(),
      title: 'YouTube video',
      linkLauncher: widget.linkLauncher,
      youtubePlayerBuilder: widget.youtubePlayerBuilder,
      playbackMemory: widget.youtubePlaybackMemory,
      onPlaybackSnapshotChanged: widget.onYoutubePlaybackChanged,
      maxWidth: 520,
      headerIcon: PhosphorIcons.youtubeLogo,
      previewKeyPrefix:
          'message-link-preview-youtube-${widget.messageId}-${widget.index}',
    );
  }
}

Future<MessageLinkPreviewMetadata?> _loadPreviewMetadata({
  required Uri uri,
  required String cacheScope,
  required MessageLinkPreviewService service,
  required bool automatic,
  required _MessageLinkPreviewAutoLoadTicket? ticket,
}) async {
  try {
    if (!automatic) {
      return await service.loadPreview(uri);
    }
    if (ticket == null || ticket.isCanceled) {
      return null;
    }
    return await _messageLinkPreviewAutoLoadGate.load(
      cacheScope,
      uri,
      service.loadPreview,
      ticket,
    );
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _loadPreviewImageBytes({
  required String imageProxyUrl,
  required String cacheScope,
  required MessageLinkPreviewService service,
  required bool automatic,
  required _MessageLinkPreviewAutoLoadTicket? ticket,
}) async {
  try {
    if (!automatic) {
      return await service.loadPreviewImage(imageProxyUrl);
    }
    if (ticket == null || ticket.isCanceled) {
      return null;
    }
    return await _messageLinkPreviewAutoLoadGate.loadImage(
      cacheScope,
      imageProxyUrl,
      service.loadPreviewImage,
      ticket,
    );
  } catch (_) {
    return null;
  }
}

typedef _MessageLinkPreviewLoader =
    Future<MessageLinkPreviewMetadata?> Function(Uri uri);
typedef _MessageLinkPreviewImageLoader =
    Future<Uint8List?> Function(String imageProxyUrl);

final class _MessageLinkPreviewAutoLoadGate {
  _MessageLinkPreviewAutoLoadGate();

  static const _defaultCacheTtl = Duration(minutes: 3);
  static const _maxConcurrent = 2;
  static const _maxPerHost = 1;
  static const _maxQueued = 48;
  static const _maxQueuedImages = 64;
  static const _maxMetadataCacheEntries = 128;
  static const _maxImageCacheEntries = 64;
  static const _maxImageCacheBytes = 8 * 1024 * 1024;
  DateTime Function() _clock = DateTime.now;
  Duration _cacheTtl = _defaultCacheTtl;
  final _queue = Queue<_QueuedMessageLinkPreviewLoad>();
  final _imageQueue = Queue<_QueuedMessageLinkPreviewImageLoad>();
  final _inFlightByUrl = <String, Future<MessageLinkPreviewMetadata?>>{};
  final _cacheByUrl = <String, _CachedMessagePreviewMetadata>{};
  final _inFlightImageByUrl = <String, Future<Uint8List?>>{};
  final _cacheImageByUrl = <String, _CachedMessagePreviewImage>{};
  final _activeByHost = <String, int>{};
  var _active = 0;
  var _activeImages = 0;
  var _cachedImageBytes = 0;

  Future<MessageLinkPreviewMetadata?> load(
    String cacheScope,
    Uri uri,
    _MessageLinkPreviewLoader loader,
    _MessageLinkPreviewAutoLoadTicket ticket,
  ) {
    _pruneCanceledMetadataQueue();
    if (ticket.isCanceled) {
      return Future<MessageLinkPreviewMetadata?>.value();
    }
    final key = _scopedCacheKey(cacheScope, uri.toString());
    final cached = _takeCachedMetadata(key);
    if (cached != null) {
      return Future<MessageLinkPreviewMetadata?>.value(cached);
    }
    final existing = _inFlightByUrl[key];
    if (existing != null) {
      return existing;
    }
    if (_queue.length >= _maxQueued) {
      return Future<MessageLinkPreviewMetadata?>.value();
    }

    final completer = Completer<MessageLinkPreviewMetadata?>();
    _inFlightByUrl[key] = completer.future;
    _queue.add(
      _QueuedMessageLinkPreviewLoad(
        key: key,
        uri: uri,
        loader: loader,
        ticket: ticket,
        completer: completer,
      ),
    );
    _drain();
    return completer.future;
  }

  Future<Uint8List?> loadImage(
    String cacheScope,
    String imageProxyUrl,
    _MessageLinkPreviewImageLoader loader,
    _MessageLinkPreviewAutoLoadTicket ticket,
  ) {
    _pruneCanceledImageQueue();
    if (ticket.isCanceled) {
      return Future<Uint8List?>.value();
    }
    final key = _scopedCacheKey(cacheScope, imageProxyUrl);
    final cached = _takeCachedImage(key);
    if (cached != null) {
      return Future<Uint8List?>.value(cached);
    }
    final existing = _inFlightImageByUrl[key];
    if (existing != null) {
      return existing;
    }
    if (_imageQueue.length >= _maxQueuedImages) {
      return Future<Uint8List?>.value();
    }

    final completer = Completer<Uint8List?>();
    _inFlightImageByUrl[key] = completer.future;
    _imageQueue.add(
      _QueuedMessageLinkPreviewImageLoad(
        key: key,
        imageProxyUrl: imageProxyUrl,
        loader: loader,
        ticket: ticket,
        completer: completer,
      ),
    );
    _drainImages();
    return completer.future;
  }

  @visibleForTesting
  void debugReset() {
    _queue.clear();
    _imageQueue.clear();
    _inFlightByUrl.clear();
    _cacheByUrl.clear();
    _inFlightImageByUrl.clear();
    _cacheImageByUrl.clear();
    _activeByHost.clear();
    _active = 0;
    _activeImages = 0;
    _cachedImageBytes = 0;
    _clock = DateTime.now;
    _cacheTtl = _defaultCacheTtl;
  }

  @visibleForTesting
  void debugConfigure({DateTime Function()? clock, Duration? cacheTtl}) {
    _clock = clock ?? DateTime.now;
    _cacheTtl = cacheTtl ?? _defaultCacheTtl;
  }

  void _drain() {
    _pruneCanceledMetadataQueue();
    while (_active < _maxConcurrent) {
      final task = _takeNextRunnable();
      if (task == null) {
        return;
      }
      _run(task);
    }
  }

  _QueuedMessageLinkPreviewLoad? _takeNextRunnable() {
    for (var index = 0; index < _queue.length; index += 1) {
      final task = _queue.elementAt(index);
      if (task.ticket.isCanceled) {
        _queue.remove(task);
        _inFlightByUrl.remove(task.key);
        if (!task.completer.isCompleted) {
          task.completer.complete(null);
        }
        index -= 1;
        continue;
      }
      if ((_activeByHost[task.host] ?? 0) >= _maxPerHost) {
        continue;
      }
      _queue.remove(task);
      return task;
    }
    return null;
  }

  void _run(_QueuedMessageLinkPreviewLoad task) {
    if (task.ticket.isCanceled) {
      _inFlightByUrl.remove(task.key);
      if (!task.completer.isCompleted) {
        task.completer.complete(null);
      }
      _drain();
      return;
    }
    _active += 1;
    _activeByHost.update(task.host, (count) => count + 1, ifAbsent: () => 1);
    unawaited(
      task
          .loader(task.uri)
          .then(
            (metadata) {
              _rememberMetadata(task.key, metadata);
              if (!task.completer.isCompleted) {
                task.completer.complete(metadata);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!task.completer.isCompleted) {
                task.completer.completeError(error, stackTrace);
              }
            },
          )
          .whenComplete(() {
            _active -= 1;
            final hostCount = (_activeByHost[task.host] ?? 1) - 1;
            if (hostCount <= 0) {
              _activeByHost.remove(task.host);
            } else {
              _activeByHost[task.host] = hostCount;
            }
            _inFlightByUrl.remove(task.key);
            _drain();
          }),
    );
  }

  void _drainImages() {
    _pruneCanceledImageQueue();
    while (_activeImages < _maxConcurrent && _imageQueue.isNotEmpty) {
      _runImage(_imageQueue.removeFirst());
    }
  }

  void _runImage(_QueuedMessageLinkPreviewImageLoad task) {
    if (task.ticket.isCanceled) {
      _inFlightImageByUrl.remove(task.key);
      if (!task.completer.isCompleted) {
        task.completer.complete(null);
      }
      _drainImages();
      return;
    }
    _activeImages += 1;
    unawaited(
      task
          .loader(task.imageProxyUrl)
          .then(
            (imageBytes) {
              _rememberImage(task.key, imageBytes);
              if (!task.completer.isCompleted) {
                task.completer.complete(imageBytes);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!task.completer.isCompleted) {
                task.completer.completeError(error, stackTrace);
              }
            },
          )
          .whenComplete(() {
            _activeImages -= 1;
            _inFlightImageByUrl.remove(task.key);
            _drainImages();
          }),
    );
  }

  MessageLinkPreviewMetadata? _takeCachedMetadata(String key) {
    final cached = _cacheByUrl.remove(key);
    if (cached == null) {
      return null;
    }
    if (_isExpired(cached.cachedAt)) {
      return null;
    }
    _cacheByUrl[key] = cached;
    return cached.metadata;
  }

  void _rememberMetadata(String key, MessageLinkPreviewMetadata? metadata) {
    if (metadata == null) {
      return;
    }
    _cacheByUrl.remove(key);
    _cacheByUrl[key] = _CachedMessagePreviewMetadata(
      metadata: metadata,
      cachedAt: _clock(),
    );
    while (_cacheByUrl.length > _maxMetadataCacheEntries) {
      _cacheByUrl.remove(_cacheByUrl.keys.first);
    }
  }

  Uint8List? _takeCachedImage(String key) {
    final cached = _cacheImageByUrl.remove(key);
    if (cached == null) {
      return null;
    }
    if (_isExpired(cached.cachedAt)) {
      _cachedImageBytes -= cached.bytes.lengthInBytes;
      return null;
    }
    _cacheImageByUrl[key] = cached;
    return cached.bytes;
  }

  void _rememberImage(String key, Uint8List? imageBytes) {
    if (imageBytes == null || imageBytes.lengthInBytes > _maxImageCacheBytes) {
      return;
    }
    final existing = _cacheImageByUrl.remove(key);
    if (existing != null) {
      _cachedImageBytes -= existing.bytes.lengthInBytes;
    }
    _cacheImageByUrl[key] = _CachedMessagePreviewImage(
      bytes: imageBytes,
      cachedAt: _clock(),
    );
    _cachedImageBytes += imageBytes.lengthInBytes;
    while (_cacheImageByUrl.length > _maxImageCacheEntries ||
        _cachedImageBytes > _maxImageCacheBytes) {
      final removed = _cacheImageByUrl.remove(_cacheImageByUrl.keys.first);
      if (removed == null) {
        break;
      }
      _cachedImageBytes -= removed.bytes.lengthInBytes;
    }
  }

  bool _isExpired(DateTime cachedAt) {
    return _clock().difference(cachedAt) > _cacheTtl;
  }

  void _pruneCanceledMetadataQueue() {
    if (_queue.isEmpty) {
      return;
    }
    final retained = Queue<_QueuedMessageLinkPreviewLoad>();
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (task.ticket.isCanceled) {
        _inFlightByUrl.remove(task.key);
        if (!task.completer.isCompleted) {
          task.completer.complete(null);
        }
      } else {
        retained.add(task);
      }
    }
    _queue.addAll(retained);
  }

  void _pruneCanceledImageQueue() {
    if (_imageQueue.isEmpty) {
      return;
    }
    final retained = Queue<_QueuedMessageLinkPreviewImageLoad>();
    while (_imageQueue.isNotEmpty) {
      final task = _imageQueue.removeFirst();
      if (task.ticket.isCanceled) {
        _inFlightImageByUrl.remove(task.key);
        if (!task.completer.isCompleted) {
          task.completer.complete(null);
        }
      } else {
        retained.add(task);
      }
    }
    _imageQueue.addAll(retained);
  }
}

final class _QueuedMessageLinkPreviewLoad {
  const _QueuedMessageLinkPreviewLoad({
    required this.key,
    required this.uri,
    required this.loader,
    required this.ticket,
    required this.completer,
  });

  final String key;
  final Uri uri;
  final _MessageLinkPreviewLoader loader;
  final _MessageLinkPreviewAutoLoadTicket ticket;
  final Completer<MessageLinkPreviewMetadata?> completer;

  String get host => uri.host.toLowerCase();
}

final class _QueuedMessageLinkPreviewImageLoad {
  const _QueuedMessageLinkPreviewImageLoad({
    required this.key,
    required this.imageProxyUrl,
    required this.loader,
    required this.ticket,
    required this.completer,
  });

  final String key;
  final String imageProxyUrl;
  final _MessageLinkPreviewImageLoader loader;
  final _MessageLinkPreviewAutoLoadTicket ticket;
  final Completer<Uint8List?> completer;
}

final class _MessageLinkPreviewAutoLoadTicket {
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }
}

final class _CachedMessagePreviewMetadata {
  const _CachedMessagePreviewMetadata({
    required this.metadata,
    required this.cachedAt,
  });

  final MessageLinkPreviewMetadata metadata;
  final DateTime cachedAt;
}

final class _CachedMessagePreviewImage {
  const _CachedMessagePreviewImage({
    required this.bytes,
    required this.cachedAt,
  });

  final Uint8List bytes;
  final DateTime cachedAt;
}

String _normalizeBodyAfterLinkRemoval(String value) {
  final normalizedLines = value
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim())
      .toList(growable: false);
  return normalizedLines
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _trimUrlToken(String value) {
  var next = value.trim();
  while (next.isNotEmpty &&
      _isTrailingUrlPunctuation(next.codeUnitAt(next.length - 1))) {
    next = next.substring(0, next.length - 1);
  }
  return next;
}

bool _isTrailingUrlPunctuation(int codeUnit) {
  return codeUnit == 0x2E || // .
      codeUnit == 0x2C || // ,
      codeUnit == 0x21 || // !
      codeUnit == 0x3F || // ?
      codeUnit == 0x3A || // :
      codeUnit == 0x3B || // ;
      codeUnit == 0x29 || // )
      codeUnit == 0x5D; // ]
}

Uri? _safePreviewUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.trim().isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      value.contains('\u0000') ||
      value.contains('\\')) {
    return null;
  }
  final host = uri.host.toLowerCase();
  if (_isLocalOrPrivateHost(host)) {
    return null;
  }
  return uri;
}

bool _isLocalOrPrivateHost(String host) {
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      _isPrivateIpv6Literal(host)) {
    return true;
  }
  final octets = _ipv4Octets(host);
  if (octets == null) {
    return false;
  }
  return octets[0] == 10 ||
      octets[0] == 127 ||
      (octets[0] == 169 && octets[1] == 254) ||
      (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
      (octets[0] == 192 && octets[1] == 168);
}

bool _isPrivateIpv6Literal(String host) {
  if (!host.contains(':')) {
    return false;
  }
  return host == '::1' ||
      host.startsWith('fc') ||
      host.startsWith('fd') ||
      host.startsWith('fe80:');
}

String _scopedCacheKey(String cacheScope, String value) {
  final scope = cacheScope.trim().isEmpty
      ? _legacyPreviewCacheScope
      : cacheScope.trim();
  return '${scope.length}:$scope|$value';
}

List<int>? _ipv4Octets(String host) {
  final parts = host.split('.');
  if (parts.length != 4) {
    return null;
  }
  final octets = <int>[];
  for (final part in parts) {
    if (part.isEmpty || !RegExp(r'^\d+$').hasMatch(part)) {
      return null;
    }
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) {
      return null;
    }
    octets.add(octet);
  }
  return octets;
}
