import 'package:flutter/material.dart';

import '../../../shared/smooth_single_child_scroll_view.dart';
import '../../../theme/verdant_theme.dart';
import 'server_settings_models.dart';

class ServerSettingsNavigation extends StatelessWidget {
  const ServerSettingsNavigation({
    required this.settings,
    required this.activeTab,
    required this.onTabSelected,
    super.key,
  });

  final ServerSettingsSeed settings;
  final ServerSettingsTabId activeTab;
  final ValueChanged<ServerSettingsTabId> onTabSelected;

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
                  settings.serverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.settingsTitle,
                ),
                const SizedBox(height: 3),
                Text('Server Settings', style: typography.settingsSubtitle),
              ],
            ),
          ),
          Expanded(
            child: SmoothSingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  for (final tab in ServerSettingsTabId.values)
                    _SettingsNavItem(
                      tab: tab,
                      selected: activeTab == tab,
                      enabled: settings.canOpen(tab),
                      onSelected: onTabSelected,
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Server ID', style: typography.settingsSubtitle),
                const SizedBox(height: 4),
                Text(
                  settings.localServerId,
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

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.tab,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ServerSettingsTabId tab;
  final bool selected;
  final bool enabled;
  final ValueChanged<ServerSettingsTabId> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    final foreground = enabled
        ? (selected ? colors.accentStrong : colors.textMuted)
        : colors.textMuted.withValues(alpha: 0.42);
    final background = selected ? colors.actionMuted : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Tooltip(
        message: enabled ? tab.label : tab.permissionHint,
        child: TextButton(
          key: ValueKey('server-settings-tab-${tab.key}'),
          onPressed: enabled ? () => onSelected(tab) : null,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: foreground,
            disabledForegroundColor: foreground,
            backgroundColor: background,
            minimumSize: const Size.fromHeight(38),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const RoundedRectangleBorder(),
          ),
          child: Row(
            children: [
              Icon(tab.icon, size: 17, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (selected
                              ? typography.settingsNavigationSelectedLabel
                              : typography.settingsNavigationLabel)
                          .copyWith(color: foreground),
                ),
              ),
              if (!enabled) Icon(Icons.lock, size: 13, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
