import 'package:flutter/material.dart';
import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import 'server_settings_audit_log_tab.dart';
import 'server_settings_bots_tab.dart';
import 'server_settings_emoji_tab.dart';
import 'server_settings_feeds_tab.dart';
import 'server_settings_invites_tab.dart';
import 'server_settings_members_tab.dart';
import 'server_settings_models.dart';
import 'server_settings_navigation.dart';
import 'server_settings_overview_tab.dart';
import 'server_settings_roles_tab.dart';
import 'server_settings_service.dart';
import 'server_settings_stickers_tab.dart';

class ServerSettingsWorkspace extends StatefulWidget {
  const ServerSettingsWorkspace({
    required this.data,
    required this.repository,
    required this.onServerUpdated,
    required this.onClose,
    required this.currentUserId,
    this.onEmojisChanged,
    this.onStickersChanged,
    super.key,
  });

  final ServerSettingsData data;
  final ServerSettingsRepository repository;
  final ValueChanged<ServerSettingsServer> onServerUpdated;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onEmojisChanged;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onStickersChanged;
  final VoidCallback onClose;
  final String currentUserId;

  @override
  State<ServerSettingsWorkspace> createState() =>
      _ServerSettingsWorkspaceState();
}

class _ServerSettingsWorkspaceState extends State<ServerSettingsWorkspace> {
  ServerSettingsTabId _activeTab = ServerSettingsTabId.overview;
  final ScrollController _scrollController = ScrollController();
  late ServerSettingsData _data = widget.data;
  bool _isLoadingFullSettings = false;
  String? _fullSettingsError;

  @override
  void initState() {
    super.initState();
    _loadFullSettingsIfAvailable();
  }

