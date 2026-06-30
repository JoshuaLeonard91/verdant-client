import 'dart:async';
import 'dart:math' as math;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/workspace_render_diagnostics.dart';
import 'custom_expression_server_icon.dart';

enum _EmojiPickerPane { emoji, stickers }

class EmojiPickerPopover extends StatefulWidget {
  const EmojiPickerPopover({
    required this.onSelected,
    required this.mediaPolicy,
    this.customEmojis = const [],
    this.customEmojiGroups = const [],
    this.customStickers = const [],
    this.customStickerGroups = const [],
    super.key,
  });

  final ValueChanged<String> onSelected;
  final ServerMediaPolicy mediaPolicy;
  final List<ServerCustomEmoji> customEmojis;
  final List<ServerCustomEmojiGroup> customEmojiGroups;
  final List<ServerCustomSticker> customStickers;
  final List<ServerCustomStickerGroup> customStickerGroups;

  @override
  State<EmojiPickerPopover> createState() => _EmojiPickerPopoverState();
}

class _EmojiPickerPopoverState extends State<EmojiPickerPopover> {
  final _searchController = TextEditingController();
  final _gridController = ScrollController();
  late final List<CategoryEmoji> _categories;
  var _sectionOffsets = <String, double>{};
  String? _selectedSectionKey;
  String? _programmaticScrollSectionKey;
  var _programmaticScrollGeneration = 0;
  var _activePane = _EmojiPickerPane.emoji;

  List<ServerCustomEmojiGroup> get _customEmojiGroups {
    final groups = widget.customEmojiGroups
        .where((group) => group.emojis.isNotEmpty)
        .toList(growable: false);
    if (groups.isNotEmpty) {
      return groups;
    }
    if (widget.customEmojis.isEmpty) {
      return const [];
    }
    final first = widget.customEmojis.first;
    return [
      ServerCustomEmojiGroup(
        serverId: first.serverId ?? 'active-server',
        networkId: first.networkId ?? 'active-network',
        label: 'Server emojis',
        emojis: widget.customEmojis,
      ),
    ];
  }

