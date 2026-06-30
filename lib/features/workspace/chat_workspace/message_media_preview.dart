import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/workspace_render_diagnostics.dart';
import '../workspace_seed.dart';
import 'message_media_download_service.dart';

enum MediaPreviewLoadState { loading, ready, poster }

class MessageMediaPreview extends StatefulWidget {
  const MessageMediaPreview({
    required this.media,
    required this.mediaPolicy,
    this.loadState = MediaPreviewLoadState.poster,
    this.preloadExtent = 720,
    this.animateExtent = 120,
    this.onLayoutSettled,
    super.key,
  });

  final MessageMediaSeed media;
  final ServerMediaPolicy mediaPolicy;
  final MediaPreviewLoadState loadState;
  final double preloadExtent;
  final double animateExtent;
  final VoidCallback? onLayoutSettled;

  @override
  State<MessageMediaPreview> createState() => _MessageMediaPreviewState();
}

class _MessageMediaPreviewState extends State<MessageMediaPreview> {
  ScrollPosition? _scrollPosition;
  var _preloadActive = false;
  var _animateActive = false;
  var _activationCheckScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncScrollPosition();
    _scheduleActivationCheck();
  }

  @override
  void didUpdateWidget(covariant MessageMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.media.id != oldWidget.media.id ||
        widget.media.url != oldWidget.media.url) {
      _preloadActive = false;
      _animateActive = false;
      _scheduleActivationCheck();
    } else if (widget.preloadExtent != oldWidget.preloadExtent ||
        widget.animateExtent != oldWidget.animateExtent) {
      _scheduleActivationCheck();
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_scheduleActivationCheck);
    super.dispose();
  }

  void _syncScrollPosition() {
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (identical(nextPosition, _scrollPosition)) {
      return;
    }
    _scrollPosition?.removeListener(_scheduleActivationCheck);
    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_scheduleActivationCheck);
  }

  void _scheduleActivationCheck() {
    if (_activationCheckScheduled) {
      return;
    }
    _activationCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activationCheckScheduled = false;
      if (!mounted) {
        return;
      }
      final preloadActive = _isInsideViewportBand(widget.preloadExtent);
      final animateActive =
          preloadActive && _isInsideViewportBand(widget.animateExtent);
      if (preloadActive != _preloadActive || animateActive != _animateActive) {
        setState(() {
          _preloadActive = preloadActive;
          _animateActive = animateActive;
        });
      }
    });
  }

  bool _isInsideViewportBand(double extent) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return true;
    }
    final mediaBox = context.findRenderObject() as RenderBox?;
    final viewportBox = scrollable.context.findRenderObject() as RenderBox?;
    if (mediaBox == null ||
        viewportBox == null ||
        !mediaBox.hasSize ||
        !viewportBox.hasSize ||
        !mediaBox.attached ||
        !viewportBox.attached) {
      return true;
    }
    final mediaTop = mediaBox.localToGlobal(Offset.zero).dy;
    final mediaBottom = mediaTop + mediaBox.size.height;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;
    return mediaBottom >= viewportTop - extent &&
        mediaTop <= viewportBottom + extent;
  }

  @override
  Widget build(BuildContext context) {
    final mediaPolicy = _chatMessageMediaPolicy(widget.mediaPolicy);
    final safeUri = _preloadActive
        ? safeServerMediaUri(widget.media.url, policy: mediaPolicy)
        : null;
    final effectiveLoadState = safeUri == null
        ? widget.loadState
        : MediaPreviewLoadState.ready;

    return WorkspaceRenderProbe(
      surface: 'messageMedia',
      id: widget.media.id,
      fields: {
        'kind': widget.media.kind.name,
        'preloadActive': _preloadActive,
        'animateActive': _animateActive,
        'loadState': effectiveLoadState.name,
        ...renderMediaUrlFields(widget.media.url),
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fallbackSize = mediaPreviewSizeFor(
            constraints: constraints,
            naturalSize: Size(
              widget.media.width.toDouble(),
              widget.media.height.toDouble(),
            ),
          );
          final borderless = _isKlipyMediaUrl(widget.media.url);
          final fallback = _MediaPreviewSurface(
            media: widget.media,
            size: fallbackSize,
            borderless: borderless,
            child: _MediaFrame(
              media: widget.media,
              loadState: effectiveLoadState,
              unavailable: widget.media.url != null && safeUri == null,
            ),
          );

          return Align(
            alignment: Alignment.centerLeft,
            child: RepaintBoundary(
              child: safeUri == null
                  ? fallback
                  : SafeServerMediaImage(
                      uri: safeUri,
                      policy: mediaPolicy,
                      surface: ServerMediaSurface.image,
                      fallback: fallback,
                      builder: (context, imageProvider) => _LoadedMediaPreview(
                        media: widget.media,
                        imageProvider: imageProvider,
                        bytes: null,
                        constraints: constraints,
                        fallbackSize: fallbackSize,
                        borderless: borderless,
                        animate: _animateActive,
                        fallback: fallback,
                        onLayoutSettled: widget.onLayoutSettled,
                      ),
                      bytesBuilder: (context, imageProvider, bytes) =>
                          _LoadedMediaPreview(
                            media: widget.media,
                            imageProvider: imageProvider,
                            bytes: bytes,
                            constraints: constraints,
                            fallbackSize: fallbackSize,
                            borderless: borderless,
                            animate: _animateActive,
                            fallback: fallback,
                            onLayoutSettled: widget.onLayoutSettled,
                          ),
                      frozenBuilder: (context, imageProvider, bytes) =>
                          _LoadedMediaPreview(
                            media: widget.media,
                            imageProvider: imageProvider,
                            bytes: bytes,
                            constraints: constraints,
                            fallbackSize: fallbackSize,
                            borderless: borderless,
                            animate: false,
                            fallback: fallback,
                            onLayoutSettled: widget.onLayoutSettled,
                          ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

@visibleForTesting
Size mediaPreviewSizeFor({
  required BoxConstraints constraints,
  required Size naturalSize,
  double maxPreviewWidth = 480.0,
  double maxPreviewHeight = 320.0,
}) {
  final naturalWidth = _safeNaturalDimension(naturalSize.width);
  final naturalHeight = _safeNaturalDimension(naturalSize.height);
  final maxWidth = math.min(
    constraints.maxWidth.isFinite ? constraints.maxWidth : maxPreviewWidth,
    maxPreviewWidth,
  );
  final maxHeight = math.min(
    constraints.maxHeight.isFinite ? constraints.maxHeight : maxPreviewHeight,
    maxPreviewHeight,
  );

  var scale = math.min(maxWidth / naturalWidth, maxHeight / naturalHeight);
  scale = math.min(scale, 1.0);

  var width = naturalWidth * scale;
  var height = naturalHeight * scale;
  if (width < 120 && maxWidth >= 120) {
    final growScale = math.min(120 / naturalWidth, maxHeight / naturalHeight);
    width = naturalWidth * growScale;
    height = naturalHeight * growScale;
  }
  return Size(width, height);
}

double _safeNaturalDimension(double value) {
  if (!value.isFinite || value <= 0) {
    return 1;
  }
  return value;
}

bool _isKlipyMediaUrl(String? raw) {
  final uri = Uri.tryParse(raw ?? '');
  if (uri == null) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == 'media.klipy.com' || host == 'static.klipy.com';
}

ServerMediaPolicy _chatMessageMediaPolicy(ServerMediaPolicy base) {
  return ServerMediaPolicy(
    allowedOrigins: {
      ...base.allowedOrigins,
      'https://media.klipy.com',
      'https://static.klipy.com',
    },
    allowLocalHttp: base.allowLocalHttp,
    apiOrigin: base.apiOrigin,
  );
}

class _LoadedMediaPreview extends StatefulWidget {
  const _LoadedMediaPreview({
    required this.media,
    required this.imageProvider,
    required this.constraints,
    required this.fallbackSize,
    required this.borderless,
    required this.animate,
    required this.fallback,
    required this.onLayoutSettled,
    this.bytes,
  });

  final MessageMediaSeed media;
  final ImageProvider imageProvider;
  final Uint8List? bytes;
  final BoxConstraints constraints;
  final Size fallbackSize;
  final bool borderless;
  final bool animate;
  final Widget fallback;
  final VoidCallback? onLayoutSettled;

  @override
  State<_LoadedMediaPreview> createState() => _LoadedMediaPreviewState();
}

class _LoadedMediaPreviewState extends State<_LoadedMediaPreview> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _decodedSize;

  Size get _surfaceSize {
    if (_hasUsableDeclaredMediaSize(widget.media)) {
      return widget.fallbackSize;
    }
    final decoded = _decodedSize;
    if (decoded == null) {
      return widget.fallbackSize;
    }
    return mediaPreviewSizeFor(
      constraints: widget.constraints,
      naturalSize: decoded,
    );
  }

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _LoadedMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameMedia =
        widget.media.id == oldWidget.media.id &&
        widget.bytes == oldWidget.bytes;
    if (!sameMedia || widget.imageProvider != oldWidget.imageProvider) {
      _stopListening();
      if (!sameMedia) {
        _decodedSize = null;
      }
      _resolveImage();
    }
    if (widget.constraints != oldWidget.constraints &&
        _decodedSize != null &&
        _surfaceSize !=
            mediaPreviewSizeFor(
              constraints: oldWidget.constraints,
              naturalSize: _decodedSize!,
            )) {
      _notifyLayoutSettled();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _surfaceSize;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openLightbox,
        child: _MediaPreviewSurface(
          media: widget.media,
          size: size,
          borderless: widget.borderless,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.animate || !_isAnimatedPreview(widget.media))
                Image(
                  key: ValueKey('message-media-image-${widget.media.id}'),
                  image: widget.imageProvider,
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) => widget.fallback,
                )
              else
                StaticFirstFrameImage(
                  key: ValueKey(
                    'message-media-static-image-${widget.media.id}',
                  ),
                  imageProvider: widget.imageProvider,
                  width: size.width,
                  height: size.height,
                ),
              Positioned(
                right: 10,
                bottom: 10,
                child: _MediaKindBadge(kind: widget.media.kind),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resolveImage() {
    logWorkspaceRender('messageMedia.resolve', {
      'id': widget.media.id,
      'kind': widget.media.kind.name,
      'bytesProvided': widget.bytes != null,
      ...renderMediaUrlFields(widget.media.url),
    });
    final stream = widget.imageProvider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(_handleImageFrame);
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _stopListening() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  void _handleImageFrame(ImageInfo info, bool synchronousCall) {
    final image = info.image;
    final decodedSize = Size(image.width.toDouble(), image.height.toDouble());
    final previousSurfaceSize = _surfaceSize;
    logWorkspaceRender('messageMedia.frame', {
      'id': widget.media.id,
      'kind': widget.media.kind.name,
      'synchronous': synchronousCall,
      'width': image.width,
      'height': image.height,
      ...renderMediaUrlFields(widget.media.url),
    });
    if (_decodedSize == decodedSize) {
      _stopListening();
      return;
    }
    setState(() {
      _decodedSize = decodedSize;
    });
    _stopListening();
    if (_surfaceSize != previousSurfaceSize) {
      _notifyLayoutSettled();
    }
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

  Future<void> _openLightbox() async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xDD000000),
      builder: (context) {
        return _MediaLightbox(
          media: widget.media,
          imageProvider: widget.imageProvider,
          bytes: widget.bytes,
          naturalSize: _decodedSize,
        );
      },
    );
  }
}

bool _isAnimatedPreview(MessageMediaSeed media) {
  return media.kind == MessageMediaKind.gif ||
      media.kind == MessageMediaKind.webp;
}

bool _hasUsableDeclaredMediaSize(MessageMediaSeed media) {
  final width = media.width.toDouble();
  final height = media.height.toDouble();
  return width.isFinite && height.isFinite && width > 0 && height > 0;
}

class _MediaLightbox extends StatelessWidget {
  const _MediaLightbox({
    required this.media,
    required this.imageProvider,
    required this.bytes,
    required this.naturalSize,
  });

  final MessageMediaSeed media;
  final ImageProvider imageProvider;
  final Uint8List? bytes;
  final Size? naturalSize;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 4,
                  child: _LightboxImage(
                    media: media,
                    imageProvider: imageProvider,
                    naturalSize: naturalSize,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Row(
              children: [
                _LightboxButton(
                  key: ValueKey('message-media-download-${media.id}'),
                  tooltip: 'Download',
                  icon: PhosphorIcons.downloadSimple,
                  onPressed: bytes == null ? null : () => _download(context),
                ),
                const SizedBox(width: 8),
                _LightboxButton(
                  key: ValueKey('message-media-close-${media.id}'),
                  tooltip: 'Close',
                  icon: PhosphorIcons.x,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final data = bytes;
    if (data == null) {
      return;
    }
    await messageMediaDownloadService.saveBytes(
      bytes: data,
      suggestedName: _downloadFileName(),
    );
  }

  String _downloadFileName() {
    final url = media.url;
    if (url != null) {
      final uri = Uri.tryParse(url);
      final segment = uri?.pathSegments.isEmpty ?? true
          ? null
          : uri!.pathSegments.last;
      if (segment != null && segment.contains('.')) {
        return segment;
      }
    }
    return 'verdant-media.${media.kind.extension}';
  }
}

class _LightboxImage extends StatelessWidget {
  const _LightboxImage({
    required this.media,
    required this.imageProvider,
    required this.naturalSize,
  });

  final MessageMediaSeed media;
  final ImageProvider imageProvider;
  final Size? naturalSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final natural =
            naturalSize ??
            Size(media.width.toDouble(), media.height.toDouble());
        final size = mediaPreviewSizeFor(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          naturalSize: natural,
          maxPreviewWidth: constraints.maxWidth,
          maxPreviewHeight: constraints.maxHeight,
        );
        return SizedBox(
          width: size.width,
          height: size.height,
          child: Image(
            key: ValueKey('message-media-lightbox-image-${media.id}'),
            image: imageProvider,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        );
      },
    );
  }
}

class _LightboxButton extends StatefulWidget {
  const _LightboxButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_LightboxButton> createState() => _LightboxButtonState();
}

class _LightboxButtonState extends State<_LightboxButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final active = enabled && _hovered;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? VerdantColors.accent.withValues(alpha: 0.20)
                  : const Color(0xDD111418),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: Border.all(
                color: active
                    ? VerdantColors.accentStrong
                    : VerdantColors.border,
              ),
            ),
            child: PhosphorIcon(
              widget.icon,
              size: 20,
              color: enabled ? VerdantColors.text : VerdantColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaPreviewSurface extends StatelessWidget {
  const _MediaPreviewSurface({
    required this.media,
    required this.size,
    required this.borderless,
    required this.child,
  });

  final MessageMediaSeed media;
  final Size size;
  final bool borderless;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('message-media-surface-${media.id}'),
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: VerdantRadii.sharp,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: borderless ? null : Border.all(color: VerdantColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({
    required this.media,
    required this.loadState,
    this.unavailable = false,
  });

  final MessageMediaSeed media;
  final MediaPreviewLoadState loadState;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _MediaBackdrop(loadState: loadState),
        _MediaLabel(
          media: media,
          loadState: loadState,
          unavailable: unavailable,
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: _MediaKindBadge(kind: media.kind),
        ),
      ],
    );
  }
}

class _MediaBackdrop extends StatelessWidget {
  const _MediaBackdrop({required this.loadState});

  final MediaPreviewLoadState loadState;

  @override
  Widget build(BuildContext context) {
    final colors = switch (loadState) {
      MediaPreviewLoadState.loading => const [
        Color(0xFF1B2532),
        Color(0xFF283447),
      ],
      MediaPreviewLoadState.ready => const [
        Color(0xFF224C45),
        Color(0xFF6C7A3C),
      ],
      MediaPreviewLoadState.poster => const [
        Color(0xFF2A3040),
        Color(0xFF44506A),
      ],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _MediaLabel extends StatelessWidget {
  const _MediaLabel({
    required this.media,
    required this.loadState,
    this.unavailable = false,
  });

  final MessageMediaSeed media;
  final MediaPreviewLoadState loadState;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final stateText = unavailable
        ? 'Preview unavailable'
        : switch (loadState) {
            MediaPreviewLoadState.loading => 'Loading preview',
            MediaPreviewLoadState.ready => 'Preview ready',
            MediaPreviewLoadState.poster => 'Static poster',
          };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            media.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: VerdantColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stateText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFD5DEE8)),
          ),
        ],
      ),
    );
  }
}

class _MediaKindBadge extends StatelessWidget {
  const _MediaKindBadge({required this.kind});

  final MessageMediaKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xCC050607),
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: const Color(0x5537E6B1)),
      ),
      child: Text(
        kind.label,
        style: const TextStyle(
          color: VerdantColors.text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
