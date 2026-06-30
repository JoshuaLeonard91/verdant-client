import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../shared/youtube_embed/workspace_youtube_playback_memory.dart';
import '../shared/youtube_embed/workspace_youtube_preview.dart';
import '../workspace_seed.dart';
import 'announcement_feed/announcement_card_preview.dart';
import 'announcement_feed/announcement_content_models.dart';
import 'announcement_feed/announcement_feed_controller.dart';
import 'announcement_feed/announcement_feed_builder.dart';
import 'announcement_feed/announcement_feed_service.dart';

class AnnouncementFeedWorkspace extends StatefulWidget {
  const AnnouncementFeedWorkspace({
    required this.feed,
    required this.seed,
    this.announcementRepository,
    this.youtubePlayerBuilder,
    this.youtubePlaybackMemory,
    super.key,
  });

  final ServerSettingsListItemSeed feed;
  final WorkspaceSeed seed;
  final AnnouncementFeedRepository? announcementRepository;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;

  @override
  State<AnnouncementFeedWorkspace> createState() =>
      _AnnouncementFeedWorkspaceState();
}

class _AnnouncementFeedWorkspaceState extends State<AnnouncementFeedWorkspace> {
  final ScrollController _timelineController = ScrollController();
  final WorkspaceYouTubePlaybackMemory _ownedYoutubePlaybackMemory =
      WorkspaceYouTubePlaybackMemory();

  AnnouncementFeedController? _controller;
  FeedAnnouncementRecord? _editingRecord;
  bool _builderOpen = false;
  bool _anchorTimelineAfterLoad = true;

  WorkspaceYouTubePlaybackMemory get _youtubePlaybackMemory =>
      widget.youtubePlaybackMemory ?? _ownedYoutubePlaybackMemory;

  @override
  void initState() {
    super.initState();
    _configureController();
    _scheduleScrollToLatest();
  }