  List<ServerCustomStickerGroup> get _customStickerGroups {
    final groups = widget.customStickerGroups
        .where((group) => group.stickers.isNotEmpty)
        .toList(growable: false);
    if (groups.isNotEmpty) {
      return groups;
    }
    if (widget.customStickers.isEmpty) {
      return const [];
    }
    final first = widget.customStickers.first;
    return [
      ServerCustomStickerGroup(
        serverId: first.serverId ?? 'active-server',
        networkId: first.networkId ?? 'active-network',
        label: 'Server stickers',
        stickers: widget.customStickers,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _categories = defaultEmojiSet
        .where((category) => category.category != Category.RECENT)
        .toList(growable: false);
    _gridController.addListener(_syncSelectedCategoryToScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = sanitizeSearchInput(_searchController.text).toLowerCase();
    final customEmojiGroups = _customEmojiGroups;
    final customStickerGroups = _customStickerGroups;
    final hasCustomStickers = customStickerGroups.isNotEmpty;
    final searchItems = query.isEmpty
        ? const <_EmojiGridItem>[]
        : _searchItems(query);

    return SizedBox(
      key: const ValueKey('emoji-picker-popover'),
      width: 392,
      height: 414,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VerdantColors.panelRaised,
          border: Border.all(color: VerdantColors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: TextField(
                key: const ValueKey('emoji-picker-search-field'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: VerdantColors.textMuted,
                    size: 18,
                  ),
                  hintText: _activePane == _EmojiPickerPane.emoji
                      ? 'Search emojis...'
                      : 'Search stickers...',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: _EmojiPickerTabs(
                activePane: _activePane,
                hasStickers: hasCustomStickers,
                onChanged: _selectPane,
              ),
            ),
            const Divider(height: 1, color: VerdantColors.border),
            Expanded(
              child: _activePane == _EmojiPickerPane.emoji
                  ? _EmojiPane(
                      query: query,
                      searchItems: searchItems,
                      selectedSectionKey: query.isEmpty
                          ? _effectiveSelectedSectionKey(customEmojiGroups)
                          : null,
                      customRailItems: _customEmojiRailItems(customEmojiGroups),
                      controller: _gridController,
                      mediaPolicy: widget.mediaPolicy,
                      onSelected: widget.onSelected,
                      onSelectSection: _selectSection,
                      onBuildSections: (width) {
                        final sections = _emojiSections();
                        _sectionOffsets = _computeSectionOffsets(
                          sections: sections,
                          width: width,
                        );
                        return sections;
                      },
                    )
                  : _StickerPane(
                      query: query,
                      searchItems: searchItems,
                      sections: _stickerSections(),
                      controller: _gridController,
                      mediaPolicy: widget.mediaPolicy,
                      onSelected: widget.onSelected,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_EmojiSection> _emojiSections() {
    final customEmojiGroups = _customEmojiGroups;
    final sections = <_EmojiSection>[];
    for (var index = 0; index < customEmojiGroups.length; index += 1) {
      final group = customEmojiGroups[index];
      if (group.emojis.isEmpty) {
        continue;
      }
      sections.add(
        _EmojiSection(
          id: _customEmojiSectionKey(group, index),
          label: group.label,
          items: [
            for (final emoji in group.emojis)
              _EmojiGridItem.custom(emoji, mediaPolicy: group.mediaPolicy),
          ],
        ),
      );
    }
    for (final category in _categories) {
      sections.add(
        _EmojiSection(
          id: _categorySectionKey(category.category),
          label: _categoryLabel(category.category),
          items: [
            for (final emoji in category.emoji)
              _EmojiGridItem.unicode(emoji, _categoryKey(category.category)),
          ],
        ),
      );
    }
    return sections;
  }

  List<_EmojiSection> _stickerSections() {
    final customStickerGroups = _customStickerGroups;
    final sections = <_EmojiSection>[];
    for (var index = 0; index < customStickerGroups.length; index += 1) {
      final group = customStickerGroups[index];
      if (group.stickers.isEmpty) {
        continue;
      }
      sections.add(
        _EmojiSection(
          id: _customStickerSectionKey(group, index),
          label: _stickerSectionLabel(group.label),
          items: [
            for (final sticker in group.stickers)
              _EmojiGridItem.customSticker(
                sticker,
                mediaPolicy: group.mediaPolicy,
              ),
          ],
        ),
      );
    }
    return sections;
  }

  List<_EmojiGridItem> _searchItems(String query) {
    final matches = <_EmojiGridItem>[];
    if (_activePane == _EmojiPickerPane.stickers) {
      for (final group in _customStickerGroups) {
        for (final sticker in group.stickers) {
          if (sticker.name.toLowerCase().contains(query)) {
            matches.add(
              _EmojiGridItem.customSticker(
                sticker,
                mediaPolicy: group.mediaPolicy,
              ),
            );
            if (matches.length >= 80) {
              return matches;
            }
          }
        }
      }
      return matches;
    }

    for (final group in _customEmojiGroups) {
      for (final emoji in group.emojis) {
        if (emoji.name.toLowerCase().contains(query)) {
          matches.add(
            _EmojiGridItem.custom(emoji, mediaPolicy: group.mediaPolicy),
          );
          if (matches.length >= 140) {
            return matches;
          }
        }
      }
    }
    for (final category in _categories) {
      for (final emoji in category.emoji) {
        final name = emoji.name.toLowerCase();
        if (emoji.emoji == query || name.contains(query)) {
          matches.add(_EmojiGridItem.unicode(emoji, 'search'));
        }
        if (matches.length >= 140) {
          return matches;
        }
      }
    }
    return matches;
  }

  void _selectPane(_EmojiPickerPane pane) {
    if (_activePane == pane) {
      return;
    }
    setState(() {
      _activePane = pane;
      _searchController.clear();
      _sectionOffsets = {};
      _selectedSectionKey = null;
      _programmaticScrollSectionKey = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _gridController.hasClients) {
        _gridController.jumpTo(0);
      }
    });
  }

  void _selectSection(String sectionKey) {
    final generation = ++_programmaticScrollGeneration;
    setState(() {
      _selectedSectionKey = sectionKey;
      _programmaticScrollSectionKey = sectionKey;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gridController.hasClients) {
        _clearProgrammaticScroll(generation);
        return;
      }
      final target = (_sectionOffsets[sectionKey] ?? 0).clamp(
        _gridController.position.minScrollExtent,
        _gridController.position.maxScrollExtent,
      );
      unawaited(
        _gridController
            .animateTo(
              target.toDouble(),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOutCubic,
            )
            .whenComplete(() => _clearProgrammaticScroll(generation)),
      );
    });
  }

  void _syncSelectedCategoryToScroll() {
    if (_activePane != _EmojiPickerPane.emoji ||
        _programmaticScrollSectionKey != null ||
        _searchController.text.trim().isNotEmpty ||
        _sectionOffsets.isEmpty) {
      return;
    }
    final offset = _gridController.offset + 24;
    var active = _selectedSectionKey ?? _sectionOffsets.keys.first;
    for (final entry in _sectionOffsets.entries) {
      if (entry.value <= offset) {
        active = entry.key;
      } else {
        break;
      }
    }
    if (active != _selectedSectionKey && mounted) {
      setState(() => _selectedSectionKey = active);
    }
  }

  void _clearProgrammaticScroll(int generation) {
    if (!mounted || generation != _programmaticScrollGeneration) {
      return;
    }
    final target = _programmaticScrollSectionKey;
    setState(() {
      _programmaticScrollSectionKey = null;
      if (target != null) {
        _selectedSectionKey = target;
      }
    });
  }

  String _effectiveSelectedSectionKey(List<ServerCustomEmojiGroup> groups) {
    final selected = _selectedSectionKey;
    if (selected != null && _isKnownEmojiSectionKey(selected, groups)) {
      return selected;
    }
    if (groups.isNotEmpty) {
      return _customEmojiSectionKey(groups.first, 0);
    }
    return _categorySectionKey(Category.SMILEYS);
  }

  bool _isKnownEmojiSectionKey(
    String sectionKey,
    List<ServerCustomEmojiGroup> groups,
  ) {
    for (var index = 0; index < groups.length; index += 1) {
      if (sectionKey == _customEmojiSectionKey(groups[index], index)) {
        return true;
      }
    }
    return _desktopCategories.any(
      (category) => sectionKey == _categorySectionKey(category),
    );
  }

  List<_EmojiCustomRailItem> _customEmojiRailItems(
    List<ServerCustomEmojiGroup> groups,
  ) {
    final items = <_EmojiCustomRailItem>[];
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      if (group.emojis.isEmpty) {
        continue;
      }
      items.add(
        _EmojiCustomRailItem(
          id: _customEmojiSectionKey(group, index),
          label: group.label,
          iconUrl: group.iconUrl,
          mediaPolicy: group.mediaPolicy,
        ),
      );
    }
    return List.unmodifiable(items);
  }
}

class _EmojiPickerTabs extends StatelessWidget {
  const _EmojiPickerTabs({
    required this.activePane,
    required this.hasStickers,
    required this.onChanged,
  });

  final _EmojiPickerPane activePane;
  final bool hasStickers;
  final ValueChanged<_EmojiPickerPane> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('emoji-picker-tabs'),
      height: 34,
      decoration: BoxDecoration(
        color: VerdantColors.panel,
        border: Border.all(color: VerdantColors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Row(
        children: [
          _EmojiPickerTabButton(
            key: const ValueKey('emoji-picker-tab-emoji'),
            label: 'Emoji',
            icon: Icons.tag_faces_outlined,
            selected: activePane == _EmojiPickerPane.emoji,
            onTap: () => onChanged(_EmojiPickerPane.emoji),
          ),
          _EmojiPickerTabButton(
            key: const ValueKey('emoji-picker-tab-stickers'),
            label: 'Stickers',
            icon: Icons.sticky_note_2_outlined,
            selected: activePane == _EmojiPickerPane.stickers,
            onTap: () => onChanged(_EmojiPickerPane.stickers),
            muted: !hasStickers,
          ),
        ],
      ),
    );
  }
}

class _EmojiPickerTabButton extends StatelessWidget {
  const _EmojiPickerTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.muted = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? VerdantColors.text
        : muted
        ? VerdantColors.textMuted.withValues(alpha: 0.78)
        : VerdantColors.textMuted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          hoverColor: VerdantColors.desktopHoverOverlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? VerdantColors.actionMuted : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: selected ? VerdantColors.action : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiPane extends StatelessWidget {
  const _EmojiPane({
    required this.query,
    required this.searchItems,
    required this.selectedSectionKey,
    required this.customRailItems,
    required this.controller,
    required this.mediaPolicy,
    required this.onSelected,
    required this.onSelectSection,
    required this.onBuildSections,
  });

  final String query;
  final List<_EmojiGridItem> searchItems;
  final String? selectedSectionKey;
  final List<_EmojiCustomRailItem> customRailItems;
  final ScrollController controller;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onSelectSection;
  final List<_EmojiSection> Function(double width) onBuildSections;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EmojiCategoryRail(
          selectedSectionKey: selectedSectionKey,
          customRailItems: customRailItems,
          fallbackMediaPolicy: mediaPolicy,
          onSelect: onSelectSection,
        ),
        const VerticalDivider(width: 1, color: VerdantColors.border),
        Expanded(
          child: query.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return _EmojiSectionedGrid(
                      sections: onBuildSections(constraints.maxWidth),
                      controller: controller,
                      mediaPolicy: mediaPolicy,
                      onSelected: onSelected,
                    );
                  },
                )
              : searchItems.isEmpty
              ? Center(
                  child: Text(
                    'No emoji found',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : _EmojiSearchGrid(
                  searchItems: searchItems,
                  controller: controller,
                  mediaPolicy: mediaPolicy,
                  onSelected: onSelected,
                ),
        ),
      ],
    );
  }
}

class _StickerPane extends StatelessWidget {
  const _StickerPane({
    required this.query,
    required this.searchItems,
    required this.sections,
    required this.controller,
    required this.mediaPolicy,
    required this.onSelected,
  });

  final String query;
  final List<_EmojiGridItem> searchItems;
  final List<_EmojiSection> sections;
  final ScrollController controller;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty && sections.isEmpty) {
      return Center(
        child: Text(
          'No stickers available',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    if (query.isNotEmpty && searchItems.isEmpty) {
      return Center(
        child: Text(
          'No stickers found',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    if (query.isNotEmpty) {
      return _EmojiSearchGrid(
        searchItems: searchItems,
        controller: controller,
        mediaPolicy: mediaPolicy,
        onSelected: onSelected,
        crossAxisCount: 4,
        spacing: 8,
      );
    }
    return _EmojiSectionedGrid(
      sections: sections,
      controller: controller,
      mediaPolicy: mediaPolicy,
      onSelected: onSelected,
      crossAxisCount: 4,
      spacing: 8,
      sectionBottomPadding: 12,
    );
  }
}

class _EmojiSearchGrid extends StatelessWidget {
  const _EmojiSearchGrid({
    required this.searchItems,
    required this.controller,
    required this.mediaPolicy,
    required this.onSelected,
    this.crossAxisCount = 7,
    this.spacing = 4,
  });

  final List<_EmojiGridItem> searchItems;
  final ScrollController controller;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<String> onSelected;
  final int crossAxisCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SmoothWheelScroll(
      controller: controller,
      child: GridView.builder(
        key: const ValueKey('emoji-picker-grid-search'),
        controller: controller,
        padding: const EdgeInsets.all(10),
        addAutomaticKeepAlives: false,
        scrollCacheExtent: const ScrollCacheExtent.pixels(120),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: searchItems.length,
        itemBuilder: (context, index) {
          final item = searchItems[index];
          final itemKey = item.key(index);
          return _EmojiGridButton(
            key: ValueKey(itemKey),
            itemKey: itemKey,
            item: item,
            mediaPolicy: mediaPolicy,
            onSelected: onSelected,
          );
        },
      ),
    );
  }
}

class _EmojiSectionedGrid extends StatelessWidget {
  const _EmojiSectionedGrid({
    required this.sections,
    required this.controller,
    required this.mediaPolicy,
    required this.onSelected,
    this.crossAxisCount = 7,
    this.spacing = 4,
    this.sectionBottomPadding = 8,
  });

  final List<_EmojiSection> sections;
  final ScrollController controller;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<String> onSelected;
  final int crossAxisCount;
  final double spacing;
  final double sectionBottomPadding;

  @override
  Widget build(BuildContext context) {
    return SmoothWheelScroll(
      controller: controller,
      child: CustomScrollView(
        key: const ValueKey('emoji-picker-grid-sections'),
        controller: controller,
        scrollCacheExtent: const ScrollCacheExtent.pixels(120),
        slivers: [
          for (final section in sections) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Text(
                  section.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: VerdantColors.textMuted,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, sectionBottomPadding),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: section.items.length,
                itemBuilder: (context, index) {
                  final item = section.items[index];
                  final itemKey = item.key(index);
                  return _EmojiGridButton(
                    key: ValueKey(itemKey),
                    itemKey: itemKey,
                    item: item,
                    mediaPolicy: mediaPolicy,
                    onSelected: onSelected,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmojiCategoryRail extends StatelessWidget {
  const _EmojiCategoryRail({
    required this.selectedSectionKey,
    required this.customRailItems,
    required this.fallbackMediaPolicy,
    required this.onSelect,
  });

  final String? selectedSectionKey;
  final List<_EmojiCustomRailItem> customRailItems;
  final ServerMediaPolicy fallbackMediaPolicy;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('emoji-picker-category-rail'),
      width: 54,
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final item in customRailItems)
              _EmojiServerCategoryButton(
                key: ValueKey(
                  'emoji-picker-category-server-${_railKeySuffix(item.id)}',
                ),
                selected: selectedSectionKey == item.id,
                tooltip: item.label,
                iconUrl: item.iconUrl,
                mediaPolicy: item.mediaPolicy ?? fallbackMediaPolicy,
                onTap: () => onSelect(item.id),
              ),
            for (final category in _desktopCategories)
              _EmojiCategoryButton(
                key: ValueKey(
                  'emoji-picker-category-${_categoryKey(category)}',
                ),
                selected: selectedSectionKey == _categorySectionKey(category),
                tooltip: _categoryLabel(category),
                icon: _categoryIcon(category),
                onTap: () => onSelect(_categorySectionKey(category)),
              ),
          ],
        ),
      ),
    );
  }
}

final class _EmojiCustomRailItem {
  const _EmojiCustomRailItem({
    required this.id,
    required this.label,
    this.iconUrl,
    this.mediaPolicy,
  });

  final String id;
  final String label;
  final String? iconUrl;
  final ServerMediaPolicy? mediaPolicy;
}

class _EmojiServerCategoryButton extends StatelessWidget {
  const _EmojiServerCategoryButton({
    required this.selected,
    required this.tooltip,
    required this.iconUrl,
    required this.mediaPolicy,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final String tooltip;
  final String? iconUrl;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconUri = iconUrl == null
        ? null
        : safeServerMediaUri(iconUrl!, policy: mediaPolicy);
    return Semantics(
      button: true,
      label: tooltip,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        hoverColor: VerdantColors.desktopHoverOverlay,
        child: AnimatedScale(
          key: ValueKey(
            selected
                ? 'emoji-picker-category-selected-$tooltip'
                : 'emoji-picker-category-idle-$tooltip',
          ),
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            key: ValueKey('emoji-picker-category-surface-$tooltip'),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: 54,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? VerdantColors.actionMuted : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: selected ? VerdantColors.action : Colors.transparent,
                  width: selected ? 4 : 0,
                ),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: VerdantColors.accent.withValues(alpha: 0.18),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: CustomExpressionServerIcon(
                uri: iconUri,
                label: safeCustomExpressionServerLabel(tooltip),
                mediaPolicy: mediaPolicy,
                size: selected ? 25 : 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiCategoryButton extends StatelessWidget {
  const _EmojiCategoryButton({
    required this.selected,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        hoverColor: VerdantColors.desktopHoverOverlay,
        child: AnimatedScale(
          key: ValueKey(
            selected
                ? 'emoji-picker-category-selected-$tooltip'
                : 'emoji-picker-category-idle-$tooltip',
          ),
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            key: ValueKey('emoji-picker-category-surface-$tooltip'),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: 54,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? VerdantColors.actionMuted : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: selected ? VerdantColors.action : Colors.transparent,
                  width: selected ? 4 : 0,
                ),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: VerdantColors.accent.withValues(alpha: 0.18),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: selected ? 22 : 20,
              color: selected
                  ? VerdantColors.accentStrong
                  : VerdantColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiGridButton extends StatefulWidget {
  const _EmojiGridButton({
    required this.itemKey,
    required this.item,
    required this.mediaPolicy,
    required this.onSelected,
    super.key,
  });

  final String itemKey;
  final _EmojiGridItem item;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<String> onSelected;

  @override
  State<_EmojiGridButton> createState() => _EmojiGridButtonState();
}

class _EmojiGridButtonState extends State<_EmojiGridButton> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    return Semantics(
      button: true,
      label: widget.item.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: () => widget.onSelected(widget.item.value),
          child: AnimatedScale(
            scale: _pressed
                ? 0.92
                : _hovered
                ? 1.06
                : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              key: ValueKey('${widget.itemKey}-surface'),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? VerdantColors.panelHover.withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: VerdantRadii.sharp,
                border: Border.all(
                  color: active
                      ? VerdantColors.accent.withValues(alpha: 0.34)
                      : Colors.transparent,
                ),
              ),
              child: widget.item.build(context, widget.mediaPolicy),
            ),
          ),
        ),
      ),
    );
  }
}

final class _EmojiGridItem {
  const _EmojiGridItem._({
    required this.value,
    required this.name,
    required this.categoryKey,
    this.customEmoji,
    this.customSticker,
    this.customMediaPolicy,
  });

  factory _EmojiGridItem.unicode(Emoji emoji, String categoryKey) {
    return _EmojiGridItem._(
      value: emoji.emoji,
      name: emoji.name,
      categoryKey: categoryKey,
    );
  }

  factory _EmojiGridItem.custom(
    ServerCustomEmoji emoji, {
    ServerMediaPolicy? mediaPolicy,
  }) {
    return _EmojiGridItem._(
      value: emoji.shortcode,
      name: emoji.name,
      categoryKey: 'custom',
      customEmoji: emoji,
      customMediaPolicy: mediaPolicy,
    );
  }

  factory _EmojiGridItem.customSticker(
    ServerCustomSticker sticker, {
    ServerMediaPolicy? mediaPolicy,
  }) {
    return _EmojiGridItem._(
      value: sticker.shortcode,
      name: sticker.name,
      categoryKey: 'sticker',
      customSticker: sticker,
      customMediaPolicy: mediaPolicy,
    );
  }

  final String value;
  final String name;
  final String categoryKey;
  final ServerCustomEmoji? customEmoji;
  final ServerCustomSticker? customSticker;
  final ServerMediaPolicy? customMediaPolicy;

  String key(int index) {
    final emoji = customEmoji;
    if (emoji != null) {
      return 'emoji-picker-custom-item-${emoji.id}';
    }
    final sticker = customSticker;
    if (sticker != null) {
      return 'emoji-picker-custom-sticker-${sticker.id}';
    }
    return 'emoji-picker-item-$categoryKey-$index';
  }

  Widget build(BuildContext context, ServerMediaPolicy mediaPolicy) {
    final emoji = customEmoji;
    final sticker = customSticker;
    if (emoji == null && sticker == null) {
      return Text(value, style: const TextStyle(fontSize: 25, height: 1));
    }
    final customAsset = emoji ?? sticker!;
    final effectiveMediaPolicy = customMediaPolicy ?? mediaPolicy;
    final uri = safeServerMediaUri(
      customAsset.imageUrl,
      policy: effectiveMediaPolicy,
    );
    final fallback = Text(
      customAsset.shortcode,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
    return WorkspaceRenderProbe(
      surface: emoji == null
          ? 'emojiPickerCustomSticker'
          : 'emojiPickerCustomEmoji',
      id: customAsset.id,
      fields: {
        'animated': customAsset.animated,
        'kind': customAsset.kind.label,
        'name': customAsset.name,
        'urlAccepted': uri != null,
        ...renderMediaUrlFields(customAsset.imageUrl),
      },
      child: uri == null
          ? fallback
          : SizedBox.square(
              dimension: sticker == null ? 28 : 58,
              child: SafeServerMediaImage(
                uri: uri,
                policy: effectiveMediaPolicy,
                surface: ServerMediaSurface.image,
                fallback: Text(
                  customAsset.shortcode,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                builder: (context, imageProvider) => Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: customAsset.name,
                ),
              ),
            ),
    );
  }
}

final class _EmojiSection {
  const _EmojiSection({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<_EmojiGridItem> items;
}

Map<String, double> _computeSectionOffsets({
  required List<_EmojiSection> sections,
  required double width,
}) {
  const horizontalPadding = 20.0;
  const spacing = 4.0;
  const columns = 7;
  const headerHeight = 34.0;
  const sectionBottomPadding = 8.0;
  final cellExtent = math.max(
    28.0,
    (width - horizontalPadding - (columns - 1) * spacing) / columns,
  );
  var cursor = 0.0;
  final offsets = <String, double>{};
  for (final section in sections) {
    offsets.putIfAbsent(section.id, () => cursor);
    final rows = (section.items.length / columns).ceil();
    cursor +=
        headerHeight +
        math.max(1, rows) * cellExtent +
        math.max(0, rows - 1) * spacing +
        sectionBottomPadding;
  }
  return offsets;
}

const _desktopCategories = [
  Category.SMILEYS,
  Category.ANIMALS,
  Category.FOODS,
  Category.TRAVEL,
  Category.ACTIVITIES,
  Category.OBJECTS,
  Category.SYMBOLS,
  Category.FLAGS,
];

String _categorySectionKey(Category category) {
  return 'category:${_categoryKey(category)}';
}

String _customEmojiSectionKey(ServerCustomEmojiGroup group, int index) {
  return 'custom:${_customServerSectionStableKey(networkId: group.networkId, serverId: group.serverId, index: index)}';
}

String _customStickerSectionKey(ServerCustomStickerGroup group, int index) {
  return 'sticker:${_customServerSectionStableKey(networkId: group.networkId, serverId: group.serverId, index: index)}';
}

String _customServerSectionStableKey({
  required String networkId,
  required String serverId,
  required int index,
}) {
  final network = networkId.trim();
  final server = serverId.trim();
  if (network.isEmpty && server.isEmpty) {
    return 'fallback-$index';
  }
  return '$network/$server';
}

String _railKeySuffix(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

String _categoryKey(Category category) {
  return switch (category) {
    Category.RECENT => 'recent',
    Category.SMILEYS => 'smileys',
    Category.ANIMALS => 'animals',
    Category.FOODS => 'foods',
    Category.ACTIVITIES => 'activities',
    Category.TRAVEL => 'travel',
    Category.OBJECTS => 'objects',
    Category.SYMBOLS => 'symbols',
    Category.FLAGS => 'flags',
  };
}

String _categoryLabel(Category category) {
  return switch (category) {
    Category.RECENT => 'Server emojis',
    Category.SMILEYS => 'Smileys',
    Category.ANIMALS => 'Nature',
    Category.FOODS => 'Food',
    Category.ACTIVITIES => 'Activities',
    Category.TRAVEL => 'Travel',
    Category.OBJECTS => 'Objects',
    Category.SYMBOLS => 'Symbols',
    Category.FLAGS => 'Flags',
  };
}

String _stickerSectionLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.toLowerCase().contains('sticker')) {
    return trimmed;
  }
  return '$trimmed stickers';
}

IconData _categoryIcon(Category category) {
  return switch (category) {
    Category.RECENT => Icons.add_reaction,
    Category.SMILEYS => Icons.tag_faces,
    Category.ANIMALS => Icons.pets,
    Category.FOODS => Icons.restaurant,
    Category.ACTIVITIES => Icons.sports_soccer,
    Category.TRAVEL => Icons.public,
    Category.OBJECTS => Icons.lightbulb_outline,
    Category.SYMBOLS => Icons.emoji_symbols,
    Category.FLAGS => Icons.flag,
  };
}
