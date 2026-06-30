import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/window_focus_scope.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_diagnostics.dart';
import '../shared/media_residency_scope.dart';
import '../shared/media_residency_service.dart';
import 'banner_crop_geometry.dart';
import 'server_media_loader.dart';
import 'server_media_url_policy.dart';
import 'server_settings_models.dart';

final _serverMediaLoader = ServerMediaLoader();

typedef ServerMediaWidgetLoader =
    Future<Uint8List> Function(
      Uri uri, {
      required ServerMediaPolicy policy,
      int? maxBytes,
    });

ServerMediaWidgetLoader? _debugServerMediaWidgetLoader;
var _debugServerMediaImageEvictionCount = 0;
const _defaultServerMediaCacheMaxEntries = 96;
const _defaultServerMediaCacheMaxBytes = 32 * 1024 * 1024;
const _workspaceImageCacheMaxEntries = 256;
const _workspaceImageCacheMaxBytes = 48 * 1024 * 1024;

var _serverMediaBytesCache = _ServerMediaBytesCache(
  maxEntries: _defaultServerMediaCacheMaxEntries,
  maxBytes: _defaultServerMediaCacheMaxBytes,
);

@visibleForTesting
void debugSetServerMediaWidgetLoader(ServerMediaWidgetLoader? loader) {
  _debugServerMediaWidgetLoader = loader;
  _debugServerMediaImageEvictionCount = 0;
  clearServerMediaImageCache();
}

@visibleForTesting
void debugConfigureServerMediaImageCacheForTesting({
  int? maxEntries,
  int? maxBytes,
}) {
  _serverMediaBytesCache = _ServerMediaBytesCache(
    maxEntries: maxEntries ?? _defaultServerMediaCacheMaxEntries,
    maxBytes: maxBytes ?? _defaultServerMediaCacheMaxBytes,
  );
}

@visibleForTesting
int debugServerMediaImageCacheEntryCount() {
  return _serverMediaBytesCache.entryCount;
}

@visibleForTesting
int debugServerMediaImageCacheTotalBytes() {
  return _serverMediaBytesCache.totalBytes;
}

@visibleForTesting
int debugFlutterImageCacheMaximumSize() {
  return PaintingBinding.instance.imageCache.maximumSize;
}

@visibleForTesting
int debugFlutterImageCacheMaximumSizeBytes() {
  return PaintingBinding.instance.imageCache.maximumSizeBytes;
}

@visibleForTesting
int debugFlutterImageCacheCurrentSize() {
  return PaintingBinding.instance.imageCache.currentSize;
}

@visibleForTesting
int debugFlutterImageCacheLiveImageCount() {
  return PaintingBinding.instance.imageCache.liveImageCount;
}

@visibleForTesting
int debugServerMediaImageEvictionCount() {
  return _debugServerMediaImageEvictionCount;
}

void clearServerMediaImageCache() {
  _serverMediaBytesCache.clear();
}

final class ServerMediaWarmRequest {
  const ServerMediaWarmRequest({
    required this.uri,
    required this.policy,
    required this.surface,
  });

  final Uri uri;
  final ServerMediaPolicy policy;
  final ServerMediaSurface surface;
}

Future<void> warmServerMediaImageCache(
  Iterable<ServerMediaWarmRequest> requests, {
  int maxConcurrent = 6,
}) async {
  final startedAt = DateTime.now();
  final uniqueRequests = <_ServerMediaCacheKey, ServerMediaWarmRequest>{};
  var inputCount = 0;
  var policyRejectedCount = 0;
  var duplicateCount = 0;
  for (final request in requests) {
    inputCount += 1;
    final safeUri = safeServerMediaUri(
      request.uri.toString(),
      policy: request.policy,
    );
    if (safeUri == null) {
      policyRejectedCount += 1;
      _recordServerMediaDiagnostic(
        'warm.skip',
        request.uri,
        surface: request.surface,
        reason: 'policyRejected',
      );
      continue;
    }
    final cacheKey = _ServerMediaCacheKey(
      uri: safeUri,
      policy: request.policy,
      surface: request.surface,
    );
    if (uniqueRequests.containsKey(cacheKey)) {
      duplicateCount += 1;
      continue;
    }
    uniqueRequests[cacheKey] = ServerMediaWarmRequest(
      uri: safeUri,
      policy: request.policy,
      surface: request.surface,
    );
  }

  if (uniqueRequests.isEmpty) {
    _recordServerMediaBatchDiagnostic('warm.batch.skip', {
      'inputCount': inputCount,
      'uniqueRequestCount': 0,
      'duplicateCount': duplicateCount,
      'policyRejectedCount': policyRejectedCount,
      'ms': DateTime.now().difference(startedAt).inMilliseconds,
    });
    return;
  }

  final queue = uniqueRequests.entries.toList(growable: false);
  var nextIndex = 0;
  final workerCount = maxConcurrent <= 0
      ? 1
      : maxConcurrent.clamp(1, queue.length);
  _recordServerMediaBatchDiagnostic('warm.batch.start', {
    'inputCount': inputCount,
    'uniqueRequestCount': queue.length,
    'duplicateCount': duplicateCount,
    'policyRejectedCount': policyRejectedCount,
    'maxConcurrent': maxConcurrent,
    'workerCount': workerCount,
    'cacheEntries': _serverMediaBytesCache.entryCount,
    'cacheBytes': _serverMediaBytesCache.totalBytes,
  });
  Future<void> worker() async {
    while (true) {
      final index = nextIndex;
      nextIndex += 1;
      if (index >= queue.length) {
        return;
      }
      final entry = queue[index];
      await _warmServerMediaImageCacheEntry(entry.key, entry.value);
    }
  }

  await Future.wait<void>([for (var i = 0; i < workerCount; i += 1) worker()]);
  _recordServerMediaBatchDiagnostic('warm.batch.done', {
    'inputCount': inputCount,
    'uniqueRequestCount': queue.length,
    'duplicateCount': duplicateCount,
    'policyRejectedCount': policyRejectedCount,
    'maxConcurrent': maxConcurrent,
    'workerCount': workerCount,
    'cacheEntries': _serverMediaBytesCache.entryCount,
    'cacheBytes': _serverMediaBytesCache.totalBytes,
    'ms': DateTime.now().difference(startedAt).inMilliseconds,
  });
}

