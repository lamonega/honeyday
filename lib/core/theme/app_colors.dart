import 'package:flutter/material.dart';

/// Central design tokens and color palette for Honeyday.
///
/// What: Defines brand colors, container tones, ink text colors, and paper background shades.
/// Why: Honeyday's physical-agenda feel relies on creamy paper tones (#FFFDF7),
/// rich amber accents (#D97706), and crisp ink text (#1E293B) for high legibility.
abstract final class AppColors {
  /// Base paper background color replicating cream-colored notebook paper.
  static const Color paperLight = Color(0xFFFFFDF7);

  /// Amber brand accent representing honey, used for primary interactive elements.
  static const Color honeyAmber = Color(0xFFD97706);

  /// Light honey container fill for chips, selection cards, and badges.
  static const Color honeyContainer = Color(0xFFFEF3C7);

  /// Deep slate color emulating ink for high-contrast legible text.
  static const Color inkSlate = Color(0xFF1E293B);

  /// Subtle gray-stone border color for paper grids and element bounding boxes.
  static const Color paperBorder = Color(0xFFE2E8F0);
}
