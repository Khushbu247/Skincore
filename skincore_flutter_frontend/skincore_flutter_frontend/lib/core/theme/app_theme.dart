import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central theme definition. Screens should always pull colors/text styles
/// from `Theme.of(context)` rather than hardcoding `AppColors` directly, so
/// dark mode "just works" everywhere.
class AppTheme {
  AppTheme._();

  static const _radiusLg = 26.0;
  static const _radiusMd = 18.0;
  static const _radiusSm = 12.0;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.rose,
      brightness: brightness,
      primary: AppColors.purple,
      secondary: AppColors.rose,
      tertiary: AppColors.coral,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      error: AppColors.danger,
    );

    final displayFont = GoogleFonts.soraTextTheme();
    final bodyFont = GoogleFonts.interTextTheme();

    final textTheme = bodyFont.copyWith(
      displayLarge: displayFont.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium: displayFont.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: displayFont.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: displayFont.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: displayFont.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: displayFont.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: displayFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: isDark ? Colors.white.withOpacity(0.92) : AppColors.ink,
      displayColor: isDark ? Colors.white : AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
        titleTextStyle: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          side: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: displayFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          side: const BorderSide(color: AppColors.purple, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        selectedColor: AppColors.purple.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
          side: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight),
        ),
        labelStyle: bodyFont.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withOpacity(0.92),
        elevation: 0,
        indicatorColor: AppColors.purple.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          bodyFont.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const [
        AppRadii(lg: _radiusLg, md: _radiusMd, sm: _radiusSm),
      ],
    );
  }
}

/// Custom ThemeExtension so radii are themeable/dark-mode-aware too.
class AppRadii extends ThemeExtension<AppRadii> {
  final double lg;
  final double md;
  final double sm;

  const AppRadii({required this.lg, required this.md, required this.sm});

  @override
  AppRadii copyWith({double? lg, double? md, double? sm}) =>
      AppRadii(lg: lg ?? this.lg, md: md ?? this.md, sm: sm ?? this.sm);

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      lg: lerpDouble(lg, other.lg, t)!,
      md: lerpDouble(md, other.md, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