Future<void> _warmServerMediaImageCacheEntry(
  _ServerMediaCacheKey cacheKey,
  ServerMediaWarmRequest request,
) async {
  final cached = _serverMediaBytesCache.get(cacheKey);
  if (cached != null) {
    _recordServerMediaDiagnostic(
      'warm.cacheHit',
      request.uri,
      surface: request.surface,
      byteLength: cached.lengthInBytes,
      extra: {
        'cacheEntries': _serverMediaBytesCache.entryCount,
        'cacheBytes': _serverMediaBytesCache.totalBytes,
      },
    );
    return;
  }

  _recordServerMediaDiagnostic(
    'warm.start',
    request.uri,
    surface: request.surface,
    extra: {
      'cacheEntries': _serverMediaBytesCache.entryCount,
      'cacheBytes': _serverMediaBytesCache.totalBytes,
    },
  );
  final pending = _serverMediaBytesCache.getOrLoad(
    cacheKey,
    () => _loadServerMediaBytesWithDiagnostics(
      uri: request.uri,
      policy: request.policy,
      surface: request.surface,
      loader: _debugServerMediaWidgetLoader,
    ),
  );
  try {
    final bytes = await pending;
    _recordServerMediaDiagnostic(
      'warm.done',
      request.uri,
      surface: request.surface,
      byteLength: bytes.lengthInBytes,
      extra: {
        'cacheEntries': _serverMediaBytesCache.entryCount,
        'cacheBytes': _serverMediaBytesCache.totalBytes,
      },
    );
  } catch (error) {
    _recordServerMediaDiagnostic(
      'warm.failure',
      request.uri,
      surface: request.surface,
      reason: _safeServerMediaReason(error),
    );
  } finally {
    _serverMediaBytesCache.releasePending(cacheKey, pending);
  }
}

class SafeServerMediaImage extends StatefulWidget {
  const SafeServerMediaImage({
    required this.uri,
    required this.policy,
    required this.fallback,
    required this.builder,
    this.bytesBuilder,
    this.frozenBuilder,
    this.loading,
    this.surface = ServerMediaSurface.image,
    this.loadWhenVisible = true,
    this.retainWhenUnfocused = false,
    super.key,
  });

  final Uri uri;
  final ServerMediaPolicy policy;
  final Widget fallback;
  final Widget? loading;
  final Widget Function(BuildContext context, ImageProvider imageProvider)
  builder;
  final Widget Function(
    BuildContext context,
    ImageProvider imageProvider,
    Uint8List bytes,
  )?
  bytesBuilder;
  final Widget Function(
    BuildContext context,
    ImageProvider imageProvider,
    Uint8List bytes,
  )?
  frozenBuilder;
  final ServerMediaSurface surface;
  final bool loadWhenVisible;
  final bool retainWhenUnfocused;

  @override
  State<SafeServerMediaImage> createState() => _SafeServerMediaImageState();
}

class _SafeServerMediaImageState extends State<SafeServerMediaImage> {
  Future<Uint8List>? _bytesFuture;
  Uint8List? _initialBytes;
  _ServerMediaCacheKey? _cacheKey;
  Future<Uint8List>? _pendingLoadFuture;
  MemoryImage? _activeImageProvider;
  Uint8List? _activeImageBytes;
  MediaResidencyService? _mediaResidencyService;
  MediaResidencyKey? _mediaResidencyKey;
  var _loadConfigured = false;
  var _visibilityCheckScheduled = false;
  var _appFocused = true;
  String? _lastRenderDiagnosticSignature;
  String? _lastLoadedMediaDiagnosticSignature;

  @override
  void initState() {
    super.initState();
    _applyWorkspaceImageCacheBudget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final residencyService = MediaResidencyScope.maybeOf(context);
    if (!identical(residencyService, _mediaResidencyService)) {
      _markMediaNotVisible();
      _mediaResidencyService = residencyService;
    }
    final appFocused = WindowFocusScope.isFocusedOf(context);
    if (appFocused == _appFocused) {
      return;
    }
    _appFocused = appFocused;
    _recordServerMediaDiagnostic(
      'focus.changed',
      widget.uri,
      surface: widget.surface,
      reason: _appFocused ? 'focused' : 'unfocused',
      extra: {
        'loadConfigured': _loadConfigured,
        'hasActiveImage': _activeImageProvider != null,
        'hasPendingLoad': _pendingLoadFuture != null,
      },
    );
    if (_appFocused) {
      _evictExpiredResidentMedia();
      _configureLoadIfVisible();
    } else {
      _handleWindowFocusLost();
    }
  }

