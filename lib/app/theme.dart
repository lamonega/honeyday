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
  static const Color paperCream = AppColors.paperCream;
  static const Color paperSurface = AppColors.paperSurface;

  /// Amber brand accent representing honey, used for primary interactive elements.
  static const Color honeyAmber = AppColors.honeyAmber;

  /// Light honey container fill for chips, selection cards, and badges.
  static const Color honeyContainer = AppColors.honeyContainer;
  static const Color honeyLight = AppColors.honeyLight;
  static const Color honeyDark = AppColors.honeyDark;

  /// Deep slate color emulating ink for high-contrast legible text.
  static const Color inkSlate = AppColors.inkSlate;
  static const Color inkPrimary = AppColors.inkPrimary;
  static const Color inkSecondary = AppColors.inkSecondary;
  static const Color inkMuted = AppColors.inkMuted;

  /// Subtle gray-stone border color for paper grids and element bounding boxes.
  static const Color paperBorder = AppColors.paperBorder;

  /// Destructive/error color for deletion and alerts.
  static const Color error = AppColors.error;
  static const Color errorContainer = AppColors.errorContainer;

  /// Light theme definition adhering to Material 3 guidelines.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.honeyAmber,
      primary: AppColors.honeyAmber,
      onPrimary: Colors.white,
      primaryContainer: AppColors.honeyContainer,
      onPrimaryContainer: AppColors.honeyDark,
      surface: AppColors.paperLight,
      onSurface: AppColors.inkPrimary,
      surfaceContainerHighest: const Color(0xFFF8FAFC),
      outline: AppColors.paperBorder,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: const Color(0xFF991B1B),
    );

    final baseSans = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.inkPrimary,
      displayColor: AppColors.inkPrimary,
    );

    final textTheme = baseSans.copyWith(
      displayLarge: GoogleFonts.fraunces(
        textStyle: baseSans.displayLarge,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.fraunces(
        textStyle: baseSans.displayMedium,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.fraunces(
        textStyle: baseSans.headlineLarge,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      headlineMedium: GoogleFonts.fraunces(
        textStyle: baseSans.headlineMedium,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
      headlineSmall: GoogleFonts.fraunces(
        textStyle: baseSans.headlineSmall,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
      titleLarge: GoogleFonts.fraunces(
        textStyle: baseSans.titleLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperLight,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paperLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColors.inkPrimary,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paperLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.paperBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paperLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: AppColors.paperBorder),
        ),
      ),
    );
  }
}
