import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/window_focus_scope.dart';
import '../../../../theme/verdant_theme.dart';
import '../media_residency_scope.dart';
import '../media_residency_service.dart';
import '../workspace_link_launcher.dart';
import '../workspace_render_diagnostics.dart';
import 'workspace_youtube_embed_service.dart';
import 'workspace_youtube_player.dart';
import 'workspace_youtube_playback_memory.dart';
import 'workspace_youtube_webview_pool.dart';

typedef WorkspaceYouTubePlayerBuilder =
    Widget Function(BuildContext context, Uri embedUri, Uri watchUri);

final _debugWorkspaceYouTubeThumbnailEvictions = <String>[];

@visibleForTesting
void debugResetWorkspaceYouTubeThumbnailEvictions() {
  _debugWorkspaceYouTubeThumbnailEvictions.clear();
}

@visibleForTesting
List<String> debugWorkspaceYouTubeThumbnailEvictions() {
  return List.unmodifiable(_debugWorkspaceYouTubeThumbnailEvictions);
}

class WorkspaceYouTubePreview extends StatelessWidget {
  const WorkspaceYouTubePreview({
    required this.url,
    this.title,
    this.linkLauncher = const WorkspaceLinkLauncher(),
    this.youtubePlayerBuilder,
    this.maxWidth = 480,
    this.headerIcon,
    this.previewKeyPrefix = 'workspace-youtube',
    this.playbackMemory,
    this.onPlaybackSnapshotChanged,
    this.youtubeWebViewPool,
    this.onWebViewLeaseAcquired,
    super.key,
  });

  final String url;
  final String? title;
  final WorkspaceLinkLauncher linkLauncher;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final double maxWidth;
  final IconData? headerIcon;
  final String previewKeyPrefix;
  final WorkspaceYouTubePlaybackMemory? playbackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onPlaybackSnapshotChanged;
  final WorkspaceYouTubeWebViewPool? youtubeWebViewPool;
  final ValueChanged<WorkspaceYouTubeWebViewLease>? onWebViewLeaseAcquired;

  @override
  Widget build(BuildContext context) {
    const embedService = WorkspaceYouTubeEmbedService();
    final embed = embedService.fromUrl(url);
    final label = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'YouTube video';
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: embed == null
            ? _UnsupportedYouTubeTile(title: label)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _YouTubeBlockHeader(title: label, icon: headerIcon),
                  const SizedBox(height: 8),
                  _YouTubePlayerShell(
                    key: ValueKey('$previewKeyPrefix-player-shell'),
                    embed: embed,
                    linkLauncher: linkLauncher,
                    youtubePlayerBuilder: youtubePlayerBuilder,
                    previewKeyPrefix: previewKeyPrefix,
                    playbackMemory:
                        playbackMemory ?? defaultWorkspaceYouTubePlaybackMemory,
                    onPlaybackSnapshotChanged: onPlaybackSnapshotChanged,
                    youtubeWebViewPool:
                        youtubeWebViewPool ??
                        defaultWorkspaceYouTubeWebViewPool,
                    onWebViewLeaseAcquired: onWebViewLeaseAcquired,
                  ),
                ],
              ),
      ),
    );
  }
}

class _UnsupportedYouTubeTile extends StatelessWidget {
  const _UnsupportedYouTubeTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '$title is not a supported YouTube URL.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ),
    );
  }
}

class _YouTubeBlockHeader extends StatelessWidget {
  const _YouTubeBlockHeader({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: colors.accentStrong),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: VerdantFontWeights.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _YouTubePlayerShell extends StatelessWidget {
  const _YouTubePlayerShell({
    required this.embed,
    required this.linkLauncher,
    required this.youtubePlayerBuilder,
    required this.previewKeyPrefix,
    required this.playbackMemory,
    required this.onPlaybackSnapshotChanged,
    required this.youtubeWebViewPool,
    required this.onWebViewLeaseAcquired,
    super.key,
  });

  final WorkspaceYouTubeEmbed embed;
  final WorkspaceLinkLauncher linkLauncher;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final String previewKeyPrefix;
  final WorkspaceYouTubePlaybackMemory playbackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onPlaybackSnapshotChanged;
  final WorkspaceYouTubeWebViewPool youtubeWebViewPool;
  final ValueChanged<WorkspaceYouTubeWebViewLease>? onWebViewLeaseAcquired;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _ViewportMountedYouTubePlayer(
        embed: embed,
        linkLauncher: linkLauncher,
        youtubePlayerBuilder: youtubePlayerBuilder,
        previewKeyPrefix: previewKeyPrefix,
        playbackMemory: playbackMemory,
        onPlaybackSnapshotChanged: onPlaybackSnapshotChanged,
        youtubeWebViewPool: youtubeWebViewPool,
        onWebViewLeaseAcquired: onWebViewLeaseAcquired,
      ),
    );
  }
}

