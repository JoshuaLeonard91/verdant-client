import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import '../../auth/auth_models.dart';
import '../chat_workspace/chat_invite_link.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

class ServerSettingsInvitesTab extends StatefulWidget {
  const ServerSettingsInvitesTab({
    required this.data,
    required this.repository,
    required this.onInvitesChanged,
    super.key,
  });

  final ServerSettingsData data;
  final ServerSettingsRepository repository;
  final ValueChanged<List<ServerSettingsListItemSeed>> onInvitesChanged;

  @override
  State<ServerSettingsInvitesTab> createState() =>
      _ServerSettingsInvitesTabState();
}

class _ServerSettingsInvitesTabState extends State<ServerSettingsInvitesTab> {
  late var _invites = [...widget.data.invites];
  var _isCreating = false;
  String? _copiedCode;
  String? _error;
  Timer? _copyTimer;

  @override
  void didUpdateWidget(covariant ServerSettingsInvitesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.invites != widget.data.invites) {
      _invites = [...widget.data.invites];
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite links',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Create, copy, and revoke invite links for this server.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 176,
                child: VerdantButton(
                  key: const ValueKey('server-settings-create-invite-button'),
                  label: 'Create Link',
                  icon: Icons.add_link,
                  isBusy: _isCreating,
                  onPressed: _isCreating ? null : _createInvite,
                  variant: VerdantButtonVariant.secondary,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _dangerColor),
            ),
          ],
          const SizedBox(height: 18),
          if (_invites.isEmpty)
            const _InviteEmptyState()
          else
            for (final invite in _invites)
              _InviteLinkRow(
                invite: invite,
                link: _linkForInvite(invite),
                backendLabel: _backendLabelForNetwork(widget.data.networkId),
                copied: _copiedCode == _inviteCode(invite),
                onCopy: () => _copyInvite(invite),
                onRevoke: () => _revokeInvite(invite),
              ),
        ],
      ),
    );
  }

  String _linkForInvite(ServerSettingsListItemSeed invite) {
    final code = _inviteCode(invite);
    return buildChatInviteShareLink(
      code,
      apiOrigin: _apiOriginForNetwork(widget.data.networkId),
    );
  }

  Future<void> _createInvite() async {
    final options = await showDialog<_InviteCreateOptions>(
      context: context,
      builder: (context) => const _CreateInviteOptionsDialog(),
    );
    if (options == null || !mounted) {
      return;
    }
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      final invite = await widget.repository.createInvite(
        serverId: widget.data.server.id,
        maxUses: options.maxUses,
        expiresIn: options.expiresIn,
      );
      final next = [invite, ..._invites];
      _syncInvites(next);
      await _copyLink(invite);
    } on ServerSettingsException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create invite link');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _copyInvite(ServerSettingsListItemSeed invite) {
    return _copyLink(invite);
  }

  Future<void> _copyLink(ServerSettingsListItemSeed invite) async {
    final code = _inviteCode(invite);
    await Clipboard.setData(ClipboardData(text: _linkForInvite(invite)));
    if (!mounted) {
      return;
    }
    _copyTimer?.cancel();
    setState(() => _copiedCode = code);
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedCode = null);
      }
    });
  }

  Future<void> _revokeInvite(ServerSettingsListItemSeed invite) async {
    final code = _inviteCode(invite);
    final previous = [..._invites];
    setState(() => _error = null);
    _syncInvites([
      for (final row in _invites)
        if (_inviteCode(row) != code) row,
    ]);
    try {
      await widget.repository.revokeInvite(
        serverId: widget.data.server.id,
        code: code,
      );
    } on ServerSettingsException catch (error) {
      if (mounted) {
        setState(() {
          _invites = previous;
          _error = error.message;
        });
        widget.onInvitesChanged(previous);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _invites = previous;
          _error = 'Could not revoke invite link';
        });
        widget.onInvitesChanged(previous);
      }
    }
  }

  void _syncInvites(List<ServerSettingsListItemSeed> invites) {
    if (!mounted) {
      return;
    }
    setState(() => _invites = invites);
    widget.onInvitesChanged(invites);
  }
}

class _InviteLinkRow extends StatelessWidget {
  const _InviteLinkRow({
    required this.invite,
    required this.link,
    required this.backendLabel,
    required this.copied,
    required this.onCopy,
    required this.onRevoke,
  });

