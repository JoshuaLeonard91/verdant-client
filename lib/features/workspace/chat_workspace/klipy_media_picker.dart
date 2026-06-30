import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/workspace_render_diagnostics.dart';
import 'klipy_media_repository.dart';

class KlipyMediaPicker extends StatefulWidget {
  const KlipyMediaPicker({
    required this.repository,
    required this.mediaPolicy,
    required this.onSelected,
    super.key,
  });

  final KlipyMediaRepository repository;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<KlipyMediaItem> onSelected;

  @override
  State<KlipyMediaPicker> createState() => _KlipyMediaPickerState();
}

class _KlipyMediaPickerState extends State<KlipyMediaPicker> {
  final _searchController = TextEditingController();
  final _homeScrollController = ScrollController();
  final _resultsScrollController = ScrollController();
  Timer? _searchDebounce;
  var _type = KlipyMediaType.gif;
  var _homeCategories = const <KlipyMediaCategory>[];
  String? _trendingPreviewUrl;
  var _view = _KlipyPickerView.home;
  String? _resultTitle;
  String _resultQuery = '';
  var _items = const <KlipyMediaItem>[];
  var _favorites = const <KlipyMediaItem>[];
  var _loading = true;
  String? _error;
  var _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFavorites());
    unawaited(_loadHome());
  }

  @override
  void dispose() {
    _loadGeneration += 1;
    _searchDebounce?.cancel();
    _searchController.dispose();
    _homeScrollController.dispose();
    _resultsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('klipy-picker-popover'),
      width: 394,
      height: 404,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VerdantColors.panelRaised,
          border: Border.all(color: VerdantColors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  if (_view == _KlipyPickerView.results) ...[
                    IconButton(
                      key: const ValueKey('klipy-picker-back-button'),
                      tooltip: 'Back',
                      onPressed: _showHome,
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: VerdantColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: TextField(
                      key: const ValueKey('klipy-picker-search-field'),
                      controller: _searchController,
                      onChanged: _queueSearch,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: VerdantColors.textMuted,
                          size: 18,
                        ),
                        hintText: 'Search ${_type.label}s',
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        filled: true,
                        fillColor: VerdantColors.panel,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: VerdantRadii.sharp,
                          borderSide: BorderSide(color: VerdantColors.border),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: VerdantRadii.sharp,
                          borderSide: BorderSide(color: VerdantColors.border),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: VerdantRadii.sharp,
                          borderSide: BorderSide(color: VerdantColors.action),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _view == _KlipyPickerView.home
                        ? 'KLIPY'
                        : _resultTitle ?? _type.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: VerdantColors.accentStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final type = KlipyMediaType.values[index];
                  return _KlipyTab(
                    key: ValueKey('klipy-picker-tab-${type.name}'),
                    label: type.label,
                    selected: type == _type,
                    onTap: () {
                      if (type == _type) {
                        return;
                      }
                      setState(() {
                        _type = type;
                        _items = const [];
                        _view = _KlipyPickerView.home;
                        _resultQuery = '';
                        _resultTitle = null;
                        _searchController.clear();
                      });
                      unawaited(_loadHome());
                    },
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemCount: KlipyMediaType.values.length,
              ),
            ),
            const Divider(height: 1, color: VerdantColors.border),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        key: ValueKey('klipy-picker-loading'),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final error = _error;
    if (error != null) {
      return Center(
        key: const ValueKey('klipy-picker-error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    if (_view == _KlipyPickerView.home) {
      return _KlipyHomeGrid(
        type: _type,
        categories: _homeCategories,
        favoritesPreviewUrl: _favoritesForType.isEmpty
            ? null
            : _favoritesForType.first.previewUrl,
        trendingPreviewUrl: _trendingPreviewUrl,
        mediaPolicy: _klipyMediaPolicy(widget.mediaPolicy),
        scrollController: _homeScrollController,
        onOpenFavorites: _favoritesForType.isEmpty ? null : _openFavorites,
        onOpenTrending: () {
          _openResults(title: 'Trending ${_type.label}s', query: '');
        },
        onOpenCategory: (category) {
          _openResults(title: category.name, query: category.slug);
        },
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No ${_type.label.toLowerCase()} results',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return SmoothWheelScroll(
      controller: _resultsScrollController,
      child: GridView.builder(
        key: ValueKey('klipy-picker-results-${_type.name}-$_resultQuery'),
        controller: _resultsScrollController,
        padding: const EdgeInsets.all(12),
        scrollCacheExtent: const ScrollCacheExtent.pixels(120),
        addAutomaticKeepAlives: false,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _KlipyTile(
            key: ValueKey('klipy-picker-item-${item.id}'),
            item: item,
            favorite: _isFavorite(item),
            mediaPolicy: _klipyMediaPolicy(widget.mediaPolicy),
            onFavorite: () => _toggleFavorite(item),
            onTap: () => widget.onSelected(item),
          );
        },
      ),
    );
  }

  void _queueSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        final query = _searchController.text.trim();
        if (query.isEmpty) {
          _showHome();
        } else {
          _openResults(title: 'Search', query: query);
        }
      }
    });
  }

  void _showHome() {
    _loadGeneration += 1;
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_homeCategories.isNotEmpty || _trendingPreviewUrl != null) {
      setState(() {
        _view = _KlipyPickerView.home;
        _resultTitle = null;
        _resultQuery = '';
        _items = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _view = _KlipyPickerView.home;
      _resultTitle = null;
      _resultQuery = '';
      _items = const [];
    });
    unawaited(_loadHome());
  }

  void _openFavorites() {
    _loadGeneration += 1;
    setState(() {
      _view = _KlipyPickerView.results;
      _resultTitle = 'Favorite ${_type.label}s';
      _resultQuery = '__favorites__';
      _items = _favoritesForType;
      _loading = false;
      _error = null;
    });
    if (_resultsScrollController.hasClients) {
      _resultsScrollController.jumpTo(0);
    }
  }

  void _openResults({required String title, required String query}) {
    setState(() {
      _view = _KlipyPickerView.results;
      _resultTitle = title;
      _resultQuery = query;
      _items = const [];
    });
    unawaited(_loadResults(query));
  }

  Future<void> _loadHome() async {
    final generation = ++_loadGeneration;
    final type = _type;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        widget.repository.loadCategories(type: _type),
        widget.repository.loadTrendingPreview(type: _type),
      ]);
      if (!mounted || generation != _loadGeneration || type != _type) {
        return;
      }
      setState(() {
        _homeCategories = results[0] as List<KlipyMediaCategory>;
        _trendingPreviewUrl = results[1] as String?;
        _loading = false;
      });
    } on KlipyMediaException catch (error) {
      if (!mounted || generation != _loadGeneration || type != _type) {
        return;
      }
      setState(() {
        if (_homeCategories.isNotEmpty || _trendingPreviewUrl != null) {
          _error = null;
        } else {
          _error = _klipyErrorMessage(error);
        }
        _loading = false;
      });
    } on Object {
      if (!mounted || generation != _loadGeneration || type != _type) {
        return;
      }
      setState(() {
        if (_homeCategories.isNotEmpty || _trendingPreviewUrl != null) {
          _error = null;
        } else {
          _error = 'Could not load Klipy media';
        }
        _loading = false;
      });
    }
  }

  Future<void> _loadResults(String query) async {
    final generation = ++_loadGeneration;
    final type = _type;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.load(type: _type, query: query);
      if (!mounted ||
          generation != _loadGeneration ||
          type != _type ||
          query != _resultQuery) {
        return;
      }
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } on KlipyMediaException catch (error) {
      if (!mounted || generation != _loadGeneration || type != _type) {
        return;
      }
      setState(() {
        _error = _klipyErrorMessage(error);
        _loading = false;
      });
    } on Object {
      if (!mounted || generation != _loadGeneration || type != _type) {
        return;
      }
      setState(() {
        _error = 'Could not load Klipy media';
        _loading = false;
      });
    }
  }

  List<KlipyMediaItem> get _favoritesForType {
    return _favorites
        .where((item) => item.type == _type)
        .toList(growable: false);
  }

  bool _isFavorite(KlipyMediaItem item) {
    return _favorites.any(
      (favorite) => favorite.id == item.id && favorite.type == item.type,
    );
  }

  Future<void> _loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_klipyFavoritesStorageKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return;
      }
      final favorites = [
        for (final item in decoded)
          if (_mapValue(item) case final row?) ?_itemFromFavoriteJson(row),
      ];
      if (mounted) {
        setState(() => _favorites = favorites);
      }
    } on Object {
      // Ignore corrupt local picker cache; it does not affect auth or routing.
    }
  }

  Future<void> _toggleFavorite(KlipyMediaItem item) async {
    final exists = _isFavorite(item);
    final next = exists
        ? _favorites
              .where(
                (favorite) =>
                    favorite.id != item.id || favorite.type != item.type,
              )
              .toList(growable: false)
        : [item, ..._favorites].take(80).toList(growable: false);
    setState(() {
      _favorites = next;
      if (_resultQuery == '__favorites__') {
        _items = _favoritesForType;
      }
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _klipyFavoritesStorageKey,
      jsonEncode([for (final favorite in next) _itemToFavoriteJson(favorite)]),
    );
  }
}

