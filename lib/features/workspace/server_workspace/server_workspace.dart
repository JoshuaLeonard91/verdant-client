import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_media_image.dart';
import '../server_settings_workspace/server_media_url_policy.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../shared/current_user_panel.dart';
import '../shared/user_context_menu.dart';
import '../workspace_seed.dart';

class ServerWorkspace extends StatelessWidget {
  const ServerWorkspace({
    required this.seed,
    required this.width,
    required this.currentUserName,
    required this.currentUserInitials,
    required this.onLogout,
    required this.onOpenServerSettings,
    required this.onOpenUserSettings,
    required this.onSelectTextChannel,
    this.currentUserId,
    this.currentUserUsername,
    this.currentUserAvatarUrl,
    this.currentUserBannerUrl,
    this.currentUserBannerBaseColor,
    this.currentUserBannerCrop,
    this.currentUserStatus,
    this.currentUserBio,
    this.showLogout = true,
    this.onUpdateCurrentUserStatus,
    this.onOpenChannelSettings,
    this.onOpenChannelPermissions,
    this.onSelectFeed,
    this.onSelectVoiceChannel,
    super.key,
  });

  final WorkspaceSeed seed;
  final double width;
  final String? currentUserId;
  final String currentUserName;
  final String currentUserInitials;
  final String? currentUserUsername;
  final String? currentUserAvatarUrl;
  final String? currentUserBannerUrl;
  final Color? currentUserBannerBaseColor;
  final BannerCrop? currentUserBannerCrop;
  final String? currentUserStatus;
  final String? currentUserBio;
  final bool showLogout;
  final VoidCallback onLogout;
  final VoidCallback onOpenServerSettings;
  final VoidCallback onOpenUserSettings;
  final Future<void> Function(String status)? onUpdateCurrentUserStatus;
  final ValueChanged<ChannelSeed> onSelectTextChannel;
  final ValueChanged<ChannelSeed>? onOpenChannelSettings;
  final ValueChanged<ChannelSeed>? onOpenChannelPermissions;
  final ValueChanged<ServerSettingsListItemSeed>? onSelectFeed;
  final ValueChanged<ChannelSeed>? onSelectVoiceChannel;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final bannerHeight = width < 280 ? 96.0 : 126.0;
    final textChannels = seed.channels
        .where((channel) => channel.type == 0)
        .toList(growable: false);
    final voiceChannels = seed.channels
        .where((channel) => channel.type == 3)
        .toList(growable: false);
    final feeds = [...seed.serverSettings.feeds]
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    return SizedBox(
      width: width,
      child: DecoratedBox(
        key: const ValueKey('server-workspace-surface'),
        decoration: BoxDecoration(color: colors.panel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ServerBanner(
              name: seed.serverName,
              iconUrl: seed.serverIconUrl,
              bannerUrl: seed.serverBannerUrl,
              bannerCrop: seed.serverBannerCrop,
              mediaPolicy: seed.mediaPolicy,
              memberCount: seed.memberCount,
              height: bannerHeight,
              canOpenServerSettings: seed.serverSettings.canManageServer,
              onOpenServerSettings: onOpenServerSettings,
            ),
            Expanded(
              child: SmoothSingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (feeds.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Text(
                          'FEEDS',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      for (final feed in feeds)
                        _FeedChannelRow(
                          feed: feed,
                          selected: _sameFeedId(
                            _feedIdentity(feed),
                            seed.activeFeedId,
                          ),
                          onTap: () => onSelectFeed?.call(feed),
                        ),
                      const SizedBox(height: 8),
                    ],
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        feeds.isEmpty ? 14 : 4,
                        20,
                        8,
                      ),
                      child: Text(
                        'TEXT CHANNELS',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    for (final channel in textChannels)
                      _ChannelRow(
                        channel: channel,
                        canManageChannels:
                            seed.serverSettings.canManageChannels,
                        onOpenSettings: onOpenChannelSettings,
                        onOpenPermissions: onOpenChannelPermissions,
                        onTap: channel.disabled
                            ? null
                            : () => onSelectTextChannel(channel),
                      ),
                    if (textChannels.isEmpty)
                      const _EmptyChannelLabel(label: 'No text channels'),
                    if (voiceChannels.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                          'VOICE CHANNELS',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      for (final channel in voiceChannels)
                        _VoiceRow(
                          channel: channel,
                          canManageChannels:
                              seed.serverSettings.canManageChannels,
                          onOpenSettings: onOpenChannelSettings,
                          onOpenPermissions: onOpenChannelPermissions,
                          onTap: channel.disabled
                              ? null
                              : () => onSelectVoiceChannel?.call(channel),
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            WorkspaceCurrentUserPanel(
              name: currentUserName,
              username: currentUserUsername ?? currentUserName,
              initials: currentUserInitials,
              avatarUrl: currentUserAvatarUrl,
              bannerUrl: currentUserBannerUrl,
              bannerBaseColor: currentUserBannerBaseColor,
              bannerCrop: currentUserBannerCrop,
              status: currentUserStatus ?? 'online',
              userId: currentUserId,
              bio: currentUserBio,
              mediaPolicy: seed.mediaPolicy,
              onLogout: onLogout,
              showLogout: showLogout,
              onOpenUserSettings: onOpenUserSettings,
              onUpdateStatus: onUpdateCurrentUserStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerBanner extends StatelessWidget {
  const _ServerBanner({
    required this.name,
    required this.iconUrl,
    required this.bannerUrl,
    required this.bannerCrop,
    required this.mediaPolicy,
    required this.memberCount,
    required this.height,
    required this.canOpenServerSettings,
    required this.onOpenServerSettings,
  });

  final String name;
  final String? iconUrl;
  final String? bannerUrl;
  final BannerCrop? bannerCrop;
  final ServerMediaPolicy mediaPolicy;
  final int memberCount;
  final double height;
  final bool canOpenServerSettings;
  final VoidCallback onOpenServerSettings;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final bannerUri = safeServerMediaUri(bannerUrl, policy: mediaPolicy);
    final compact = height < 110;
    final iconSize = compact ? 36.0 : 42.0;
    final titleStyle =
        (compact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge)
            ?.copyWith(height: 1.05);
    final memberStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(height: 1.05);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF080A0B), Color(0xFF121717)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: bannerUri == null
                  ? const SizedBox.expand()
                  : SafeServerMediaImage(
                      uri: bannerUri,
                      policy: mediaPolicy,
                      surface: ServerMediaSurface.serverBanner,
                      retainWhenUnfocused: true,
                      fallback: const SizedBox.expand(),
                      builder: (context, imageProvider) {
                        return CroppedServerBannerImage(
                          imageProvider: imageProvider,
                          crop: bannerCrop,
                          animate: true,
                          imageKey: const ValueKey('server-banner-media-image'),
                        );
                      },
                    ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.58),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 58, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ServerMediaIcon(
                    name: name,
                    iconUrl: iconUrl,
                    mediaPolicy: mediaPolicy,
                    size: iconSize,
                    animate: true,
                    imageKey: const ValueKey('server-icon-media-image'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$memberCount members',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: memberStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canOpenServerSettings)
            Positioned(
              right: 10,
              top: 10,
              child: Tooltip(
                message: 'Server Settings',
                child: IconButton(
                  key: const ValueKey('server-settings-open-button'),
                  onPressed: onOpenServerSettings,
                  icon: const Icon(Icons.settings_outlined, size: 19),
                  color: colors.textMuted,
                  splashRadius: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedChannelRow extends StatelessWidget {
  const _FeedChannelRow({
    required this.feed,
    required this.selected,
    required this.onTap,
  });

  final ServerSettingsListItemSeed feed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final feedId = _feedIdentity(feed);
    final textColor = selected ? colors.text : colors.textMuted;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? colors.panelRaised : Colors.transparent,
        borderRadius: VerdantRadii.sharp,
        child: InkWell(
          key: ValueKey('server-feed-channel-row-$feedId'),
          onTap: onTap,
          borderRadius: VerdantRadii.sharp,
          hoverColor: colors.panelHover.withValues(alpha: 0.68),
          splashColor: colors.accent.withValues(alpha: 0.12),
          child: SizedBox(
            height: 36,
            child: Stack(
              children: [
                if (selected)
                  Positioned(
                    key: ValueKey('server-feed-channel-selected-$feedId'),
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: VerdantRadii.sharp,
                      ),
                      child: const SizedBox(width: 3),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: selected
                            ? colors.textMuted
                            : colors.textMuted.withValues(alpha: 0.92),
                        size: 17,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          key: ValueKey(
                            'server-feed-channel-name-${_stableChannelNameKey(feed.title)}',
                          ),
                          feed.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
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

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.onTap,
    required this.canManageChannels,
    required this.onOpenSettings,
    required this.onOpenPermissions,
  });

  final ChannelSeed channel;
  final VoidCallback? onTap;
  final bool canManageChannels;
  final ValueChanged<ChannelSeed>? onOpenSettings;
  final ValueChanged<ChannelSeed>? onOpenPermissions;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final selected = channel.selected;
    final unread = channel.unread && !selected;
    final disabled = channel.disabled;
    final textColor = disabled
        ? colors.textMuted.withValues(alpha: 0.48)
        : selected || unread
        ? colors.text
        : colors.textMuted;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => _showChannelContextMenu(
          context: context,
          position: details.globalPosition,
          channel: channel,
          canManageChannels: canManageChannels,
          onOpenSettings: onOpenSettings,
          onOpenPermissions: onOpenPermissions,
        ),
        child: Material(
          color: selected ? colors.panelRaised : Colors.transparent,
          borderRadius: VerdantRadii.sharp,
          child: InkWell(
            key: ValueKey('server-channel-${channel.id}'),
            onTap: onTap,
            borderRadius: VerdantRadii.sharp,
            hoverColor: colors.panelHover.withValues(alpha: 0.68),
            splashColor: colors.accent.withValues(alpha: 0.12),
            child: SizedBox(
              height: 36,
              child: Stack(
                children: [
                  if (selected)
                    Positioned(
                      key: ValueKey('server-channel-selected-${channel.id}'),
                      left: 0,
                      top: 8,
                      bottom: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: VerdantRadii.sharp,
                        ),
                        child: const SizedBox(width: 3),
                      ),
                    )
                  else if (unread)
                    Positioned(
                      key: ValueKey('server-channel-unread-${channel.id}'),
                      left: 4,
                      top: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          color: selected
                              ? colors.textMuted
                              : colors.textMuted.withValues(
                                  alpha: disabled ? 0.42 : 1,
                                ),
                          size: 17,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            key: ValueKey(
                              'server-channel-name-${_stableChannelNameKey(channel.name)}',
                            ),
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: unread || selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (channel.mentionCount > 0)
                          _MentionBadge(
                            key: ValueKey(
                              'server-channel-mention-${channel.id}',
                            ),
                            count: channel.mentionCount,
                          ),
                        if (disabled)
                          Icon(
                            key: ValueKey(
                              'server-channel-disabled-${channel.id}',
                            ),
                            Icons.lock_outline,
                            color: colors.textMuted.withValues(alpha: 0.48),
                            size: 14,
                          ),
                      ],
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
}

class _VoiceRow extends StatelessWidget {
  const _VoiceRow({
    required this.channel,
    required this.onTap,
    required this.canManageChannels,
    required this.onOpenSettings,
    required this.onOpenPermissions,
  });

  final ChannelSeed channel;
  final VoidCallback? onTap;
  final bool canManageChannels;
  final ValueChanged<ChannelSeed>? onOpenSettings;
  final ValueChanged<ChannelSeed>? onOpenPermissions;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final disabled = channel.disabled;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => _showChannelContextMenu(
          context: context,
          position: details.globalPosition,
          channel: channel,
          canManageChannels: canManageChannels,
          onOpenSettings: onOpenSettings,
          onOpenPermissions: onOpenPermissions,
        ),
        child: Material(
          color: channel.selected ? colors.panelRaised : Colors.transparent,
          borderRadius: VerdantRadii.sharp,
          child: InkWell(
            key: ValueKey('server-voice-channel-${channel.id}'),
            onTap: onTap,
            borderRadius: VerdantRadii.sharp,
            hoverColor: colors.panelHover.withValues(alpha: 0.68),
            splashColor: colors.accent.withValues(alpha: 0.12),
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic_none,
                      color: colors.textMuted.withValues(
                        alpha: disabled ? 0.42 : 1,
                      ),
                      size: 17,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        key: ValueKey(
                          'server-voice-channel-name-${_stableChannelNameKey(channel.name)}',
                        ),
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: disabled
                                  ? colors.textMuted.withValues(alpha: 0.48)
                                  : channel.selected
                                  ? colors.text
                                  : colors.textMuted,
                            ),
                      ),
                    ),
                    if (disabled)
                      Icon(
                        key: ValueKey('server-channel-disabled-${channel.id}'),
                        Icons.lock_outline,
                        color: colors.textMuted.withValues(alpha: 0.48),
                        size: 14,
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
}

Future<void> _showChannelContextMenu({
  required BuildContext context,
  required Offset position,
  required ChannelSeed channel,
  required bool canManageChannels,
  required ValueChanged<ChannelSeed>? onOpenSettings,
  required ValueChanged<ChannelSeed>? onOpenPermissions,
}) async {
  final entries = <WorkspaceUserContextMenuEntry>[
    if (canManageChannels) ...[
      const WorkspaceUserContextMenuItem(
        id: 'channel-settings',
        label: 'Channel Settings',
        icon: PhosphorIconsRegular.slidersHorizontal,
      ),
      const WorkspaceUserContextMenuItem(
        id: 'channel-permissions',
        label: 'Permissions',
        icon: PhosphorIconsRegular.shieldCheck,
      ),
      const WorkspaceUserContextMenuDivider(),
    ],
    const WorkspaceUserContextMenuItem(
      id: 'copy-channel-id',
      label: 'Copy Channel ID',
      icon: PhosphorIconsRegular.copy,
    ),
  ];

  final selected = await showWorkspaceUserContextMenu(
    context: context,
    globalPosition: position,
    entries: entries,
  );
  switch (selected) {
    case 'channel-settings':
      onOpenSettings?.call(channel);
    case 'channel-permissions':
      onOpenPermissions?.call(channel);
    case 'copy-channel-id':
      await Clipboard.setData(ClipboardData(text: channel.id));
  }
}

String _stableChannelNameKey(String name) {
  final normalized = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'unnamed' : normalized;
}

String _feedIdentity(ServerSettingsListItemSeed feed) {
  return feed.id ?? feed.title;
}

bool _sameFeedId(String left, String? right) {
  if (right == null) {
    return false;
  }
  return left == right || _localId(left) == _localId(right);
}

String _localId(String value) {
  final slash = value.indexOf('/');
  return slash < 0 ? value : value.substring(slash + 1);
}

class _MentionBadge extends StatelessWidget {
  const _MentionBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      margin: const EdgeInsets.only(left: 8),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB83842),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyChannelLabel extends StatelessWidget {
  const _EmptyChannelLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