  @override
  void didUpdateWidget(covariant SafeServerMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri ||
        widget.policy != oldWidget.policy ||
        widget.surface != oldWidget.surface ||
        widget.loadWhenVisible != oldWidget.loadWhenVisible) {
      _markMediaNotVisible();
      _unmountActiveMedia(reason: 'widgetChanged');
      if (_appFocused) {
        _configureLoadIfVisible();
      }
    }
  }

  void _handleWindowFocusLost() {
    _markMediaNotVisible();
    if (_shouldRetainLoadedMedia()) {
      final retainedByBlurPolicy =
          widget.retainWhenUnfocused && _hasLoadedResidentMedia();
      _recordServerMediaDiagnostic(
        retainedByBlurPolicy ? 'focus.retain' : 'residency.retain',
        widget.uri,
        surface: widget.surface,
        reason: 'windowFocusLost',
        extra: {
          'hasActiveImage': _activeImageProvider != null,
          'hasInitialBytes': _initialBytes != null,
          'hasActiveBytes': _activeImageBytes != null,
        },
      );
      _visibilityCheckScheduled = false;
      return;
    }
    _unmountActiveMedia(reason: 'windowFocusLost');
  }

  void _configureLoadIfVisible() {
    if (!_appFocused) {
      return;
    }
    if (_loadConfigured) {
      return;
    }
    if (!widget.loadWhenVisible || _isInViewport()) {
      _loadConfigured = true;
      _configureLoad();
      return;
    }
    if (_visibilityCheckScheduled) {
      return;
    }
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckScheduled = false;
      if (!mounted || _loadConfigured || !_appFocused) {
        return;
      }
      if (_isInViewport()) {
        setState(() {
          _loadConfigured = true;
          _configureLoad();
        });
      }
    });
  }

  bool _isInViewport() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return true;
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final bounds = topLeft & renderObject.size;
    final viewport = Offset.zero & mediaQuery.size;
    return bounds.overlaps(viewport);
  }

  void _configureLoad() {
    final cacheKey = _cacheKeyForWidget();
    _releasePendingLoad();
    _cacheKey = cacheKey;
    final cached = _serverMediaBytesCache.get(cacheKey);
    if (cached != null) {
      _recordServerMediaDiagnostic(
        'cache.hit',
        widget.uri,
        surface: widget.surface,
        byteLength: cached.lengthInBytes,
        extra: _diagnosticStateExtra()
          ..addAll({
            'cacheEntries': _serverMediaBytesCache.entryCount,
            'cacheBytes': _serverMediaBytesCache.totalBytes,
          }),
      );
      _initialBytes = cached;
      _bytesFuture = null;
      _markMediaVisible(cached);
      return;
    }

    _recordServerMediaDiagnostic(
      'cache.miss',
      widget.uri,
      surface: widget.surface,
      extra: _diagnosticStateExtra()
        ..addAll({
          'cacheEntries': _serverMediaBytesCache.entryCount,
          'cacheBytes': _serverMediaBytesCache.totalBytes,
        }),
    );
    _initialBytes = null;
    final pending = _serverMediaBytesCache.getOrLoad(
      cacheKey,
      _loadWithDiagnostics,
    );
    _pendingLoadFuture = pending;
    _bytesFuture = pending;
  }

  _ServerMediaCacheKey _cacheKeyForWidget() {
    return _ServerMediaCacheKey(
      uri: widget.uri,
      policy: widget.policy,
      surface: widget.surface,
    );
  }

  bool _primeLoadFromWarmedCache() {
    if (_loadConfigured && _retainedBytes != null) {
      return true;
    }
    final cacheKey = _cacheKeyForWidget();
    final cached = _serverMediaBytesCache.get(cacheKey);
    if (cached == null) {
      return false;
    }
    _releasePendingLoad();
    _cacheKey = cacheKey;
    _initialBytes = cached;
    _bytesFuture = null;
    _loadConfigured = true;
    _visibilityCheckScheduled = false;
    _recordServerMediaDiagnostic(
      'cache.prime',
      widget.uri,
      surface: widget.surface,
      byteLength: cached.lengthInBytes,
      extra: _diagnosticStateExtra()
        ..addAll({
          'cacheEntries': _serverMediaBytesCache.entryCount,
          'cacheBytes': _serverMediaBytesCache.totalBytes,
        }),
    );
    return true;
  }

  void _unmountActiveMedia({required String reason}) {
    final retainPendingLoad =
        reason == 'windowFocusLost' &&
        widget.retainWhenUnfocused &&
        _pendingLoadFuture != null;
    _recordServerMediaDiagnostic(
      'unmount.active',
      widget.uri,
      surface: widget.surface,
      reason: reason,
      extra: {
        'loadConfigured': _loadConfigured,
        'visibilityCheckScheduled': _visibilityCheckScheduled,
        'hasActiveImage': _activeImageProvider != null,
        'hasInitialBytes': _initialBytes != null,
        'hasPendingLoad': _pendingLoadFuture != null,
        'retainPendingLoad': retainPendingLoad,
      },
    );
    if (!retainPendingLoad) {
      _releasePendingLoad();
    }
    _evictActiveImageProvider(reason: reason);
    _cacheKey = null;
    _bytesFuture = null;
    _initialBytes = null;
    _loadConfigured = false;
    _visibilityCheckScheduled = false;
  }

  @override
  void dispose() {
    _markMediaNotVisible();
    _releasePendingLoad();
    _evictActiveImageProvider(reason: 'dispose');
    super.dispose();
  }

  void _releasePendingLoad() {
    final cacheKey = _cacheKey;
    final pending = _pendingLoadFuture;
    if (cacheKey != null && pending != null) {
      _serverMediaBytesCache.releasePending(cacheKey, pending);
    }
    _pendingLoadFuture = null;
  }

  void _evictActiveImageProvider({required String reason}) {
    final imageProvider = _activeImageProvider;
    if (imageProvider != null) {
      _recordServerMediaDiagnostic(
        'evict.provider',
        widget.uri,
        surface: widget.surface,
        reason: reason,
      );
      assert(() {
        _debugServerMediaImageEvictionCount += 1;
        return true;
      }());
      unawaited(imageProvider.evict());
    }
    _activeImageProvider = null;
    _activeImageBytes = null;
  }

  void _evictExpiredResidentMedia() {
    if (!_hasLoadedResidentMedia()) {
      return;
    }
    final residencyService = _mediaResidencyService;
    final key = _mediaResidencyKey;
    if (residencyService == null ||
        key == null ||
        residencyService.shouldRemainResident(key)) {
      return;
    }
    _unmountActiveMedia(reason: 'residencyExpired');
  }

  bool _shouldRetainLoadedMedia() {
    if (widget.retainWhenUnfocused && _hasLoadedResidentMedia()) {
      return true;
    }
    final residencyService = _mediaResidencyService;
    final key = _mediaResidencyKey;
    return residencyService != null &&
        key != null &&
        _hasLoadedResidentMedia() &&
        residencyService.shouldRemainResident(key);
  }

  bool _hasLoadedResidentMedia() {
    return _activeImageProvider != null ||
        _activeImageBytes != null ||
        _initialBytes != null;
  }

  Uint8List? get _retainedBytes => _activeImageBytes ?? _initialBytes;

  void _markMediaVisible(Uint8List bytes) {
    final residencyService = _mediaResidencyService;
    if (residencyService == null) {
      return;
    }
    final key = _residencyKeyForWidget();
    _mediaResidencyKey = key;
    residencyService.markVisible(key, estimatedBytes: bytes.lengthInBytes);
  }

  void _markMediaNotVisible() {
    final residencyService = _mediaResidencyService;
    final key = _mediaResidencyKey;
    if (residencyService == null || key == null) {
      return;
    }
    residencyService.markNotVisible(key);
  }

  MediaResidencyKey _residencyKeyForWidget() {
    final apiOrigin = widget.policy.apiOrigin?.trim();
    final networkId = apiOrigin == null || apiOrigin.isEmpty
        ? 'origin:${_originForDiagnostic(widget.uri)}'
        : 'origin:${Uri.encodeComponent(apiOrigin)}';
    return MediaResidencyKey(
      networkId: networkId,
      routeId: 'workspace-media:${widget.surface.diagnosticName}',
      kind: MediaResidencyKind.image,
      identity: widget.uri.toString(),
      variant: widget.surface.diagnosticName,
    );
  }

  Future<Uint8List> _loadWithDiagnostics() async {
    return _loadServerMediaBytesWithDiagnostics(
      uri: widget.uri,
      policy: widget.policy,
      surface: widget.surface,
      loader: _debugServerMediaWidgetLoader,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_appFocused) {
      final retainedBytes = _retainedBytes;
      if (retainedBytes != null && _shouldRetainLoadedMedia()) {
        _recordRenderBranch(
          'unfocusedFrozen',
          bytes: retainedBytes,
          frozen: true,
        );
        return _buildLoadedMedia(
          context,
          retainedBytes,
          markVisible: false,
          frozen: true,
        );
      }
      _recordRenderBranch('unfocusedFallback');
      return widget.fallback;
    }
    _primeLoadFromWarmedCache();
    _configureLoadIfVisible();
    if (!_loadConfigured) {
      _recordRenderBranch('deferredOrLoadingPlaceholder');
      return widget.loading ?? widget.fallback;
    }
    final retainedBytes = _retainedBytes;
    if (retainedBytes != null) {
      _recordRenderBranch(
        'focusedRetained',
        bytes: retainedBytes,
        snapshotState: 'retained',
      );
      return _buildLoadedMedia(
        context,
        retainedBytes,
        markVisible: true,
        frozen: false,
      );
    }
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      initialData: _initialBytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          _recordRenderBranch(
            'loaded',
            bytes: bytes,
            snapshotState: snapshot.connectionState.name,
          );
          return _buildLoadedMedia(
            context,
            bytes,
            markVisible: true,
            frozen: false,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          _recordRenderBranch(
            'futureWaiting',
            snapshotState: snapshot.connectionState.name,
          );
          return widget.loading ?? widget.fallback;
        }
        _recordRenderBranch(
          'futureFallback',
          snapshotState: snapshot.connectionState.name,
        );
        return widget.fallback;
      },
    );
  }

  Widget _buildLoadedMedia(
    BuildContext context,
    Uint8List bytes, {
    required bool markVisible,
    required bool frozen,
  }) {
    if (markVisible) {
      _markMediaVisible(bytes);
    }
    final providerChanged =
        !identical(_activeImageBytes, bytes) || _activeImageProvider == null;
    if (!identical(_activeImageBytes, bytes) || _activeImageProvider == null) {
      _evictActiveImageProvider(reason: 'imageBytesChanged');
      _activeImageBytes = bytes;
      _activeImageProvider = MemoryImage(bytes);
    }
    final imageProvider = _activeImageProvider!;
    final builderKind = frozen && widget.frozenBuilder != null
        ? 'frozenBuilder'
        : widget.bytesBuilder != null
        ? 'bytesBuilder'
        : 'builder';
    _recordLoadedMediaBranch(
      builderKind,
      bytes: bytes,
      frozen: frozen,
      markVisible: markVisible,
      providerChanged: providerChanged,
      imageProvider: imageProvider,
    );
    if (frozen) {
      final frozenBuilder = widget.frozenBuilder;
      if (frozenBuilder != null) {
        return frozenBuilder(context, imageProvider, bytes);
      }
    }
    final bytesBuilder = widget.bytesBuilder;
    if (bytesBuilder != null) {
      return bytesBuilder(context, imageProvider, bytes);
    }
    return widget.builder(context, imageProvider);
  }

  Map<String, Object?> _diagnosticStateExtra() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'focused': _appFocused,
      'retainWhenUnfocused': widget.retainWhenUnfocused,
      'loadConfigured': _loadConfigured,
      'visibilityCheckScheduled': _visibilityCheckScheduled,
      'hasActiveImage': _activeImageProvider != null,
      'hasActiveBytes': _activeImageBytes != null,
      'hasInitialBytes': _initialBytes != null,
      'hasPendingLoad': _pendingLoadFuture != null,
      'hasRetainedBytes': _retainedBytes != null,
      'imageCacheCurrent': imageCache.currentSize,
      'imageCacheLive': imageCache.liveImageCount,
    };
  }

  void _recordRenderBranch(
    String branch, {
    Uint8List? bytes,
    bool frozen = false,
    String? snapshotState,
  }) {
    final signature = [
      branch,
      _appFocused,
      widget.retainWhenUnfocused,
      _loadConfigured,
      _visibilityCheckScheduled,
      _activeImageProvider != null,
      _activeImageBytes != null,
      _initialBytes != null,
      _pendingLoadFuture != null,
      _retainedBytes != null,
      bytes?.lengthInBytes ?? -1,
      frozen,
      snapshotState ?? 'none',
    ].join('|');
    if (signature == _lastRenderDiagnosticSignature) {
      return;
    }
    _lastRenderDiagnosticSignature = signature;
    _recordServerMediaDiagnostic(
      'render.branch',
      widget.uri,
      surface: widget.surface,
      byteLength: bytes?.lengthInBytes,
      extra: _diagnosticStateExtra()
        ..addAll({
          'branch': branch,
          'frozen': frozen,
          'snapshotState': snapshotState ?? 'none',
        }),
    );
  }

  void _recordLoadedMediaBranch(
    String builderKind, {
    required Uint8List bytes,
    required bool frozen,
    required bool markVisible,
    required bool providerChanged,
    required ImageProvider imageProvider,
  }) {
    final signature = [
      builderKind,
      frozen,
      markVisible,
      providerChanged,
      bytes.lengthInBytes,
      identityHashCode(bytes),
      identityHashCode(imageProvider),
    ].join('|');
    if (signature == _lastLoadedMediaDiagnosticSignature) {
      return;
    }
    _lastLoadedMediaDiagnosticSignature = signature;
    _recordServerMediaDiagnostic(
      'render.loadedMedia',
      widget.uri,
      surface: widget.surface,
      byteLength: bytes.lengthInBytes,
      extra: _diagnosticStateExtra()
        ..addAll({
          'builder': builderKind,
          'frozen': frozen,
          'markVisible': markVisible,
          'providerChanged': providerChanged,
          'bytesHash': identityHashCode(bytes),
          'providerHash': identityHashCode(imageProvider),
        }),
    );
  }
}

