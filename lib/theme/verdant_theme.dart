import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

abstract final class VerdantColors {
  static const background = Color(0xFF111315);
  static const panel = Color(0xFF15181B);
  static const panelRaised = Color(0xFF1B1F23);
  static const panelHover = Color(0xFF252B30);
  static const border = Color(0xFF343B42);
  static const borderStrong = Color(0xFF4A535C);
  static const text = Color(0xFFF2F4EF);
  static const textMuted = Color(0xFFA0AAA4);
  static const accent = Color(0xFF1EE3B6);
  static const accentStrong = Color(0xFF8EF4D3);
  static const action = Color(0xFF1EE3B6);
  static const actionStrong = Color(0xFF8EF4D3);
  static const actionSurface = Color(0xFF17D0A5);
  static const actionText = Color(0xFF02110D);
  static const actionHover = Color(0x33FFFFFF);
  static const actionMuted = Color(0x331EE3B6);
  static const desktopHoverOverlay = Color(0x201EE3B6);
  static const desktopPressedOverlay = Color(0x2E1EE3B6);
  static const name = Color(0xFFB9A8FF);
  static const orange = Color(0xFFE29A50);
}

abstract final class VerdantRadii {
  static const sharp = BorderRadius.all(Radius.circular(4));
}

abstract final class VerdantFontFamilies {
  static const primary = 'Segoe UI Variable Text';
  static const fallback = ['Segoe UI'];
}

abstract final class VerdantFontSizes {
  static const titleLarge = 21.0;
  static const titleMedium = 17.0;
  static const body = 15.0;
  static const bodySmall = 13.0;
  static const label = 14.0;
  static const settingsNavigation = 13.0;
  static const settingsEyebrow = 12.0;
  static const badge = 11.0;
}

abstract final class VerdantFontWeights {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const navigation = FontWeight.w700;
  static const selectedNavigation = FontWeight.w800;
  static const heavy = FontWeight.w800;
  static const black = FontWeight.w900;
}

enum VerdantThemeMode { dark, light }

final class VerdantThemeColors extends ThemeExtension<VerdantThemeColors> {
  const VerdantThemeColors({
    required this.background,
    required this.panel,
    required this.panelRaised,
    required this.panelHover,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentStrong,
    required this.action,
    required this.actionStrong,
    required this.actionSurface,
    required this.actionText,
    required this.actionHover,
    required this.actionMuted,
    required this.desktopHoverOverlay,
    required this.desktopPressedOverlay,
    required this.name,
    required this.orange,
  });

  static const dark = VerdantThemeColors(
    background: VerdantColors.background,
    panel: VerdantColors.panel,
    panelRaised: VerdantColors.panelRaised,
    panelHover: VerdantColors.panelHover,
    border: VerdantColors.border,
    borderStrong: VerdantColors.borderStrong,
    text: VerdantColors.text,
    textMuted: VerdantColors.textMuted,
    accent: VerdantColors.accent,
    accentStrong: VerdantColors.accentStrong,
    action: VerdantColors.action,
    actionStrong: VerdantColors.actionStrong,
    actionSurface: VerdantColors.actionSurface,
    actionText: VerdantColors.actionText,
    actionHover: VerdantColors.actionHover,
    actionMuted: VerdantColors.actionMuted,
    desktopHoverOverlay: VerdantColors.desktopHoverOverlay,
    desktopPressedOverlay: VerdantColors.desktopPressedOverlay,
    name: VerdantColors.name,
    orange: VerdantColors.orange,
  );

  static const light = VerdantThemeColors(
    background: Color(0xFFE9EEEB),
    panel: Color(0xFFF6F8F6),
    panelRaised: Color(0xFFFFFFFF),
    panelHover: Color(0xFFDDE8E3),
    border: Color(0xFFC8D3CE),
    borderStrong: Color(0xFFA8B7B1),
    text: Color(0xFF15211C),
    textMuted: Color(0xFF596A63),
    accent: Color(0xFF008F73),
    accentStrong: Color(0xFF006F5B),
    action: Color(0xFF13C89F),
    actionStrong: Color(0xFF007B65),
    actionSurface: Color(0xFF18D3A8),
    actionText: Color(0xFF041410),
    actionHover: Color(0x1A006F5B),
    actionMuted: Color(0x24008F73),
    desktopHoverOverlay: Color(0x17008F73),
    desktopPressedOverlay: Color(0x28008F73),
    name: Color(0xFF6B44BC),
    orange: Color(0xFFB66B1F),
  );

  static VerdantThemeColors forMode(VerdantThemeMode mode) {
    return switch (mode) {
      VerdantThemeMode.dark => dark,
      VerdantThemeMode.light => light,
    };
  }

  static VerdantThemeColors of(BuildContext context) {
    return Theme.of(context).extension<VerdantThemeColors>() ?? dark;
  }

