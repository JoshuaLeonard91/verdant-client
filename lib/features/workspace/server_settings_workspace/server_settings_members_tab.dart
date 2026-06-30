import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../shared/member_profile_popover.dart';
import '../workspace_seed.dart';
import 'server_media_url_policy.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

class ServerSettingsMembersTab extends StatefulWidget {
  const ServerSettingsMembersTab({
    required this.serverId,
    required this.networkId,
    required this.members,
    required this.roles,
    required this.currentUserId,
    required this.ownerId,
    required this.canKickMembers,
    required this.canBanMembers,
    required this.mediaPolicy,
    this.moderationRepository,
    this.onMembersChanged,
    super.key,
  });

  final String serverId;
  final String networkId;
  final List<ServerSettingsListItemSeed> members;
  final List<ServerSettingsListItemSeed> roles;
  final String currentUserId;
  final String ownerId;
  final bool canKickMembers;
  final bool canBanMembers;
  final ServerMediaPolicy mediaPolicy;
  final ServerSettingsModerationRepository? moderationRepository;
  final ValueChanged<List<ServerSettingsListItemSeed>>? onMembersChanged;

  @override
  State<ServerSettingsMembersTab> createState() =>
      _ServerSettingsMembersTabState();
}

class _ServerSettingsMembersTabState extends State<ServerSettingsMembersTab> {
  final ScrollController _membersScrollController = ScrollController();
  late List<ServerSettingsListItemSeed> _members = [...widget.members];
  List<ServerSettingsListItemSeed> _bans = const [];
  String _query = '';
  String? _expandedUserId;
  bool _showBans = false;
  bool _loadingBans = false;
  String? _error;

