part of 'user_settings_workspace.dart';

class _UserSettingsNavigation extends StatelessWidget {
  const _UserSettingsNavigation({
    required this.activeCategory,
    required this.onCategorySelected,
  });

  final _UserSettingsCategory activeCategory;
  final ValueChanged<_UserSettingsCategory> onCategorySelected;

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
                Text('Settings', style: typography.settingsTitle),
                const SizedBox(height: 3),
                Text('User Settings', style: typography.settingsSubtitle),
              ],
            ),
          ),
          Expanded(
            child: SmoothSingleChildScrollView(
              key: const ValueKey('user-settings-navigation-scroll'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in _UserSettingsGroup.values) ...[
                    for (final category in _UserSettingsCategory.values.where(
                      (category) => category.group == group,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _UserSettingsNavigationButton(
                          category: category,
                          selected: category == activeCategory,
                          onPressed: () => onCategorySelected(category),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSettingsNavigationButton extends StatelessWidget {
  const _UserSettingsNavigationButton({
    required this.category,
    required this.selected,
    required this.onPressed,
  });

  final _UserSettingsCategory category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final typography = VerdantThemeTypography.of(context);
    final foreground = selected ? colors.accentStrong : colors.textMuted;
    final background = selected ? colors.actionMuted : Colors.transparent;
    return Tooltip(
      message: category.label,
      child: TextButton(
        key: ValueKey('user-settings-category-${category.key}'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: foreground,
          backgroundColor: background,
          minimumSize: const Size.fromHeight(38),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: const RoundedRectangleBorder(),
        ),
        child: Row(
          children: [
            Icon(category.icon, size: 17, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (selected
                            ? typography.settingsNavigationSelectedLabel
                            : typography.settingsNavigationLabel)
                        .copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSettingsHeader extends StatelessWidget {
  const _UserSettingsHeader({
    required this.activeCategory,
    required this.settingsContext,
    required this.homeNetworkId,
    required this.onClose,
  });

  final _UserSettingsCategory activeCategory;
  final UserSettingsContext settingsContext;
  final String homeNetworkId;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showContextSelector = constraints.maxWidth >= 520;
          return Row(
            children: [
              Icon(activeCategory.icon, color: colors.accentStrong, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  activeCategory.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (showContextSelector) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: _UserSettingsContextLabel(
                    contextData: settingsContext,
                    homeNetworkId: homeNetworkId,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Tooltip(
                message: 'Close user settings',
                child: TextButton(
                  key: const ValueKey('user-settings-close-button'),
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
          );
        },
      ),
    );
  }
}

class _UserSettingsContextLabel extends StatelessWidget {
  const _UserSettingsContextLabel({
    required this.contextData,
    required this.homeNetworkId,
  });

  final UserSettingsContext contextData;
  final String homeNetworkId;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final networkLabel =
        sameWorkspaceNetworkId(contextData.networkId, homeNetworkId)
        ? 'Home Network'
        : 'Federated Network';
    return ConstrainedBox(
      key: const ValueKey('user-settings-context-label'),
      constraints: const BoxConstraints(maxWidth: 238),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panelHover,
          border: Border.all(color: colors.borderStrong),
          borderRadius: VerdantRadii.sharp,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.public_outlined, size: 15, color: colors.accentStrong),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: networkLabel,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: VerdantFontWeights.semibold,
                        ),
                      ),
                      TextSpan(
                        text: '  /  ',
                        style: TextStyle(color: colors.textMuted),
                      ),
                      TextSpan(
                        text: contextData.usernameLabel,
                        style: TextStyle(
                          color: contextData.signedIn
                              ? colors.accentStrong
                              : colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