Future<Uint8List> _loadServerMediaBytesWithDiagnostics({
  required Uri uri,
  required ServerMediaPolicy policy,
  required ServerMediaSurface surface,
  ServerMediaWidgetLoader? loader,
}) async {
  final requestUri = _cdnTransformedMediaUri(uri, surface);
  final startedAt = DateTime.now();
  try {
    final bytes = await _loadServerMediaUri(
      requestUri,
      policy: policy,
      surface: surface,
      loader: loader,
    );
    _recordServerMediaDiagnostic(
      'load.success',
      requestUri,
      surface: surface,
      byteLength: bytes.length,
      elapsed: DateTime.now().difference(startedAt),
    );
    return bytes;
  } on Object catch (error) {
    if (_shouldRetryRawCdnMedia(
      error: error,
      requestUri: requestUri,
      rawUri: uri,
    )) {
      _recordServerMediaDiagnostic(
        'load.retryRaw',
        requestUri,
        surface: surface,
        reason: _safeServerMediaReason(error),
        elapsed: DateTime.now().difference(startedAt),
      );
      try {
        final bytes = await _loadServerMediaUri(
          uri,
          policy: policy,
          surface: surface,
          loader: loader,
        );
        _recordServerMediaDiagnostic(
          'load.success',
          uri,
          surface: surface,
          byteLength: bytes.length,
          elapsed: DateTime.now().difference(startedAt),
        );
        return bytes;
      } on Object catch (rawError) {
        _recordServerMediaDiagnostic(
          'load.failure',
          uri,
          surface: surface,
          reason: _safeServerMediaReason(rawError),
          elapsed: DateTime.now().difference(startedAt),
        );
        rethrow;
      }
    }
    _recordServerMediaDiagnostic(
      'load.failure',
      requestUri,
      surface: surface,
      reason: _safeServerMediaReason(error),
      elapsed: DateTime.now().difference(startedAt),
    );
    rethrow;
  }
}

