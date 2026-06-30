import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBox, ScrollCacheExtent;

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/chat_timestamp_format.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/workspace_render_diagnostics.dart';
import '../shared/youtube_embed/workspace_youtube_playback_memory.dart';
import '../shared/youtube_embed/workspace_youtube_preview.dart';
import '../workspace_local_id.dart';
import '../workspace_seed.dart';
import 'message_item.dart';
import 'message_invite_card.dart';
import 'link_preview_service.dart';
import 'message_link_preview.dart';

const _messageGroupWindow = Duration(minutes: 5);
const _messageDeletionCollapseDuration = Duration(milliseconds: 170);

class MessageTimeline extends StatefulWidget {
  const MessageTimeline({
    required this.messages,
    this.beginningLabel = 'Beginning of #general',
    this.pageStorageKey = 'chat-message-timeline',
    this.stickToBottom = true,
    this.bottomPadding = 14,
    this.mediaPolicy = const ServerMediaPolicy(
      allowedOrigins: {},
      allowLocalHttp: false,
    ),
    this.networkId,
    this.members = const [],
    this.timestampOptions,
    this.linkPreviewService,
    this.customEmojis = const [],
    this.customStickers = const [],
    this.customExpressionSources = const {},
    this.youtubePlayerBuilder,
    this.youtubePlaybackMemory,
    this.hasOlderMessages = false,
    this.isLoadingOlderMessages = false,
    this.canManageMessages = false,
    this.onLoadOlderMessages,
    this.onReplyMessage,
    this.onEditMessage,
    this.onDeleteMessage,
    this.onSetReaction,
    this.onPreviewInvite,
    this.onAcceptInvite,
    this.onPrepareMemberProfile,
    super.key,
  });

  final List<MessageSeed> messages;
  final String beginningLabel;
  final String pageStorageKey;
  final bool stickToBottom;
  final double bottomPadding;
  final ServerMediaPolicy mediaPolicy;
  final String? networkId;
  final List<MemberSeed> members;
  final ChatTimestampFormatOptions? timestampOptions;
  final MessageLinkPreviewService? linkPreviewService;
  final List<ServerCustomEmoji> customEmojis;
  final List<ServerCustomSticker> customStickers;
  final Map<String, CustomExpressionSource> customExpressionSources;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final bool hasOlderMessages;
  final bool isLoadingOlderMessages;
  final bool canManageMessages;
  final Future<void> Function()? onLoadOlderMessages;
  final ValueChanged<MessageSeed>? onReplyMessage;
  final ValueChanged<MessageSeed>? onEditMessage;
  final ValueChanged<MessageSeed>? onDeleteMessage;
  final ServerReactionChangeHandler? onSetReaction;
  final ChatInvitePreviewHandler? onPreviewInvite;
  final ChatInviteAcceptHandler? onAcceptInvite;
  final FutureOr<MemberSeed> Function(MemberSeed member)?
  onPrepareMemberProfile;

  @override
  State<MessageTimeline> createState() => _MessageTimelineState();
}

class _MessageTimelineState extends State<MessageTimeline> {
  static const _nearBottomThreshold = 160.0;
  static const _nearTopThreshold = 96.0;
  static final _savedOffsets = <String, double>{};
  static final _savedPinnedToBottom = <String, bool>{};
  late ScrollController _controller;
  late bool _restoredFromSavedOffset;
  var _hasScrolledToInitialBottom = false;
  var _autoStickToBottom = false;
  var _userPinnedAwayFromBottom = false;
  var _suppressBottomReturnUntilAway = false;
  var _loadOlderInFlight = false;
  var _loadOlderArmed = true;
  var _scrollGeometryVersion = 0;
  var _bottomScrollGeneration = 0;
  final _scrollMetricsVersion = ValueNotifier<int>(0);
  final WorkspaceYouTubePlaybackMemory _ownedYoutubePlaybackMemory =
      WorkspaceYouTubePlaybackMemory();
  late List<_TimelineMessageEntry> _messageEntries;
  final _messageRemovalTimers = <String, Timer>{};
  String? _historyCenterMessageId;
  _MessagePrependAnchor? _pendingPrependAnchor;

  WorkspaceYouTubePlaybackMemory get _youtubePlaybackMemory =>
      widget.youtubePlaybackMemory ?? _ownedYoutubePlaybackMemory;

  @override
  void initState() {
    super.initState();
    _messageEntries = _entriesFromMessages(widget.messages);
    _restoredFromSavedOffset = _hasSavedOffset(widget.pageStorageKey);
    _controller = _createController(widget.pageStorageKey);
    _controller.addListener(_saveCurrentOffset);
    final restoreToBottom =
        widget.stickToBottom && _wasSavedAtBottom(widget.pageStorageKey);
    if (!_restoredFromSavedOffset || restoreToBottom) {
      _autoStickToBottom = true;
      _scheduleScrollToBottom(animated: false, reason: 'initial');
    } else {
      _hasScrolledToInitialBottom = true;
      _userPinnedAwayFromBottom = true;
    }
  }

