import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';

class RailIconButton extends StatelessWidget {
  const RailIconButton({
    required this.icon,
    required this.tooltip,
    this.selected = false,
    this.onPressed,
    this.badgeLabel,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VerdantThemeColors.of(context);
    final foreground = selected ? colors.accentStrong : colors.textMuted;
    final background = selected ? colors.panelHover : colors.panelRaised;
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Material(
              color: background,
              shape: RoundedRectangleBorder(
                borderRadius: VerdantRadii.sharp,
                side: BorderSide(
                  color: selected ? colors.accent : colors.border,
                ),
              ),
              child: InkWell(
                onTap: onPressed,
                customBorder: const RoundedRectangleBorder(
                  borderRadius: VerdantRadii.sharp,
                ),
                hoverColor: colors.desktopHoverOverlay,
                splashColor: Colors.transparent,
                highlightColor: colors.desktopPressedOverlay,
                child: Center(
                  child: PhosphorIcon(icon, size: 22, color: foreground),
                ),
              ),
            ),
          ),
          if (badgeLabel != null)
            Positioned(
              right: -4,
              top: -4,
              child: _RailBadge(label: badgeLabel!),
            ),
        ],
      ),
    );
  }
}

class _RailBadge extends StatelessWidget {
  const _RailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFDC3F4D),
        borderRadius: BorderRadius.all(Radius.circular(9)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