Future<Uint8List> _loadServerMediaUri(
  Uri uri, {
  required ServerMediaPolicy policy,
  required ServerMediaSurface surface,
  ServerMediaWidgetLoader? loader,
}) {
  if (loader != null) {
    return loader(uri, policy: policy, maxBytes: surface.maxBytes);
  }
  return _serverMediaLoader.load(
    uri,
    policy: policy,
    maxBytes: surface.maxBytes,
  );
}

void _applyWorkspaceImageCacheBudget() {
  final imageCache = PaintingBinding.instance.imageCache;
  if (imageCache.maximumSize > _workspaceImageCacheMaxEntries) {
    imageCache.maximumSize = _workspaceImageCacheMaxEntries;
  }
  if (imageCache.maximumSizeBytes > _workspaceImageCacheMaxBytes) {
    imageCache.maximumSizeBytes = _workspaceImageCacheMaxBytes;
  }
}

final class _ServerMediaCacheKey {
  const _ServerMediaCacheKey({
    required this.uri,
    required this.policy,
    required this.surface,
  });

  final Uri uri;
  final ServerMediaPolicy policy;
  final ServerMediaSurface surface;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _ServerMediaCacheKey &&
            uri == other.uri &&
            policy == other.policy &&
            surface == other.surface;
  }

  @override
  int get hashCode => Object.hash(uri, policy, surface);
}

final class _ServerMediaBytesCache {
  _ServerMediaBytesCache({required this.maxEntries, required this.maxBytes})
    : assert(maxEntries > 0),
      assert(maxBytes > 0);

  final int maxEntries;
  final int maxBytes;
  final _entries = <_ServerMediaCacheKey, Uint8List>{};
  final _pending = <_ServerMediaCacheKey, _PendingServerMediaLoad>{};
  int _totalBytes = 0;
  var _generation = 0;

  int get entryCount => _entries.length;

  int get totalBytes => _totalBytes;

  Uint8List? get(_ServerMediaCacheKey key) {
    final bytes = _entries.remove(key);
    if (bytes == null) {
      return null;
    }
    _entries[key] = bytes;
    return bytes;
  }