enum _KlipyPickerView { home, results }

class _KlipyTab extends StatelessWidget {
  const _KlipyTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: VerdantColors.desktopHoverOverlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? VerdantColors.actionMuted : Colors.transparent,
          border: Border.all(
            color: selected ? VerdantColors.action : VerdantColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? VerdantColors.accentStrong : VerdantColors.text,
          ),
        ),
      ),
    );
  }
}

class _KlipyTile extends StatelessWidget {
  const _KlipyTile({
    required this.item,
    required this.favorite,
    required this.mediaPolicy,
    required this.onFavorite,
    required this.onTap,
    super.key,
  });

  final KlipyMediaItem item;
  final bool favorite;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uri = safeServerMediaUri(item.previewUrl, policy: mediaPolicy);
    final fallback = _KlipyFallback(item: item);
    return WorkspaceRenderProbe(
      surface: 'klipyTile',
      id: item.id,
      fields: {
        'type': item.type.name,
        'favorite': favorite,
        'urlAccepted': uri != null,
        ...renderMediaUrlFields(item.previewUrl),
      },
      child: Semantics(
        button: true,
        label: item.title,
        child: InkWell(
          onTap: onTap,
          hoverColor: VerdantColors.desktopHoverOverlay,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: VerdantColors.background,
              border: Border.all(color: VerdantColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (uri == null)
                  fallback
                else
                  SafeServerMediaImage(
                    uri: uri,
                    policy: mediaPolicy,
                    surface: ServerMediaSurface.image,
                    fallback: fallback,
                    builder: (context, imageProvider) =>
                        _HoverAnimatedKlipyImage(
                          imageProvider: imageProvider,
                          label: item.title,
                          diagnosticId: item.id,
                          diagnosticType: item.type.name,
                          diagnosticUrl: item.previewUrl,
                        ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _FavoriteButton(favorite: favorite, onTap: onFavorite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KlipyHomeGrid extends StatelessWidget {
  const _KlipyHomeGrid({
    required this.type,
    required this.categories,
    required this.favoritesPreviewUrl,
    required this.trendingPreviewUrl,
    required this.mediaPolicy,
    required this.scrollController,
    required this.onOpenFavorites,
    required this.onOpenTrending,
    required this.onOpenCategory,
  });

  final KlipyMediaType type;
  final List<KlipyMediaCategory> categories;
  final String? favoritesPreviewUrl;
  final String? trendingPreviewUrl;
  final ServerMediaPolicy mediaPolicy;
  final ScrollController scrollController;
  final VoidCallback? onOpenFavorites;
  final VoidCallback onOpenTrending;
  final ValueChanged<KlipyMediaCategory> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (onOpenFavorites != null)
        _KlipyCategoryTile(
          key: ValueKey('klipy-picker-favorites-${type.name}'),
          label: 'Favorites',
          imageUrl: favoritesPreviewUrl,
          mediaPolicy: mediaPolicy,
          icon: Icons.star,
          onTap: onOpenFavorites!,
        ),
      _KlipyCategoryTile(
        key: ValueKey('klipy-picker-trending-${type.name}'),
        label: 'Trending ${type.label}s',
        imageUrl: trendingPreviewUrl,
        mediaPolicy: mediaPolicy,
        icon: Icons.local_fire_department,
        onTap: onOpenTrending,
      ),
      for (final category in categories)
        _KlipyCategoryTile(
          key: ValueKey('klipy-picker-category-${category.slug}'),
          label: category.name,
          imageUrl: category.imageUrl,
          mediaPolicy: mediaPolicy,
          icon: Icons.image,
          onTap: () => onOpenCategory(category),
        ),
    ];

    if (tiles.length == 1) {
      return Center(
        child: Text(
          'No categories found',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return SmoothWheelScroll(
      controller: scrollController,
      child: GridView.builder(
        key: ValueKey('klipy-picker-home-${type.name}'),
        controller: scrollController,
        padding: const EdgeInsets.all(12),
        scrollCacheExtent: const ScrollCacheExtent.pixels(120),
        addAutomaticKeepAlives: false,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.52,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) => tiles[index],
      ),
    );
  }
}

class _KlipyCategoryTile extends StatelessWidget {
  const _KlipyCategoryTile({
    required this.label,
    required this.imageUrl,
    required this.mediaPolicy,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? imageUrl;
  final ServerMediaPolicy mediaPolicy;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uri = safeServerMediaUri(imageUrl, policy: mediaPolicy);
    final fallback = ColoredBox(
      color: VerdantColors.background,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
    return WorkspaceRenderProbe(
      surface: 'klipyCategoryTile',
      id: label,
      fields: {'urlAccepted': uri != null, ...renderMediaUrlFields(imageUrl)},
      child: InkWell(
        onTap: onTap,
        hoverColor: VerdantColors.desktopHoverOverlay,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: VerdantColors.background,
            border: Border.all(color: VerdantColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (uri == null)
                fallback
              else
                SafeServerMediaImage(
                  uri: uri,
                  policy: mediaPolicy,
                  surface: ServerMediaSurface.image,
                  fallback: fallback,
                  builder: (context, imageProvider) => _HoverAnimatedKlipyImage(
                    imageProvider: imageProvider,
                    label: label,
                    diagnosticId: label,
                    diagnosticType: 'category',
                    diagnosticUrl: imageUrl,
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0x00000000),
                      VerdantColors.background.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: VerdantColors.accentStrong),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: VerdantColors.text,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 8),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.favorite, required this.onTap});

  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: favorite ? 'Remove favorite' : 'Add favorite',
      child: InkResponse(
        key: const ValueKey('klipy-picker-favorite-button'),
        onTap: onTap,
        radius: 18,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: favorite
                ? const Color(0xCCFFD65A)
                : VerdantColors.background.withValues(alpha: 0.82),
            border: Border.all(
              color: favorite ? const Color(0xFFFFD65A) : VerdantColors.border,
            ),
          ),
          child: Icon(
            favorite ? Icons.star : Icons.star_border,
            size: 16,
            color: favorite ? Colors.black : VerdantColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _HoverAnimatedKlipyImage extends StatefulWidget {
  const _HoverAnimatedKlipyImage({
    required this.imageProvider,
    required this.label,
    required this.diagnosticId,
    required this.diagnosticType,
    required this.diagnosticUrl,
  });

  final ImageProvider imageProvider;
  final String label;
  final String diagnosticId;
  final String diagnosticType;
  final String? diagnosticUrl;

  @override
  State<_HoverAnimatedKlipyImage> createState() =>
      _HoverAnimatedKlipyImageState();
}

class _HoverAnimatedKlipyImageState extends State<_HoverAnimatedKlipyImage> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return WorkspaceRenderProbe(
      surface: 'klipyAnimatedImage',
      id: widget.diagnosticId,
      fields: {
        'type': widget.diagnosticType,
        'hovered': _hovered,
        ...renderMediaUrlFields(widget.diagnosticUrl),
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 140.0;
            final height = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 100.0;
            if (!_hovered) {
              return StaticFirstFrameImage(
                imageProvider: widget.imageProvider,
                width: width,
                height: height,
              );
            }
            return Image(
              image: widget.imageProvider,
              fit: BoxFit.cover,
              width: width,
              height: height,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              semanticLabel: widget.label,
            );
          },
        ),
      ),
    );
  }
}

class _KlipyFallback extends StatelessWidget {
  const _KlipyFallback({required this.item});

  final KlipyMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.type.label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: VerdantColors.accentStrong),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

ServerMediaPolicy _klipyMediaPolicy(ServerMediaPolicy base) {
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

KlipyMediaType _mediaTypeFromJson(
  Object? value, {
  required KlipyMediaType fallback,
}) {
  if (value is! String) {
    return fallback;
  }
  for (final type in KlipyMediaType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return fallback;
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}

String _stringValue(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

int _intValue(Object? value, {required int fallback}) {
  return value is num ? value.toInt() : fallback;
}

Map<String, Object?> _itemToFavoriteJson(KlipyMediaItem item) {
  return {
    'id': item.id,
    'title': item.title,
    'type': item.type.name,
    'previewUrl': item.previewUrl,
    'originalUrl': item.originalUrl,
    'width': item.width,
    'height': item.height,
  };
}

KlipyMediaItem? _itemFromFavoriteJson(Map<String, Object?> json) {
  final type = _mediaTypeFromJson(json['type'], fallback: KlipyMediaType.gif);
  final previewUrl = _nullableString(json['previewUrl']);
  final originalUrl = _nullableString(json['originalUrl']);
  if (previewUrl == null || originalUrl == null) {
    return null;
  }
  return KlipyMediaItem(
    id: _stringValue(json['id'], fallback: originalUrl),
    title: _stringValue(json['title'], fallback: type.label),
    type: type,
    previewUrl: previewUrl,
    originalUrl: originalUrl,
    width: _intValue(json['width'], fallback: 320),
    height: _intValue(json['height'], fallback: 240),
  );
}

const _klipyFavoritesStorageKey = 'verdant:flutter:klipy-favorites:v1';

String _klipyErrorMessage(KlipyMediaException error) {
  final message = error.message.trim();
  return message.isEmpty ? 'Could not load Klipy media' : message;
}
