import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../shared/verdant_input_sanitizer.dart';
import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../shared/current_user_panel.dart';
import '../shared/member_profile_popover.dart';
import '../shared/user_context_menu.dart';
import '../workspace_seed.dart';
import 'direct_messages_models.dart';

class DmSidebarModule extends StatefulWidget {
  const DmSidebarModule({
    required this.data,
    required this.width,
    required this.activeChannelId,
    required this.onShowFriends,
    required this.onOpenConversation,
    required this.onCloseConversation,
    required this.onRemoveFriend,
    required this.mediaPolicy,
    required this.onLogout,
    required this.onOpenUserSettings,
    super.key,
    this.currentUserId,
    this.currentUserUsername,
    this.currentUserAvatarUrl,
    this.currentUserBannerUrl,
    this.currentUserBannerBaseColor,
    this.currentUserBannerCrop,
    this.currentUserBio,
    this.showLogout = true,
    this.onUpdateCurrentUserStatus,
  });

  final DirectMessagesWorkspaceData data;
  final double width;
  final String? activeChannelId;
  final VoidCallback onShowFriends;
  final Future<void> Function(DmConversationPreviewSeed conversation)
  onOpenConversation;
  final Future<void> Function(DmConversationPreviewSeed conversation)
  onCloseConversation;
  final Future<void> Function(String localUserId) onRemoveFriend;
  final String? currentUserId;
  final String? currentUserUsername;
  final String? currentUserAvatarUrl;
  final String? currentUserBannerUrl;
  final Color? currentUserBannerBaseColor;
  final BannerCrop? currentUserBannerCrop;
  final String? currentUserBio;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onLogout;
  final VoidCallback onOpenUserSettings;
  final bool showLogout;
  final Future<void> Function(String status)? onUpdateCurrentUserStatus;

  @override
  State<DmSidebarModule> createState() => _DmSidebarModuleState();
}