  @override
  void didUpdateWidget(covariant ServerSettingsWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _data = widget.data;
      _fullSettingsError = null;
      _loadFullSettingsIfAvailable();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final activeTab = _activeTab;
    final settings = ServerSettingsSeed.fromData(
      _data,
      currentUserId: widget.currentUserId,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('server-settings-workspace'),
        decoration: BoxDecoration(
          color: colors.panelRaised,
          border: Border(left: BorderSide(color: colors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 22,
              offset: Offset(-10, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 192,
              child: ServerSettingsNavigation(
                settings: settings,
                activeTab: activeTab,
                onTabSelected: _selectTab,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _ServerSettingsHeader(
                    activeTab: activeTab,
                    data: _data,
                    isLoadingFullSettings: _isLoadingFullSettings,
                    fullSettingsError: _fullSettingsError,
                    onClose: widget.onClose,
                  ),
                  Expanded(child: _buildTabContent(activeTab)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ServerSettingsTabId tab) {
    final content = KeyedSubtree(
      key: ValueKey('server-settings-content-${tab.key}'),
      child: _buildTab(tab),
    );
    if (tab == ServerSettingsTabId.roles ||
        tab == ServerSettingsTabId.feeds ||
        tab == ServerSettingsTabId.members) {
      return content;
    }
    return Scrollbar(
      key: const ValueKey('server-settings-page-scrollbar'),
      controller: _scrollController,
      thumbVisibility: true,
      child: SmoothSingleChildScrollView(
        controller: _scrollController,
        primary: false,
        child: content,
      ),
    );
  }

  void _selectTab(ServerSettingsTabId tab) {
    final settings = ServerSettingsSeed.fromData(
      _data,
      currentUserId: widget.currentUserId,
    );
    if (!settings.canOpen(tab)) {
      return;
    }
    setState(() => _activeTab = tab);
  }

  void _loadFullSettingsIfAvailable() {
    final repository = widget.repository;
    if (repository is! FullServerSettingsRepository || _isLoadingFullSettings) {
      return;
    }
    setState(() {
      _isLoadingFullSettings = true;
      _fullSettingsError = null;
    });
    (repository as FullServerSettingsRepository)
        .loadFullServerSettings(_data.server)
        .then((loaded) {
          if (!mounted || loaded.server.id != _data.server.id) {
            return;
          }
          setState(() {
            _data = loaded;
            _isLoadingFullSettings = false;
          });
        })
        .catchError((Object _) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoadingFullSettings = false;
            _fullSettingsError = 'Some settings could not be loaded.';
          });
        });
  }

  Widget _buildTab(ServerSettingsTabId tab) {
    final settings = ServerSettingsSeed.fromData(
      _data,
      currentUserId: widget.currentUserId,
    );

    return switch (tab) {
      ServerSettingsTabId.overview => ServerSettingsOverviewTab(
        data: _data,
        repository: widget.repository,
        onServerUpdated: _handleServerUpdated,
      ),
      ServerSettingsTabId.emoji => ServerSettingsEmojiTab(
        serverId: _data.server.id,
        emojis: settings.emojis,
        canManageServer: settings.canManageServer,
        mediaPolicy: _data.mediaPolicy,
        emojiRepository: widget.repository is ServerSettingsEmojiRepository
            ? widget.repository as ServerSettingsEmojiRepository
            : null,
        onEmojisChanged: _handleEmojisChanged,
      ),
      ServerSettingsTabId.stickers => ServerSettingsStickersTab(
        serverId: _data.server.id,
        stickers: settings.stickers,
        canManageServer: settings.canManageServer,
        mediaPolicy: _data.mediaPolicy,
        stickerRepository: widget.repository is ServerSettingsEmojiRepository
            ? widget.repository as ServerSettingsEmojiRepository
            : null,
        onStickersChanged: _handleStickersChanged,
      ),
      ServerSettingsTabId.invites => ServerSettingsInvitesTab(
        data: _data,
        repository: widget.repository,
        onInvitesChanged: _handleInvitesChanged,
      ),
      ServerSettingsTabId.roles => ServerSettingsRolesTab(
        serverId: _data.server.id,
        roles: settings.roles,
        canManageRoles: settings.canManageRoles,
        roleRepository: widget.repository is ServerSettingsRoleRepository
            ? widget.repository as ServerSettingsRoleRepository
            : null,
        onRolesChanged: _handleRolesChanged,
      ),
      ServerSettingsTabId.members => ServerSettingsMembersTab(
        serverId: _data.server.id,
        networkId: _data.networkId,
        members: settings.members,
        roles: settings.roles,
        currentUserId: widget.currentUserId,
        ownerId: _data.server.ownerId,
        canKickMembers: settings.canKickMembers,
        canBanMembers: settings.canBanMembers,
        mediaPolicy: _data.mediaPolicy,
        moderationRepository:
            widget.repository is ServerSettingsModerationRepository
            ? widget.repository as ServerSettingsModerationRepository
            : null,
        onMembersChanged: _handleMembersChanged,
      ),
      ServerSettingsTabId.auditLog => ServerSettingsAuditLogTab(
        serverId: _data.server.id,
        entries: settings.auditEvents,
        auditRepository: widget.repository is ServerSettingsAuditRepository
            ? widget.repository as ServerSettingsAuditRepository
            : null,
      ),
      ServerSettingsTabId.feeds => ServerSettingsFeedsTab(
        serverId: _data.server.id,
        feeds: settings.feeds,
        roles: settings.roles,
        canManageServer: settings.canManageServer,
        feedRepository: widget.repository is ServerSettingsFeedRepository
            ? widget.repository as ServerSettingsFeedRepository
            : null,
        onFeedsChanged: _handleFeedsChanged,
      ),
      ServerSettingsTabId.bots => ServerSettingsBotsTab(
        serverId: _data.server.id,
        bots: settings.bots,
        canManageServer: settings.canManageServer,
        botRepository: widget.repository is ServerSettingsBotRepository
            ? widget.repository as ServerSettingsBotRepository
            : null,
        onBotsChanged: _handleBotsChanged,
      ),
    };
  }

  void _handleServerUpdated(ServerSettingsServer server) {
    setState(() => _data = _data.copyWith(server: server));
    widget.onServerUpdated(server);
  }

  void _handleInvitesChanged(List<ServerSettingsListItemSeed> invites) {
    setState(() => _data = _data.copyWith(invites: invites));
  }

  void _handleRolesChanged(List<ServerSettingsListItemSeed> roles) {
    setState(() => _data = _data.copyWith(roles: roles));
  }

  void _handleMembersChanged(List<ServerSettingsListItemSeed> members) {
    setState(() => _data = _data.copyWith(members: members));
  }

  void _handleEmojisChanged(List<ServerSettingsListItemSeed> emojis) {
    setState(() => _data = _data.copyWith(emojis: emojis));
    widget.onEmojisChanged?.call(emojis);
  }

  void _handleStickersChanged(List<ServerSettingsListItemSeed> stickers) {
    setState(() => _data = _data.copyWith(stickers: stickers));
    widget.onStickersChanged?.call(stickers);
  }

  void _handleFeedsChanged(List<ServerSettingsListItemSeed> feeds) {
    setState(() => _data = _data.copyWith(feeds: feeds));
  }

  void _handleBotsChanged(List<ServerSettingsListItemSeed> bots) {
    setState(() => _data = _data.copyWith(bots: bots));
  }
}

class _ServerSettingsHeader extends StatelessWidget {
  const _ServerSettingsHeader({
    required this.activeTab,
    required this.data,
    required this.isLoadingFullSettings,
    required this.fullSettingsError,
    required this.onClose,
  });

  final ServerSettingsTabId activeTab;
  final ServerSettingsData data;
  final bool isLoadingFullSettings;
  final String? fullSettingsError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 22, right: 10),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(activeTab.icon, color: colors.accentStrong, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeTab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                if (fullSettingsError != null)
                  Text(
                    fullSettingsError!,
                    key: const ValueKey('server-settings-load-error'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFFF809A),
                    ),
                  )
                else if (isLoadingFullSettings)
                  Text(
                    'Loading settings data...',
                    key: const ValueKey('server-settings-load-status'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                  )
                else
                  _NetworkBadge(
                    key: const ValueKey('server-settings-network-chip'),
                    networkId: data.networkId,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Close server settings',
            child: TextButton(
              key: const ValueKey('server-settings-close-button'),
              onPressed: onClose,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentStrong,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Done',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.accentStrong,
                  fontWeight: VerdantFontWeights.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  const _NetworkBadge({required this.networkId, super.key});

  final String networkId;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    final apiOrigin = apiOriginFromNetworkId(networkId);
    final label = apiOrigin == null
        ? 'Saved network'
        : Uri.parse(apiOrigin).host;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: typography.badgeLabel,
        children: [
          TextSpan(
            text: 'Network: ',
            style: TextStyle(color: colors.textMuted),
          ),
          TextSpan(
            text: label,
            style: TextStyle(color: colors.accentStrong),
          ),
        ],
      ),
    );
  }
}
