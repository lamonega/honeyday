import 'dart:ui';

/// Converts a hex color string to a Flutter [Color].
///
/// Supports 6-character hex ('#D97706' or 'D97706') and 8-character hex ('FFD97706').
/// Returns [fallback] if the string is empty, null, or not a valid hex color.
Color hexToColor(String? hex, {Color fallback = const Color(0xFF1E293B)}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.isEmpty) return fallback;
  try {
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
  } on FormatException catch (_) {
    return fallback;
  }
  return fallback;
}

/// Darkens a [Color] by reducing its HSL lightness.
Color darken(Color color, [double amount = 0.15]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}
