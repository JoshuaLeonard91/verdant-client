import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../theme/verdant_theme.dart';

class RailActionModalShell extends StatelessWidget {
  const RailActionModalShell({
    required this.title,
    required this.icon,
    required this.child,
    this.maxWidth = 500,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: VerdantColors.panel,
            border: Border.all(color: VerdantColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PhosphorIcon(
                      icon,
                      size: 20,
                      color: VerdantColors.accentStrong,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      key: ValueKey(
                        '${title.toLowerCase().replaceAll(' ', '-')}-close',
                      ),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const PhosphorIcon(PhosphorIconsRegular.x),
                      color: VerdantColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration railActionInputDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: VerdantColors.background,
    labelStyle: const TextStyle(color: VerdantColors.textMuted),
    hintStyle: const TextStyle(color: VerdantColors.textMuted),
    enabledBorder: const OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: BorderSide(color: VerdantColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: BorderSide(color: VerdantColors.accent),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: BorderSide(color: Color(0xFFFF6575)),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: VerdantRadii.sharp,
      borderSide: BorderSide(color: Color(0xFFFF8A96)),
    ),
  );
}

class RailActionErrorText extends StatelessWidget {
  const RailActionErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF8A96)),
    );
  }
}