  @override
  void didUpdateWidget(covariant ServerSettingsMembersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      _members = [...widget.members];
    }
  }

  @override
  void dispose() {
    _membersScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _TabButton(
                key: const ValueKey('server-members-members-tab'),
                label: 'Members',
                selected: !_showBans,
                onPressed: () => setState(() => _showBans = false),
              ),
              if (widget.canBanMembers) ...[
                const SizedBox(width: 8),
                _TabButton(
                  key: const ValueKey('server-members-bans-tab'),
                  label: 'Bans',
                  selected: _showBans,
                  onPressed: _openBans,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Member moderation routes through ${_backendLabelForNetwork(widget.networkId)}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (!_showBans)
            TextField(
              key: const ValueKey('server-members-search-field'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search members',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const ValueKey('server-members-error'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: _showBans
                ? _buildBans(context)
                : _buildMembers(context, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildMembers(BuildContext context, VerdantThemeColors colors) {
    final filtered = [
      for (final member in _members)
        if (_matchesQuery(member)) member,
    ];
    if (filtered.isEmpty) {
      return _EmptyPanel(label: 'No matching members.');
    }
    final backendLabel = _backendLabelForNetwork(widget.networkId);
    return SmoothSingleChildScrollView(
      key: const ValueKey('server-members-smooth-scroll'),
      controller: _membersScrollController,
      primary: false,
      child: Column(
        children: [
          for (final indexed in filtered.indexed)
            _MemberRow(
              key: ValueKey(
                'server-members-row-${_stableRowId(indexed.$2, indexed.$1)}',
              ),
              member: indexed.$2,
              roles: widget.roles,
              backendLabel: backendLabel,
              mediaPolicy: widget.mediaPolicy,
              expanded: _expandedUserId == _stableRowId(indexed.$2, indexed.$1),
              canKick: _canModerate(indexed.$2, widget.canKickMembers),
              canBan: _canModerate(indexed.$2, widget.canBanMembers),
              onToggle: () {
                final id = _stableRowId(indexed.$2, indexed.$1);
                setState(() {
                  _expandedUserId = _expandedUserId == id ? null : id;
                });
              },
              onKick: () => _confirmKick(indexed.$2),
              onBan: () => _confirmBan(indexed.$2),
            ),
        ],
      ),
    );
  }

  Widget _buildBans(BuildContext context) {
    if (_loadingBans) {
      return const _EmptyPanel(label: 'Loading bans...');
    }
    if (_bans.isEmpty) {
      return const _EmptyPanel(label: 'No banned users.');
    }
    final backendLabel = _backendLabelForNetwork(widget.networkId);
    return SmoothSingleChildScrollView(
      key: const ValueKey('server-bans-smooth-scroll'),
      controller: _membersScrollController,
      primary: false,
      child: Column(
        children: [
          for (final ban in _bans)
            _BanRow(
              key: ValueKey('server-ban-row-${ban.userId ?? ban.id}'),
              ban: ban,
              backendLabel: backendLabel,
              mediaPolicy: widget.mediaPolicy,
              onUnban: () => _confirmUnban(ban),
            ),
        ],
      ),
    );
  }

  bool _matchesQuery(ServerSettingsListItemSeed member) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return member.title.toLowerCase().contains(normalized) ||
        (member.username?.toLowerCase().contains(normalized) ?? false);
  }

  bool _canModerate(ServerSettingsListItemSeed member, bool allowed) {
    if (!allowed || widget.moderationRepository == null) {
      return false;
    }
    final userId = member.userId ?? member.id;
    if (userId == null) {
      return false;
    }
    return userId != widget.currentUserId && userId != widget.ownerId;
  }

  Future<void> _openBans() async {
    setState(() {
      _showBans = true;
      _loadingBans = true;
      _error = null;
    });
    final repository = widget.moderationRepository;
    if (repository == null) {
      setState(() => _loadingBans = false);
      return;
    }
    try {
      final bans = await repository.listBans(serverId: widget.serverId);
      if (!mounted) {
        return;
      }
      setState(() {
        _bans = bans;
        _loadingBans = false;
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loadingBans = false;
      });
    }
  }

  Future<void> _confirmKick(ServerSettingsListItemSeed member) async {
    final userId = member.userId ?? member.id;
    if (userId == null) {
      return;
    }
    final reason = await _showReasonDialog(
      title: 'Kick ${member.title}',
      confirmLabel: 'Kick',
      reasonKey: const ValueKey('server-member-kick-reason-field'),
      confirmKey: const ValueKey('server-member-kick-confirm'),
    );
    if (reason == null || !mounted) {
      return;
    }
    try {
      await widget.moderationRepository?.kickMember(
        serverId: widget.serverId,
        userId: userId,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      _removeMember(userId);
    } on ServerSettingsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not kick ${member.title}.');
      }
    }
  }

  Future<void> _confirmBan(ServerSettingsListItemSeed member) async {
    final userId = member.userId ?? member.id;
    if (userId == null) {
      return;
    }
    final reason = await _showReasonDialog(
      title: 'Ban ${member.title}',
      confirmLabel: 'Ban',
      reasonKey: const ValueKey('server-member-ban-reason-field'),
      confirmKey: const ValueKey('server-member-ban-confirm'),
    );
    if (reason == null || !mounted) {
      return;
    }
    try {
      await widget.moderationRepository?.banMember(
        serverId: widget.serverId,
        userId: userId,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      _removeMember(userId);
    } on ServerSettingsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not ban ${member.title}.');
      }
    }
  }

  Future<void> _confirmUnban(ServerSettingsListItemSeed ban) async {
    final userId = ban.userId ?? ban.id;
    if (userId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ban for ${ban.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: ValueKey('server-ban-unban-confirm-$userId'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unban'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await widget.moderationRepository?.unbanMember(
        serverId: widget.serverId,
        userId: userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bans = [
          for (final item in _bans)
            if ((item.userId ?? item.id) != userId) item,
        ];
      });
    } on ServerSettingsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not remove ban for ${ban.title}.');
      }
    }
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String confirmLabel,
    required Key reasonKey,
    required Key confirmKey,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _ReasonDialog(
        title: title,
        confirmLabel: confirmLabel,
        reasonKey: reasonKey,
        confirmKey: confirmKey,
      ),
    );
  }

  void _removeMember(String userId) {
    setState(() {
      _members = [
        for (final member in _members)
          if ((member.userId ?? member.id) != userId) member,
      ];
      _expandedUserId = null;
    });
    widget.onMembersChanged?.call(_members);
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.confirmLabel,
    required this.reasonKey,
    required this.confirmKey,
  });

  final String title;
  final String confirmLabel;
  final Key reasonKey;
  final Key confirmKey;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.reasonKey,
        controller: _controller,
        autofocus: true,
        maxLength: 512,
        decoration: const InputDecoration(hintText: 'Reason optional'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: widget.confirmKey,
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

String _stableRowId(ServerSettingsListItemSeed item, int index) {
  return item.userId ??
      item.id ??
      '${index}_${item.title}_${item.subtitle}'.replaceAll(RegExp(r'\s+'), '_');
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.roles,
    required this.backendLabel,
    required this.mediaPolicy,
    required this.expanded,
    required this.canKick,
    required this.canBan,
    required this.onToggle,
    required this.onKick,
    required this.onBan,
    super.key,
  });

  final ServerSettingsListItemSeed member;
  final List<ServerSettingsListItemSeed> roles;
  final String backendLabel;
  final ServerMediaPolicy mediaPolicy;
  final bool expanded;
  final bool canKick;
  final bool canBan;
  final VoidCallback onToggle;
  final VoidCallback onKick;
  final VoidCallback onBan;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final userId = member.userId ?? member.id ?? 'unknown';
    final roleLabels = [
      for (final roleId in member.roleIds) _roleTitle(roleId) ?? roleId,
    ];
    final roleLabel = roleLabels.isEmpty
        ? (member.trailing?.isNotEmpty == true ? member.trailing! : 'No roles')
        : roleLabels.join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: expanded ? colors.action : colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _MemberAvatar(item: member, mediaPolicy: mediaPolicy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.title,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          member.username == null
                              ? member.subtitle
                              : '@${member.username}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          backendLabel,
                          key: ValueKey('server-member-backend-$userId'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(roleLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        if (canKick)
                          SizedBox(
                            width: 104,
                            child: VerdantButton(
                              key: ValueKey('server-member-kick-$userId'),
                              label: 'Kick',
                              icon: Icons.logout,
                              onPressed: onKick,
                              variant: VerdantButtonVariant.secondary,
                            ),
                          ),
                        if (canKick && canBan) const SizedBox(width: 8),
                        if (canBan)
                          SizedBox(
                            width: 104,
                            child: VerdantButton(
                              key: ValueKey('server-member-ban-$userId'),
                              label: 'Ban',
                              icon: Icons.block,
                              onPressed: onBan,
                              variant: VerdantButtonVariant.secondary,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String? _roleTitle(String roleId) {
    for (final role in roles) {
      if (role.id == roleId) {
        return role.title;
      }
    }
    return null;
  }
}

class _BanRow extends StatelessWidget {
  const _BanRow({
    required this.ban,
    required this.backendLabel,
    required this.mediaPolicy,
    required this.onUnban,
    super.key,
  });

  final ServerSettingsListItemSeed ban;
  final String backendLabel;
  final ServerMediaPolicy mediaPolicy;
  final VoidCallback onUnban;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final userId = ban.userId ?? ban.id ?? 'unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Row(
        children: [
          _MemberAvatar(item: ban, mediaPolicy: mediaPolicy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ban.title, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  ban.reason == null || ban.reason!.isEmpty
                      ? 'No reason provided'
                      : ban.reason!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  backendLabel,
                  key: ValueKey('server-ban-backend-$userId'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 112,
            child: VerdantButton(
              key: ValueKey('server-ban-unban-$userId'),
              label: 'Unban',
              icon: Icons.undo,
              onPressed: onUnban,
              variant: VerdantButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? colors.actionStrong : colors.textMuted,
        side: BorderSide(color: selected ? colors.action : colors.borderStrong),
      ),
      child: Text(label),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.item, required this.mediaPolicy});

  final ServerSettingsListItemSeed item;
  final ServerMediaPolicy mediaPolicy;

  @override
  Widget build(BuildContext context) {
    final member = MemberSeed(
      id: item.userId ?? item.id,
      name: item.title,
      username: item.username,
      status: item.subtitle,
      initials: _initialsFor(item.title),
      roleIds: item.roleIds,
      avatarUrl: item.avatarUrl,
      bannerUrl: item.bannerUrl,
      bannerBaseColor: item.bannerBaseColor,
      bannerCrop: item.bannerCrop,
      memberListBannerUrl: item.memberListBannerUrl,
      memberListBannerCrop: item.memberListBannerCrop,
    );
    final keyId = item.userId ?? item.id ?? item.title;
    return MemberMediaAvatar(
      key: ValueKey('server-settings-member-avatar-$keyId'),
      member: member,
      mediaPolicy: mediaPolicy,
      size: 36,
      playAnimatedMedia: true,
      imageKeyPrefix: 'server-settings-member-avatar-image',
      loadingPlaceholder: _Avatar(label: item.title),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.orange,
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(
        _initialsFor(label),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.text,
          fontWeight: VerdantFontWeights.black,
        ),
      ),
    );
  }
}

String _initialsFor(String label) {
  final compact = label.replaceAll(RegExp(r'\s+'), '');
  if (compact.length >= 2) {
    return compact.substring(0, 2).toUpperCase();
  }
  return compact.toUpperCase();
}

String _backendLabelForNetwork(String networkId) {
  final apiOrigin = apiOriginFromNetworkId(networkId);
  if (apiOrigin == null) {
    return 'saved network';
  }
  final host = Uri.parse(apiOrigin).host;
  return host.isEmpty ? apiOrigin : host;
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