  @override
  void didUpdateWidget(covariant MessageTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageStorageKey != widget.pageStorageKey) {
      _youtubePlaybackMemory.markAllStopped();
      _resetMessageEntries();
      _replaceController(oldWidget.pageStorageKey);
      return;
    }
    _syncMessageEntries();
    if (!widget.stickToBottom) {
      return;
    }
    final oldFirstId = oldWidget.messages.isEmpty
        ? null
        : oldWidget.messages.first.id;
    final newFirstId = widget.messages.isEmpty
        ? null
        : widget.messages.first.id;
    final olderPrepended =
        oldFirstId != null &&
        newFirstId != null &&
        oldFirstId != newFirstId &&
        widget.messages.any((message) => message.id == oldFirstId);
    if (olderPrepended) {
      final anchor = _pendingPrependAnchor;
      _pendingPrependAnchor = null;
      _historyCenterMessageId ??= oldFirstId;
      _scrollGeometryVersion += 1;
      _hasScrolledToInitialBottom = true;
      _autoStickToBottom = false;
      _userPinnedAwayFromBottom = true;
      _preserveVisibleAnchorAfterSplit(anchor);
      return;
    }
    if (_historyCenterMessageId != null &&
        !widget.messages.any(
          (message) => message.id == _historyCenterMessageId,
        )) {
      _historyCenterMessageId = null;
    }
    final oldLastId = oldWidget.messages.isEmpty
        ? null
        : oldWidget.messages.last.id;
    final newLastId = widget.messages.isEmpty ? null : widget.messages.last.id;
    if (oldWidget.messages.length != widget.messages.length ||
        oldLastId != newLastId) {
      if (!_hasScrolledToInitialBottom || _autoStickToBottom) {
        _scheduleScrollToBottom(
          animated: _hasScrolledToInitialBottom,
          reason: 'messagesChanged',
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubePlaybackMemory.markAllStopped();
    for (final timer in _messageRemovalTimers.values) {
      timer.cancel();
    }
    _messageRemovalTimers.clear();
    _saveOffset(widget.pageStorageKey);
    _controller.removeListener(_saveCurrentOffset);
    _controller.dispose();
    _scrollMetricsVersion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final centerKey = ValueKey<String>(
      'message-timeline-center-${widget.pageStorageKey}',
    );
    final entries = _messageEntries;
    final historyCenterIndex = _historyCenterIndex(entries);
    final hasHistorySplit = historyCenterIndex > 0;
    final messageIndexesById = <String, int>{
      for (var index = 0; index < entries.length; index += 1)
        entries[index].message.id: index,
    };
    return KeyedSubtree(
      key: const ValueKey('message-timeline-module'),
      child: DecoratedBox(
        key: ValueKey<String>(
          'message-timeline-module-page-${widget.pageStorageKey}',
        ),
        decoration: BoxDecoration(color: colors.panelRaised),
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _handleScrollMetricsNotification,
            child: Stack(
              children: [
                ScrollConfiguration(
                  key: ValueKey<String>(
                    'message-timeline-scroll-configuration-${widget.pageStorageKey}',
                  ),
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SmoothWheelScroll(
                    controller: _controller,
                    onWheelScrollDelta: _handleWheelScrollDelta,
                    resetToken: _scrollGeometryVersion,
                    child: CustomScrollView(
                      key: ValueKey<String>(
                        'message-timeline-scrollable-${widget.pageStorageKey}',
                      ),
                      controller: _controller,
                      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                      center: centerKey,
                      slivers: [
                        if (hasHistorySplit)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == historyCenterIndex) {
                                    return _TimelineStartMarker(
                                      label: widget.beginningLabel,
                                      storageKey: widget.pageStorageKey,
                                    );
                                  }
                                  return _buildMessageRow(
                                    historyCenterIndex - 1 - index,
                                    entries,
                                  );
                                },
                                childCount: historyCenterIndex + 1,
                                findChildIndexCallback: (key) =>
                                    _findHistoryChildIndexForKey(
                                      key,
                                      messageIndexesById: messageIndexesById,
                                      historyCenterIndex: historyCenterIndex,
                                    ),
                                addAutomaticKeepAlives: true,
                                addRepaintBoundaries: true,
                              ),
                            ),
                          ),
                        SliverPadding(
                          key: centerKey,
                          padding: EdgeInsets.fromLTRB(
                            10,
                            hasHistorySplit ? 0 : 8,
                            10,
                            widget.bottomPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (!hasHistorySplit && index == 0) {
                                  return _TimelineStartMarker(
                                    label: widget.beginningLabel,
                                    storageKey: widget.pageStorageKey,
                                  );
                                }
                                final messageIndex =
                                    historyCenterIndex +
                                    index -
                                    (hasHistorySplit ? 0 : 1);
                                return _buildMessageRow(messageIndex, entries);
                              },
                              childCount:
                                  entries.length -
                                  historyCenterIndex +
                                  (hasHistorySplit ? 0 : 1),
                              findChildIndexCallback: (key) =>
                                  _findCenterChildIndexForKey(
                                    key,
                                    messageIndexesById: messageIndexesById,
                                    historyCenterIndex: historyCenterIndex,
                                    hasHistorySplit: hasHistorySplit,
                                  ),
                              addAutomaticKeepAlives: true,
                              addRepaintBoundaries: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _TimelineScrollIndicator(
                  controller: _controller,
                  metricsVersion: _scrollMetricsVersion,
                  storageKey: widget.pageStorageKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _findHistoryChildIndexForKey(
    Key key, {
    required Map<String, int> messageIndexesById,
    required int historyCenterIndex,
  }) {
    final messageId = _messageIdFromRowKey(key);
    if (messageId == null) {
      return null;
    }
    final messageIndex = messageIndexesById[messageId];
    if (messageIndex == null || messageIndex >= historyCenterIndex) {
      return null;
    }
    return historyCenterIndex - 1 - messageIndex;
  }

  int? _findCenterChildIndexForKey(
    Key key, {
    required Map<String, int> messageIndexesById,
    required int historyCenterIndex,
    required bool hasHistorySplit,
  }) {
    final messageId = _messageIdFromRowKey(key);
    if (messageId == null) {
      return null;
    }
    final messageIndex = messageIndexesById[messageId];
    if (messageIndex == null || messageIndex < historyCenterIndex) {
      return null;
    }
    return messageIndex - historyCenterIndex + (hasHistorySplit ? 0 : 1);
  }

  String? _messageIdFromRowKey(Key key) {
    if (key is! ValueKey<String>) {
      return null;
    }
    const prefix = 'message-row-';
    final value = key.value;
    return value.startsWith(prefix) ? value.substring(prefix.length) : null;
  }

  Widget _buildMessageRow(
    int messageIndex,
    List<_TimelineMessageEntry> entries,
  ) {
    final entry = entries[messageIndex];
    final message = entry.message;
    final previous = messageIndex > 0
        ? entries[messageIndex - 1].message
        : null;
    final showHeader = _shouldShowMessageHeader(previous, message);

    return _MessageTimelineRow(
      key: ValueKey('message-row-${message.id}'),
      message: message,
      removing: entry.removing,
      playbackMemory: _youtubePlaybackMemory,
      childBuilder: (onYoutubePlaybackChanged) => MessageItem(
        message: message,
        profileMember: _memberForMessage(message),
        networkId: widget.networkId,
        mentionMembers: widget.members,
        customEmojis: widget.customEmojis,
        customStickers: widget.customStickers,
        customExpressionSources: widget.customExpressionSources,
        onPrepareMemberProfile: widget.onPrepareMemberProfile,
        timestampOptions: widget.timestampOptions,
        linkPreviewService: widget.linkPreviewService,
        youtubePlayerBuilder: widget.youtubePlayerBuilder,
        youtubePlaybackMemory: _youtubePlaybackMemory,
        onYoutubePlaybackChanged: onYoutubePlaybackChanged,
        canManageMessages: widget.canManageMessages,
        showHeader: showHeader,
        mediaPolicy: widget.mediaPolicy,
        onReply: widget.onReplyMessage,
        onEdit: widget.onEditMessage,
        onDelete: widget.onDeleteMessage,
        onSetReaction: widget.onSetReaction,
        onPreviewInvite: widget.onPreviewInvite,
        onAcceptInvite: widget.onAcceptInvite,
        onInviteLayoutSettled: _handleInviteLayoutSettled,
        onMediaLayoutSettled: _handleMediaLayoutSettled,
        onReactionLayoutSettled: _handleReactionLayoutSettled,
      ),
    );
  }

  int _historyCenterIndex(List<_TimelineMessageEntry> entries) {
    final centerMessageId = _historyCenterMessageId;
    if (centerMessageId == null) {
      return 0;
    }
    final index = entries.indexWhere(
      (entry) => entry.message.id == centerMessageId,
    );
    return index <= 0 ? 0 : index;
  }

  List<_TimelineMessageEntry> _entriesFromMessages(List<MessageSeed> messages) {
    return [
      for (final message in messages) _TimelineMessageEntry(message: message),
    ];
  }

  void _resetMessageEntries() {
    for (final timer in _messageRemovalTimers.values) {
      timer.cancel();
    }
    _messageRemovalTimers.clear();
    _messageEntries = _entriesFromMessages(widget.messages);
  }

  void _syncMessageEntries() {
    final incomingById = <String, MessageSeed>{
      for (final message in widget.messages) message.id: message,
    };
    final existingById = <String, _TimelineMessageEntry>{
      for (final entry in _messageEntries) entry.message.id: entry,
    };
    final nextEntries = <_TimelineMessageEntry>[
      for (final message in widget.messages)
        (existingById[message.id] ?? _TimelineMessageEntry(message: message))
            .copyWith(message: message, removing: false),
    ];

    for (final message in widget.messages) {
      _messageRemovalTimers.remove(message.id)?.cancel();
    }

    for (var oldIndex = 0; oldIndex < _messageEntries.length; oldIndex += 1) {
      final entry = _messageEntries[oldIndex];
      final messageId = entry.message.id;
      if (incomingById.containsKey(messageId)) {
        continue;
      }
      final removingEntry = entry.copyWith(removing: true);
      final insertIndex = _removedEntryInsertIndex(oldIndex, nextEntries);
      nextEntries.insert(insertIndex, removingEntry);
      _ensureMessageRemovalTimer(messageId);
    }

    _messageEntries = nextEntries;
  }

  int _removedEntryInsertIndex(
    int oldIndex,
    List<_TimelineMessageEntry> nextEntries,
  ) {
    for (var index = oldIndex - 1; index >= 0; index -= 1) {
      final previousId = _messageEntries[index].message.id;
      final nextIndex = nextEntries.indexWhere(
        (entry) => entry.message.id == previousId,
      );
      if (nextIndex >= 0) {
        return nextIndex + 1;
      }
    }
    for (var index = oldIndex + 1; index < _messageEntries.length; index += 1) {
      final nextId = _messageEntries[index].message.id;
      final nextIndex = nextEntries.indexWhere(
        (entry) => entry.message.id == nextId,
      );
      if (nextIndex >= 0) {
        return nextIndex;
      }
    }
    return oldIndex.clamp(0, nextEntries.length);
  }

  void _ensureMessageRemovalTimer(String messageId) {
    if (_messageRemovalTimers.containsKey(messageId)) {
      return;
    }
    _messageRemovalTimers[messageId] = Timer(
      _messageDeletionCollapseDuration,
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _messageRemovalTimers.remove(messageId);
          _messageEntries = [
            for (final entry in _messageEntries)
              if (entry.message.id != messageId) entry,
          ];
        });
      },
    );
  }

  void _preserveVisibleAnchorAfterSplit(_MessagePrependAnchor? anchor) {
    if (anchor == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final currentTop = _messageRowTop(anchor.messageId);
      if (currentTop == null) {
        return;
      }
      final target = (_controller.offset + currentTop - anchor.top).clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      );
      if ((_controller.offset - target).abs() > 0.5) {
        _controller.jumpTo(target);
      }
      _saveOffset(widget.pageStorageKey);
    });
  }

  void _scheduleScrollToBottom({
    required bool animated,
    required String reason,
  }) {
    final generation = _bottomScrollGeneration;
    _logScroll('scheduleBottom', {
      'reason': reason,
      'animated': animated,
      'scheduledGeneration': generation,
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomWhenReady(
        animated: animated,
        remainingFrames: 8,
        generation: generation,
        reason: reason,
      );
    });
  }

  void _handleMediaLayoutSettled() {
    if (!widget.stickToBottom) {
      return;
    }
    if (_userPinnedAwayFromBottom) {
      _logScroll('mediaLayoutIgnored', {'reason': 'userPinnedAway'});
      return;
    }
    if (!_hasScrolledToInitialBottom || _autoStickToBottom || _isAtBottom()) {
      _scheduleScrollToBottom(
        animated: _hasScrolledToInitialBottom,
        reason: 'mediaLayoutSettled',
      );
    }
  }

  void _handleInviteLayoutSettled() {
    if (!widget.stickToBottom) {
      return;
    }
    if (!_hasScrolledToInitialBottom || _autoStickToBottom || _isNearBottom()) {
      _scheduleScrollToBottom(
        animated: _hasScrolledToInitialBottom,
        reason: 'inviteLayoutSettled',
      );
    }
  }

  void _handleReactionLayoutSettled() {
    if (!widget.stickToBottom) {
      return;
    }
    if (_autoStickToBottom) {
      final generation = _bottomScrollGeneration;
      _logScroll('reactionLayoutBottomCheck', {
        'scheduledGeneration': generation,
      });
      _scrollToBottomWhenReady(
        animated: false,
        remainingFrames: 8,
        generation: generation,
        reason: 'reactionLayoutSettled',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _autoStickToBottom &&
            generation == _bottomScrollGeneration) {
          _scrollToBottomWhenReady(
            animated: false,
            remainingFrames: 8,
            generation: generation,
            reason: 'reactionLayoutSettledPostFrame',
          );
        }
      });
    }
  }

  void _scrollToBottomWhenReady({
    required bool animated,
    required int remainingFrames,
    required int generation,
    required String reason,
  }) {
    if (!mounted || !widget.stickToBottom) {
      return;
    }
    if (generation != _bottomScrollGeneration) {
      _logScroll('bottomSkipped', {
        'reason': reason,
        'skip': 'staleGeneration',
        'scheduledGeneration': generation,
      });
      return;
    }
    if (_hasScrolledToInitialBottom &&
        _userPinnedAwayFromBottom &&
        !_autoStickToBottom) {
      _logScroll('bottomSkipped', {
        'reason': reason,
        'skip': 'userPinnedAway',
        'scheduledGeneration': generation,
      });
      return;
    }
    if (!_controller.hasClients) {
      _logScroll('bottomWait', {
        'reason': reason,
        'wait': 'noClients',
        'remainingFrames': remainingFrames,
      });
      if (remainingFrames > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottomWhenReady(
            animated: animated,
            remainingFrames: remainingFrames - 1,
            generation: generation,
            reason: reason,
          );
        });
      }
      return;
    }
    final position = _controller.position;
    if ((!position.haveDimensions ||
            position.maxScrollExtent <= 0 && _messageEntries.length > 8) &&
        remainingFrames > 0) {
      _logScroll('bottomWait', {
        'reason': reason,
        'wait': position.haveDimensions ? 'emptyExtent' : 'noDimensions',
        'remainingFrames': remainingFrames,
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottomWhenReady(
          animated: animated,
          remainingFrames: remainingFrames - 1,
          generation: generation,
          reason: reason,
        );
      });
      return;
    }
    final target = position.maxScrollExtent;
    if (animated && (_controller.offset - target).abs() > 1) {
      _logScroll('bottomAction', {
        'reason': reason,
        'mode': 'animate',
        'target': _scrollNumber(target),
        'scheduledGeneration': generation,
      });
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } else {
      _logScroll('bottomAction', {
        'reason': reason,
        'mode': 'jump',
        'target': _scrollNumber(target),
        'scheduledGeneration': generation,
      });
      _controller.jumpTo(target);
    }
    _hasScrolledToInitialBottom = true;
    _autoStickToBottom = true;
    _userPinnedAwayFromBottom = false;
    _saveOffset(widget.pageStorageKey);
  }

  void _cancelPendingBottomScrolls({required String reason}) {
    _bottomScrollGeneration += 1;
    _logScroll('cancelBottom', {'reason': reason});
  }

  ScrollController _createController(String key) {
    return ScrollController(
      initialScrollOffset: _savedOffsets[key] ?? 0,
      keepScrollOffset: false,
    );
  }

  void _replaceController(String oldKey) {
    _saveOffset(oldKey);
    _controller.removeListener(_saveCurrentOffset);
    _controller.dispose();
    _controller = _createController(widget.pageStorageKey);
    _controller.addListener(_saveCurrentOffset);
    _restoredFromSavedOffset = _hasSavedOffset(widget.pageStorageKey);
    final restoreToBottom =
        widget.stickToBottom && _wasSavedAtBottom(widget.pageStorageKey);
    _hasScrolledToInitialBottom = _restoredFromSavedOffset && !restoreToBottom;
    _autoStickToBottom = !_restoredFromSavedOffset || restoreToBottom;
    _userPinnedAwayFromBottom = _restoredFromSavedOffset && !restoreToBottom;
    _suppressBottomReturnUntilAway = false;
    _loadOlderInFlight = false;
    _loadOlderArmed = true;
    _historyCenterMessageId = null;
    _cancelPendingBottomScrolls(reason: 'replaceController');
    if (!_hasScrolledToInitialBottom || restoreToBottom) {
      _scheduleScrollToBottom(animated: false, reason: 'replaceController');
    }
  }

  bool _hasSavedOffset(String key) {
    return _savedOffsets.containsKey(key);
  }

  bool _wasSavedAtBottom(String key) {
    return _savedPinnedToBottom[key] ?? false;
  }

  bool _isNearBottom() {
    if (!_controller.hasClients) {
      return true;
    }
    final position = _controller.position;
    return position.maxScrollExtent - position.pixels <= _nearBottomThreshold;
  }

  void _saveCurrentOffset() {
    _saveOffset(widget.pageStorageKey);
    _maybeLoadOlder();
    if (!_controller.hasClients || !_hasScrolledToInitialBottom) {
      return;
    }
    final previousPinned = _userPinnedAwayFromBottom;
    final previousAuto = _autoStickToBottom;
    if (_isAtBottom()) {
      if (_suppressBottomReturnUntilAway) {
        _logScroll('bottomReturnSuppressed', {'source': 'saveOffset'});
        return;
      }
      _userPinnedAwayFromBottom = false;
      _autoStickToBottom = true;
      _logScrollStateChangeIfNeeded(
        previousPinned: previousPinned,
        previousAuto: previousAuto,
        reason: 'atBottom',
      );
      return;
    }
    if (_userPinnedAwayFromBottom) {
      _autoStickToBottom = false;
      _logScrollStateChangeIfNeeded(
        previousPinned: previousPinned,
        previousAuto: previousAuto,
        reason: 'userPinnedAway',
      );
      return;
    }
    _autoStickToBottom = _isNearBottom();
    _logScrollStateChangeIfNeeded(
      previousPinned: previousPinned,
      previousAuto: previousAuto,
      reason: 'nearBottomCheck',
    );
  }

  void _handleWheelScrollDelta(double delta) {
    if (!_controller.hasClients) {
      _logScroll('wheelIgnored', {'reason': 'noClients', 'delta': delta});
      return;
    }
    _logScroll('wheelDelta', {'delta': delta});
    if (delta < 0) {
      _cancelPendingBottomScrolls(reason: 'wheelUp');
      _hasScrolledToInitialBottom = true;
      _userPinnedAwayFromBottom = true;
      _autoStickToBottom = false;
      _suppressBottomReturnUntilAway = _isAtBottom();
      _logScroll('wheelPinnedAway', {'delta': delta});
    } else if (delta > 0 && _isAtBottom()) {
      _suppressBottomReturnUntilAway = false;
      _userPinnedAwayFromBottom = false;
      _autoStickToBottom = true;
      _logScroll('wheelReturnedBottom', {'delta': delta});
    }
  }

  _MessagePrependAnchor? _captureVisibleMessageAnchor(
    List<MessageSeed> messages,
  ) {
    final timelineBox = context.findRenderObject();
    if (timelineBox is! RenderBox || !timelineBox.hasSize) {
      return null;
    }
    final timelineTop = timelineBox.localToGlobal(Offset.zero).dy;
    final timelineBottom = timelineTop + timelineBox.size.height;
    _MessagePrependAnchor? fallback;

    for (final message in messages) {
      final rowBox = _messageRowBox(message.id);
      if (rowBox == null || !rowBox.hasSize) {
        continue;
      }
      final top = rowBox.localToGlobal(Offset.zero).dy;
      final bottom = top + rowBox.size.height;
      final isVisible = bottom > timelineTop && top < timelineBottom;
      if (!isVisible) {
        continue;
      }
      final anchor = _MessagePrependAnchor(messageId: message.id, top: top);
      if (top >= timelineTop) {
        return anchor;
      }
      fallback ??= anchor;
    }

    return fallback;
  }

  double? _messageRowTop(String messageId) {
    final rowBox = _messageRowBox(messageId);
    if (rowBox == null || !rowBox.hasSize) {
      return null;
    }
    return rowBox.localToGlobal(Offset.zero).dy;
  }

  RenderBox? _messageRowBox(String messageId) {
    final element = _findElementByWidgetKey(
      context,
      ValueKey('message-row-$messageId'),
    );
    final renderObject = element?.renderObject;
    return renderObject is RenderBox ? renderObject : null;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_hasScrolledToInitialBottom ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        notification.metrics.maxScrollExtent - notification.metrics.pixels >
            1) {
      _suppressBottomReturnUntilAway = false;
      _userPinnedAwayFromBottom = true;
      _autoStickToBottom = false;
      _logScroll('dragPinnedAway', {
        'pixels': _scrollNumber(notification.metrics.pixels),
        'max': _scrollNumber(notification.metrics.maxScrollExtent),
      });
    }
    if (notification is UserScrollNotification && _isAtBottom()) {
      if (_suppressBottomReturnUntilAway) {
        _logScroll('bottomReturnSuppressed', {
          'source': 'userScrollNotification',
          'direction': notification.direction.name,
        });
        _maybeLoadOlder();
        return false;
      }
      _userPinnedAwayFromBottom = false;
      _autoStickToBottom = true;
      _logScroll('userScrollReturnedBottom', {
        'direction': notification.direction.name,
      });
    }
    _maybeLoadOlder();
    return false;
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _scrollMetricsVersion.value += 1;
      if (widget.stickToBottom &&
          !_userPinnedAwayFromBottom &&
          (!_hasScrolledToInitialBottom ||
              (_autoStickToBottom && _isNearBottom()))) {
        _scheduleScrollToBottom(animated: false, reason: 'metricsChanged');
      }
    }
    return false;
  }

  void _maybeLoadOlder() {
    final loadOlder = widget.onLoadOlderMessages;
    if (loadOlder == null ||
        !widget.hasOlderMessages ||
        widget.isLoadingOlderMessages ||
        _loadOlderInFlight ||
        !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final distanceFromTop = position.pixels - position.minScrollExtent;
    if (distanceFromTop > _nearTopThreshold * 2) {
      _loadOlderArmed = true;
      return;
    }
    if (!_loadOlderArmed || distanceFromTop > _nearTopThreshold) {
      return;
    }
    _loadOlderArmed = false;
    _loadOlderInFlight = true;
    _userPinnedAwayFromBottom = true;
    _autoStickToBottom = false;
    _suppressBottomReturnUntilAway = false;
    _cancelPendingBottomScrolls(reason: 'loadOlder');
    _logScroll('loadOlderTriggered', {
      'distanceFromTop': _scrollNumber(distanceFromTop),
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _pendingPrependAnchor = _captureVisibleMessageAnchor(widget.messages);
      unawaited(
        loadOlder().whenComplete(() {
          if (mounted) {
            _loadOlderInFlight = false;
          }
        }),
      );
    });
  }

  void _logScrollStateChangeIfNeeded({
    required bool previousPinned,
    required bool previousAuto,
    required String reason,
  }) {
    if (previousPinned == _userPinnedAwayFromBottom &&
        previousAuto == _autoStickToBottom) {
      return;
    }
    _logScroll('stateChanged', {
      'reason': reason,
      'previousPinned': previousPinned,
      'previousAuto': previousAuto,
    });
  }

  void _logScroll(String event, Map<String, Object?> fields) {
    logWorkspaceRender('chatScroll.$event', {
      'timelineKeyHash': _diagnosticHash(widget.pageStorageKey),
      'messages': widget.messages.length,
      'generation': _bottomScrollGeneration,
      'hasInitialBottom': _hasScrolledToInitialBottom,
      'autoStick': _autoStickToBottom,
      'pinnedAway': _userPinnedAwayFromBottom,
      'loadingOlder': _loadOlderInFlight,
      if (_controller.hasClients) ..._scrollMetricFields(_controller.position),
      ...fields,
    });
  }

  Map<String, Object?> _scrollMetricFields(ScrollMetrics metrics) {
    return {
      'pixels': _scrollNumber(metrics.pixels),
      'min': _scrollNumber(metrics.minScrollExtent),
      'max': _scrollNumber(metrics.maxScrollExtent),
      'fromBottom': _scrollNumber(metrics.maxScrollExtent - metrics.pixels),
      'fromTop': _scrollNumber(metrics.pixels - metrics.minScrollExtent),
    };
  }

  bool _isAtBottom() {
    if (!_controller.hasClients) {
      return true;
    }
    final position = _controller.position;
    return position.maxScrollExtent - position.pixels <= 1;
  }

  void _saveOffset(String key) {
    if (_controller.hasClients) {
      _savedOffsets[key] = _controller.offset;
      _savedPinnedToBottom[key] =
          !_suppressBottomReturnUntilAway && _isAtBottom();
    }
  }

  MemberSeed _memberForMessage(MessageSeed message) {
    for (final member in widget.members) {
      if (_memberMatchesMessage(member, message)) {
        return member;
      }
    }
    return MemberSeed(
      id: message.authorId,
      name: message.author,
      username: message.author,
      status: 'Offline',
      initials: message.initials,
      role: 'Member',
      displayColor: message.authorColor,
      avatarUrl: message.avatarUrl,
      bannerBaseColor: message.authorBannerBaseColor,
      isActive: false,
    );
  }

  bool _memberMatchesMessage(MemberSeed member, MessageSeed message) {
    final memberId = member.id?.trim();
    final authorId = message.authorId.trim();
    if (memberId == null || memberId.isEmpty || authorId.isEmpty) {
      return false;
    }
    if (memberId == authorId) {
      return true;
    }
    final networkId = widget.networkId;
    if (networkId == null || authorId.contains('/')) {
      return false;
    }
    final slash = memberId.indexOf('/');
    if (slash <= 0 ||
        memberId.indexOf('/', slash + 1) >= 0 ||
        !sameWorkspaceNetworkId(memberId.substring(0, slash), networkId)) {
      return false;
    }
    try {
      return safeWorkspaceLocalId(memberId, allowScopedPrefix: true) ==
          safeWorkspaceLocalId(authorId);
    } on FormatException {
      return false;
    }
  }
}

