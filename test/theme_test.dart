import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_design/moon_design.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  test('theme uses softened charcoal neutrals with sharp Verdant corners', () {
    final theme = buildVerdantTheme();

    expect(theme.scaffoldBackgroundColor, const Color(0xFF111315));
    expect(VerdantColors.panel, const Color(0xFF15181B));
    expect(VerdantColors.panelRaised, const Color(0xFF1B1F23));
    expect(VerdantColors.textMuted, const Color(0xFFA0AAA4));
    expect(VerdantRadii.sharp, BorderRadius.circular(4));
    expect(theme.colorScheme.primary, VerdantColors.action);
    expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w700);
    expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.titleLarge?.letterSpacing, 0);
    final moonTheme = theme.extension<MoonTheme>();
    expect(moonTheme, isNotNull);
    expect(moonTheme!.tokens.colors.piccolo, VerdantColors.action);
    expect(moonTheme.tokens.colors.hit, VerdantColors.actionStrong);
    expect(moonTheme.tokens.borders.interactiveSm, VerdantRadii.sharp);
    expect(
      moonTheme.buttonTheme.colors.filledVariantBackgroundColor,
      VerdantColors.actionSurface,
    );
    expect(
      moonTheme.buttonTheme.colors.filledVariantTextColor,
      VerdantColors.actionText,
    );
    expect(
      moonTheme.buttonTheme.colors.textVariantTextColor,
      VerdantColors.actionStrong,
    );
    expect(
      theme.filledButtonTheme.style?.shape?.resolve({}),
      isA<RoundedRectangleBorder>(),
    );
    expect(
      theme.outlinedButtonTheme.style?.side?.resolve({}),
      const BorderSide(color: VerdantColors.borderStrong),
    );
    expect(
      theme.outlinedButtonTheme.style?.side?.resolve({WidgetState.hovered}),
      const BorderSide(color: VerdantColors.action),
    );
  });
}
