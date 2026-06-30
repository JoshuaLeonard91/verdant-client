import 'package:flutter/material.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import 'server_settings_models.dart';
import 'server_settings_service.dart';

class ServerSettingsAuditLogTab extends StatefulWidget {
  const ServerSettingsAuditLogTab({
    required this.serverId,
    required this.entries,
    this.auditRepository,
    super.key,
  });

  final String serverId;
  final List<ServerSettingsListItemSeed> entries;
  final ServerSettingsAuditRepository? auditRepository;

  @override
  State<ServerSettingsAuditLogTab> createState() =>
      _ServerSettingsAuditLogTabState();
}

class _ServerSettingsAuditLogTabState extends State<ServerSettingsAuditLogTab> {
  late List<ServerSettingsListItemSeed> _entries = [...widget.entries];
  late bool _hasMore = widget.auditRepository != null && _entries.isNotEmpty;
  bool _loading = false;
  String? _error;

  @override
  void didUpdateWidget(covariant ServerSettingsAuditLogTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _entries = [...widget.entries];
      _hasMore = widget.auditRepository != null && _entries.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audit Log', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Recent moderation and server configuration events.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (_entries.isEmpty)
            const _AuditEmpty(label: 'No audit events.')
          else
            for (final entry in _entries)
              _AuditRow(
                key: ValueKey('server-audit-row-${entry.id ?? entry.title}'),
                entry: entry,
              ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const ValueKey('server-audit-error'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
            ),
          ],
          const SizedBox(height: 10),
          if (_hasMore)
            Align(
              alignment: Alignment.centerLeft,
              child: VerdantButton(
                key: const ValueKey('server-audit-load-more-button'),
                label: _loading ? 'Loading...' : 'Load More',
                icon: Icons.expand_more,
                onPressed: _loading ? null : _loadMore,
                variant: VerdantButtonVariant.secondary,
              ),
            )
          else if (_entries.isNotEmpty)
            Text(
              'No more audit events',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Future<void> _loadMore() async {
    final repository = widget.auditRepository;
    if (repository == null || _entries.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await repository.listAuditEvents(
        serverId: widget.serverId,
        beforeEventId: _entries.last.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = [..._entries, ...page.entries];
        _hasMore = page.hasMore;
        _loading = false;
      });
    } on ServerSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry, super.key});

  final ServerSettingsListItemSeed entry;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: VerdantRadii.sharp,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_auditIcon(entry.action), size: 18, color: colors.accentStrong),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      entry.actorUsername ?? 'System',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      _auditActionTitle(entry.action),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.accentStrong,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (entry.reason != null && entry.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.reason!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.text),
                  ),
                ],
              ],
            ),
          ),
          if (entry.trailing != null) ...[
            const SizedBox(width: 12),
            Text(
              entry.trailing!,
              style: typography.badgeLabel.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditEmpty extends StatelessWidget {
  const _AuditEmpty({required this.label});

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

String _auditActionTitle(String? action) {
  return switch (action) {
    'KICK_MEMBER' || 'MEMBER_KICK' => 'Kicked member',
    'BAN_MEMBER' || 'MEMBER_BAN' => 'Banned member',
    'UNBAN_MEMBER' || 'MEMBER_UNBAN' => 'Removed ban',
    'CREATE_ROLE' || 'ROLE_CREATE' => 'Created role',
    'UPDATE_ROLE' || 'ROLE_UPDATE' => 'Updated role',
    'DELETE_ROLE' || 'ROLE_DELETE' => 'Deleted role',
    'ASSIGN_ROLE' || 'ROLE_ASSIGN' => 'Assigned role',
    'REMOVE_ROLE' || 'ROLE_REMOVE' => 'Removed role',
    'SET_NAME_COLOR' => 'Updated name color',
    _ =>
      action == null
          ? 'Updated server'
          : action.toLowerCase().replaceAll('_', ' '),
  };
}

IconData _auditIcon(String? action) {
  return switch (action) {
    'KICK_MEMBER' || 'MEMBER_KICK' => Icons.logout,
    'BAN_MEMBER' || 'MEMBER_BAN' => Icons.block,
    'UNBAN_MEMBER' || 'MEMBER_UNBAN' => Icons.undo,
    'CREATE_ROLE' ||
    'UPDATE_ROLE' ||
    'DELETE_ROLE' ||
    'ASSIGN_ROLE' ||
    'REMOVE_ROLE' ||
    'ROLE_CREATE' ||
    'ROLE_UPDATE' ||
    'ROLE_DELETE' ||
    'ROLE_ASSIGN' ||
    'ROLE_REMOVE' => Icons.shield_outlined,
    _ => Icons.assignment_outlined,
  };
}
