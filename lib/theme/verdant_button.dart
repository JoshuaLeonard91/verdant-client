import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import 'verdant_theme.dart';

enum VerdantButtonVariant { primary, secondary, ghost }

class VerdantButton extends StatelessWidget {
  const VerdantButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = VerdantButtonVariant.primary,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final VerdantButtonVariant variant;
  final bool isBusy;

  bool get _enabled => onPressed != null && !isBusy;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundColor(context);
    final labelWidget = _ButtonContent(
      label: label,
      icon: icon,
      foreground: foreground,
      isBusy: isBusy,
    );

    return switch (variant) {
      VerdantButtonVariant.primary => MoonFilledButton(
        isFullWidth: true,
        borderRadius: VerdantRadii.sharp,
        buttonSize: MoonButtonSize.md,
        height: 40,
        width: double.infinity,
        semanticLabel: label,
        onTap: _enabled ? onPressed : null,
        label: labelWidget,
      ),
      VerdantButtonVariant.secondary => MoonOutlinedButton(
        isFullWidth: true,
        borderRadius: VerdantRadii.sharp,
        borderColor: VerdantThemeColors.of(context).borderStrong,
        buttonSize: MoonButtonSize.md,
        height: 40,
        width: double.infinity,
        semanticLabel: label,
        onTap: _enabled ? onPressed : null,
        label: labelWidget,
      ),
      VerdantButtonVariant.ghost => MoonTextButton(
        isFullWidth: true,
        buttonSize: MoonButtonSize.md,
        height: 40,
        width: double.infinity,
        semanticLabel: label,
        onTap: _enabled ? onPressed : null,
        label: labelWidget,
      ),
    };
  }

  Color _foregroundColor(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    if (!_enabled) {
      return variant == VerdantButtonVariant.primary
          ? colors.text
          : colors.textMuted;
    }

    return switch (variant) {
      VerdantButtonVariant.primary => colors.text,
      VerdantButtonVariant.secondary => colors.text,
      VerdantButtonVariant.ghost => colors.actionStrong,
    };
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.isBusy,
  });

  final String label;
  final IconData? icon;
  final Color foreground;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ButtonLeading(icon: icon, foreground: foreground, isBusy: isBusy),
          if (isBusy || icon != null) const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VerdantThemeTypography.of(
                context,
              ).buttonLabel.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonLeading extends StatelessWidget {
  const _ButtonLeading({
    required this.icon,
    required this.foreground,
    required this.isBusy,
  });

  final IconData? icon;
  final Color foreground;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return MoonCircularLoader(
        color: foreground,
        sizeValue: 14,
        strokeWidth: 2,
      );
    }

    if (icon == null) {
      return const SizedBox.shrink();
    }

    return Icon(icon, color: foreground, size: 16);
  }
}
