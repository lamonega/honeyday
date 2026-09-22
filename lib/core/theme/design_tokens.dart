/// Centralized design tokens for consistent UI across the app.
abstract final class DesignTokens {
  // ── Border Radius ──
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusExtraLarge = 20;
  static const double borderRadiusBottomSheet = 24;

  // ── Spacing ──
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;

  // ── Animation ──
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 200);
  static const Duration animationSlow = Duration(milliseconds: 350);

  // ── Navigation ──
  static const double navTextFontSize = 12;
  static const double navIconSize = 24;

  // ── Input ──
  static const double inputPaddingHorizontal = 16;
  static const double inputPaddingVertical = 14;
}
