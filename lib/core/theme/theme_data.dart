import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/core/theme/theme_component_themes.dart';
import 'package:honeyday/core/theme/theme_text_styles.dart';

/// Provides application-wide Material 3 themes with a warm paper & honey aesthetic.
///
/// The theme system is decomposed into:
/// - `app_colors.dart` — raw color constants (light, dark, semantic).
/// - `theme_text_styles.dart` — Fraunces + Plus Jakarta Sans text theme builder.
/// - `theme_component_themes.dart` — per-widget theme data (card, input, dialog, …).
/// - This file — the top-level [lightTheme] / [darkTheme] entry points that
///   compose all of the above into a complete [ThemeData].
abstract final class HoneydayTheme {
  /// Light variant of the Honeyday theme.
  ///
  /// [seed] defaults to [AppColors.honeyAmber] and drives the
  /// [ColorScheme] generation via [ColorScheme.fromSeed].
  static ThemeData lightTheme({Color seed = AppColors.honeyAmber}) {
    final container = containerFor(seed);
    final containerText = containerTextFor(seed);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: seed,
      onPrimary: AppColors.paperSurface,
      primaryContainer: container,
      onPrimaryContainer: containerText,
      surface: AppColors.paperLight,
      onSurface: AppColors.inkPrimary,
      surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
      outline: AppColors.paperBorder,
      error: AppColors.error,
      onError: AppColors.paperSurface,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainerLight,
    );

    final baseSans = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.inkPrimary,
      displayColor: AppColors.inkPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperLight,
      textTheme: buildHoneydayTextTheme(baseSans, AppColors.inkPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paperLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColors.inkPrimary,
        centerTitle: false,
      ),
      cardTheme: lightCardTheme(),
      inputDecorationTheme: lightInputTheme(seed),
      dialogTheme: lightDialogTheme(),
      bottomSheetTheme: lightBottomSheetTheme,
      navigationBarTheme: lightNavigationBarTheme(
        seed: seed,
        container: container,
      ),
    );
  }

  /// Dark variant of the Honeyday theme.
  ///
  /// [seed] defaults to [AppColors.honeyAmber] and drives the
  /// [ColorScheme] generation via [ColorScheme.fromSeed].
  static ThemeData darkTheme({Color seed = AppColors.honeyAmber}) {
    final container = Color.alphaBlend(
      seed.withValues(alpha: 0.15),
      AppColors.paperDark,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: seed,
      onPrimary: AppColors.paperDark,
      primaryContainer: container,
      onPrimaryContainer: AppColors.honeyDarkOnDark,
      surface: AppColors.paperDark,
      onSurface: AppColors.inkPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceContainerDark,
      outline: AppColors.paperBorderDark,
      error: AppColors.errorDark,
      onError: AppColors.paperDark,
      errorContainer: AppColors.errorContainerDark,
      onErrorContainer: AppColors.errorDark,
    );

    final baseSans =
        GoogleFonts.plusJakartaSansTextTheme(const TextTheme()).apply(
      bodyColor: AppColors.inkPrimaryDark,
      displayColor: AppColors.inkPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperDark,
      textTheme: buildHoneydayTextTheme(baseSans, AppColors.inkPrimaryDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColors.inkPrimaryDark,
        centerTitle: false,
      ),
      cardTheme: darkCardTheme(),
      inputDecorationTheme: darkInputTheme(seed),
      dialogTheme: darkDialogTheme(),
      bottomSheetTheme: darkBottomSheetTheme,
      navigationBarTheme: darkNavigationBarTheme(
        seed: seed,
        container: container,
      ),
    );
  }
}
