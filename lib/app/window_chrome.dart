import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/verdant_assets.dart';
import '../theme/verdant_theme.dart';

abstract interface class WindowChromeControls {
  Future<void> minimize();
  Future<void> toggleMaximize();
  Future<void> close();
}

final class WindowManagerChromeControls implements WindowChromeControls {
  const WindowManagerChromeControls();

  @override
  Future<void> close() {
    return windowManager.close();
  }

  @override
  Future<void> minimize() {
    return windowManager.minimize();
  }

  @override
  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
}

class VerdantWindowFrame extends StatelessWidget {
  const VerdantWindowFrame({
    super.key,
    required this.child,
    this.controls = const WindowManagerChromeControls(),
    this.profileBadgeLabel,
    this.overlayBuilder,
  });

  final Widget child;
  final WindowChromeControls controls;
  final String? profileBadgeLabel;
  final WidgetBuilder? overlayBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Material(
      color: colors.background,
      child: Stack(
        children: [
          Column(
            children: [
              VerdantWindowTitleBar(
                controls: controls,
                profileBadgeLabel: profileBadgeLabel,
              ),
              Expanded(child: child),
            ],
          ),
          if (overlayBuilder case final builder?)
            Positioned.fill(child: builder(context)),
        ],
      ),
    );
  }
}

class VerdantWindowTitleBar extends StatelessWidget {
  const VerdantWindowTitleBar({
    super.key,
    required this.controls,
    this.profileBadgeLabel,
  });

  final WindowChromeControls controls;
  final String? profileBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final captionBrightness = Theme.of(context).brightness;
    return Container(
      key: const ValueKey('verdant-window-title-bar'),
      height: 36,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Center(
                child: Row(
                  key: const ValueKey('verdant-window-brand'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        verdantAppIconAsset,
                        key: const ValueKey('verdant-window-app-icon'),
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verdant',
                      key: const ValueKey('verdant-window-title'),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    if (profileBadgeLabel case final label?)
                      _WindowProfileBadge(label: label),
                  ],
                ),
              ),
            ),
          ),
          WindowCaptionButton.minimize(
            key: const ValueKey('window-minimize-button'),
            brightness: captionBrightness,
            onPressed: controls.minimize,
          ),
          WindowCaptionButton.maximize(
            key: const ValueKey('window-maximize-button'),
            brightness: captionBrightness,
            onPressed: controls.toggleMaximize,
          ),
          WindowCaptionButton.close(
            key: const ValueKey('window-close-button'),
            brightness: captionBrightness,
            onPressed: controls.close,
          ),
        ],
      ),
    );
  }
}

class _WindowProfileBadge extends StatelessWidget {
  const _WindowProfileBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    return Container(
      key: const ValueKey('verdant-window-profile-badge'),
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.actionSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.action),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.action,
          fontWeight: FontWeight.w800,
          letterSpacing: .1,
        ),
      ),
    );
  }
}
