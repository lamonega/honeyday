import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/core/utils/color_utils.dart';

/// Predefined harmonious color palette for agenda elements (pastel and accent colors).
class ElementColorPreset {
  /// Constructs an [ElementColorPreset].
  const ElementColorPreset({
    required this.name,
    required this.fillColor,
    required this.borderColor,
  });

  /// Name of the color preset.
  final String name;

  /// Background or fill color.
  final Color fillColor;

  /// Perimeter or outline border color.
  final Color borderColor;

  /// Hex representation of [fillColor].
  String get fillHex => ElementConfig.colorToHex(fillColor);

  /// Hex representation of [borderColor].
  String get borderHex => ElementConfig.colorToHex(borderColor);
}

/// 10 aesthetic color presets matching digital planner designs.
const List<ElementColorPreset> kElementColorPresets = [
  ElementColorPreset(
    name: 'Ámbar Miel',
    fillColor: Color(0xFFFEF3C7), // Amber 100
    borderColor: Color(0xFFD97706), // Amber 600
  ),
  ElementColorPreset(
    name: 'Rosa Pastel',
    fillColor: Color(0xFFFFE4E6), // Rose 100
    borderColor: Color(0xFFE11D48), // Rose 600
  ),
  ElementColorPreset(
    name: 'Verde Salvia',
    fillColor: Color(0xFFD1FAE5), // Emerald 100
    borderColor: Color(0xFF059669), // Emerald 600
  ),
  ElementColorPreset(
    name: 'Lavanda',
    fillColor: Color(0xFFEDE9FE), // Violet 100
    borderColor: Color(0xFF7C3AED), // Violet 600
  ),
  ElementColorPreset(
    name: 'Azul Cielo',
    fillColor: Color(0xFFE0F2FE), // Sky 100
    borderColor: Color(0xFF0284C7), // Sky 600
  ),
  ElementColorPreset(
    name: 'Melocotón',
    fillColor: Color(0xFFFFEDD5), // Orange 100
    borderColor: Color(0xFFEA580C), // Orange 600
  ),
  ElementColorPreset(
    name: 'Blanco Puro',
    fillColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFCBD5E1), // Slate 300
  ),
  ElementColorPreset(
    name: 'Crema Papel',
    fillColor: Color(0xFFFFFDF7),
    borderColor: Color(0xFFE2E8F0),
  ),
  ElementColorPreset(
    name: 'Pizarra',
    fillColor: Color(0xFFF1F5F9), // Slate 100
    borderColor: Color(0xFF475569), // Slate 600
  ),
  ElementColorPreset(
    name: 'Transparente',
    fillColor: Colors.transparent,
    borderColor: Color(0xFF64748B),
  ),
];

/// Configuration model serializing visual properties (fill, border, opacity) of canvas elements.
@immutable
class ElementConfig {
  const ElementConfig({
    this.colorHex = '#FEF3C7',
    this.borderColorHex = '#D97706',
    this.borderWidth = 1.5,
    this.opacity = 1.0,
    this.cornerRadius = 12.0,
    this.customProps = const {},
  });

  factory ElementConfig.fromJsonString(String jsonStr) {
    if (jsonStr.isEmpty || jsonStr == '{}') {
      return const ElementConfig();
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ElementConfig(
        colorHex: map['color'] as String? ?? '#FEF3C7',
        borderColorHex: map['borderColor'] as String? ?? '#D97706',
        borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 1.5,
        opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
        cornerRadius: (map['cornerRadius'] as num?)?.toDouble() ?? 12.0,
        customProps: map,
      );
    } on Exception catch (_) {
      return const ElementConfig();
    }
  }

  /// Fill color in hex format (e.g. '#FEF3C7' or 'transparent').
  final String colorHex;

  /// Border/outline color in hex format (e.g. '#D97706').
  final String borderColorHex;

  /// Border line width in pixels.
  final double borderWidth;

  /// Overall element opacity (0.0 to 1.0).
  final double opacity;

  /// Corner radius for box and card elements.
  final double cornerRadius;

  /// Additional widget-specific static configuration.
  final Map<String, dynamic> customProps;

  /// Resolves [colorHex] into a Flutter [Color].
  Color get fillColor =>
      _parseColor(colorHex, defaultColor: const Color(0xFFFEF3C7));

  /// Resolves [borderColorHex] into a Flutter [Color].
  Color get borderColor =>
      _parseColor(borderColorHex, defaultColor: const Color(0xFFD97706));

  /// Parses a hex color string into a [Color].
  static Color _parseColor(String? hex, {required Color defaultColor}) {
    if (hex == null || hex.isEmpty) return defaultColor;
    if (hex == 'transparent') return Colors.transparent;
    return hexToColor(hex, fallback: defaultColor);
  }

  /// Converts a [Color] to a hex string representation.
  static String colorToHex(Color color) {
    if (color == Colors.transparent) return 'transparent';
    return '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Serializes this config into a JSON string.
  String toJsonString() {
    final map = Map<String, dynamic>.from(customProps);
    map['color'] = colorHex;
    map['borderColor'] = borderColorHex;
    map['borderWidth'] = borderWidth;
    map['opacity'] = opacity;
    map['cornerRadius'] = cornerRadius;
    return jsonEncode(map);
  }

  /// Creates a copy with specified fields replaced.
  ElementConfig copyWith({
    String? colorHex,
    String? borderColorHex,
    double? borderWidth,
    double? opacity,
    double? cornerRadius,
    Map<String, dynamic>? customProps,
  }) {
    return ElementConfig(
      colorHex: colorHex ?? this.colorHex,
      borderColorHex: borderColorHex ?? this.borderColorHex,
      borderWidth: borderWidth ?? this.borderWidth,
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      customProps: customProps ?? this.customProps,
    );
  }

  /// Updates the color attributes within an existing raw JSON string.
  static String updateColorInJson(
    String jsonStr, {
    required Color fillColor,
    Color? borderColor,
  }) {
    final current = ElementConfig.fromJsonString(jsonStr);
    final updated = current.copyWith(
      colorHex: colorToHex(fillColor),
      borderColorHex: borderColor != null ? colorToHex(borderColor) : null,
    );
    return updated.toJsonString();
  }
}
