import 'dart:convert';

import 'package:flutter/material.dart';
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

  /// Parses a colour preset from its [name] string, falling back to [honey].
  static TextBoxColor fromString(String? val) {
    return TextBoxColor.values.firstWhere(
      (e) => e.name == val?.toLowerCase(),
      orElse: () => TextBoxColor.honey,
    );
  }
}

/// Immutable configuration model for the text box widget.
///
/// Stores the plain-text content, background [TextBoxColor] preset, and
/// font size. Provides JSON serialisation for widget config persistence.
@immutable
class TextBoxConfig {
  const TextBoxConfig({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  /// Deserialises a [TextBoxConfig] from a raw JSON string.
  ///
  /// Returns the default config when the input is empty or malformed.
  factory TextBoxConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return TextBoxConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final text = decoded['text']?.toString() ?? '';
        final color = TextBoxColor.fromString(decoded['color']?.toString());
        final rawSize = decoded['fontSize'];
        final fontSize = (rawSize is num) ? rawSize.toDouble() : 14.0;

        return TextBoxConfig(
          text: text,
          color: color,
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

  /// The plain-text content of the widget.
  final String text;

  /// The background colour preset.
  final TextBoxColor color;

  /// The font size in logical pixels (clamped between 10 and 24).
  final double fontSize;

  /// Returns a new [TextBoxConfig] with selectively overridden fields.
  TextBoxConfig copyWith({
    String? text,
    TextBoxColor? color,
    double? fontSize,
  }) {
    return TextBoxConfig(
      text: text ?? this.text,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  /// Serialises this configuration to a JSON string.
  String toJsonString() {
    return jsonEncode({
      'text': text,
      'color': color.name,
      'fontSize': fontSize,
    });
  }
}