  final Color background;
  final Color panel;
  final Color panelRaised;
  final Color panelHover;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentStrong;
  final Color action;
  final Color actionStrong;
  final Color actionSurface;
  final Color actionText;
  final Color actionHover;
  final Color actionMuted;
  final Color desktopHoverOverlay;
  final Color desktopPressedOverlay;
  final Color name;
  final Color orange;

  @override
  VerdantThemeColors copyWith() => this;

  @override
  VerdantThemeColors lerp(ThemeExtension<VerdantThemeColors>? other, double t) {
    if (other is! VerdantThemeColors) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

final class VerdantThemeTypography
    extends ThemeExtension<VerdantThemeTypography> {
  const VerdantThemeTypography({
    required this.workspaceTitle,
    required this.workspaceSubtitle,
    required this.workspaceBody,
    required this.workspaceCaption,
    required this.settingsTitle,
    required this.settingsSubtitle,
    required this.settingsSectionLabel,
    required this.settingsNavigationLabel,
    required this.settingsNavigationSelectedLabel,
    required this.buttonLabel,
    required this.badgeLabel,
  });

  factory VerdantThemeTypography.fromColors(VerdantThemeColors colors) {
    return VerdantThemeTypography(
      workspaceTitle: TextStyle(
        fontSize: VerdantFontSizes.titleLarge,
        fontWeight: VerdantFontWeights.bold,
        letterSpacing: 0,
        color: colors.text,
      ),
      workspaceSubtitle: TextStyle(
        fontSize: VerdantFontSizes.titleMedium,
        fontWeight: VerdantFontWeights.semibold,
        letterSpacing: 0,
        color: colors.text,
      ),
      workspaceBody: TextStyle(
        fontSize: VerdantFontSizes.body,
        fontWeight: VerdantFontWeights.regular,
        letterSpacing: 0,
        color: colors.text,
      ),
      workspaceCaption: TextStyle(
        fontSize: VerdantFontSizes.bodySmall,
        fontWeight: VerdantFontWeights.regular,
        letterSpacing: 0,
        color: colors.textMuted,
      ),
      settingsTitle: TextStyle(
        fontSize: VerdantFontSizes.titleMedium,
        fontWeight: VerdantFontWeights.bold,
        letterSpacing: 0,
        color: colors.text,
      ),
      settingsSubtitle: TextStyle(
        fontSize: VerdantFontSizes.bodySmall,
        fontWeight: VerdantFontWeights.regular,
        letterSpacing: 0,
        color: colors.textMuted,
      ),
      settingsSectionLabel: TextStyle(
        fontSize: VerdantFontSizes.settingsEyebrow,
        fontWeight: VerdantFontWeights.heavy,
        letterSpacing: 0.8,
        color: colors.textMuted,
      ),
      settingsNavigationLabel: TextStyle(
        fontSize: VerdantFontSizes.settingsNavigation,
        fontWeight: VerdantFontWeights.navigation,
        letterSpacing: 0,
        color: colors.textMuted,
      ),
      settingsNavigationSelectedLabel: TextStyle(
        fontSize: VerdantFontSizes.settingsNavigation,
        fontWeight: VerdantFontWeights.selectedNavigation,
        letterSpacing: 0,
        color: colors.accentStrong,
      ),
      buttonLabel: TextStyle(
        fontSize: VerdantFontSizes.label,
        fontWeight: VerdantFontWeights.heavy,
        letterSpacing: 0,
        color: colors.text,
      ),
      badgeLabel: TextStyle(
        fontSize: VerdantFontSizes.badge,
        fontWeight: VerdantFontWeights.black,
        letterSpacing: 0,
        color: colors.text,
      ),
    );
  }

  static VerdantThemeTypography of(BuildContext context) {
    return Theme.of(context).extension<VerdantThemeTypography>() ??
        VerdantThemeTypography.fromColors(VerdantThemeColors.of(context));
  }

  final TextStyle workspaceTitle;
  final TextStyle workspaceSubtitle;
  final TextStyle workspaceBody;
  final TextStyle workspaceCaption;
  final TextStyle settingsTitle;
  final TextStyle settingsSubtitle;
  final TextStyle settingsSectionLabel;
  final TextStyle settingsNavigationLabel;
  final TextStyle settingsNavigationSelectedLabel;
  final TextStyle buttonLabel;
  final TextStyle badgeLabel;

  @override
  VerdantThemeTypography copyWith() => this;

  @override
  VerdantThemeTypography lerp(
    ThemeExtension<VerdantThemeTypography>? other,
    double t,
  ) {
    if (other is! VerdantThemeTypography) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

ThemeData buildVerdantTheme({VerdantThemeMode mode = VerdantThemeMode.dark}) {
  final colors = VerdantThemeColors.forMode(mode);
  final typography = VerdantThemeTypography.fromColors(colors);
  final moonTokens = _buildVerdantMoonTokens(colors);
  final moonButtonTheme = MoonButtonTheme(tokens: moonTokens);

  final colorScheme = ColorScheme.fromSeed(
    brightness: mode == VerdantThemeMode.light
        ? Brightness.light
        : Brightness.dark,
    seedColor: colors.action,
    surface: colors.background,
    primary: colors.action,
    secondary: colors.name,
    onSurface: colors.text,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: VerdantFontFamilies.primary,
    fontFamilyFallback: VerdantFontFamilies.fallback,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: colors.desktopHoverOverlay,
    extensions: <ThemeExtension<dynamic>>[
      colors,
      typography,
      MoonTheme(tokens: moonTokens).copyWith(
        buttonTheme: moonButtonTheme.copyWith(
          colors: moonButtonTheme.colors.copyWith(
            borderColor: colors.borderStrong,
            textColor: colors.text,
            filledVariantBackgroundColor: colors.actionSurface,
            filledVariantTextColor: colors.actionText,
            textVariantFocusColor: colors.action,
            textVariantHoverColor: colors.actionMuted,
            textVariantTextColor: colors.actionStrong,
          ),
        ),
      ),
    ],
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: colors.actionText,
        backgroundColor: colors.action,
        disabledForegroundColor: colors.textMuted,
        disabledBackgroundColor: colors.panelRaised,
        overlayColor: colors.desktopPressedOverlay,
        shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.textMuted;
          }
          return colors.accentStrong;
        }),
        overlayColor: _desktopOverlayColor(colors),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return BorderSide(color: colors.action);
          }
          return BorderSide(color: colors.borderStrong);
        }),
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.accentStrong,
        overlayColor: colors.desktopPressedOverlay,
        shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        overlayColor: colors.desktopPressedOverlay,
        shape: const RoundedRectangleBorder(borderRadius: VerdantRadii.sharp),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 420),
      showDuration: const Duration(milliseconds: 1800),
      preferBelow: false,
      decoration: BoxDecoration(
        color: colors.panelRaised,
        border: Border.all(color: colors.borderStrong),
        borderRadius: VerdantRadii.sharp,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      textStyle: typography.workspaceCaption.copyWith(color: colors.text),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.panel,
      hintStyle: typography.workspaceBody.copyWith(color: colors.textMuted),
      labelStyle: typography.workspaceCaption,
      helperStyle: typography.workspaceCaption,
      errorStyle: typography.workspaceCaption.copyWith(
        color: const Color(0xFFD9455F),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: VerdantRadii.sharp,
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: VerdantRadii.sharp,
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: VerdantRadii.sharp,
        borderSide: BorderSide(color: colors.action),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: VerdantRadii.sharp,
        borderSide: BorderSide(color: colors.border.withValues(alpha: 0.72)),
      ),
      prefixIconColor: colors.textMuted,
      suffixIconColor: colors.textMuted,
    ),
    textTheme: TextTheme(
      titleLarge: typography.workspaceTitle,
      titleMedium: typography.workspaceSubtitle,
      bodyMedium: typography.workspaceBody,
      bodySmall: typography.workspaceCaption,
      labelLarge: typography.buttonLabel.copyWith(
        fontWeight: VerdantFontWeights.semibold,
      ),
    ),
  );
}