class _ViewportMountedYouTubePlayer extends StatefulWidget {
  const _ViewportMountedYouTubePlayer({
    required this.embed,
    required this.linkLauncher,
    required this.youtubePlayerBuilder,
    required this.previewKeyPrefix,
    required this.playbackMemory,
    required this.onPlaybackSnapshotChanged,
    required this.youtubeWebViewPool,
    required this.onWebViewLeaseAcquired,
  });

  final WorkspaceYouTubeEmbed embed;
  final WorkspaceLinkLauncher linkLauncher;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final String previewKeyPrefix;
  final WorkspaceYouTubePlaybackMemory playbackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onPlaybackSnapshotChanged;
  final WorkspaceYouTubeWebViewPool youtubeWebViewPool;
  final ValueChanged<WorkspaceYouTubeWebViewLease>? onWebViewLeaseAcquired;

  @override
  State<_ViewportMountedYouTubePlayer> createState() =>
      _ViewportMountedYouTubePlayerState();
}

class _ViewportMountedYouTubePlayerState
    extends State<_ViewportMountedYouTubePlayer>
    with AutomaticKeepAliveClientMixin {
  static const _viewportMountExtent = 96.0;
  static const _inactiveUnmountGrace = Duration(milliseconds: 350);
  static const _minimumMountLifetimeBeforeUnmount = Duration(seconds: 2);

  var _mountPlayer = false;
  var _lastFocused = true;
  var _lastVisibleInViewport = true;
  var _lastTickerModeEnabled = true;
  var _activationCheckScheduled = false;
  var _playbackActive = false;
  var _autoplayOnMount = false;
  var _lastPlaybackPositionSeconds = 0.0;
  MediaResidencyService? _mediaResidencyService;
  DateTime _playerMountedAt = DateTime.now();
  Timer? _inactiveUnmountTimer;
  ScrollPosition? _scrollPosition;
  WorkspaceYouTubeWebViewLease? _webViewLease;

  @override
  bool get wantKeepAlive => _mountPlayer;

  @override
  void initState() {
    super.initState();
    _hydratePlaybackSnapshot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaResidencyService = MediaResidencyScope.maybeOf(context);
    _syncScrollPosition();
    _scheduleActivationCheck('dependencies');
  }

  @override
  void didUpdateWidget(covariant _ViewportMountedYouTubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embed.embedUri != widget.embed.embedUri ||
        oldWidget.embed.watchUri != widget.embed.watchUri) {
      _logYouTubePreview('embedChanged', widget.embed, {
        'oldVideoId': oldWidget.embed.videoId,
        'mountPlayer': _mountPlayer,
      });
      _cancelInactiveUnmount();
      _releaseWebViewLease('embedChanged');
      _mountPlayer = false;
      widget.playbackMemory.markStopped(oldWidget.embed.videoId);
      _autoplayOnMount = false;
      _hydratePlaybackSnapshot();
      updateKeepAlive();
      _scheduleActivationCheck('embedChanged');
    }
  }

  @override
  void dispose() {
    _logYouTubePreview('dispose', widget.embed, {
      'mountPlayer': _mountPlayer,
      'lastFocused': _lastFocused,
      'lastVisibleInViewport': _lastVisibleInViewport,
      'lastTickerModeEnabled': _lastTickerModeEnabled,
      'playbackActive': _playbackActive,
      'positionSeconds': _lastPlaybackPositionSeconds.round(),
      'inactiveTimerActive': _inactiveUnmountTimer?.isActive == true,
    });
    _scrollPosition?.removeListener(_handleScrollPositionChanged);
    _scrollPosition = null;
    _cancelInactiveUnmount();
    _markPlayerNotVisible();
    _releaseWebViewLease('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _syncScrollPosition();
    final focused = WindowFocusScope.isFocusedOf(context);
    final tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    _lastFocused = focused;
    _lastTickerModeEnabled = tickerModeEnabled;
    _logYouTubePreview('build', widget.embed, {
      'mountPlayer': _mountPlayer,
      'focused': focused,
      'tickerModeEnabled': tickerModeEnabled,
      'keepAlive': wantKeepAlive,
      'playbackActive': _playbackActive,
      'positionSeconds': _lastPlaybackPositionSeconds.round(),
      'inactiveTimerActive': _inactiveUnmountTimer?.isActive == true,
      'hasWebViewLease': _webViewLease != null,
    });
    _scheduleActivationCheck('build');
    if (!_mountPlayer) {
      return _YouTubePlayerStaticThumbnail(
        embed: widget.embed,
        previewKeyPrefix: widget.previewKeyPrefix,
        onPrepare: _handlePrepareRequested,
      );
    }
    final customPlayerBuilder = widget.youtubePlayerBuilder;
    if (customPlayerBuilder != null) {
      _ensureWebViewLease('customPlayer');
      return customPlayerBuilder(
        context,
        widget.embed.embedUri,
        widget.embed.watchUri,
      );
    }
    final webViewLease = _ensureWebViewLease('defaultPlayer');
    return WorkspaceYouTubePlayer(
      embedUri: widget.embed.embedUri,
      watchUri: widget.embed.watchUri,
      linkLauncher: widget.linkLauncher,
      initialStartSeconds: _lastPlaybackPositionSeconds,
      autoplay: _autoplayOnMount,
      keepAlive: webViewLease.keepAlive,
      onPlaybackUpdate: _handlePlaybackUpdate,
    );
  }

  void _hydratePlaybackSnapshot() {
    final snapshot = widget.playbackMemory.snapshotFor(widget.embed.videoId);
    _playbackActive = snapshot.isPlaying;
    _lastPlaybackPositionSeconds = snapshot.positionSeconds;
    _mountPlayer = snapshot.isPlaying;
    _autoplayOnMount = false;
    if (_mountPlayer) {
      _playerMountedAt = DateTime.now();
    }
  }

  void _handlePrepareRequested() {
    if (_mountPlayer) {
      return;
    }
    _logYouTubePreview('prepareRequested', widget.embed, {
      'positionSeconds': _lastPlaybackPositionSeconds.round(),
    });
    setState(() {
      _mountPlayer = true;
      _autoplayOnMount = false;
      _playerMountedAt = DateTime.now();
    });
    updateKeepAlive();
  }

  void _syncScrollPosition() {
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (identical(nextPosition, _scrollPosition)) {
      return;
    }
    _scrollPosition?.removeListener(_handleScrollPositionChanged);
    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_handleScrollPositionChanged);
  }

  void _handleScrollPositionChanged() {
    _scheduleActivationCheck('scroll');
  }

  void _scheduleActivationCheck(String reason) {
    if (_activationCheckScheduled) {
      return;
    }
    _activationCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activationCheckScheduled = false;
      if (!mounted) {
        return;
      }
      _runActivationCheck(reason);
    });
  }

  void _runActivationCheck(String reason) {
    final focused = WindowFocusScope.isFocusedOf(context);
    final tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    final visibleInViewport = _isInsideViewportBand(_viewportMountExtent);
    _syncPlayerResidency(visibleInViewport: visibleInViewport);
    final residentDelay = _residentDelay(
      focused: focused,
      tickerModeEnabled: tickerModeEnabled,
    );
    final shouldMount =
        tickerModeEnabled &&
        (focused || _mountPlayer) &&
        (visibleInViewport || _playbackActive);
    _lastFocused = focused;
    _lastTickerModeEnabled = tickerModeEnabled;
    _lastVisibleInViewport = visibleInViewport;
    _logYouTubePreview('activationCheck', widget.embed, {
      'reason': reason,
      'focused': focused,
      'tickerModeEnabled': tickerModeEnabled,
      'visibleInViewport': visibleInViewport,
      'mountPlayer': _mountPlayer,
      'playbackActive': _playbackActive,
      'positionSeconds': _lastPlaybackPositionSeconds.round(),
      'residentMs': residentDelay?.inMilliseconds,
      'shouldMount': shouldMount,
    });
    if (shouldMount) {
      _cancelInactiveUnmount();
      if (!_mountPlayer) {
        _logYouTubePreview('viewportMount', widget.embed, {'reason': reason});
        setState(() {
          _mountPlayer = true;
          _autoplayOnMount = false;
          _playerMountedAt = DateTime.now();
        });
        updateKeepAlive();
      }
      return;
    }
    if (_mountPlayer) {
      _scheduleInactiveUnmount(reason, minimumDelay: residentDelay);
    }
  }

  void _handlePlaybackUpdate(WorkspaceYouTubePlaybackUpdate update) {
    if (update.videoId != widget.embed.videoId) {
      return;
    }
    widget.playbackMemory.record(update);
    final snapshot = widget.playbackMemory.snapshotFor(widget.embed.videoId);
    final nextPlaybackActive = snapshot.isPlaying;
    final nextPositionSeconds = snapshot.positionSeconds;
    widget.onPlaybackSnapshotChanged?.call(widget.embed.videoId, snapshot);
    _logYouTubePreview('playbackUpdate', widget.embed, {
      'state': update.state,
      'playbackActive': nextPlaybackActive,
      'positionSeconds': nextPositionSeconds.round(),
    });
    if (nextPlaybackActive) {
      _cancelInactiveUnmount();
    }
    if (nextPlaybackActive == _playbackActive) {
      _lastPlaybackPositionSeconds = nextPositionSeconds;
      if (snapshot.hasStarted && _autoplayOnMount) {
        _autoplayOnMount = false;
      }
      _syncPlayerResidency(visibleInViewport: _lastVisibleInViewport);
      return;
    }
    setState(() {
      _playbackActive = nextPlaybackActive;
      _lastPlaybackPositionSeconds = nextPositionSeconds;
      if (snapshot.hasStarted) {
        _autoplayOnMount = false;
      }
    });
    _syncPlayerResidency(visibleInViewport: _lastVisibleInViewport);
    updateKeepAlive();
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

  void _scheduleInactiveUnmount(String reason, {Duration? minimumDelay}) {
    if (_inactiveUnmountTimer?.isActive == true) {
      _logYouTubePreview('inactiveAlreadyScheduled', widget.embed, {
        'reason': reason,
        'lastFocused': _lastFocused,
        'lastTickerModeEnabled': _lastTickerModeEnabled,
        'lastVisibleInViewport': _lastVisibleInViewport,
        'playbackActive': _playbackActive,
      });
      return;
    }
    final mountedFor = DateTime.now().difference(_playerMountedAt);
    final minimumRemaining = _minimumMountLifetimeBeforeUnmount - mountedFor;
    var delay = minimumRemaining > _inactiveUnmountGrace
        ? minimumRemaining
        : _inactiveUnmountGrace;
    if (minimumDelay != null && minimumDelay > delay) {
      delay = minimumDelay;
    }
    _logYouTubePreview('inactiveScheduled', widget.embed, {
      'reason': reason,
      'graceMs': delay.inMilliseconds,
      'residentMs': minimumDelay?.inMilliseconds,
      'mountedForMs': mountedFor.inMilliseconds,
      'lastFocused': _lastFocused,
      'lastTickerModeEnabled': _lastTickerModeEnabled,
      'lastVisibleInViewport': _lastVisibleInViewport,
      'playbackActive': _playbackActive,
    });
    _inactiveUnmountTimer = Timer(delay, () {
      if (!mounted || !_mountPlayer) {
        _logYouTubePreview('inactiveSkippedUnmounted', widget.embed, {
          'mounted': mounted,
          'mountPlayer': _mountPlayer,
        });
        return;
      }
      final focused = WindowFocusScope.isFocusedOf(context);
      final tickerModeEnabled = TickerMode.valuesOf(context).enabled;
      final visibleInViewport = _isInsideViewportBand(_viewportMountExtent);
      if (_playbackActive ||
          (focused && tickerModeEnabled && visibleInViewport)) {
        _logYouTubePreview('inactiveSkippedActive', widget.embed, {
          'focused': focused,
          'tickerModeEnabled': tickerModeEnabled,
          'visibleInViewport': visibleInViewport,
          'playbackActive': _playbackActive,
        });
        return;
      }
      final residentDelay = _residentDelay(
        focused: focused,
        tickerModeEnabled: tickerModeEnabled,
      );
      if (residentDelay != null && residentDelay > Duration.zero) {
        _logYouTubePreview('inactiveSkippedResident', widget.embed, {
          'residentMs': residentDelay.inMilliseconds,
        });
        _scheduleInactiveUnmount('residentRetain', minimumDelay: residentDelay);
        return;
      }
      _lastFocused = focused;
      _lastTickerModeEnabled = tickerModeEnabled;
      _lastVisibleInViewport = visibleInViewport;
      _logYouTubePreview('inactiveUnmount', widget.embed, {
        'reason': reason,
        'lastFocused': _lastFocused,
        'lastTickerModeEnabled': _lastTickerModeEnabled,
        'lastVisibleInViewport': _lastVisibleInViewport,
        'playbackActive': _playbackActive,
      });
      _releaseWebViewLease('inactiveUnmount');
      setState(() => _mountPlayer = false);
      updateKeepAlive();
    });
  }

  WorkspaceYouTubeWebViewLease _ensureWebViewLease(String reason) {
    final existing = _webViewLease;
    if (existing != null &&
        existing.poolKey == _webViewPoolKey() &&
        existing.videoId == widget.embed.videoId) {
      return existing;
    }
    if (existing != null) {
      _releaseWebViewLease('replace:$reason');
    }
    final lease = widget.youtubeWebViewPool.acquire(
      _webViewPoolKey(),
      videoId: widget.embed.videoId,
    );
    _webViewLease = lease;
    widget.onWebViewLeaseAcquired?.call(lease);
    _logYouTubePreview('webViewLeaseAcquired', widget.embed, {
      'reason': reason,
      'reusedExistingPlayer': lease.reusedExistingPlayer,
    });
    return lease;
  }

  void _releaseWebViewLease(String reason) {
    final lease = _webViewLease;
    if (lease == null) {
      return;
    }
    _webViewLease = null;
    _logYouTubePreview('webViewLeaseReleased', widget.embed, {
      'reason': reason,
      'reusedExistingPlayer': lease.reusedExistingPlayer,
    });
    unawaited(widget.youtubeWebViewPool.release(lease));
  }

  String _webViewPoolKey() {
    return '${widget.previewKeyPrefix}:${widget.embed.videoId}';
  }

  void _cancelInactiveUnmount() {
    final hadTimer = _inactiveUnmountTimer?.isActive == true;
    _inactiveUnmountTimer?.cancel();
    _inactiveUnmountTimer = null;
    if (hadTimer) {
      _logYouTubePreview('inactiveCanceled', widget.embed, {
        'lastFocused': _lastFocused,
        'lastTickerModeEnabled': _lastTickerModeEnabled,
        'lastVisibleInViewport': _lastVisibleInViewport,
        'playbackActive': _playbackActive,
      });
    }
  }

  void _syncPlayerResidency({required bool visibleInViewport}) {
    final service = _mediaResidencyService;
    if (service == null) {
      return;
    }
    final key = _playerResidencyKey();
    if (_mountPlayer && visibleInViewport) {
      service.markVisible(key, estimatedBytes: 1);
    } else {
      service.markNotVisible(key);
    }
    service.markActive(key, active: _playbackActive);
  }

  void _markPlayerNotVisible() {
    final service = _mediaResidencyService;
    if (service == null) {
      return;
    }
    final key = _playerResidencyKey();
    service.markActive(key, active: false);
    service.markNotVisible(key);
  }

  Duration? _residentDelay({
    required bool focused,
    required bool tickerModeEnabled,
  }) {
    if (!focused || !tickerModeEnabled || _playbackActive) {
      return null;
    }
    final service = _mediaResidencyService;
    if (service == null) {
      return null;
    }
    final key = _playerResidencyKey();
    if (!service.shouldRemainResident(key)) {
      return null;
    }
    return service.timeUntilExpiry(key);
  }

  MediaResidencyKey _playerResidencyKey() {
    return MediaResidencyKey(
      networkId: 'external:youtube',
      routeId: widget.previewKeyPrefix,
      kind: MediaResidencyKind.youtubePlayer,
      identity: widget.embed.videoId,
      variant: 'iframe',
    );
  }
}

