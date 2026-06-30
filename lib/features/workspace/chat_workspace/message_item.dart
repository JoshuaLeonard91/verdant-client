import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../shared/chat_timestamp_format.dart';
import '../shared/custom_expressive_asset.dart';
import '../shared/member_profile_popover.dart';
import '../shared/user_identity_labels.dart';
import '../shared/youtube_embed/workspace_youtube_playback_memory.dart';
import '../shared/youtube_embed/workspace_youtube_preview.dart';
import '../workspace_seed.dart';
import 'custom_expression_metadata_menu.dart';
import 'chat_invite_link.dart';
import 'emoji_picker_popover.dart';
import 'message_media_preview.dart';
import 'message_mentions.dart';
import 'message_invite_card.dart';
import 'message_link_preview.dart';
import 'link_preview_service.dart';
import 'message_reaction_chip.dart';

part 'message_context_menu.dart';
part 'message_identity.dart';
part 'message_reactions.dart';
part 'message_text.dart';

const _messageMentionTextColor = Color(0xFF4ADE80);
const _messageMentionBackgroundColor = Color(0x264ADE80);
const _messageMentionHoverBackgroundColor = Color(0x334ADE80);
const _messageMentionPressedBackgroundColor = Color(0x474ADE80);

class MessageItem extends StatefulWidget {
  const MessageItem({
    required this.message,
    required this.showHeader,
    required this.mediaPolicy,
    this.profileMember,
    this.networkId,
    this.mentionMembers = const [],
    this.customEmojis = const [],
    this.customStickers = const [],
    this.customExpressionSources = const {},
    this.onPrepareMemberProfile,
    this.timestampOptions,
    this.linkPreviewService,
    this.youtubePlayerBuilder,
    this.youtubePlaybackMemory,
    this.onYoutubePlaybackChanged,
    this.canManageMessages = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onSetReaction,
    this.onPreviewInvite,
    this.onAcceptInvite,
    this.onInviteLayoutSettled,
    this.onMediaLayoutSettled,
    this.onReactionLayoutSettled,
    super.key,
  });

