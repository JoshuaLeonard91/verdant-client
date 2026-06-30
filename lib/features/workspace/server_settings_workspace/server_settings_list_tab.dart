import 'package:flutter/material.dart';

import '../../../theme/verdant_button.dart';
import '../../../theme/verdant_theme.dart';
import 'server_settings_models.dart';

class ServerSettingsListTab extends StatelessWidget {
  const ServerSettingsListTab({
    required this.title,
    required this.description,
    required this.items,
    required this.emptyLabel,
    this.actionLabel,
    this.actionIcon,
    super.key,
  });

  final String title;
  final String description;
  final List<ServerSettingsListItemSeed> items;
  final String emptyLabel;
  final String? actionLabel;
  final IconData? actionIcon;

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
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 14),
                SizedBox(
                  width: 156,
                  child: VerdantButton(
                    label: actionLabel!,
                    icon: actionIcon,
                    onPressed: null,
                    variant: VerdantButtonVariant.secondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            _EmptyState(label: emptyLabel)
          else
            for (final item in items) _SettingsListItem(item: item),
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  const _SettingsListItem({required this.item});

  final ServerSettingsListItemSeed item;

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
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 34,
            decoration: BoxDecoration(
              color: item.accent ?? colors.accent,
              borderRadius: VerdantRadii.sharp,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: VerdantFontWeights.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (item.trailing != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border.all(color: colors.border),
              ),
              child: Text(
                item.trailing!,
                style: typography.badgeLabel.copyWith(
                  color: colors.accentStrong,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

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
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
