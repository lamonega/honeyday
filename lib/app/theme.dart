import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/theme/app_colors.dart';

export 'package:honeyday/core/theme/app_colors.dart';

/// Provides application-wide Material 3 themes with a warm paper & honey aesthetic.
///
/// What: Defines light and dark ColorSchemes, typography, and component styling.
/// Why: Honeyday's physical-agenda feel relies on creamy paper tones (#FFFDF7),
/// rich amber accents (#D97706), and crisp ink text (#1E293B) for high legibility.
abstract final class HoneydayTheme {
  /// Base paper background color replicating cream-colored notebook paper.
  static const Color paperLight = AppColors.paperLight;

  /// Amber brand accent representing honey, used for primary interactive elements.
  static const Color honeyAmber = AppColors.honeyAmber;

  /// Light honey container fill for chips, selection cards, and badges.
  static const Color honeyContainer = AppColors.honeyContainer;

  /// Deep slate color emulating ink for high-contrast legible text.
  static const Color inkSlate = AppColors.inkSlate;

  /// Subtle gray-stone border color for paper grids and element bounding boxes.
  static const Color paperBorder = AppColors.paperBorder;

  /// Light theme definition adhering to Material 3 guidelines.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.honeyAmber,
      primary: AppColors.honeyAmber,
      onPrimary: Colors.white,
      primaryContainer: AppColors.honeyContainer,
      onPrimaryContainer: const Color(0xFF78350F),
      surface: AppColors.paperLight,
      onSurface: AppColors.inkSlate,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      outline: AppColors.paperBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperLight,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: AppColors.inkSlate,
        displayColor: AppColors.inkSlate,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paperLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColors.inkSlate,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.paperBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.paperBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.paperBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.honeyAmber, width: 2),
        ),
      ),
    );
  }
}
