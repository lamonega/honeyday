import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/theme/app_colors.dart';

export 'package:honeyday/core/theme/app_colors.dart';

/// Provides application-wide Material 3 themes with a warm paper & honey aesthetic.
abstract final class HoneydayTheme {
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return base.copyWith(
      displayLarge: GoogleFonts.fraunces(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.fraunces(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.fraunces(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.fraunces(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.fraunces(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.fraunces(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Light Theme
  // ──────────────────────────────────────────────

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.honeyAmber,
      brightness: Brightness.light,
      primary: AppColors.honeyAmber,
      onPrimary: AppColors.paperSurface,
      primaryContainer: AppColors.honeyContainer,
      onPrimaryContainer: AppColors.honeyDark,
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
      textTheme: _buildTextTheme(baseSans, AppColors.inkPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paperLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColors.inkPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paperSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.paperBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperSurface,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paperLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.honeyContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.honeyAmber : AppColors.inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? AppColors.honeyAmber : AppColors.inkMuted,
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Dark Theme
  // ──────────────────────────────────────────────

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.honeyAmber,
      brightness: Brightness.dark,
      primary: AppColors.honeyAmberDark,
      onPrimary: AppColors.paperDark,
      primaryContainer: AppColors.honeyContainerDark,
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

    final baseSans = GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(),
    ).apply(
      bodyColor: AppColors.inkPrimaryDark,
      displayColor: AppColors.inkPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperDark,
      textTheme: _buildTextTheme(baseSans, AppColors.inkPrimaryDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: AppColors.inkPrimaryDark,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.paperBorderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.paperBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.paperBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.honeyAmberDark, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.paperBorderDark),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: AppColors.paperBorderDark),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paperDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.honeyContainerDark,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.honeyAmberDark : AppColors.inkMutedDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? AppColors.honeyAmberDark : AppColors.inkMutedDark,
          );
        }),
      ),
    );
  }
}
