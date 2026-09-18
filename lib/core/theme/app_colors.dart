import 'package:flutter/material.dart';

/// Central design tokens and color palette for Honeyday.
abstract final class AppColors {
  // ──────────────────────────────────────────────
  // Light Theme
  // ──────────────────────────────────────────────

  /// Base paper background color replicating cream-colored notebook paper.
  static const Color paperLight = Color(0xFFFFFDF7);

  /// Pure white surface for cards and modular widgets.
  static const Color paperSurface = Color(0xFFFFFFFF);

  /// Amber brand accent representing honey, used for primary interactive elements.
  static const Color honeyAmber = Color(0xFFD97706);

  /// Light honey container fill for chips, selection cards, and badges.
  static const Color honeyContainer = Color(0xFFFEF3C7);

  /// Very light warm honey tint for subtle selection backgrounds.
  static const Color honeyLight = Color(0xFFFFFBEB);

  /// Deep honey brown for high-contrast legible text on top of honeyContainer.
  static const Color honeyDark = Color(0xFF92400E);

  /// Deep slate color emulating ink for high-contrast legible text.
  static const Color inkPrimary = Color(0xFF1E293B);

  /// Slate secondary color for subtitles, labels, and secondary UI text.
  static const Color inkSecondary = Color(0xFF475569);

  /// Muted slate color for placeholders, disabled controls, and minor icons.
  static const Color inkMuted = Color(0xFF94A3B8);

  /// Subtle gray-stone border color for paper grids and element bounding boxes.
  static const Color paperBorder = Color(0xFFE2E8F0);

  /// Destructive/error red for deletion and alerts.
  static const Color error = Color(0xFFEF4444);

  /// Light error red container fill for destructive action badges.
  static const Color errorContainer = Color(0xFFFEE2E2);

  /// Subtle cream border color for page edges and decorative borders.
  static const Color paperEdge = Color(0xFFFBF8EE);

  /// Elevated surface for subtle container backgrounds in light mode.
  static const Color surfaceContainerHighestLight = Color(0xFFF8FAFC);

  /// Error-on-container text in light mode.
  static const Color onErrorContainerLight = Color(0xFF991B1B);

  // ──────────────────────────────────────────────
  // Semantic colors (used across both themes)
  // ──────────────────────────────────────────────

  /// Green for income/positive values.
  static const Color incomeGreen = Color(0xFF16A34A);

  /// Red for expense/negative values.
  static const Color expenseRed = Color(0xFFDC2626);

  /// Light green background for income badges.
  static const Color incomeGreenLight = Color(0xFFDCFCE7);

  /// Light red background for expense badges.
  static const Color expenseRedLight = Color(0xFFFFE4E6);

  /// Dark green for income icons on light backgrounds.
  static const Color incomeGreenDark = Color(0xFF166534);

  /// Dark red for expense icons on light backgrounds.
  static const Color expenseRedDark = Color(0xFF991B1B);

  // ──────────────────────────────────────────────
  // Dark Theme
  // ──────────────────────────────────────────────

  /// Dark paper background — warm charcoal instead of pure black to avoid halation.
  static const Color paperDark = Color(0xFF1A1614);

  /// Dark surface for cards and panels.
  static const Color surfaceDark = Color(0xFF252019);

  /// Elevated surface for cards in dark mode.
  static const Color surfaceContainerDark = Color(0xFF302A20);

  /// Primary amber for dark mode — slightly brighter for contrast.
  static const Color honeyAmberDark = Color(0xFFFBBF24);

  /// Honey container for dark mode.
  static const Color honeyContainerDark = Color(0xFF3D2E0A);

  /// Honey light for dark mode selections.
  static const Color honeyLightDark = Color(0xFF2A2008);

  /// Honey dark text on dark honey container.
  static const Color honeyDarkOnDark = Color(0xFFFEF3C7);

  /// Primary text for dark mode — off-white.
  static const Color inkPrimaryDark = Color(0xFFF1F5F9);

  /// Secondary text for dark mode.
  static const Color inkSecondaryDark = Color(0xFF94A3B8);

  /// Muted text for dark mode.
  static const Color inkMutedDark = Color(0xFF64748B);

  /// Border color for dark mode.
  static const Color paperBorderDark = Color(0xFF3E362C);

  /// Error color for dark mode.
  static const Color errorDark = Color(0xFFFCA5A5);

  /// Error container for dark mode.
  static const Color errorContainerDark = Color(0xFF450A0A);
}