class _DmSidebarModuleState extends State<DmSidebarModule> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final conversations = widget.data.conversations
        .where((conversation) {
          if (query.isEmpty) {
            return true;
          }
          return conversation.displayName.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final pendingCount = widget.data.friends
        .where(
          (friend) => friend.kind == FriendRelationshipKind.pendingIncoming,
        )
        .length;

    return SizedBox(
      key: const ValueKey('dm-sidebar-module'),
      width: widget.width,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.panel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: _SearchField(
                key: const ValueKey('dm-sidebar-search-field'),
                controller: _searchController,
                hintText: 'Find a conversation',
                onChanged: (_) => setState(() {}),
              ),
            ),
            _SidebarPrimaryRow(
              pendingCount: pendingCount,
              active: widget.activeChannelId == null,
              onPressed: widget.onShowFriends,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Divider(color: colors.border, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'DIRECT MESSAGES',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('dm-new-message-button'),
                    tooltip: 'New DM',
                    onPressed: () {},
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.pencilSimpleLine,
                      size: 17,
                    ),
                    color: colors.textMuted,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SmoothSingleChildScrollView(
                child: Column(
                  children: [
                    for (final conversation in conversations)
                      _ConversationRow(
                        conversation: conversation,
                        mediaPolicy: widget.mediaPolicy,
                        active:
                            conversation.channelId == widget.activeChannelId,
                        onPressed: () {
                          unawaited(widget.onOpenConversation(conversation));
                        },
                        onClose: () {
                          unawaited(widget.onCloseConversation(conversation));
                        },
                        onRemoveFriend: () {
                          final localUserId = conversation.localUserId;
                          if (localUserId == null) {
                            return;
                          }
                          unawaited(widget.onRemoveFriend(localUserId));
                        },
                      ),
                    if (conversations.isEmpty && !widget.data.hasHydrated)
                      const _HydrationRowsPlaceholder(
                        key: ValueKey('dm-sidebar-hydration-placeholder'),
                      )
                    else if (conversations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 36, 22, 0),
                        child: Text(
                          query.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations found',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            WorkspaceCurrentUserPanel(
              name: widget.data.currentUserName,
              username:
                  widget.currentUserUsername ?? widget.data.currentUserName,
              initials: widget.data.currentUserInitials,
              avatarUrl: widget.currentUserAvatarUrl,
              bannerUrl: widget.currentUserBannerUrl,
              bannerBaseColor: widget.currentUserBannerBaseColor,
              bannerCrop: widget.currentUserBannerCrop,
              status: widget.data.currentUserStatus,
              userId: widget.currentUserId,
              bio: widget.currentUserBio,
              mediaPolicy: widget.mediaPolicy,
              onLogout: widget.onLogout,
              showLogout: widget.showLogout,
              onOpenUserSettings: widget.onOpenUserSettings,
              onUpdateStatus: widget.onUpdateCurrentUserStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class FriendsListModule extends StatefulWidget {
  const FriendsListModule({
    required this.data,
    required this.onAddFriend,
    required this.onAcceptFriend,
    required this.onRemoveFriend,
    required this.onMessageFriend,
    required this.mediaPolicy,
    super.key,
  });

  final DirectMessagesWorkspaceData data;
  final Future<void> Function(String username) onAddFriend;
  final Future<void> Function(String localUserId) onAcceptFriend;
  final Future<void> Function(String localUserId) onRemoveFriend;
  final Future<void> Function(String localUserId) onMessageFriend;
  final ServerMediaPolicy mediaPolicy;

  @override
  State<FriendsListModule> createState() => _FriendsListModuleState();
}

class _FriendsListModuleState extends State<FriendsListModule> {
  final _searchController = TextEditingController();
  final _gridController = ScrollController();
  var _showAddFriend = false;
  var _showBlocked = false;
  var _actionInFlight = false;

  @override
  void dispose() {
    _searchController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final visibleFriends = widget.data.friends
        .where((friend) {
          if (!_showBlocked && friend.kind == FriendRelationshipKind.blocked) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return friend.displayName.toLowerCase().contains(query) ||
              friend.status.toLowerCase().contains(query) ||
              friend.networkId.toLowerCase().contains(query);
        })
        .toList(growable: false);
    final onlineCount = widget.data.friends
        .where(
          (friend) =>
              friend.kind == FriendRelationshipKind.friend &&
              friend.status != 'Offline',
        )
        .length;
    final blockedCount = widget.data.friends
        .where((friend) => friend.kind == FriendRelationshipKind.blocked)
        .length;

    return DecoratedBox(
      key: const ValueKey('friends-list-module'),
      decoration: BoxDecoration(color: colors.background),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(
                    key: const ValueKey('friends-search-field'),
                    controller: _searchController,
                    hintText: 'Search friends...',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                _NetworkFilterButton(networkId: widget.data.networkId),
                const SizedBox(width: 10),
                SizedBox(
                  key: const ValueKey('friends-add-toggle-button'),
                  width: _showAddFriend ? 96 : 132,
                  child: VerdantButton(
                    label: _showAddFriend ? 'Back' : 'Add Friend',
                    icon: _showAddFriend
                        ? PhosphorIconsRegular.arrowLeft
                        : PhosphorIconsRegular.userPlus,
                    onPressed: () =>
                        setState(() => _showAddFriend = !_showAddFriend),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 112,
                  child: VerdantButton(
                    label: 'Blocked',
                    icon: PhosphorIconsRegular.prohibit,
                    variant: _showBlocked
                        ? VerdantButtonVariant.secondary
                        : VerdantButtonVariant.ghost,
                    onPressed: () =>
                        setState(() => _showBlocked = !_showBlocked),
                  ),
                ),
                if (blockedCount > 0) ...[
                  const SizedBox(width: 6),
                  _SmallCounter(label: blockedCount.toString()),
                ],
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 760 ? 270.0 : 300.0;
                final columns = (constraints.maxWidth / cardWidth)
                    .floor()
                    .clamp(1, 5);
                if (visibleFriends.isEmpty && !_showAddFriend) {
                  if (!widget.data.hasHydrated) {
                    return const _HydrationRowsPlaceholder(
                      key: ValueKey('friends-hydration-placeholder'),
                      cardStyle: true,
                    );
                  }
                  return _FriendsEmptyState(error: widget.data.error);
                }
                return SmoothWheelScroll(
                  controller: _gridController,
                  child: GridView.builder(
                    key: const ValueKey('friends-grid'),
                    controller: _gridController,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 72,
                    ),
                    itemCount: visibleFriends.length + (_showAddFriend ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_showAddFriend && index == 0) {
                        return _AddFriendCard(
                          networkId: widget.data.networkId,
                          enabled: !_actionInFlight,
                          onSubmit: _addFriend,
                        );
                      }
                      final friend =
                          visibleFriends[index - (_showAddFriend ? 1 : 0)];
                      return _FriendCard(
                        friend: friend,
                        mediaPolicy: widget.mediaPolicy,
                        onPrimaryAction: () => _primaryFriendAction(friend),
                        onMessage: () => _messageFriend(friend),
                        onAccept: () => _acceptFriend(friend),
                        onRemove: () => _removeFriend(friend),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                _StatusDot(color: colors.accent),
                const SizedBox(width: 7),
                Text(
                  '$onlineCount online',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text('Network', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFriend(String username) async {
    final trimmed = sanitizeUsernameInput(username);
    if (trimmed.isEmpty) {
      return;
    }
    await _runRelationshipAction(
      () => widget.onAddFriend(trimmed),
      success: 'Friend request sent to $trimmed',
    );
    if (mounted) {
      setState(() => _showAddFriend = false);
    }
  }

  Future<void> _acceptFriend(FriendPreviewSeed friend) async {
    await _runRelationshipAction(
      () => widget.onAcceptFriend(friend.localUserId),
      success: '${friend.displayName} accepted',
    );
  }

  Future<void> _primaryFriendAction(FriendPreviewSeed friend) {
    return switch (friend.kind) {
      FriendRelationshipKind.pendingIncoming => _acceptFriend(friend),
      FriendRelationshipKind.blocked => _removeFriend(friend),
      _ => _messageFriend(friend),
    };
  }

  Future<void> _removeFriend(FriendPreviewSeed friend) async {
    final action = friend.kind == FriendRelationshipKind.blocked
        ? 'unblocked'
        : 'removed';
    await _runRelationshipAction(
      () => widget.onRemoveFriend(friend.localUserId),
      success: '${friend.displayName} $action',
    );
  }

  Future<void> _messageFriend(FriendPreviewSeed friend) async {
    await _runRelationshipAction(
      () => widget.onMessageFriend(friend.localUserId),
      success: 'Opened DM with ${friend.displayName}',
    );
  }

  Future<void> _runRelationshipAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (_actionInFlight) {
      return;
    }
    setState(() => _actionInFlight = true);
    try {
      await action();
      if (mounted) {
        _showActionFeedback(success);
      }
    } catch (error) {
      if (mounted) {
        _showActionFeedback(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _actionInFlight = false);
      }
    }
  }

  void _showActionFeedback(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autocorrect: false,
        enableSuggestions: false,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodySmall,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 8),
            child: PhosphorIcon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 15,
              color: colors.textMuted,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          filled: true,
          fillColor: colors.panelRaised,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: VerdantRadii.sharp,
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: VerdantRadii.sharp,
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: VerdantRadii.sharp,
            borderSide: BorderSide(color: colors.accent),
          ),
        ),
      ),
    );
  }
}

class _SidebarPrimaryRow extends StatelessWidget {
  const _SidebarPrimaryRow({
    required this.pendingCount,
    required this.active,
    required this.onPressed,
  });

  final int pendingCount;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return TextButton(
      key: const ValueKey('dm-sidebar-friends-row'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        foregroundColor: colors.text,
        backgroundColor: active ? colors.panelHover : Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
      ),
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsFill.users,
              size: 19,
              color: colors.accentStrong,
            ),
            const SizedBox(width: 10),
            Text('Friends', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            if (pendingCount > 0) _SmallCounter(label: pendingCount.toString()),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.mediaPolicy,
    required this.active,
    required this.onPressed,
    required this.onClose,
    required this.onRemoveFriend,
  });

  final DmConversationPreviewSeed conversation;
  final ServerMediaPolicy mediaPolicy;
  final bool active;
  final VoidCallback onPressed;
  final VoidCallback onClose;
  final VoidCallback onRemoveFriend;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showConversationContextMenu(context, details.globalPosition),
      child: TextButton(
        key: ValueKey('dm-conversation-${conversation.channelId}'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          foregroundColor: colors.text,
          backgroundColor: active ? colors.panelHover : Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _ConversationAvatar(
                conversation: conversation,
                mediaPolicy: mediaPolicy,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _networkLabel(conversation.networkId),
                      key: ValueKey(
                        'dm-conversation-network-${conversation.channelId}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _networkColor(conversation.networkId, colors),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0)
                _SmallCounter(label: conversation.unreadCount.toString())
              else
                IconButton(
                  key: ValueKey(
                    'dm-conversation-close-${conversation.channelId}',
                  ),
                  tooltip: 'Close conversation',
                  onPressed: onClose,
                  icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 14),
                  color: colors.textMuted,
                  splashRadius: 15,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 26,
                    height: 26,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConversationContextMenu(
    BuildContext context,
    Offset position,
  ) async {
    final selected = await showWorkspaceUserContextMenu(
      context: context,
      globalPosition: position,
      entries: [
        const WorkspaceUserContextMenuItem(
          id: 'profile',
          label: 'Profile',
          icon: PhosphorIconsRegular.user,
          enabled: false,
        ),
        const WorkspaceUserContextMenuItem(
          id: 'message',
          label: 'Message',
          icon: PhosphorIconsRegular.chatDots,
        ),
        const WorkspaceUserContextMenuDivider(),
        WorkspaceUserContextMenuItem(
          id: 'remove',
          label: 'Remove Friend',
          icon: PhosphorIconsRegular.userMinus,
          tone: WorkspaceUserContextMenuTone.danger,
          enabled: conversation.localUserId != null,
        ),
        const WorkspaceUserContextMenuItem(
          id: 'report',
          label: 'Report User',
          icon: PhosphorIconsRegular.flag,
          enabled: false,
        ),
        const WorkspaceUserContextMenuItem(
          id: 'block',
          label: 'Block',
          icon: PhosphorIconsRegular.prohibit,
          tone: WorkspaceUserContextMenuTone.danger,
          enabled: false,
        ),
        const WorkspaceUserContextMenuDivider(),
        const WorkspaceUserContextMenuItem(
          id: 'copy',
          label: 'Copy User ID',
          icon: PhosphorIconsRegular.copy,
        ),
      ],
    );

    switch (selected) {
      case 'message':
        onPressed();
      case 'remove':
        onRemoveFriend();
      case 'copy':
        final userId = conversation.localUserId == null
            ? conversation.channelId
            : scopedWorkspaceId(
                conversation.networkId,
                conversation.localUserId!,
              );
        await Clipboard.setData(ClipboardData(text: userId));
    }
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.conversation,
    required this.mediaPolicy,
  });

  final DmConversationPreviewSeed conversation;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final fallback = _Avatar(
      initials: conversation.initials,
      status: conversation.status,
      color: _avatarColor(conversation.displayName),
    );
    if (conversation.avatarUrl == null) {
      return fallback;
    }
    return MemberMediaAvatar(
      key: ValueKey('dm-conversation-avatar-${conversation.channelId}'),
      member: MemberSeed(
        id: conversation.localUserId == null
            ? conversation.channelId
            : '${conversation.networkId}/${conversation.localUserId}',
        name: conversation.displayName,
        status: conversation.status,
        initials: conversation.initials,
        avatarUrl: conversation.avatarUrl,
        bannerUrl: conversation.bannerUrl,
      ),
      mediaPolicy: mediaPolicy,
      size: 34,
      playAnimatedMedia: true,
      imageKeyPrefix: 'dm-conversation-avatar-image',
      loadingPlaceholder: fallback,
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.friend, required this.mediaPolicy});

  final FriendPreviewSeed friend;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final fallback = _Avatar(
      initials: friend.initials,
      status: friend.status,
      color: _avatarColor(friend.displayName),
    );
    if (friend.avatarUrl == null) {
      return fallback;
    }
    return MemberMediaAvatar(
      key: ValueKey('friend-avatar-${friend.id}'),
      member: MemberSeed(
        id: '${friend.networkId}/${friend.localUserId}',
        name: friend.displayName,
        username: friend.displayName,
        status: friend.status,
        initials: friend.initials,
        avatarUrl: friend.avatarUrl,
        bannerUrl: friend.bannerUrl,
      ),
      mediaPolicy: mediaPolicy,
      size: 34,
      playAnimatedMedia: true,
      imageKeyPrefix: 'friend-avatar-image',
      loadingPlaceholder: fallback,
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.mediaPolicy,
    required this.onPrimaryAction,
    required this.onMessage,
    required this.onAccept,
    required this.onRemove,
  });

  final FriendPreviewSeed friend;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onPrimaryAction;
  final VoidCallback onMessage;
  final VoidCallback onAccept;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final isBlocked = friend.kind == FriendRelationshipKind.blocked;
    final isPending =
        friend.kind == FriendRelationshipKind.pendingIncoming ||
        friend.kind == FriendRelationshipKind.pendingOutgoing;
    final networkColor = _networkColor(friend.networkId, colors);

    return Material(
      key: ValueKey('friend-card-${friend.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onPrimaryAction,
        onSecondaryTapDown: (details) =>
            _showFriendContextMenu(context, details.globalPosition),
        hoverColor: colors.panelHover,
        splashColor: Colors.transparent,
        highlightColor: colors.desktopPressedOverlay,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.panelRaised,
            border: Border.all(
              color: isBlocked
                  ? const Color(0xFF7A2E36)
                  : isPending
                  ? const Color(0xFF695B30)
                  : colors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _FriendAvatar(friend: friend, mediaPolicy: mediaPolicy),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StatusDot(color: _statusColor(friend.status, colors)),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _networkLabel(friend.networkId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: networkColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFriendContextMenu(
    BuildContext context,
    Offset position,
  ) async {
    final selected = await showWorkspaceUserContextMenu(
      context: context,
      globalPosition: position,
      entries: [
        const WorkspaceUserContextMenuItem(
          id: 'profile',
          label: 'Profile',
          icon: PhosphorIconsRegular.user,
          enabled: false,
        ),
        WorkspaceUserContextMenuItem(
          id: 'message',
          label: 'Message',
          icon: PhosphorIconsRegular.chatDots,
          enabled: friend.kind == FriendRelationshipKind.friend,
        ),
        const WorkspaceUserContextMenuDivider(),
        if (friend.kind == FriendRelationshipKind.pendingIncoming)
          const WorkspaceUserContextMenuItem(
            id: 'accept',
            label: 'Accept Request',
            icon: PhosphorIconsRegular.userPlus,
            tone: WorkspaceUserContextMenuTone.success,
          )
        else if (friend.kind == FriendRelationshipKind.pendingOutgoing)
          const WorkspaceUserContextMenuItem(
            id: 'remove',
            label: 'Cancel Request',
            icon: PhosphorIconsRegular.userMinus,
            tone: WorkspaceUserContextMenuTone.warning,
          )
        else if (friend.kind == FriendRelationshipKind.blocked)
          const WorkspaceUserContextMenuItem(
            id: 'remove',
            label: 'Unblock',
            icon: PhosphorIconsRegular.prohibit,
            tone: WorkspaceUserContextMenuTone.warning,
          )
        else
          const WorkspaceUserContextMenuItem(
            id: 'remove',
            label: 'Remove Friend',
            icon: PhosphorIconsRegular.userMinus,
            tone: WorkspaceUserContextMenuTone.danger,
          ),
        const WorkspaceUserContextMenuItem(
          id: 'report',
          label: 'Report User',
          icon: PhosphorIconsRegular.flag,
          enabled: false,
        ),
        const WorkspaceUserContextMenuItem(
          id: 'block',
          label: 'Block',
          icon: PhosphorIconsRegular.prohibit,
          tone: WorkspaceUserContextMenuTone.danger,
          enabled: false,
        ),
        const WorkspaceUserContextMenuDivider(),
        const WorkspaceUserContextMenuItem(
          id: 'copy',
          label: 'Copy User ID',
          icon: PhosphorIconsRegular.copy,
        ),
      ],
    );

    switch (selected) {
      case 'message':
        onMessage();
      case 'accept':
        onAccept();
      case 'remove':
        onRemove();
      case 'copy':
        await Clipboard.setData(ClipboardData(text: friend.id));
    }
  }
}

class _AddFriendCard extends StatefulWidget {
  const _AddFriendCard({
    required this.networkId,
    required this.enabled,
    required this.onSubmit,
  });

  final String networkId;
  final bool enabled;
  final Future<void> Function(String username) onSubmit;

  @override
  State<_AddFriendCard> createState() => _AddFriendCardState();
}

class _AddFriendCardState extends State<_AddFriendCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      key: const ValueKey('add-friend-card'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.borderStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                key: const ValueKey('add-friend-username-field'),
                controller: _controller,
                autocorrect: false,
                enableSuggestions: false,
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: widget.enabled
                    ? (value) => widget.onSubmit(sanitizeUsernameInput(value))
                    : null,
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: colors.panel,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: VerdantRadii.sharp,
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            height: 36,
            child: FilledButton(
              key: const ValueKey('add-friend-submit-button'),
              onPressed: widget.enabled
                  ? () =>
                        widget.onSubmit(sanitizeUsernameInput(_controller.text))
                  : null,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Send', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkFilterButton extends StatelessWidget {
  const _NetworkFilterButton({required this.networkId});

  final String networkId;

  @override
  Widget build(BuildContext context) {
    final apiOrigin = apiOriginFromNetworkId(networkId);
    final label = apiOrigin == null ? 'Network' : Uri.parse(apiOrigin).host;
    return SizedBox(
      width: 156,
      child: OutlinedButton.icon(
        key: const ValueKey('friends-network-filter-button'),
        onPressed: () {},
        icon: const PhosphorIcon(
          PhosphorIconsRegular.globeHemisphereEast,
          size: 15,
        ),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.status,
    required this.color,
  });

  final String initials;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: VerdantRadii.sharp,
          ),
          child: Text(
            initials,
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.panel,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _StatusDot(color: _statusColor(status, colors)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FriendsEmptyState extends StatelessWidget {
  const _FriendsEmptyState({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.userPlus,
              size: 34,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              error == null ? 'No friends yet' : 'Could not load friends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              error ?? 'Add a friend to start a direct message.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrationRowsPlaceholder extends StatelessWidget {
  const _HydrationRowsPlaceholder({super.key, this.cardStyle = false});

  final bool cardStyle;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    if (cardStyle) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var index = 0; index < 6; index += 1)
              _SkeletonBlock(
                width: 300,
                height: 72,
                color: colors.panel.withValues(alpha: 0.72),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          for (var index = 0; index < 4; index += 1) ...[
            _SkeletonBlock(
              width: double.infinity,
              height: 42,
              color: colors.panelRaised.withValues(alpha: 0.74),
            ),
            if (index != 3) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: VerdantRadii.sharp,
        border: Border.all(color: colors.border.withValues(alpha: 0.74)),
      ),
    );
  }
}

class _SmallCounter extends StatelessWidget {
  const _SmallCounter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: const BorderRadius.all(Radius.circular(9)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.actionText,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _statusColor(String status, VerdantThemeColors colors) {
  final normalized = status.toLowerCase();
  if (normalized.contains('online')) {
    return colors.accent;
  }
  if (normalized.contains('idle') ||
      normalized.contains('pending') ||
      normalized.contains('sent')) {
    return const Color(0xFFFFD166);
  }
  if (normalized.contains('busy') || normalized.contains('blocked')) {
    return const Color(0xFFFF808A);
  }
  return colors.textMuted;
}

String _networkLabel(String networkId) {
  final apiOrigin = apiOriginFromNetworkId(networkId);
  if (apiOrigin == null) {
    return 'Network';
  }
  return Uri.parse(apiOrigin).host;
}

Color _networkColor(String networkId, VerdantThemeColors colors) {
  if (networkId.isEmpty) {
    return colors.accentStrong;
  }
  final accents = [
    colors.accentStrong,
    const Color(0xFFFFD166),
    const Color(0xFF8EBBFF),
    const Color(0xFFC9A7FF),
  ];
  final index =
      networkId.codeUnits.fold<int>(0, (sum, code) => sum + code) %
      accents.length;
  return accents[index];
}

Color _avatarColor(String value) {
  final colors = [
    const Color(0xFF0B3D32),
    const Color(0xFF2A2447),
    const Color(0xFF383016),
    const Color(0xFF1E3A4A),
  ];
  final index =
      value.codeUnits.fold<int>(0, (sum, code) => sum + code) % colors.length;
  return colors[index];
}