  final ServerSettingsListItemSeed invite;
  final String link;
  final String backendLabel;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final code = _inviteCode(invite);
    return Container(
      key: ValueKey('server-settings-invite-row-$code'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 8,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: VerdantRadii.sharp,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  link,
                  key: ValueKey('server-settings-invite-link-$code'),
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  _inviteMeta(invite),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  backendLabel,
                  key: ValueKey('server-settings-invite-backend-$code'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconAction(
            key: ValueKey('server-settings-invite-copy-$code'),
            tooltip: copied ? 'Copied' : 'Copy invite link',
            icon: copied
                ? PhosphorIconsRegular.check
                : PhosphorIconsRegular.copy,
            onPressed: onCopy,
          ),
          const SizedBox(width: 6),
          _IconAction(
            key: ValueKey('server-settings-invite-revoke-$code'),
            tooltip: 'Revoke invite',
            icon: PhosphorIconsRegular.trash,
            danger: true,
            onPressed: onRevoke,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.danger = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: PhosphorIcon(icon, size: 16),
        color: danger ? _dangerColor : colors.textMuted,
        splashRadius: 18,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _InviteEmptyState extends StatelessWidget {
  const _InviteEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'No active invites for this server.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

final class _InviteCreateOptions {
  const _InviteCreateOptions({required this.maxUses, required this.expiresIn});

  final int? maxUses;
  final Duration? expiresIn;
}

final class _InviteUsesOption {
  const _InviteUsesOption(this.label, this.value, this.key);

  final String label;
  final int? value;
  final String key;
}

final class _InviteDurationOption {
  const _InviteDurationOption(this.label, this.value, this.key);

  final String label;
  final Duration? value;
  final String key;
}

const _inviteUsesOptions = [
  _InviteUsesOption('1 use', 1, '1'),
  _InviteUsesOption('5 uses', 5, '5'),
  _InviteUsesOption('10 uses', 10, '10'),
  _InviteUsesOption('25 uses', 25, '25'),
  _InviteUsesOption('Unlimited', null, 'unlimited'),
];

const _inviteDurationOptions = [
  _InviteDurationOption('1 hour', Duration(hours: 1), '1h'),
  _InviteDurationOption('24 hours', Duration(hours: 24), '24h'),
  _InviteDurationOption('7 days', Duration(days: 7), '7d'),
  _InviteDurationOption('30 days', Duration(days: 30), '30d'),
  _InviteDurationOption('Never', null, 'never'),
];

class _CreateInviteOptionsDialog extends StatefulWidget {
  const _CreateInviteOptionsDialog();

  @override
  State<_CreateInviteOptionsDialog> createState() =>
      _CreateInviteOptionsDialogState();
}

class _CreateInviteOptionsDialogState
    extends State<_CreateInviteOptionsDialog> {
  int? _maxUses = 10;
  Duration? _expiresIn = const Duration(days: 7);

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return AlertDialog(
      key: const ValueKey('server-settings-create-invite-options'),
      backgroundColor: colors.panelRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.border),
      ),
      title: const Text('Create invite link'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Max uses', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _inviteUsesOptions)
                  _InviteOptionChip(
                    key: ValueKey(
                      'server-settings-invite-max-uses-${option.key}',
                    ),
                    label: option.label,
                    selected: _maxUses == option.value,
                    onPressed: () => setState(() => _maxUses = option.value),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Expires after',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _inviteDurationOptions)
                  _InviteOptionChip(
                    key: ValueKey(
                      'server-settings-invite-duration-${option.key}',
                    ),
                    label: option.label,
                    selected: _expiresIn == option.value,
                    onPressed: () => setState(() => _expiresIn = option.value),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('server-settings-create-invite-confirm'),
          onPressed: () {
            Navigator.of(context).pop(
              _InviteCreateOptions(maxUses: _maxUses, expiresIn: _expiresIn),
            );
          },
          child: const Text('Create Link'),
        ),
      ],
    );
  }
}

class _InviteOptionChip extends StatelessWidget {
  const _InviteOptionChip({
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
        backgroundColor: selected ? colors.action : Colors.transparent,
        foregroundColor: selected ? colors.actionText : colors.text,
        side: BorderSide(color: selected ? colors.action : colors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
      ),
      child: Text(label),
    );
  }
}

String _inviteCode(ServerSettingsListItemSeed invite) {
  final code = invite.inviteCode ?? invite.id;
  if (code != null && code.trim().isNotEmpty) {
    return code.trim();
  }
  final title = invite.title.trim();
  if (title.toLowerCase().startsWith('invite ')) {
    return title.substring(7).trim();
  }
  return title;
}

String _inviteMeta(ServerSettingsListItemSeed invite) {
  final inviter = invite.inviterUsername ?? _createdByFromSubtitle(invite);
  final uses = invite.inviteUses ?? 0;
  final maxUses = invite.inviteMaxUses;
  final maxLabel = maxUses == null || maxUses == 0 ? 'unlimited' : '$maxUses';
  final expiry = _expiryLabel(invite.inviteExpiresAt);
  final expiryCopy = switch (expiry) {
    'Never' => 'Never expires',
    'Expired' => 'Expired',
    _ => 'Expires in $expiry',
  };
  return '$uses / $maxLabel uses - invited by $inviter - $expiryCopy';
}

String _createdByFromSubtitle(ServerSettingsListItemSeed invite) {
  const prefix = 'Created by ';
  return invite.subtitle.startsWith(prefix)
      ? invite.subtitle.substring(prefix.length)
      : 'unknown';
}

String _expiryLabel(String? expiresAt) {
  if (expiresAt == null || expiresAt.trim().isEmpty) {
    return 'Never';
  }
  final expires = DateTime.tryParse(expiresAt);
  if (expires == null) {
    return expiresAt;
  }
  final diff = expires.difference(DateTime.now().toUtc());
  if (diff.isNegative) {
    return 'Expired';
  }
  final days = diff.inDays;
  if (days > 0) {
    return '${days}d ${diff.inHours % 24}h';
  }
  final hours = diff.inHours;
  if (hours > 0) {
    return '${hours}h ${diff.inMinutes % 60}m';
  }
  return '${diff.inMinutes}m';
}

String? _apiOriginForNetwork(String networkId) {
  return apiOriginFromNetworkId(networkId);
}

String _backendLabelForNetwork(String networkId) {
  final apiOrigin = _apiOriginForNetwork(networkId);
  if (apiOrigin == null) {
    return 'Backend: saved network';
  }
  final host = Uri.parse(apiOrigin).host;
  return 'Backend: ${host.isEmpty ? apiOrigin : host}';
}

const _dangerColor = Color(0xFFFF8A8A);