typedef _MessageTimelineRowBuilder =
    Widget Function(
      void Function(String, WorkspaceYouTubePlaybackSnapshot)
      onYoutubePlaybackChanged,
    );

class _TimelineMessageEntry {
  const _TimelineMessageEntry({required this.message, this.removing = false});

  final MessageSeed message;
  final bool removing;

  _TimelineMessageEntry copyWith({MessageSeed? message, bool? removing}) {
    return _TimelineMessageEntry(
      message: message ?? this.message,
      removing: removing ?? this.removing,
    );
  }
}

class _MessageTimelineRow extends StatefulWidget {
  const _MessageTimelineRow({
    required this.message,
    required this.removing,
    required this.playbackMemory,
    required this.childBuilder,
    super.key,
  });

  final MessageSeed message;
  final bool removing;
  final WorkspaceYouTubePlaybackMemory playbackMemory;
  final _MessageTimelineRowBuilder childBuilder;

  @override
  State<_MessageTimelineRow> createState() => _MessageTimelineRowState();
}

class _MessageTimelineRowState extends State<_MessageTimelineRow>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _removalController;
  late final CurvedAnimation _removalAnimation;
  var _hasActiveYoutubePlayback = false;

  @override
  bool get wantKeepAlive => _hasActiveYoutubePlayback || widget.removing;

  @override
  void initState() {
    super.initState();
    _removalController = AnimationController(
      vsync: this,
      duration: _messageDeletionCollapseDuration,
      value: widget.removing ? 0 : 1,
    );
    _removalAnimation = CurvedAnimation(
      parent: _removalController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _hasActiveYoutubePlayback = _messageHasActiveYouTubePlayback(
      widget.message,
      widget.playbackMemory,
    );
  }

  @override
  void didUpdateWidget(covariant _MessageTimelineRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.playbackMemory != widget.playbackMemory) {
      _hasActiveYoutubePlayback = _messageHasActiveYouTubePlayback(
        widget.message,
        widget.playbackMemory,
      );
      updateKeepAlive();
    }
    if (!oldWidget.removing && widget.removing) {
      _removalController.reverse();
      updateKeepAlive();
    } else if (oldWidget.removing && !widget.removing) {
      _removalController.forward();
      updateKeepAlive();
    }
  }

  @override
  void dispose() {
    _removalAnimation.dispose();
    _removalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _removalAnimation,
        alignment: AlignmentDirectional.topStart,
        child: FadeTransition(
          opacity: _removalAnimation,
          child: widget.childBuilder(_handleYoutubePlaybackChanged),
        ),
      ),
    );
  }

  void _handleYoutubePlaybackChanged(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  ) {
    final nextActive = _messageHasActiveYouTubePlayback(
      widget.message,
      widget.playbackMemory,
    );
    if (nextActive == _hasActiveYoutubePlayback) {
      return;
    }
    setState(() => _hasActiveYoutubePlayback = nextActive);
    updateKeepAlive();
  }
}