  @override
  void didUpdateWidget(covariant AnnouncementFeedWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed.id != widget.feed.id ||
        oldWidget.feed.title != widget.feed.title ||
        oldWidget.seed.serverId != widget.seed.serverId ||
        oldWidget.announcementRepository != widget.announcementRepository) {
      _youtubePlaybackMemory.markAllStopped();
      _builderOpen = false;
      _editingRecord = null;
      _anchorTimelineAfterLoad = true;
      _configureController();
      _scheduleScrollToLatest();
    }
  }

  @override
  void dispose() {
    _youtubePlaybackMemory.markAllStopped();
    _controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _configureController() {
    final repository = widget.announcementRepository;
    final feedId = widget.feed.id?.trim();
    if (repository == null || feedId == null || feedId.isEmpty) {
      _controller?.removeListener(_handleControllerChanged);
      _controller?.dispose();
      _controller = null;
      return;
    }
    final existing = _controller;
    if (existing == null) {
      final controller = AnnouncementFeedController(
        repository: repository,
        serverId: widget.seed.serverId,
        feedId: feedId,
      );
      controller.addListener(_handleControllerChanged);
      _controller = controller;
      unawaited(controller.load());
      return;
    }
    existing.updateRoute(serverId: widget.seed.serverId, feedId: feedId);
    unawaited(existing.load());
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final shouldAnchor =
        _anchorTimelineAfterLoad &&
        _controller?.hasLoaded == true &&
        _controller?.isLoading == false;
    setState(() {});
    if (shouldAnchor) {
      _anchorTimelineAfterLoad = false;
      _scheduleScrollToLatest();
    }
  }

  void _scheduleScrollToLatest({int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_timelineController.hasClients ||
          !_timelineController.position.haveDimensions) {
        if (attempt < 3) {
          _scheduleScrollToLatest(attempt: attempt + 1);
        }
        return;
      }
      final target = _timelineController.position.maxScrollExtent;
      if ((_timelineController.position.pixels - target).abs() < 0.5) {
        return;
      }
      _timelineController.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final description = widget.feed.subtitle == 'No description'
        ? ''
        : widget.feed.subtitle;
    final controller = _controller;
    final canManage =
        widget.seed.serverSettings.canManageServer && controller != null;
    return DecoratedBox(
      key: const ValueKey('announcement-feed-workspace-surface'),
      decoration: BoxDecoration(color: colors.panelRaised),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: colors.accentStrong,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.feed.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: VerdantFontWeights.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description.isEmpty
                            ? widget.seed.serverName
                            : description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  key: const ValueKey('announcement-feed-header-actions'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      key: const ValueKey(
                        'announcement-feed-header-pin-action',
                      ),
                      message: 'Pinned announcements',
                      waitDuration: const Duration(milliseconds: 350),
                      child: Icon(
                        Icons.push_pin_outlined,
                        color: colors.textMuted,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Tooltip(
                      key: const ValueKey(
                        'announcement-feed-header-members-action',
                      ),
                      message: 'Show member list',
                      waitDuration: const Duration(milliseconds: 350),
                      child: Icon(
                        Icons.groups_2_outlined,
                        color: colors.accentStrong,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: _builderOpen
                  ? AnnouncementFeedBuilderPanel(
                      key: ValueKey(
                        'announcement-feed-builder-route-${_editingRecord?.id ?? 'new'}',
                      ),
                      feedName: widget.feed.title,
                      initialDraft: _editingRecord?.draft,
                      submitLabel: _editingRecord == null
                          ? 'Publish'
                          : 'Save changes',
                      onClose: () => setState(() {
                        _builderOpen = false;
                        _editingRecord = null;
                      }),
                      onPublish: controller == null
                          ? null
                          : (draft) async {
                              final editingRecord = _editingRecord;
                              if (editingRecord == null) {
                                await controller.publish(draft);
                              } else {
                                await controller.update(
                                  announcementId: editingRecord.id,
                                  draft: draft,
                                );
                              }
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _builderOpen = false;
                                _editingRecord = null;
                              });
                              _scheduleScrollToLatest();
                            },
                    )
                  : controller == null
                  ? _AnnouncementUnavailableState(
                      key: const ValueKey('announcement-feed-unavailable'),
                      message:
                          'Announcements are unavailable for this network route.',
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: _AnnouncementTimelineSurface(
                            key: ValueKey(
                              'announcement-feed-workspace-${widget.feed.id ?? widget.feed.title}',
                            ),
                            records: controller.records,
                            isLoading: controller.isLoading,
                            errorMessage: controller.errorMessage,
                            canManage: canManage,
                            timelineController: _timelineController,
                            youtubePlayerBuilder: widget.youtubePlayerBuilder,
                            youtubePlaybackMemory: _youtubePlaybackMemory,
                            onEdit: (record) => setState(() {
                              _editingRecord = record;
                              _builderOpen = true;
                            }),
                            onDelete: (record) =>
                                unawaited(controller.delete(record.id)),
                          ),
                        ),
                        if (canManage)
                          _CreateFeedPostAction(
                            onPressed: () => setState(() {
                              _editingRecord = null;
                              _builderOpen = true;
                            }),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementTimelineSurface extends StatelessWidget {
  const _AnnouncementTimelineSurface({
    required this.records,
    required this.isLoading,
    required this.errorMessage,
    required this.canManage,
    required this.timelineController,
    required this.youtubePlayerBuilder,
    required this.youtubePlaybackMemory,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<FeedAnnouncementRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final bool canManage;
  final ScrollController timelineController;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory youtubePlaybackMemory;
  final ValueChanged<FeedAnnouncementRecord> onEdit;
  final ValueChanged<FeedAnnouncementRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 720 ? 18.0 : 28.0;
        if (isLoading && records.isEmpty) {
          return const _AnnouncementLoadingState();
        }
        if (errorMessage != null && records.isEmpty) {
          return _AnnouncementUnavailableState(message: errorMessage!);
        }
        if (records.isEmpty) {
          return const _AnnouncementEmptyState();
        }

        final itemCount = records.length + (errorMessage == null ? 0 : 1);
        final bottomPadding = _timelineBottomPadding(context);
        return SmoothWheelScroll(
          controller: timelineController,
          resetToken: records.length,
          child: ListView.builder(
            key: const ValueKey('announcement-feed-timeline-list'),
            controller: timelineController,
            itemCount: itemCount,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              bottomPadding,
            ),
            itemBuilder: (context, index) {
              if (errorMessage != null && index == 0) {
                return _AnnouncementInlineError(message: errorMessage!);
              }
              final recordIndex = index - (errorMessage == null ? 0 : 1);
              final record = records[recordIndex];
              return _AnnouncementTimelineEntry(
                key: ValueKey('announcement-feed-card-${record.id}'),
                record: record,
                index: recordIndex,
                totalAnnouncements: records.length,
                canManage: canManage,
                youtubePlayerBuilder: youtubePlayerBuilder,
                youtubePlaybackMemory: youtubePlaybackMemory,
                onEdit: () => onEdit(record),
                onDelete: () => onDelete(record),
              );
            },
          ),
        );
      },
    );
  }
}

double _timelineBottomPadding(BuildContext context) {
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return (bottomInset + 10).clamp(10.0, 18.0);
}

class _CreateFeedPostAction extends StatefulWidget {
  const _CreateFeedPostAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CreateFeedPostAction> createState() => _CreateFeedPostActionState();
}

class _CreateFeedPostActionState extends State<_CreateFeedPostAction> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final active = _hovered || _pressed;
    return Positioned(
      right: 24,
      bottom: 24,
      child: Tooltip(
        message: 'Create feed post',
        waitDuration: const Duration(milliseconds: 350),
        child: Semantics(
          button: true,
          label: 'Create feed post',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() {
              _hovered = false;
              _pressed = false;
            }),
            child: Listener(
              onPointerDown: (_) => setState(() => _pressed = true),
              onPointerUp: (_) => setState(() => _pressed = false),
              onPointerCancel: (_) => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.96 : (_hovered ? 1.05 : 1),
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                child: Material(
                  color: Colors.transparent,
                  elevation: active ? 16 : 10,
                  shadowColor: colors.accent.withValues(
                    alpha: active ? 0.36 : 0.24,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: active ? colors.accentStrong : colors.accent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active
                            ? colors.actionText.withValues(alpha: 0.45)
                            : colors.accentStrong.withValues(alpha: 0.42),
                      ),
                    ),
                    child: InkWell(
                      key: const ValueKey('announcement-feed-create-button'),
                      onTap: widget.onPressed,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      splashColor: colors.actionText.withValues(alpha: 0.12),
                      highlightColor: colors.actionText.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.add,
                          color: colors.actionText,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementInlineError extends StatelessWidget {
  const _AnnouncementInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AnnouncementTimelineEntry extends StatefulWidget {
  const _AnnouncementTimelineEntry({
    required this.record,
    required this.index,
    required this.totalAnnouncements,
    required this.canManage,
    required this.youtubePlayerBuilder,
    required this.youtubePlaybackMemory,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FeedAnnouncementRecord record;
  final int index;
  final int totalAnnouncements;
  final bool canManage;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory youtubePlaybackMemory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_AnnouncementTimelineEntry> createState() =>
      _AnnouncementTimelineEntryState();
}

class _AnnouncementTimelineEntryState extends State<_AnnouncementTimelineEntry>
    with AutomaticKeepAliveClientMixin {
  var _hasActiveYoutubePlayback = false;

  @override
  bool get wantKeepAlive => _hasActiveYoutubePlayback;

  @override
  void initState() {
    super.initState();
    _hasActiveYoutubePlayback = _recordHasActiveYouTubePlayback(
      widget.record,
      widget.youtubePlaybackMemory,
    );
  }

  @override
  void didUpdateWidget(covariant _AnnouncementTimelineEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record != widget.record ||
        oldWidget.youtubePlaybackMemory != widget.youtubePlaybackMemory) {
      _hasActiveYoutubePlayback = _recordHasActiveYouTubePlayback(
        widget.record,
        widget.youtubePlaybackMemory,
      );
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLast = widget.index == widget.totalAnnouncements - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _AnnouncementTimelineSeparator(
                  label: _timelineLabelFor(
                    widget.index,
                    widget.totalAnnouncements,
                  ),
                ),
              ),
              if (widget.canManage) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit announcement',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                ),
                IconButton(
                  tooltip: 'Delete announcement',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 17),
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          AnnouncementCardPreview(
            draft: widget.record.draft,
            youtubePreviewKeyPrefix: 'announcement-feed-${widget.record.id}',
            youtubePlayerBuilder: widget.youtubePlayerBuilder,
            youtubePlaybackMemory: widget.youtubePlaybackMemory,
            onYoutubePlaybackChanged: _handleYoutubePlaybackChanged,
          ),
        ],
      ),
    );
  }

  void _handleYoutubePlaybackChanged(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  ) {
    final nextActive = _recordHasActiveYouTubePlayback(
      widget.record,
      widget.youtubePlaybackMemory,
    );
    if (nextActive == _hasActiveYoutubePlayback) {
      return;
    }
    setState(() => _hasActiveYoutubePlayback = nextActive);
    updateKeepAlive();
  }
}

bool _recordHasActiveYouTubePlayback(
  FeedAnnouncementRecord record,
  WorkspaceYouTubePlaybackMemory playbackMemory,
) {
  return _youtubeVideoIdsForDraft(
    record.draft,
  ).any((videoId) => playbackMemory.snapshotFor(videoId).isPlaying);
}

Iterable<String> _youtubeVideoIdsForDraft(FeedAnnouncementDraft draft) sync* {
  for (final section in draft.sections) {
    if (section is FeedAnnouncementYouTubeSection) {
      final videoId = section.videoId;
      if (videoId != null) {
        yield videoId;
      }
    }
  }
}

class _AnnouncementTimelineSeparator extends StatelessWidget {
  const _AnnouncementTimelineSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colors.accentStrong,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: VerdantFontWeights.black,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: colors.border, height: 1)),
      ],
    );
  }
}

class _AnnouncementLoadingState extends StatelessWidget {
  const _AnnouncementLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: colors.accentStrong,
        ),
      ),
    );
  }
}

class _AnnouncementEmptyState extends StatelessWidget {
  const _AnnouncementEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _AnnouncementUnavailableState(message: 'No announcements yet');
  }
}

class _AnnouncementUnavailableState extends StatelessWidget {
  const _AnnouncementUnavailableState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, color: colors.textMuted, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timelineLabelFor(int index, int totalAnnouncements) {
  if (index == totalAnnouncements - 1) {
    return 'LATEST ANNOUNCEMENT';
  }
  if (index >= totalAnnouncements - 2) {
    return 'RECENT ANNOUNCEMENT';
  }
  return 'OLDER ANNOUNCEMENT';
}
