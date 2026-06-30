import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import '../server_settings_workspace/server_settings_models.dart';
import '../server_settings_workspace/server_settings_permissions.dart';
import '../server_settings_workspace/server_settings_service.dart';

enum ChannelSettingsTabId {
  overview(key: 'overview', label: 'Overview', icon: Icons.tune),
  permissions(
    key: 'permissions',
    label: 'Permissions',
    icon: Icons.shield_outlined,
  );

  const ChannelSettingsTabId({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class ChannelSettingsWorkspace extends StatefulWidget {
  const ChannelSettingsWorkspace({
    required this.data,
    required this.channel,
    required this.initialTab,
    required this.repository,
    required this.onChannelUpdated,
    required this.onClose,
    this.canManageChannels = true,
    super.key,
  });

  final ServerSettingsData data;
  final ServerSettingsChannelSeed channel;
  final ChannelSettingsTabId initialTab;
  final ChannelSettingsRepository? repository;
  final ValueChanged<ServerSettingsChannelSeed> onChannelUpdated;
  final VoidCallback onClose;
  final bool canManageChannels;

  @override
  State<ChannelSettingsWorkspace> createState() =>
      _ChannelSettingsWorkspaceState();
}

class _ChannelSettingsWorkspaceState extends State<ChannelSettingsWorkspace> {
  late ChannelSettingsTabId _activeTab = widget.initialTab;
  late ServerSettingsChannelSeed _channel = widget.channel;

  @override
  void didUpdateWidget(covariant ChannelSettingsWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id ||
        oldWidget.channel != widget.channel) {
      _channel = widget.channel;
    }
    if (oldWidget.initialTab != widget.initialTab) {
      _activeTab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('channel-settings-workspace'),
        decoration: BoxDecoration(
          color: colors.panelRaised,
          border: Border(left: BorderSide(color: colors.border)),
          boxShadow: const [
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
              width: 188,
              child: _ChannelSettingsNavigation(
                channel: _channel,
                activeTab: _activeTab,
                onTabSelected: (tab) => setState(() => _activeTab = tab),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _ChannelSettingsHeader(
                    channel: _channel,
                    activeTab: _activeTab,
                    networkId: widget.data.networkId,
                    onClose: widget.onClose,
                  ),
                  Expanded(
                    child: SmoothSingleChildScrollView(
                      child: KeyedSubtree(
                        key: ValueKey(
                          'channel-settings-content-${_activeTab.key}',
                        ),
                        child: switch (_activeTab) {
                          ChannelSettingsTabId.overview => _ChannelOverviewTab(
                            channel: _channel,
                            repository: widget.repository,
                            canManageChannels: widget.canManageChannels,
                            onUpdated: _handleChannelUpdated,
                          ),
                          ChannelSettingsTabId.permissions =>
                            _ChannelPermissionsTab(data: widget.data),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChannelUpdated(ServerSettingsChannelSeed channel) {
    setState(() => _channel = channel);
    widget.onChannelUpdated(channel);
  }
}

class _ChannelSettingsNavigation extends StatelessWidget {
  const _ChannelSettingsNavigation({
    required this.channel,
    required this.activeTab,
    required this.onTabSelected,
  });

  final ServerSettingsChannelSeed channel;
  final ChannelSettingsTabId activeTab;
  final ValueChanged<ChannelSettingsTabId> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${channel.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.settingsTitle,
                ),
                const SizedBox(height: 3),
                Text('Channel Settings', style: typography.settingsSubtitle),
              ],
            ),
          ),
          for (final tab in ChannelSettingsTabId.values)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 3),
              child: TextButton(
                key: ValueKey('channel-settings-tab-${tab.key}'),
                onPressed: () => onTabSelected(tab),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: activeTab == tab
                      ? colors.accentStrong
                      : colors.textMuted,
                  backgroundColor: activeTab == tab
                      ? colors.actionMuted
                      : Colors.transparent,
                  minimumSize: const Size.fromHeight(38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Row(
                  children: [
                    Icon(tab.icon, size: 17),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tab.label)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Channel ID', style: typography.settingsSubtitle),
                const SizedBox(height: 4),
                Text(
                  channel.id,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.settingsSectionLabel.copyWith(
                    letterSpacing: 0,
                    fontWeight: VerdantFontWeights.semibold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelSettingsHeader extends StatelessWidget {
  const _ChannelSettingsHeader({
    required this.channel,
    required this.activeTab,
    required this.networkId,
    required this.onClose,
  });

  final ServerSettingsChannelSeed channel;
  final ChannelSettingsTabId activeTab;
  final String networkId;
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
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$networkId / ${channel.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Close',
            child: IconButton(
              key: const ValueKey('channel-settings-close-button'),
              onPressed: onClose,
              icon: const Icon(PhosphorIcons.x, size: 18),
              color: colors.textMuted,
              splashRadius: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelOverviewTab extends StatefulWidget {
  const _ChannelOverviewTab({
    required this.channel,
    required this.repository,
    required this.canManageChannels,
    required this.onUpdated,
  });

  final ServerSettingsChannelSeed channel;
  final ChannelSettingsRepository? repository;
  final bool canManageChannels;
  final ValueChanged<ServerSettingsChannelSeed> onUpdated;

  @override
  State<_ChannelOverviewTab> createState() => _ChannelOverviewTabState();
}

class _ChannelOverviewTabState extends State<_ChannelOverviewTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _topicController;
  late bool _readOnly;
  late int _slowmodeSeconds;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel.name);
    _topicController = TextEditingController(text: widget.channel.topic ?? '');
    _readOnly = widget.channel.readOnly;
    _slowmodeSeconds = widget.channel.slowmodeSeconds;
    _nameController.addListener(_onChanged);
    _topicController.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _ChannelOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id ||
        oldWidget.channel != widget.channel) {
      _nameController.text = widget.channel.name;
      _topicController.text = widget.channel.topic ?? '';
      _readOnly = widget.channel.readOnly;
      _slowmodeSeconds = widget.channel.slowmodeSeconds;
      _error = null;
    }
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onChanged)
      ..dispose();
    _topicController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final canEdit =
        widget.canManageChannels && widget.repository != null && !_saving;
    final hasChanges = _hasChanges;
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Channel Setup', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'Backend permissions remain authoritative. This panel only sends scoped channel updates to the owning backend.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _FieldLabel(label: 'Channel Name'),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('channel-settings-name-field'),
            controller: _nameController,
            enabled: canEdit,
            maxLength: 100,
            decoration: _inputDecoration(context, hintText: 'general'),
          ),
          const SizedBox(height: 14),
          _FieldLabel(label: 'Channel Topic'),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('channel-settings-topic-field'),
            controller: _topicController,
            enabled: canEdit,
            maxLength: 1024,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDecoration(
              context,
              hintText: 'What is this channel about?',
            ),
          ),
          const SizedBox(height: 16),
          _ToggleRow(
            title: 'Read Only',
            description:
                'Lock this channel to moderator posts. Backend checks still enforce message permissions.',
            enabled: _readOnly,
            onChanged: canEdit
                ? (value) => setState(() => _readOnly = value)
                : null,
          ),
          const SizedBox(height: 18),
          _FieldLabel(label: 'Slowmode'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _slowmodeOptions)
                _SlowmodeChoice(
                  seconds: option,
                  selected: _slowmodeSeconds == option,
                  enabled: canEdit,
                  onSelected: () => setState(() => _slowmodeSeconds = option),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Limits how often members can send messages. Manage Messages bypasses this server-side.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF809A)),
            ),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('channel-settings-save-button'),
              onPressed: canEdit && hasChanges ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                disabledBackgroundColor: colors.panel,
                foregroundColor: Colors.black,
                disabledForegroundColor: colors.textMuted,
              ),
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  void _onChanged() => setState(() {});

  bool get _hasChanges {
    return _normalizedName(_nameController.text) != widget.channel.name ||
        _topicController.text.trim() != (widget.channel.topic ?? '') ||
        _readOnly != widget.channel.readOnly ||
        _slowmodeSeconds != widget.channel.slowmodeSeconds;
  }

  Future<void> _save() async {
    final repository = widget.repository;
    if (repository == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final patch = ChannelSettingsPatch(
        name: _normalizedName(_nameController.text) == widget.channel.name
            ? null
            : _nameController.text,
        topic: _topicController.text.trim() == (widget.channel.topic ?? '')
            ? ChannelSettingsPatch.unset
            : _topicController.text,
        readOnly: _readOnly == widget.channel.readOnly ? null : _readOnly,
        slowmodeSeconds: _slowmodeSeconds == widget.channel.slowmodeSeconds
            ? null
            : _slowmodeSeconds,
      );
      final updated = await repository.updateChannel(
        channelId: widget.channel.id,
        patch: patch,
      );
      widget.onUpdated(updated);
    } on ServerSettingsException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save channel settings');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ChannelPermissionsTab extends StatelessWidget {
  const _ChannelPermissionsTab({required this.data});

  final ServerSettingsData data;

  @override
  Widget build(BuildContext context) {
    final roles = data.roles.isEmpty
        ? const [
            ServerSettingsListItemSeed(
              id: 'everyone',
              title: '@everyone',
              subtitle: 'Default channel access',
              permissions: 0,
              position: 0,
            ),
          ]
        : data.roles;
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Overrides',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Text(
            'Role rows show the backend-owned permission baseline. Override editing is intentionally kept in this channel settings surface so future writes can route through the owning backend.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          for (final role in roles) _ChannelRolePermissionCard(role: role),
        ],
      ),
    );
  }
}

class _ChannelRolePermissionCard extends StatelessWidget {
  const _ChannelRolePermissionCard({required this.role});

  final ServerSettingsListItemSeed role;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: role.accent ?? colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  role.title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                'Inherited',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final permission in channelPermissionDefinitions)
                _PermissionChip(
                  permission: permission,
                  enabled: permissionsInclude(
                    role.permissions ?? 0,
                    permission.bit,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.permission, required this.enabled});

  final ServerPermissionDefinition permission;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final foreground = enabled ? colors.accentStrong : colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: enabled
            ? colors.accent.withValues(alpha: 0.10)
            : colors.panel.withValues(alpha: 0.72),
        border: Border.all(
          color: enabled
              ? colors.accent.withValues(alpha: 0.34)
              : colors.border,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForPermission(permission), size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            permission.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('channel-settings-read-only-switch'),
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SlowmodeChoice extends StatelessWidget {
  const _SlowmodeChoice({
    required this.seconds,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final int seconds;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return OutlinedButton(
      key: ValueKey('channel-slowmode-$seconds'),
      onPressed: enabled ? onSelected : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? colors.accentStrong : colors.textMuted,
        side: BorderSide(color: selected ? colors.accentStrong : colors.border),
        backgroundColor: selected
            ? colors.accent.withValues(alpha: 0.12)
            : colors.panel,
        shape: const RoundedRectangleBorder(),
      ),
      child: Text(_slowmodeLabel(seconds)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 1.4,
        fontWeight: VerdantFontWeights.black,
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hintText,
}) {
  final colors = VerdantThemeColors.of(context);
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: colors.panel,
    counterText: '',
    border: OutlineInputBorder(
      borderSide: BorderSide(color: colors.border),
      borderRadius: BorderRadius.zero,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colors.border),
      borderRadius: BorderRadius.zero,
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colors.accentStrong),
      borderRadius: BorderRadius.zero,
    ),
  );
}

String _normalizedName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

const _slowmodeOptions = <int>[
  0,
  5,
  10,
  15,
  30,
  60,
  120,
  300,
  600,
  900,
  1800,
  3600,
  7200,
  21600,
];

String _slowmodeLabel(int seconds) {
  return switch (seconds) {
    0 => 'Off',
    5 => '5 seconds',
    10 => '10 seconds',
    15 => '15 seconds',
    30 => '30 seconds',
    60 => '1 minute',
    120 => '2 minutes',
    300 => '5 minutes',
    600 => '10 minutes',
    900 => '15 minutes',
    1800 => '30 minutes',
    3600 => '1 hour',
    7200 => '2 hours',
    21600 => '6 hours',
    _ => '$seconds seconds',
  };
}