bool _messageHasActiveYouTubePlayback(
  MessageSeed message,
  WorkspaceYouTubePlaybackMemory playbackMemory,
) {
  return extractMessageLinkPreviews(message.body)
      .map((preview) => preview.youtubeEmbed?.videoId)
      .whereType<String>()
      .any((videoId) => playbackMemory.snapshotFor(videoId).isPlaying);
}

@visibleForTesting
void debugClearMessageTimelineScrollState() {
  _MessageTimelineState._savedOffsets.clear();
  _MessageTimelineState._savedPinnedToBottom.clear();
}

bool _shouldShowMessageHeader(MessageSeed? previous, MessageSeed message) {
  if (previous == null || previous.authorId != message.authorId) {
    return true;
  }
  final previousTime = _messageTime(previous);
  final messageTime = _messageTime(message);
  if (previousTime == null || messageTime == null) {
    return false;
  }
  return messageTime.difference(previousTime) > _messageGroupWindow;
}

DateTime? _messageTime(MessageSeed message) {
  final rawCreatedAt = message.createdAt;
  if (rawCreatedAt != null) {
    final parsed = DateTime.tryParse(rawCreatedAt);
    if (parsed != null) {
      return parsed;
    }
  }
  final parsedDisplay = DateTime.tryParse(message.time);
  if (parsedDisplay != null) {
    return parsedDisplay;
  }
  return _timeOfDay(message.time);
}