  Future<Uint8List> getOrLoad(
    _ServerMediaCacheKey key,
    Future<Uint8List> Function() loader,
  ) {
    final cached = get(key);
    if (cached != null) {
      return SynchronousFuture(cached);
    }
    final pending = _pending[key];
    if (pending != null) {
      pending.retain();
      return pending.future;
    }

    final generation = _generation;
    final sharedLoad = _PendingServerMediaLoad();
    sharedLoad.retain();
    final shared = loader()
        .then((bytes) {
          if (generation == _generation && sharedLoad.hasListeners) {
            put(key, bytes);
          }
          return bytes;
        })
        .whenComplete(() {
          if (identical(_pending[key], sharedLoad)) {
            _pending.remove(key);
          }
        });
    sharedLoad.future = shared;
    _pending[key] = sharedLoad;
    return sharedLoad.future;
  }

  void releasePending(_ServerMediaCacheKey key, Future<Uint8List> future) {
    final pending = _pending[key];
    if (pending == null || !identical(pending.future, future)) {
      return;
    }
    pending.release();
  }

  void put(_ServerMediaCacheKey key, Uint8List bytes) {
    final existing = _entries.remove(key);
    if (existing != null) {
      _totalBytes -= existing.lengthInBytes;
    }
    if (bytes.lengthInBytes > maxBytes) {
      _evictToBudget();
      return;
    }
    _entries[key] = bytes;
    _totalBytes += bytes.lengthInBytes;
    _evictToBudget();
  }

  void clear() {
    _entries.clear();
    _pending.clear();
    _totalBytes = 0;
    _generation += 1;
  }

  void _evictToBudget() {
    while (_entries.length > maxEntries || _totalBytes > maxBytes) {
      final oldestKey = _entries.keys.first;
      final oldestValue = _entries.remove(oldestKey);
      if (oldestValue == null) {
        continue;
      }
      _totalBytes -= oldestValue.lengthInBytes;
    }
  }
}

final class _PendingServerMediaLoad {
  late Future<Uint8List> future;
  var _listeners = 0;

  bool get hasListeners => _listeners > 0;

  void retain() {
    _listeners += 1;
  }

  void release() {
    if (_listeners > 0) {
      _listeners -= 1;
    }
  }
}

enum ServerMediaSurface {
  image('image', 8 * 1024 * 1024),
  serverIcon('serverIcon', 8 * 1024 * 1024),
  serverBanner('serverBanner', 16 * 1024 * 1024);

  const ServerMediaSurface(this.diagnosticName, this.maxBytes);

  final String diagnosticName;
  final int maxBytes;
}

Uri _cdnTransformedMediaUri(Uri uri, ServerMediaSurface surface) {
  if (!_isCloudflareImageHost(uri.host) ||
      uri.path.startsWith('/cdn-cgi/image/') ||
      surface == ServerMediaSurface.image) {
    return uri;
  }
  final params = switch (surface) {
    ServerMediaSurface.serverIcon =>
      'width=256,height=256,fit=cover,format=auto,metadata=none',
    ServerMediaSurface.serverBanner =>
      'width=1200,fit=scale-down,format=auto,metadata=none',
    ServerMediaSurface.image => '',
  };
  return uri.replace(path: '/cdn-cgi/image/$params${uri.path}');
}

bool _isCloudflareImageHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'cdn.pryzmapp.com' || normalized == 'cdn.verdant.chat';
}

bool _shouldRetryRawCdnMedia({
  required Object error,
  required Uri requestUri,
  required Uri rawUri,
}) {
  return requestUri != rawUri &&
      _isCloudflareImageHost(requestUri.host) &&
      error is ServerMediaLoadException &&
      error.statusCode == 400;
}

void _recordServerMediaDiagnostic(
  String event,
  Uri uri, {
  required ServerMediaSurface surface,
  String? reason,
  int? byteLength,
  Duration? elapsed,
  Map<String, Object?> extra = const {},
}) {
  if (!verdantClientDiagnosticsEnabled) {
    return;
  }
  final fields = <String, Object?>{
    'surface': surface.diagnosticName,
    'origin': _originForDiagnostic(uri),
    'pathRoot': _pathRootForDiagnostic(uri),
    'extension': _extensionForDiagnostic(uri),
  };
  if (verdantClientMediaUrlDiagnosticsEnabled) {
    fields['url'] = uri.toString();
  }
  if (reason != null) {
    fields['reason'] = reason;
  }
  if (byteLength != null) {
    fields['bytes'] = byteLength;
  }
  if (elapsed != null) {
    fields['ms'] = elapsed.inMilliseconds;
  }
  fields.addAll(extra);
  debugPrint('verdant.media $event $fields');
}

void _recordServerMediaBatchDiagnostic(
  String event,
  Map<String, Object?> fields,
) {
  if (!verdantClientDiagnosticsEnabled) {
    return;
  }
  debugPrint('verdant.media $event ${sanitizeAuthDiagnosticFields(fields)}');
}

void _recordStaticFrameDiagnostic(
  String event, {
  required String widgetName,
  required ImageProvider imageProvider,
  Key? key,
  double? width,
  double? height,
  bool? hasFrame,
  bool? synchronousCall,
  int? imageWidth,
  int? imageHeight,
  bool? providerChanged,
  Map<String, Object?> extra = const {},
}) {
  if (!verdantClientDiagnosticsEnabled) {
    return;
  }
  final fields = <String, Object?>{
    'widget': widgetName,
    'keyType': key?.runtimeType.toString() ?? 'none',
    'keyHash': key == null ? 0 : identityHashCode(key),
    'providerType': imageProvider.runtimeType.toString(),
    'providerHash': identityHashCode(imageProvider),
  };
  if (width != null) {
    fields['width'] = width.round();
  }
  if (height != null) {
    fields['height'] = height.round();
  }
  if (hasFrame != null) {
    fields['hasFrame'] = hasFrame;
  }
  if (synchronousCall != null) {
    fields['synchronousCall'] = synchronousCall;
  }
  if (imageWidth != null) {
    fields['imageWidth'] = imageWidth;
  }
  if (imageHeight != null) {
    fields['imageHeight'] = imageHeight;
  }
  if (providerChanged != null) {
    fields['providerChanged'] = providerChanged;
  }
  fields.addAll(extra);
  debugPrint('verdant.media.staticFrame $event $fields');
}