  final MessageSeed message;
  final MemberSeed? profileMember;
  final String? networkId;
  final List<MemberSeed> mentionMembers;
  final List<ServerCustomEmoji> customEmojis;
  final List<ServerCustomSticker> customStickers;
  final Map<String, CustomExpressionSource> customExpressionSources;
  final FutureOr<MemberSeed> Function(MemberSeed member)?
  onPrepareMemberProfile;
  final ChatTimestampFormatOptions? timestampOptions;
  final MessageLinkPreviewService? linkPreviewService;
  final WorkspaceYouTubePlayerBuilder? youtubePlayerBuilder;
  final WorkspaceYouTubePlaybackMemory? youtubePlaybackMemory;
  final void Function(
    String videoId,
    WorkspaceYouTubePlaybackSnapshot snapshot,
  )?
  onYoutubePlaybackChanged;
  final bool canManageMessages;
  final bool showHeader;
  final ServerMediaPolicy mediaPolicy;
  final ValueChanged<MessageSeed>? onReply;
  final ValueChanged<MessageSeed>? onEdit;
  final ValueChanged<MessageSeed>? onDelete;
  final ServerReactionChangeHandler? onSetReaction;
  final ChatInvitePreviewHandler? onPreviewInvite;
  final ChatInviteAcceptHandler? onAcceptInvite;
  final VoidCallback? onInviteLayoutSettled;
  final VoidCallback? onMediaLayoutSettled;
  final VoidCallback? onReactionLayoutSettled;

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> {
  final _actionBarKey = GlobalKey();
  final _reactionBarKey = GlobalKey();
  var _isHovered = false;
  var _menuOpen = false;
  OverlayEntry? _contextMenuEntry;
  OverlayEntry? _mentionContextMenuEntry;
  OverlayEntry? _reactionPickerEntry;
  OverlayEntry? _profileEntry;
  late List<ReactionSeed> _reactions;
  var _suppressNextMessageContextMenu = false;
  var _profileRequestSerial = 0;
  Timer? _mentionContextMenuSuppressTimer;

  MessageSeed get message => widget.message;
  MemberSeed get profileMember =>
      widget.profileMember ??
      MemberSeed(
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

  @override
  void initState() {
    super.initState();
    _reactions = [...message.reactions];
  }

  @override
  void dispose() {
    _mentionContextMenuSuppressTimer?.cancel();
    _removeMessageContextMenu(updateState: false);
    _removeMentionContextMenu(updateState: false);
    _removeReactionPicker(updateState: false);
    _removeProfilePopover();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != message.id ||
        !_sameReactionSnapshot(
          oldWidget.message.reactions,
          message.reactions,
        )) {
      _reactions = [...message.reactions];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final showActionBar = _isHovered || _menuOpen;
    final klipyMedia = message.media == null
        ? klipyMediaFromMessageBody(message)
        : null;
    final inlineMedia = message.media ?? klipyMedia;
    final inviteTargets = extractChatInviteTargets(message.body);
    final previewableBody = removeChatInviteLinksFromBody(
      _messageDisplayBody(message, klipyMedia),
    );
    final linkPreviews = extractMessageLinkPreviews(previewableBody);
    final displayBody = removePreviewedLinksFromMessageBody(
      previewableBody,
      linkPreviews,
    );
    final createdAt = _messageCreatedAt(message);
    final timestamp = formatChatTimestamp(
      createdAt: createdAt,
      fallbackLabel: message.time,
      now: DateTime.now(),
      options:
          widget.timestampOptions ??
          ChatTimestampFormatOptions.fromLocale(
            Localizations.localeOf(context),
          ),
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          left: 6,
          right: 6,
          top: widget.showHeader ? 6 : 0,
          bottom: inlineMedia == null ? 3 : 8,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: (details) {
              if (_suppressNextMessageContextMenu ||
                  _mentionContextMenuEntry != null) {
                _clearMentionContextMenuSuppression();
                return;
              }
              _showMessageContextMenu(details.globalPosition);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  key: ValueKey('message-hover-surface-${message.id}'),
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: showActionBar
                        ? colors.panelHover.withValues(alpha: 0.42)
                        : Colors.transparent,
                    borderRadius: VerdantRadii.sharp,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showHeader)
                        MessageAvatar(
                          member: profileMember,
                          mediaPolicy: widget.mediaPolicy,
                          onOpenProfile: _showAuthorProfile,
                        )
                      else
                        const SizedBox(width: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.showHeader) ...[
                              MessageMeta(
                                authorKey: profileMember.id ?? message.authorId,
                                author: message.author,
                                time: timestamp,
                                isOwnMessage: message.isOwnMessage,
                                authorColor:
                                    profileMember.displayColor ??
                                    message.authorColor,
                                onOpenProfile: _showAuthorProfile,
                              ),
                              const SizedBox(height: 3),
                            ],
                            if (displayBody.isNotEmpty)
                              _MessageText(
                                body: displayBody,
                                messageId: message.id,
                                networkId: widget.networkId,
                                members: widget.mentionMembers,
                                mediaPolicy: widget.mediaPolicy,
                                customEmojis: widget.customEmojis,
                                customStickers: widget.customStickers,
                                customExpressionSources:
                                    widget.customExpressionSources,
                                onOpenMention: _showMentionProfile,
                                onMentionContextMenu: _showMentionContextMenu,
                                onMentionSecondaryPointerDown:
                                    _suppressNextMessageContextMenuForNestedTarget,
                                onCustomExpressionSecondaryPointerDown:
                                    _suppressNextMessageContextMenuForNestedTarget,
                              ),
                            if (inviteTargets.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              for (
                                var index = 0;
                                index < inviteTargets.length;
                                index += 1
                              )
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == inviteTargets.length - 1
                                        ? 0
                                        : 6,
                                  ),
                                  child: MessageInviteCard(
                                    key: _inviteCardKey(message.id, index),
                                    messageId: message.id,
                                    target: inviteTargets[index],
                                    mediaPolicy: widget.mediaPolicy,
                                    onPreview: widget.onPreviewInvite,
                                    onAccept: widget.onAcceptInvite,
                                    onLayoutSettled:
                                        widget.onInviteLayoutSettled,
                                  ),
                                ),
                            ],
                            if (linkPreviews.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              MessageLinkPreviews(
                                messageId: message.id,
                                previews: linkPreviews,
                                cacheScope: widget.networkId ?? 'legacy',
                                linkPreviewService: widget.linkPreviewService,
                                youtubePlayerBuilder:
                                    widget.youtubePlayerBuilder,
                                youtubePlaybackMemory:
                                    widget.youtubePlaybackMemory,
                                onYoutubePlaybackChanged:
                                    widget.onYoutubePlaybackChanged,
                                onLayoutSettled: widget.onMediaLayoutSettled,
                              ),
                            ],
                            if (inlineMedia case final media?) ...[
                              const SizedBox(height: 8),
                              MessageMediaPreview(
                                key: ValueKey('message-media-${media.id}'),
                                media: media,
                                mediaPolicy: widget.mediaPolicy,
                                loadState: indexBasedLoadState(message.id),
                                onLayoutSettled: widget.onMediaLayoutSettled,
                              ),
                            ],
                            if (_reactions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              MessageReactionBar(
                                key: _reactionBarKey,
                                messageId: message.id,
                                initialReactions: _reactions,
                                mediaPolicy: widget.mediaPolicy,
                                customEmojis: widget.customEmojis,
                                onSetReaction: widget.onSetReaction,
                                onChanged: (reactions) {
                                  setState(() => _reactions = reactions);
                                  _notifyReactionLayoutSettled();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showActionBar)
                  Positioned(
                    top: 0,
                    right: 14,
                    child: AnimatedScale(
                      scale: showActionBar ? 1 : 0.96,
                      duration: const Duration(milliseconds: 110),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: showActionBar ? 1 : 0,
                        duration: const Duration(milliseconds: 110),
                        curve: Curves.easeOutCubic,
                        child: KeyedSubtree(
                          key: _actionBarKey,
                          child: _MessageActionBar(
                            messageId: message.id,
                            isOwnMessage: message.isOwnMessage,
                            onReact: _showReactionPicker,
                            onReply: () => _handleMessageAction('reply'),
                            onEdit: () => _handleMessageAction('edit'),
                            onMore: _showMessageContextMenu,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAuthorProfile(Rect anchorRect) {
    unawaited(_showMemberProfile(profileMember, anchorRect));
  }

  void _showMentionProfile(MessageMentionResolution mention, Rect anchorRect) {
    final member = mention.member;
    if (member == null) {
      return;
    }
    unawaited(_showMemberProfile(member, anchorRect));
  }

  Future<void> _showMemberProfile(MemberSeed member, Rect anchorRect) async {
    _removeProfilePopover();
    final requestSerial = ++_profileRequestSerial;
    final prepare = widget.onPrepareMemberProfile;
    final prepared = prepare == null
        ? member
        : await Future<MemberSeed>.value(prepare(member));
    if (!mounted || requestSerial != _profileRequestSerial) {
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    final viewportRect = _overlayViewportRect(overlay);
    final side = _preferredProfilePopoverSide(anchorRect, viewportRect);
    final entry = OverlayEntry(
      builder: (context) {
        return MemberIdentityPopoverOverlay(
          member: prepared,
          mediaPolicy: widget.mediaPolicy,
          anchorRect: anchorRect,
          side: side,
          viewportRect: viewportRect,
          onDismiss: _removeProfilePopover,
        );
      },
    );
    _profileEntry = entry;
    overlay.insert(entry);
  }

  Rect? _overlayViewportRect(OverlayState overlay) {
    final box = overlay.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  MemberIdentityPopoverSide _preferredProfilePopoverSide(
    Rect anchorRect,
    Rect? viewportRect,
  ) {
    final bounds =
        viewportRect ??
        Rect.fromLTWH(
          0,
          0,
          MediaQuery.maybeSizeOf(context)?.width ?? 0,
          MediaQuery.maybeSizeOf(context)?.height ?? 0,
        );
    final rightSpace = bounds.right - anchorRect.right;
    final leftSpace = anchorRect.left - bounds.left;
    const preferredSpace = 318.0;
    if (rightSpace >= preferredSpace) {
      return MemberIdentityPopoverSide.right;
    }
    if (leftSpace >= preferredSpace) {
      return MemberIdentityPopoverSide.left;
    }
    return rightSpace >= leftSpace
        ? MemberIdentityPopoverSide.right
        : MemberIdentityPopoverSide.left;
  }

  void _removeProfilePopover() {
    _profileRequestSerial += 1;
    _profileEntry?.remove();
    _profileEntry = null;
  }

  void _showMessageContextMenu(Offset globalPosition) {
    _removeMentionContextMenu();
    _removeMessageContextMenu();
    setState(() => _menuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _insertMessageContextMenu(globalPosition);
      }
    });
  }

  void _insertMessageContextMenu(Offset fallbackPosition) {
    _removeMessageContextMenu(updateState: false);
    final overlay = Overlay.of(context, rootOverlay: true);
    final anchorRect =
        _actionBarGlobalRect() ??
        Rect.fromLTWH(fallbackPosition.dx, fallbackPosition.dy, 0, 0);
    final entry = OverlayEntry(
      builder: (context) {
        return _MessageContextMenuOverlay(
          messageId: message.id,
          anchorRect: anchorRect,
          entries: _contextEntries(),
          onSelected: (selected) {
            _removeMessageContextMenu();
            _handleMessageAction(selected);
          },
          onDismiss: _removeMessageContextMenu,
        );
      },
    );
    _contextMenuEntry = entry;
    overlay.insert(entry);
  }

  void _suppressNextMessageContextMenuForNestedTarget() {
    _suppressNextMessageContextMenu = true;
    _mentionContextMenuSuppressTimer?.cancel();
    _mentionContextMenuSuppressTimer = Timer(
      const Duration(milliseconds: 350),
      () {
        _suppressNextMessageContextMenu = false;
      },
    );
  }

  void _clearMentionContextMenuSuppression() {
    _mentionContextMenuSuppressTimer?.cancel();
    _mentionContextMenuSuppressTimer = null;
    _suppressNextMessageContextMenu = false;
  }

  Rect? _actionBarGlobalRect() {
    final box = _actionBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _removeMessageContextMenu({bool updateState = true}) {
    _contextMenuEntry?.remove();
    _contextMenuEntry = null;
    if (updateState && mounted && _menuOpen) {
      setState(() => _menuOpen = false);
    }
  }

  void _showMentionContextMenu(
    MessageMentionResolution mention,
    Offset globalPosition,
  ) {
    final localUserId = mention.localUserId;
    if (localUserId == null || mention.member == null) {
      return;
    }
    _suppressNextMessageContextMenuForNestedTarget();
    _removeMessageContextMenu();
    _removeMentionContextMenu(clearSuppression: false);
    setState(() => _menuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _insertMentionContextMenu(
          mention: mention,
          localUserId: localUserId,
          globalPosition: globalPosition,
        );
      }
    });
  }

  void _insertMentionContextMenu({
    required MessageMentionResolution mention,
    required String localUserId,
    required Offset globalPosition,
  }) {
    _removeMentionContextMenu(updateState: false, clearSuppression: false);
    final overlay = Overlay.of(context, rootOverlay: true);
    final anchorRect = Rect.fromLTWH(
      globalPosition.dx,
      globalPosition.dy,
      0,
      0,
    );
    final entry = OverlayEntry(
      builder: (context) {
        return _MessageContextMenuOverlay(
          messageId: message.id,
          menuKey: 'message-mention-context-menu-${message.id}-$localUserId',
          anchorRect: anchorRect,
          entries: [
            _MessageContextMenuItem(
              id: 'copy_user_id',
              label: workspaceUserCopyLabel(mention.member?.id),
              icon: PhosphorIcons.copy,
            ),
          ],
          onSelected: (selected) {
            _removeMentionContextMenu();
            if (selected == 'copy_user_id') {
              Clipboard.setData(
                ClipboardData(
                  text: workspaceUserClipboardId(
                    mention.member?.id ?? mention.clipboardUserId,
                    fallback: localUserId,
                  ),
                ),
              );
            }
          },
          onDismiss: _removeMentionContextMenu,
        );
      },
    );
    _mentionContextMenuEntry = entry;
    overlay.insert(entry);
  }

  void _removeMentionContextMenu({
    bool updateState = true,
    bool clearSuppression = true,
  }) {
    _mentionContextMenuEntry?.remove();
    _mentionContextMenuEntry = null;
    if (clearSuppression) {
      _clearMentionContextMenuSuppression();
    }
    if (updateState && mounted && _menuOpen && _contextMenuEntry == null) {
      setState(() => _menuOpen = false);
    }
  }

  List<_MessageContextMenuEntry> _contextEntries() {
    final canDelete =
        widget.onDelete != null &&
        (message.isOwnMessage || widget.canManageMessages);
    return [
      const _MessageContextMenuItem(
        id: 'react',
        label: 'Add Reaction',
        icon: PhosphorIcons.smiley,
      ),
      const _MessageContextMenuItem(
        id: 'reply',
        label: 'Reply',
        icon: PhosphorIcons.arrowBendUpLeft,
      ),
      if (message.isOwnMessage)
        const _MessageContextMenuItem(
          id: 'edit',
          label: 'Edit Message',
          icon: PhosphorIcons.pencilSimpleLine,
        ),
      if (canDelete)
        const _MessageContextMenuItem(
          id: 'delete',
          label: 'Delete Message',
          icon: PhosphorIcons.trash,
          danger: true,
        ),
      const _MessageContextMenuDivider(),
      const _MessageContextMenuItem(
        id: 'copy',
        label: 'Copy Text',
        icon: PhosphorIcons.copy,
      ),
      const _MessageContextMenuItem(
        id: 'copy_id',
        label: 'Copy Message ID',
        icon: PhosphorIcons.hash,
      ),
    ];
  }

  void _handleMessageAction(String action) {
    switch (action) {
      case 'react':
        _showReactionPicker();
      case 'copy':
        Clipboard.setData(ClipboardData(text: message.body));
      case 'copy_id':
        Clipboard.setData(ClipboardData(text: message.id));
      case 'reply':
        widget.onReply?.call(message);
      case 'edit':
        widget.onEdit?.call(message);
      case 'delete':
        widget.onDelete?.call(message);
        break;
    }
  }

  void _addReaction(String emoji) {
    final existing = _reactions.indexWhere(
      (reaction) => reaction.emoji == emoji,
    );
    final existingReaction = existing >= 0 ? _reactions[existing] : null;
    final selected = existingReaction == null
        ? true
        : !existingReaction.reactedByCurrentUser;
    setState(() {
      if (existing >= 0) {
        _reactions = [
          for (final reaction in _reactions)
            if (reaction.emoji == emoji)
              _toggledReaction(reaction)
            else
              reaction,
        ].where((reaction) => reaction.count > 0).toList(growable: false);
      } else {
        _reactions = [
          ..._reactions,
          ReactionSeed(emoji: emoji, count: 1, reactedByCurrentUser: true),
        ];
      }
    });
    unawaited(
      widget.onSetReaction?.call(
            messageId: message.id,
            emoji: emoji,
            emojiId: existingReaction?.emojiId,
            selected: selected,
          ) ??
          Future<void>.value(),
    );
    _notifyReactionLayoutSettled();
  }

  void _showReactionPicker() {
    _removeMessageContextMenu();
    _removeReactionPicker();
    setState(() => _menuOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final overlay = Overlay.of(context, rootOverlay: true);
      final fallbackBox = context.findRenderObject() as RenderBox?;
      final fallbackRect = fallbackBox == null || !fallbackBox.hasSize
          ? null
          : fallbackBox.localToGlobal(Offset.zero) & fallbackBox.size;
      final anchorRect = _actionBarGlobalRect() ?? fallbackRect ?? Rect.zero;
      final entry = OverlayEntry(
        builder: (context) {
          return _ReactionPickerOverlay(
            anchorRect: anchorRect,
            mediaPolicy: widget.mediaPolicy,
            customEmojis: widget.customEmojis,
            onDismiss: _removeReactionPicker,
            onSelected: (emoji) {
              _removeReactionPicker();
              _addReaction(emoji);
            },
          );
        },
      );
      _reactionPickerEntry = entry;
      overlay.insert(entry);
    });
  }

  void _removeReactionPicker({bool updateState = true}) {
    _reactionPickerEntry?.remove();
    _reactionPickerEntry = null;
    if (updateState && mounted && _menuOpen && _contextMenuEntry == null) {
      setState(() => _menuOpen = false);
    }
  }

  void _notifyReactionLayoutSettled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final targetContext = _reactionBarKey.currentContext ?? context;
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
        widget.onReactionLayoutSettled?.call();
      });
    });
  }
}

MediaPreviewLoadState indexBasedLoadState(String messageId) {
  final trailingDigits = RegExp(r'\d+$').firstMatch(messageId)?.group(0);
  final index = int.tryParse(trailingDigits ?? '') ?? 0;
  return index.isEven
      ? MediaPreviewLoadState.ready
      : MediaPreviewLoadState.loading;
}

ValueKey<String> _inviteCardKey(String messageId, int index) {
  final suffix = index == 0 ? '' : '-$index';
  return ValueKey('message-invite-card-$messageId$suffix');
}

@visibleForTesting
MessageMediaSeed? klipyMediaFromMessageBody(MessageSeed message) {
  final match = _klipyImageUrlPattern.firstMatch(message.body);
  if (match == null) {
    return null;
  }
  final url = match.group(0);
  if (url == null) {
    return null;
  }
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  final extension = _mediaExtension(uri);
  final kind = switch (extension) {
    'gif' => MessageMediaKind.gif,
    'webp' => MessageMediaKind.webp,
    'png' || 'jpg' || 'jpeg' => MessageMediaKind.image,
    _ => null,
  };
  if (kind == null) {
    return null;
  }
  return MessageMediaSeed(
    id: '${message.id}/klipy-${match.start}',
    label: 'Klipy media',
    kind: kind,
    width: 480,
    height: 320,
    url: url,
  );
}

final _klipyImageUrlPattern = RegExp(
  r'''https://(?:static|media)\.klipy\.com/[^\s<>"']+\.(?:gif|webp|png|jpe?g)(?:\?[^\s<>"']*)?''',
  caseSensitive: false,
);

String _mediaExtension(Uri uri) {
  if (uri.pathSegments.isEmpty) {
    return '';
  }
  final last = uri.pathSegments.last.toLowerCase();
  final dot = last.lastIndexOf('.');
  if (dot < 0 || dot == last.length - 1) {
    return '';
  }
  return last.substring(dot + 1);
}

String _messageDisplayBody(MessageSeed message, MessageMediaSeed? inlineMedia) {
  final inlineUrl = inlineMedia?.url;
  if (inlineUrl == null || inlineUrl.isEmpty) {
    return message.body;
  }
  return message.body.replaceFirst(inlineUrl, '').trim();
}

DateTime? _messageCreatedAt(MessageSeed message) {
  final raw = message.createdAt;
  if (raw == null) {
    return null;
  }
  return DateTime.tryParse(raw);
}

bool _sameReactionSnapshot(List<ReactionSeed> a, List<ReactionSeed> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    final left = a[index];
    final right = b[index];
    if (left.emoji != right.emoji ||
        left.count != right.count ||
        left.reactedByCurrentUser != right.reactedByCurrentUser) {
      return false;
    }
  }
  return true;
}