InputDecoration verdantBareInputDecoration(
  BuildContext context, {
  String? hintText,
  TextStyle? hintStyle,
  EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
}) {
  final colors = VerdantThemeColors.of(context);
  return InputDecoration(
    hintText: hintText,
    hintStyle:
        hintStyle ??
        Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
    isCollapsed: true,
    filled: false,
    fillColor: Colors.transparent,
    contentPadding: contentPadding,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}

WidgetStateProperty<Color?> _desktopOverlayColor(VerdantThemeColors colors) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return Colors.transparent;
    }
    if (states.contains(WidgetState.pressed)) {
      return colors.desktopPressedOverlay;
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return colors.desktopHoverOverlay;
    }
    return Colors.transparent;
  });
}

MoonTokens _buildVerdantMoonTokens(VerdantThemeColors colors) {
  const moonBorders = MoonBorders(
    interactiveXs: VerdantRadii.sharp,
    interactiveSm: VerdantRadii.sharp,
    interactiveMd: VerdantRadii.sharp,
    surfaceXs: VerdantRadii.sharp,
    surfaceSm: VerdantRadii.sharp,
    surfaceMd: BorderRadius.all(Radius.circular(4)),
    surfaceLg: BorderRadius.all(Radius.circular(6)),
    defaultBorderWidth: 1,
    activeBorderWidth: 1.5,
  );

  return MoonTokens.dark.copyWith(
    borders: moonBorders,
    colors: MoonColors.dark.copyWith(
      piccolo: colors.action,
      hit: colors.actionStrong,
      beerus: colors.border,
      goku: colors.background,
      gohan: colors.panelRaised,
      bulma: colors.text,
      trunks: colors.borderStrong,
      goten: colors.text,
      popo: colors.text,
      jiren: colors.actionMuted,
      heles: colors.actionHover,
      textPrimary: colors.text,
      textSecondary: colors.textMuted,
      iconPrimary: colors.text,
      iconSecondary: colors.textMuted,
    ),
  );
}