DateTime? _timeOfDay(String value) {
  final match = RegExp(
    r'(?:Today at\s+)?(\d{1,2}):(\d{2})\s*(AM|PM)?',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) {
    return null;
  }
  final rawHour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (rawHour == null ||
      minute == null ||
      rawHour < 0 ||
      rawHour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  final suffix = match.group(3)?.toUpperCase();
  var hour = rawHour;
  if (suffix == 'AM') {
    hour = rawHour == 12 ? 0 : rawHour;
  } else if (suffix == 'PM') {
    hour = rawHour == 12 ? 12 : rawHour + 12;
  }
  if (hour > 23) {
    return null;
  }
  return DateTime(2000, 1, 1, hour, minute);
}

class _TimelineStartMarker extends StatelessWidget {
  const _TimelineStartMarker({required this.label, required this.storageKey});

  final String label;
  final String storageKey;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Padding(
      key: ValueKey<String>('message-timeline-start-$storageKey'),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 18),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.border)),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.border)),
        ],
      ),
    );
  }
}

class _TimelineScrollIndicator extends StatefulWidget {
  const _TimelineScrollIndicator({
    required this.controller,
    required this.metricsVersion,
    required this.storageKey,
  });

  static const _trackTop = 8.0;
  static const _trackBottom = 8.0;
  static const _thumbMinHeight = 34.0;
  static const _thumbWidth = 3.0;
  static const _hitWidth = 14.0;
  static const _animationDuration = Duration(milliseconds: 110);
  static const _metricsSettleDelay = Duration(milliseconds: 180);

