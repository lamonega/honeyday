import 'package:flutter/material.dart';

/// Central design tokens and color palette for Honeyday.
///
/// What: Defines brand colors, container tones, ink text colors, and paper background shades.
/// Why: Honeyday's physical-agenda feel relies on creamy paper tones (#FFFDF7),
/// rich amber accents (#D97706), and crisp ink text (#1E293B) for high legibility.
abstract final class AppColors {
  /// Base paper background color replicating cream-colored notebook paper.
  static const Color paperLight = Color(0xFFFFFDF7);
  static const Color paperCream = Color(0xFFFFFDF7);

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
  static const Color inkSlate = Color(0xFF1E293B);
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
}
