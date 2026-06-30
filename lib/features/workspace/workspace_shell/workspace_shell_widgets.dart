part of 'workspace_shell.dart';

class _WorkspaceStatus extends StatelessWidget {
  const _WorkspaceStatus({
    required this.label,
    this.actionLabel = 'Retry',
    this.onAction,
    this.showProgress = false,
  });

  final String label;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress) ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 14),
              ],
              Text(label, textAlign: TextAlign.center),
              if (onAction != null) ...[
                const SizedBox(height: 14),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return VerticalDivider(color: colors.border, width: 1, thickness: 1);
  }
}

class _LeftWorkspacePane extends StatelessWidget {
  const _LeftWorkspacePane({
    required this.width,
    required this.showDirectMessages,
    required this.serverChild,
    required this.directMessagesChild,
  });

  final double width;
  final bool showDirectMessages;
  final Widget serverChild;
  final Widget directMessagesChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _WorkspacePaneStack(
        key: const ValueKey('left-workspace-pane-stack'),
        showAlternate: showDirectMessages,
        primaryChild: serverChild,
        alternateChild: directMessagesChild,
      ),
    );
  }
}

class _MainWorkspacePane extends StatelessWidget {
  const _MainWorkspacePane({
    required this.showDirectMessages,
    required this.serverChild,
    required this.directMessagesChild,
  });

  final bool showDirectMessages;
  final Widget serverChild;
  final Widget directMessagesChild;

  @override
  Widget build(BuildContext context) {
    return _WorkspacePaneStack(
      key: const ValueKey('main-workspace-pane-stack'),
      showAlternate: showDirectMessages,
      primaryChild: serverChild,
      alternateChild: KeyedSubtree(
        key: const ValueKey('direct-messages-workspace'),
        child: directMessagesChild,
      ),
    );
  }
}

class _WorkspacePaneStack extends StatelessWidget {
  const _WorkspacePaneStack({
    required this.showAlternate,
    required this.primaryChild,
    required this.alternateChild,
    super.key,
  });

  final bool showAlternate;
  final Widget primaryChild;
  final Widget alternateChild;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _KeptWorkspaceChild(
            offstage: showAlternate,
            focusGuardKey: const ValueKey('workspace-swap-primary-focus-guard'),
            child: primaryChild,
          ),
        ),
        Positioned.fill(
          child: _KeptWorkspaceChild(
            offstage: !showAlternate,
            focusGuardKey: const ValueKey(
              'workspace-swap-alternate-focus-guard',
            ),
            child: alternateChild,
          ),
        ),
      ],
    );
  }
}

class _KeptWorkspaceChild extends StatelessWidget {
  const _KeptWorkspaceChild({
    required this.offstage,
    required this.focusGuardKey,
    required this.child,
  });

  final bool offstage;
  final Key focusGuardKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: offstage,
      child: TickerMode(
        enabled: !offstage,
        child: _GuardedWorkspaceSwapChild(
          focusGuardKey: focusGuardKey,
          inactive: offstage,
          child: child,
        ),
      ),
    );
  }
}

class _GuardedWorkspaceSwapChild extends StatelessWidget {
  const _GuardedWorkspaceSwapChild({
    required this.focusGuardKey,
    required this.inactive,
    required this.child,
  });

  final Key focusGuardKey;
  final bool inactive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      key: focusGuardKey,
      excluding: inactive,
      child: ExcludeSemantics(
        excluding: inactive,
        child: IgnorePointer(ignoring: inactive, child: child),
      ),
    );
  }
}

ThemeData _workspaceThemeFor(UserSettingsPreferences preferences) {
  final base = buildVerdantTheme(
    mode: _workspaceThemeModeFor(preferences.theme),
  );
  return base.copyWith(
    visualDensity: preferences.density == UserSettingsDensityPreference.compact
        ? const VisualDensity(horizontal: -1, vertical: -1)
        : VisualDensity.standard,
    materialTapTargetSize:
        preferences.density == UserSettingsDensityPreference.compact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded,
  );
}

VerdantThemeMode _workspaceThemeModeFor(
  UserSettingsThemePreference preference,
) {
  return switch (preference) {
    UserSettingsThemePreference.dark => VerdantThemeMode.dark,
    UserSettingsThemePreference.light => VerdantThemeMode.light,
  };
}

class _WorkspaceTextScale extends StatelessWidget {
  const _WorkspaceTextScale({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: _ComposedWorkspaceTextScaler(
          base: media.textScaler,
          workspaceScale: scale,
        ),
      ),
      child: child,
    );
  }
}

Color? _profileHexColor(String? value) {
  if (value == null || !value.startsWith('#') || value.length != 7) {
    return null;
  }
  final parsed = int.tryParse(value.substring(1), radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}

final class _ComposedWorkspaceTextScaler extends TextScaler {
  const _ComposedWorkspaceTextScaler({
    required this.base,
    required this.workspaceScale,
  });

  final TextScaler base;
  final double workspaceScale;

  @override
  double scale(double fontSize) =>
      math.max(base.scale(fontSize), fontSize * workspaceScale);

  // TextScaler still requires this deprecated compatibility getter.
  // Approximate it from scale(1) so callers that still read it keep the larger
  // of the platform accessibility scale and Verdant's workspace scale.
  // ignore: deprecated_member_use
  @override
  double get textScaleFactor => math.max(base.scale(1), workspaceScale);
}