  final ScrollController controller;
  final ValueListenable<int> metricsVersion;
  final String storageKey;

  @override
  State<_TimelineScrollIndicator> createState() =>
      _TimelineScrollIndicatorState();
}

class _TimelineScrollIndicatorState extends State<_TimelineScrollIndicator> {
  _TimelineScrollMetrics? _visualMetrics;
  _TimelineScrollMetrics? _pendingMetrics;
  _TimelineScrollbarDragAnchor? _dragAnchor;
  Timer? _metricsSettleTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScrollOrMetricsChanged);
    widget.metricsVersion.addListener(_handleScrollOrMetricsChanged);
  }

  @override
  void didUpdateWidget(covariant _TimelineScrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleScrollOrMetricsChanged);
      widget.controller.addListener(_handleScrollOrMetricsChanged);
      _visualMetrics = null;
      _pendingMetrics = null;
      _dragAnchor = null;
      _metricsSettleTimer?.cancel();
      _metricsSettleTimer = null;
    }
    if (oldWidget.metricsVersion != widget.metricsVersion) {
      oldWidget.metricsVersion.removeListener(_handleScrollOrMetricsChanged);
      widget.metricsVersion.addListener(_handleScrollOrMetricsChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScrollOrMetricsChanged);
    widget.metricsVersion.removeListener(_handleScrollOrMetricsChanged);
    _metricsSettleTimer?.cancel();
    super.dispose();
  }

  void _handleScrollOrMetricsChanged() {
    final actualMetrics = _readMetrics();
    if (actualMetrics != null) {
      _reconcileVisualMetrics(actualMetrics);
    }
    if (mounted) {
      setState(() {});
    }
  }

  _TimelineScrollMetrics? _readMetrics() {
    if (!widget.controller.hasClients ||
        !widget.controller.position.haveDimensions) {
      return null;
    }
    final position = widget.controller.position;
    return _TimelineScrollMetrics(
      minScrollExtent: position.minScrollExtent,
      maxScrollExtent: position.maxScrollExtent,
      viewportDimension: position.viewportDimension,
    );
  }

  void _reconcileVisualMetrics(_TimelineScrollMetrics actualMetrics) {
    final currentMetrics = _visualMetrics;
    if (currentMetrics == null || currentMetrics.isSameExtent(actualMetrics)) {
      _visualMetrics = actualMetrics;
      _pendingMetrics = null;
      _metricsSettleTimer?.cancel();
      _metricsSettleTimer = null;
      return;
    }

    _schedulePendingMetrics(actualMetrics);
  }

  void _schedulePendingMetrics(_TimelineScrollMetrics actualMetrics) {
    if (_dragAnchor != null) {
      _pendingMetrics = actualMetrics;
      return;
    }
    _pendingMetrics = actualMetrics;
    _metricsSettleTimer?.cancel();
    _metricsSettleTimer = Timer(
      _TimelineScrollIndicator._metricsSettleDelay,
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _visualMetrics = _readMetrics() ?? _pendingMetrics;
          _pendingMetrics = null;
          _metricsSettleTimer = null;
        });
      },
    );
  }

  _TimelineScrollbarGeometry? _geometryFor(
    BoxConstraints constraints,
    _TimelineScrollMetrics metrics,
  ) {
    final viewport = metrics.viewportDimension;
    final scrollRange = metrics.maxScrollExtent - metrics.minScrollExtent;
    if (scrollRange <= 1 || viewport <= 0) {
      return null;
    }

    final trackHeight =
        constraints.maxHeight -
        _TimelineScrollIndicator._trackTop -
        _TimelineScrollIndicator._trackBottom;
    if (trackHeight <= 0) {
      return null;
    }

    final totalExtent = scrollRange + viewport;
    final thumbHeight = (viewport / totalExtent * trackHeight)
        .clamp(_TimelineScrollIndicator._thumbMinHeight, trackHeight)
        .toDouble();
    return _TimelineScrollbarGeometry(
      trackHeight: trackHeight,
      thumbHeight: thumbHeight,
      scrollRange: scrollRange,
    );
  }

  void _handleDragStart(
    DragStartDetails details,
    BoxConstraints constraints,
    _TimelineScrollMetrics metrics,
  ) {
    if (!widget.controller.hasClients) {
      return;
    }
    final geometry = _geometryFor(constraints, metrics);
    if (geometry == null || geometry.thumbTravel <= 0) {
      return;
    }
    _metricsSettleTimer?.cancel();
    _metricsSettleTimer = null;
    setState(() {
      _dragAnchor = _TimelineScrollbarDragAnchor(
        globalY: details.globalPosition.dy,
        scrollPixels: widget.controller.position.pixels,
        metrics: metrics,
        geometry: geometry,
      );
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final anchor = _dragAnchor;
    if (anchor == null || !widget.controller.hasClients) {
      return;
    }
    final deltaY = details.globalPosition.dy - anchor.globalY;
    final scrollDelta =
        deltaY / anchor.geometry.thumbTravel * anchor.geometry.scrollRange;
    final target = (anchor.scrollPixels + scrollDelta)
        .clamp(
          widget.controller.position.minScrollExtent,
          widget.controller.position.maxScrollExtent,
        )
        .toDouble();
    widget.controller.jumpTo(target);
  }

  void _handleDragEnd() {
    final pendingMetrics = _pendingMetrics;
    setState(() {
      _dragAnchor = null;
    });
    if (pendingMetrics != null) {
      _schedulePendingMetrics(pendingMetrics);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Positioned.fill(
      key: ValueKey<String>(
        'message-timeline-scroll-indicator-${widget.storageKey}',
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actualMetrics = _readMetrics();
          if (_visualMetrics == null && actualMetrics != null) {
            _visualMetrics = actualMetrics;
          }
          final visualMetrics = _visualMetrics ?? actualMetrics;
          if (visualMetrics == null ||
              constraints.maxHeight <=
                  _TimelineScrollIndicator._trackTop +
                      _TimelineScrollIndicator._trackBottom) {
            return const SizedBox.shrink();
          }

          if (actualMetrics != null &&
              !visualMetrics.isSameExtent(actualMetrics)) {
            _schedulePendingMetrics(actualMetrics);
          }
          final geometry = _geometryFor(constraints, visualMetrics);
          if (geometry == null) {
            return const SizedBox.shrink();
          }

          final pixels = widget.controller.hasClients
              ? widget.controller.position.pixels
              : visualMetrics.minScrollExtent;
          final progress =
              ((pixels - visualMetrics.minScrollExtent) / geometry.scrollRange)
                  .clamp(0.0, 1.0)
                  .toDouble();
          final thumbTop =
              _TimelineScrollIndicator._trackTop +
              geometry.thumbTravel * progress;

          return Stack(
            children: [
              Positioned(
                top: _TimelineScrollIndicator._trackTop,
                right: 2,
                width: 1,
                height: geometry.trackHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                key: ValueKey<String>(
                  'message-timeline-scroll-thumb-${widget.storageKey}',
                ),
                duration: _dragAnchor == null
                    ? _TimelineScrollIndicator._animationDuration
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                top: thumbTop,
                right: 1,
                width: _TimelineScrollIndicator._thumbWidth,
                height: geometry.thumbHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                key: ValueKey<String>(
                  'message-timeline-scrollbar-hit-${widget.storageKey}',
                ),
                top: 0,
                right: 0,
                bottom: 0,
                width: _TimelineScrollIndicator._hitWidth,
                child: MouseRegion(
                  cursor: SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (details) => _handleDragStart(
                      details,
                      constraints,
                      actualMetrics ?? visualMetrics,
                    ),
                    onVerticalDragUpdate: _handleDragUpdate,
                    onVerticalDragEnd: (_) => _handleDragEnd(),
                    onVerticalDragCancel: _handleDragEnd,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineScrollbarGeometry {
  const _TimelineScrollbarGeometry({
    required this.trackHeight,
    required this.thumbHeight,
    required this.scrollRange,
  });

  final double trackHeight;
  final double thumbHeight;
  final double scrollRange;

  double get thumbTravel => trackHeight - thumbHeight;
}

class _TimelineScrollbarDragAnchor {
  const _TimelineScrollbarDragAnchor({
    required this.globalY,
    required this.scrollPixels,
    required this.metrics,
    required this.geometry,
  });

  final double globalY;
  final double scrollPixels;
  final _TimelineScrollMetrics metrics;
  final _TimelineScrollbarGeometry geometry;
}

class _TimelineScrollMetrics {
  const _TimelineScrollMetrics({
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.viewportDimension,
  });

  final double minScrollExtent;
  final double maxScrollExtent;
  final double viewportDimension;

  bool isSameExtent(_TimelineScrollMetrics other) {
    return (minScrollExtent - other.minScrollExtent).abs() < 0.5 &&
        (maxScrollExtent - other.maxScrollExtent).abs() < 0.5 &&
        (viewportDimension - other.viewportDimension).abs() < 0.5;
  }
}

class _MessagePrependAnchor {
  const _MessagePrependAnchor({required this.messageId, required this.top});

  final String messageId;
  final double top;
}

Element? _findElementByWidgetKey(BuildContext root, Key key) {
  Element? result;

  void visitor(Element element) {
    if (result != null) {
      return;
    }
    if (element.widget.key == key) {
      result = element;
      return;
    }
    element.visitChildElements(visitor);
  }

  root.visitChildElements(visitor);
  return result;
}

double _scrollNumber(double value) {
  if (!value.isFinite) {
    return value;
  }
  return (value * 10).roundToDouble() / 10;
}

String _diagnosticHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