class _YouTubePlayerStaticThumbnail extends StatefulWidget {
  const _YouTubePlayerStaticThumbnail({
    required this.embed,
    required this.previewKeyPrefix,
    required this.onPrepare,
  });

  final WorkspaceYouTubeEmbed embed;
  final String previewKeyPrefix;
  final VoidCallback onPrepare;

  @override
  State<_YouTubePlayerStaticThumbnail> createState() =>
      _YouTubePlayerStaticThumbnailState();
}

class _YouTubePlayerStaticThumbnailState
    extends State<_YouTubePlayerStaticThumbnail> {
  static const _estimatedThumbnailBytes = 480 * 360 * 4;

  MediaResidencyService? _mediaResidencyService;
  MediaResidencyKey? _mediaResidencyKey;
  NetworkImage? _thumbnailImageProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextService = MediaResidencyScope.maybeOf(context);
    if (identical(nextService, _mediaResidencyService)) {
      return;
    }
    _markThumbnailNotVisible();
    _mediaResidencyService = nextService;
    _markThumbnailVisible();
  }

  @override
  void didUpdateWidget(covariant _YouTubePlayerStaticThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embed.thumbnailUri != widget.embed.thumbnailUri ||
        oldWidget.embed.videoId != widget.embed.videoId ||
        oldWidget.previewKeyPrefix != widget.previewKeyPrefix) {
      _markThumbnailNotVisible();
      _thumbnailImageProvider = null;
      _markThumbnailVisible();
    }
  }

  @override
  void dispose() {
    _markThumbnailNotVisible();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Semantics(
      button: true,
      label: 'Play YouTube video',
      child: MouseRegion(
        onEnter: (_) => widget.onPrepare(),
        child: GestureDetector(
          key: ValueKey('${widget.previewKeyPrefix}-play-target'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPrepare,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: _thumbnailImageProviderForWidget(),
                    key: ValueKey('${widget.previewKeyPrefix}-thumbnail'),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      _logYouTubePreview('thumbnailError', widget.embed, {
                        'errorType': error.runtimeType.toString(),
                      });
                      return DecoratedBox(
                        decoration: BoxDecoration(color: colors.panelRaised),
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.48),
                        ],
                        stops: const [0, 0.58, 1],
                      ),
                    ),
                  ),
                  Center(
                    child: DecoratedBox(
                      key: ValueKey(
                        '${widget.previewKeyPrefix}-play-placeholder',
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0033),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.34),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 64,
                        height: 44,
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  NetworkImage _thumbnailImageProviderForWidget() {
    return _thumbnailImageProvider ??= NetworkImage(
      widget.embed.thumbnailUri.toString(),
    );
  }

  void _markThumbnailVisible() {
    final service = _mediaResidencyService;
    if (service == null) {
      return;
    }
    final key = _thumbnailResidencyKey();
    final imageProvider = _thumbnailImageProviderForWidget();
    _mediaResidencyKey = key;
    service.markVisibleWithEviction(
      key,
      estimatedBytes: _estimatedThumbnailBytes,
      onEvict: () => _evictThumbnailImage(imageProvider),
    );
  }

  void _markThumbnailNotVisible() {
    final service = _mediaResidencyService;
    final key = _mediaResidencyKey;
    if (service == null || key == null) {
      return;
    }
    service.markNotVisible(key);
  }

  void _evictThumbnailImage(NetworkImage imageProvider) {
    assert(() {
      _debugWorkspaceYouTubeThumbnailEvictions.add(imageProvider.url);
      return true;
    }());
    unawaited(imageProvider.evict());
    if (identical(_thumbnailImageProvider, imageProvider)) {
      _thumbnailImageProvider = null;
    }
  }

  MediaResidencyKey _thumbnailResidencyKey() {
    return MediaResidencyKey(
      networkId: 'external:youtube',
      routeId: widget.previewKeyPrefix,
      kind: MediaResidencyKind.youtubeThumbnail,
      identity: widget.embed.videoId,
      variant: 'thumbnail',
    );
  }
}

void _logYouTubePreview(
  String event,
  WorkspaceYouTubeEmbed embed, [
  Map<String, Object?> fields = const {},
]) {
  logWorkspaceRender('youtube.preview.$event', {
    'videoId': embed.videoId,
    'embedHost': embed.embedUri.host.toLowerCase(),
    ...fields,
  });
}
