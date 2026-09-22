import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/core/theme/design_tokens.dart';

/// Returns a semi-transparent container color derived from [accent] blended
/// onto [AppColors.paperSurface].
Color containerFor(Color accent) =>
    Color.alphaBlend(accent.withValues(alpha: 0.12), AppColors.paperSurface);

/// Returns high-contrast text color suitable for use on top of [containerFor].
Color containerTextFor(Color accent) =>
    HSLColor.fromColor(accent).withLightness(0.25).toColor();

/// Card theme for the light variant.
CardThemeData lightCardTheme() => CardThemeData(
      color: AppColors.paperSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLarge),
        side: const BorderSide(color: AppColors.paperBorder),
      ),
    );

/// Card theme for the dark variant.
CardThemeData darkCardTheme() => CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLarge),
        side: const BorderSide(color: AppColors.paperBorderDark),
      ),
    );

/// Input decoration theme for the light variant.
InputDecorationTheme lightInputTheme(Color seed) => InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paperSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.inputPaddingHorizontal,
        vertical: DesignTokens.inputPaddingVertical,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        borderSide: const BorderSide(color: AppColors.paperBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        borderSide: const BorderSide(color: AppColors.paperBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        borderSide: BorderSide(color: seed, width: 2),
      ),
    );

/// Input decoration theme for the dark variant.
InputDecorationTheme darkInputTheme(Color seed) => InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.inputPaddingHorizontal,
        vertical: DesignTokens.inputPaddingVertical,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        borderSide: const BorderSide(color: AppColors.paperBorderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        borderSide: const BorderSide(color: AppColors.paperBorderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        borderSide: BorderSide(color: seed, width: 2),
      ),
    );

/// Dialog theme for the light variant.
DialogThemeData lightDialogTheme() => DialogThemeData(
      backgroundColor: AppColors.paperLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
        side: const BorderSide(color: AppColors.paperBorder),
      ),
    );

/// Dialog theme for the dark variant.
DialogThemeData darkDialogTheme() => DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(DesignTokens.borderRadiusExtraLarge),
        side: const BorderSide(color: AppColors.paperBorderDark),
      ),
    );

/// Bottom sheet theme for the light variant.
const BottomSheetThemeData lightBottomSheetTheme = BottomSheetThemeData(
  backgroundColor: AppColors.paperLight,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(DesignTokens.borderRadiusBottomSheet),
    ),
    side: BorderSide(color: AppColors.paperBorder),
  ),
);

/// Bottom sheet theme for the dark variant.
const BottomSheetThemeData darkBottomSheetTheme = BottomSheetThemeData(
  backgroundColor: AppColors.surfaceDark,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(DesignTokens.borderRadiusBottomSheet),
    ),
    side: BorderSide(color: AppColors.paperBorderDark),
  ),
);

/// Navigation bar theme for the light variant.
NavigationBarThemeData lightNavigationBarTheme({
  required Color seed,
  required Color container,
}) =>
    NavigationBarThemeData(
      backgroundColor: AppColors.paperLight,
      surfaceTintColor: Colors.transparent,
      indicatorColor: container,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: DesignTokens.navTextFontSize,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? seed : AppColors.inkMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: DesignTokens.navIconSize,
          color: isSelected ? seed : AppColors.inkMuted,
        );
      }),
    );

/// Navigation bar theme for the dark variant.
NavigationBarThemeData darkNavigationBarTheme({
  required Color seed,
  required Color container,
}) =>
    NavigationBarThemeData(
      backgroundColor: AppColors.paperDark,
      surfaceTintColor: Colors.transparent,
      indicatorColor: container,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: DesignTokens.navTextFontSize,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? seed : AppColors.inkMutedDark,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: DesignTokens.navIconSize,
          color: isSelected ? seed : AppColors.inkMutedDark,
        );
      }),
    );
