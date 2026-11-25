import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Available background colour presets for the text box widget.
enum TextBoxColor {
  honey(Color(0xFFFEF3C7)),
  rose(Color(0xFFFFE4E6)),
  sage(Color(0xFFDCFCE7)),
  transparent(Colors.transparent);

  TextBoxColor(this.color);

  /// The [Color] value of this preset.
  final Color color;

  /// Returns a user-facing label for this colour, resolved via [BuildContext].
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TextBoxColor.honey:
        return l10n.catalogColorHoney;
      case TextBoxColor.rose:
        return l10n.catalogColorPink;
      case TextBoxColor.sage:
        return l10n.catalogColorSage;
      case TextBoxColor.transparent:
        return l10n.catalogColorTransparent;
    }
  }

  /// Finds the preset matching [value], if any.
  static TextBoxColor? tryFromColor(Color value) {
    for (final preset in TextBoxColor.values) {
      if (preset.color == value) return preset;
    }
    return null;
  }

  /// Parses a colour preset from its [name] string, falling back to [honey].
  static TextBoxColor fromString(String? val) {
    return TextBoxColor.values.firstWhere(
      (e) => e.name == val?.trim().toLowerCase(),
      orElse: () => TextBoxColor.honey,
    );
  }
}

/// Immutable configuration model for the text box widget.
///
/// Stores the plain-text content, background [TextBoxColor] preset (or an
/// optional [customColor] set from the canvas action bar), and font size.
/// Provides JSON serialisation for widget config persistence.
@immutable
class TextBoxConfig {
  const TextBoxConfig({
    required this.text,
    required this.color,
    required this.fontSize,
    this.customColor,
  });

  /// Deserialises a [TextBoxConfig] from a raw JSON string.
  ///
  /// Accepts both named [TextBoxColor] presets and hex colour strings written
  /// by `CanvasActionBar` via [ElementConfig.updateColorInJson]. Returns the
  /// default config when the input is empty or malformed.
  factory TextBoxConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return TextBoxConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final text = decoded['text']?.toString() ?? '';
        final rawColor = decoded['color']?.toString();
        final parsedHex = _tryParseHexColor(rawColor);
        final TextBoxColor color;
        final Color? customColor;
        if (parsedHex != null) {
          final matchedPreset = TextBoxColor.tryFromColor(parsedHex);
          if (matchedPreset != null) {
            color = matchedPreset;
            customColor = null;
          } else {
            color = TextBoxColor.honey;
            customColor = parsedHex;
          }
        } else {
          color = TextBoxColor.fromString(rawColor);
          customColor = null;
        }
        final rawSize = decoded['fontSize'];
        final fontSize = (rawSize is num) ? rawSize.toDouble() : 14.0;

        return TextBoxConfig(
          text: text,
          color: color,
          customColor: customColor,
          fontSize: fontSize.clamp(10.0, 24.0),
        );
      }
    } on Object catch (_) {}
    return TextBoxConfig.defaultConfig();
  }

  /// Creates the default configuration (empty text, honey background, 14 pt).
  factory TextBoxConfig.defaultConfig() {
    return const TextBoxConfig(
      text: '',
      color: TextBoxColor.honey,
      fontSize: 14,
    );
  }

  static Color? _tryParseHexColor(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('#')) return null;
    final cleaned = trimmed.substring(1);
    if (cleaned.length != 6 && cleaned.length != 8) return null;
    final parsed = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return parsed != null ? Color(parsed) : null;
  }

  /// The plain-text content of the widget.
  final String text;

  /// The background colour preset.
  final TextBoxColor color;

  /// Optional custom hex background colour applied via the canvas action bar.
  final Color? customColor;

  /// The font size in logical pixels (clamped between 10 and 24).
  final double fontSize;

  /// The resolved background [Color] to paint.
  Color get effectiveColor => customColor ?? color.color;

  /// Whether the resolved background is fully transparent.
  bool get isTransparent => effectiveColor == Colors.transparent;

  /// Returns a new [TextBoxConfig] with selectively overridden fields.
  ///
  /// Passing a [color] preset clears [customColor] unless [customColor] is also
  /// provided.
  TextBoxConfig copyWith({
    String? text,
    TextBoxColor? color,
    Color? customColor,
    bool clearCustomColor = false,
    double? fontSize,
  }) {
    return TextBoxConfig(
      text: text ?? this.text,
      color: color ?? this.color,
      customColor: clearCustomColor || color != null
          ? customColor
          : (customColor ?? this.customColor),
      fontSize: fontSize ?? this.fontSize,
    );
  }

  /// Serialises this configuration to a JSON string.
  String toJsonString() {
    return jsonEncode({
      'text': text,
      'color': customColor != null
          ? ElementConfig.colorToHex(customColor!)
          : color.name,
      'fontSize': fontSize,
    });
  }
}