String _safeServerMediaReason(Object error) {
  if (error is ServerMediaLoadException) {
    return error.message;
  }
  return error.runtimeType.toString();
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

String _extensionForDiagnostic(Uri uri) {
  if (uri.pathSegments.isEmpty) {
    return 'none';
  }
  final last = uri.pathSegments.last.toLowerCase();
  final dot = last.lastIndexOf('.');
  if (dot < 0 || dot == last.length - 1) {
    return 'none';
  }
  final extension = last.substring(dot + 1);
  return extension.length <= 12 ? extension : 'long';
}

class CroppedServerBannerImage extends StatelessWidget {
  const CroppedServerBannerImage({
    required this.imageProvider,
    this.crop,
    this.imageKey,
    this.animate = false,
    super.key,
  });

  final ImageProvider imageProvider;
  final BannerCrop? crop;
  final Key? imageKey;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final focused = WindowFocusScope.isFocusedOf(context);
    if (!animate || !focused) {
      return CroppedStaticFirstFrameBannerImage(
        key: imageKey,
        imageProvider: imageProvider,
        crop: crop,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rect = bannerCropPreviewRect(size, crop);
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: rect,
                child: Image(
                  key: imageKey,
                  image: imageProvider,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return const BlankServerBannerCanvas();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ServerMediaIcon extends StatelessWidget {
  const ServerMediaIcon({
    required this.name,
    required this.iconUrl,
    required this.mediaPolicy,
    required this.size,
    this.showBorder = true,
    this.animate = false,
    this.imageKey,
    this.borderRadius,
    super.key,
  });

  final String name;
  final String? iconUrl;
  final ServerMediaPolicy mediaPolicy;
  final double size;
  final bool showBorder;
  final bool animate;
  final Key? imageKey;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final iconUri = safeServerMediaUri(iconUrl, policy: mediaPolicy);
    final effectiveAnimate = animate && WindowFocusScope.isFocusedOf(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF062A22),
        borderRadius: borderRadius,
        border: showBorder ? Border.all(color: colors.accentStrong) : null,
      ),
      child: iconUri == null
          ? ServerIconInitials(name: name, size: size)
          : SafeServerMediaImage(
              uri: iconUri,
              policy: mediaPolicy,
              surface: ServerMediaSurface.serverIcon,
              retainWhenUnfocused: true,
              fallback: ServerIconInitials(name: name, size: size),
              builder: (context, imageProvider) {
                if (effectiveAnimate) {
                  return Image(
                    key: imageKey,
                    image: imageProvider,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  );
                }
                return StaticFirstFrameImage(
                  key: imageKey,
                  imageProvider: imageProvider,
                  width: size,
                  height: size,
                );
              },
              frozenBuilder: (context, imageProvider, bytes) {
                return StaticFirstFrameImage(
                  key: imageKey,
                  imageProvider: imageProvider,
                  width: size,
                  height: size,
                );
              },
            ),
    );
  }
}

class StaticFirstFrameImage extends StatefulWidget {
  const StaticFirstFrameImage({
    required this.imageProvider,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final ImageProvider imageProvider;
  final double width;
  final double height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  State<StaticFirstFrameImage> createState() => _StaticFirstFrameImageState();
}

class _StaticFirstFrameImageState extends State<StaticFirstFrameImage> {
  ImageStream? _stream;
  ImageInfo? _firstFrame;
  late final ImageStreamListener _listener;
  String? _lastBuildDiagnosticSignature;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_handleImage);
    _recordStaticFrameDiagnostic(
      'init',
      widgetName: 'StaticFirstFrameImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      width: widget.width,
      height: widget.height,
      hasFrame: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null && _firstFrame == null) {
      _resolveImage();
    }
  }

  @override
  void didUpdateWidget(covariant StaticFirstFrameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _recordStaticFrameDiagnostic(
        'providerChanged',
        widgetName: 'StaticFirstFrameImage',
        key: widget.key,
        imageProvider: widget.imageProvider,
        width: widget.width,
        height: widget.height,
        hasFrame: _firstFrame != null,
        providerChanged: true,
        extra: {'oldProviderHash': identityHashCode(oldWidget.imageProvider)},
      );
      _stopListening();
      _firstFrame?.dispose();
      _firstFrame = null;
      _lastBuildDiagnosticSignature = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _recordStaticFrameDiagnostic(
      'dispose',
      widgetName: 'StaticFirstFrameImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      width: widget.width,
      height: widget.height,
      hasFrame: _firstFrame != null,
    );
    _stopListening();
    _firstFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _firstFrame;
    if (frame == null) {
      _recordBuildBranch('buildPending');
      return SizedBox(width: widget.width, height: widget.height);
    }
    _recordBuildBranch(
      'buildFrame',
      imageWidth: frame.image.width,
      imageHeight: frame.image.height,
    );
    return RawImage(
      image: frame.image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
    );
  }

  void _resolveImage() {
    _recordStaticFrameDiagnostic(
      'resolve',
      widgetName: 'StaticFirstFrameImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      width: widget.width,
      height: widget.height,
      hasFrame: _firstFrame != null,
    );
    final stream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    _stream = stream;
    stream.addListener(_listener);
  }

  void _stopListening() {
    _stream?.removeListener(_listener);
    _stream = null;
  }

  void _handleImage(ImageInfo image, bool synchronousCall) {
    if (_firstFrame != null) {
      _recordStaticFrameDiagnostic(
        'extraFrame',
        widgetName: 'StaticFirstFrameImage',
        key: widget.key,
        imageProvider: widget.imageProvider,
        width: widget.width,
        height: widget.height,
        hasFrame: true,
        synchronousCall: synchronousCall,
        imageWidth: image.image.width,
        imageHeight: image.image.height,
      );
      image.dispose();
      _stopListening();
      return;
    }
    _recordStaticFrameDiagnostic(
      'resolved',
      widgetName: 'StaticFirstFrameImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      width: widget.width,
      height: widget.height,
      hasFrame: false,
      synchronousCall: synchronousCall,
      imageWidth: image.image.width,
      imageHeight: image.image.height,
    );
    setState(() {
      _firstFrame = image;
    });
    _stopListening();
  }

  void _recordBuildBranch(String event, {int? imageWidth, int? imageHeight}) {
    final signature = [
      event,
      identityHashCode(widget.imageProvider),
      widget.width.round(),
      widget.height.round(),
      _firstFrame != null,
      imageWidth ?? -1,
      imageHeight ?? -1,
    ].join('|');
    if (signature == _lastBuildDiagnosticSignature) {
      return;
    }
    _lastBuildDiagnosticSignature = signature;
    _recordStaticFrameDiagnostic(
      event,
      widgetName: 'StaticFirstFrameImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      width: widget.width,
      height: widget.height,
      hasFrame: _firstFrame != null,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }
}

class CroppedStaticFirstFrameBannerImage extends StatefulWidget {
  const CroppedStaticFirstFrameBannerImage({
    required this.imageProvider,
    this.crop,
    super.key,
  });

  final ImageProvider imageProvider;
  final BannerCrop? crop;

  @override
  State<CroppedStaticFirstFrameBannerImage> createState() =>
      _CroppedStaticFirstFrameBannerImageState();
}

class _CroppedStaticFirstFrameBannerImageState
    extends State<CroppedStaticFirstFrameBannerImage> {
  ImageStream? _stream;
  ImageInfo? _firstFrame;
  late final ImageStreamListener _listener;
  String? _lastBuildDiagnosticSignature;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_handleImage);
    _recordStaticFrameDiagnostic(
      'init',
      widgetName: 'CroppedStaticFirstFrameBannerImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      hasFrame: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null && _firstFrame == null) {
      _resolveImage();
    }
  }

  @override
  void didUpdateWidget(covariant CroppedStaticFirstFrameBannerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _recordStaticFrameDiagnostic(
        'providerChanged',
        widgetName: 'CroppedStaticFirstFrameBannerImage',
        key: widget.key,
        imageProvider: widget.imageProvider,
        hasFrame: _firstFrame != null,
        providerChanged: true,
        extra: {'oldProviderHash': identityHashCode(oldWidget.imageProvider)},
      );
      _stopListening();
      _firstFrame?.dispose();
      _firstFrame = null;
      _lastBuildDiagnosticSignature = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _recordStaticFrameDiagnostic(
      'dispose',
      widgetName: 'CroppedStaticFirstFrameBannerImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      hasFrame: _firstFrame != null,
    );
    _stopListening();
    _firstFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _firstFrame;
    if (frame == null) {
      _recordBuildBranch('buildPending');
      return const SizedBox.expand();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _recordBuildBranch(
          'buildFrame',
          width: size.width,
          height: size.height,
          imageWidth: frame.image.width,
          imageHeight: frame.image.height,
        );
        final rect = bannerCropPreviewRect(size, widget.crop);
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: rect,
                child: RawImage(image: frame.image, fit: BoxFit.fill),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resolveImage() {
    _recordStaticFrameDiagnostic(
      'resolve',
      widgetName: 'CroppedStaticFirstFrameBannerImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      hasFrame: _firstFrame != null,
    );
    final stream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    _stream = stream;
    stream.addListener(_listener);
  }

  void _stopListening() {
    _stream?.removeListener(_listener);
    _stream = null;
  }

  void _handleImage(ImageInfo image, bool synchronousCall) {
    if (_firstFrame != null) {
      _recordStaticFrameDiagnostic(
        'extraFrame',
        widgetName: 'CroppedStaticFirstFrameBannerImage',
        key: widget.key,
        imageProvider: widget.imageProvider,
        hasFrame: true,
        synchronousCall: synchronousCall,
        imageWidth: image.image.width,
        imageHeight: image.image.height,
      );
      image.dispose();
      _stopListening();
      return;
    }
    _recordStaticFrameDiagnostic(
      'resolved',
      widgetName: 'CroppedStaticFirstFrameBannerImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      hasFrame: false,
      synchronousCall: synchronousCall,
      imageWidth: image.image.width,
      imageHeight: image.image.height,
    );
    setState(() {
      _firstFrame = image;
    });
    _stopListening();
  }

  void _recordBuildBranch(
    String event, {
    double? width,
    double? height,
    int? imageWidth,
    int? imageHeight,
  }) {
    final signature = [
      event,
      identityHashCode(widget.imageProvider),
      width?.round() ?? -1,
      height?.round() ?? -1,
      _firstFrame != null,
      imageWidth ?? -1,
      imageHeight ?? -1,
    ].join('|');
    if (signature == _lastBuildDiagnosticSignature) {
      return;
    }
    _lastBuildDiagnosticSignature = signature;
    _recordStaticFrameDiagnostic(
      event,
      widgetName: 'CroppedStaticFirstFrameBannerImage',
      key: widget.key,
      imageProvider: widget.imageProvider,
      width: width,
      height: height,
      hasFrame: _firstFrame != null,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }
}

class ServerIconInitials extends StatelessWidget {
  const ServerIconInitials({required this.name, required this.size, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Text(
      serverInitials(name),
      style: TextStyle(
        color: colors.accentStrong,
        fontWeight: VerdantFontWeights.black,
        fontSize: size * 0.28,
      ),
    );
  }
}

class BlankServerBannerCanvas extends StatelessWidget {
  const BlankServerBannerCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return ColoredBox(color: colors.panel);
  }
}

String serverInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (compact.length >= 2) {
    return compact.substring(0, 2).toUpperCase();
  }
  return compact.toUpperCase();
}
