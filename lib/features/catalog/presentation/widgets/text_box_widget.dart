import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

/// Supported background color styles for [TextBoxWidget].
enum TextBoxColor {
  /// Warm honey pastel (`#FEF3C7`).
  honey(Color(0xFFFEF3C7), 'Miel'),

  /// Soft blush rose pastel (`#FFE4E6`).
  rose(Color(0xFFFFE4E6), 'Rosa'),

  /// Calming herbal sage pastel (`#DCFCE7`).
  sage(Color(0xFFDCFCE7), 'Salvia'),

  /// Transparent background showing underlying page grid.
  transparent(Colors.transparent, 'Transparente');

  TextBoxColor(this.color, this.label);

  /// Actual Flutter [Color] used for container rendering.
  final Color color;

  /// Human-readable Spanish name.
  final String label;

  /// Parses color from string token with fallback to [TextBoxColor.honey].
  static TextBoxColor fromString(String? val) {
    return TextBoxColor.values.firstWhere(
      (e) => e.name == val?.toLowerCase(),
      orElse: () => TextBoxColor.honey,
    );
  }
}

/// Parsed configuration model for [TextBoxWidget].
///
/// What: Holds text body, background color profile, and font size.
/// Why: Provides an immutable model for sticker notes and freeform text cards.
@immutable
class TextBoxConfig {
  /// Constructs a [TextBoxConfig].
  const TextBoxConfig({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  /// Decodes JSON string into a [TextBoxConfig].
  factory TextBoxConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return TextBoxConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final text = decoded['text']?.toString() ?? 'Nota...';
        final color = TextBoxColor.fromString(decoded['color']?.toString());
        final rawSize = decoded['fontSize'];
        final fontSize = (rawSize is num) ? rawSize.toDouble() : 15.0;

        return TextBoxConfig(text: text, color: color, fontSize: fontSize);
      }
    } on Object catch (_) {
      // Fallback on JSON parse failure
    }
    return TextBoxConfig.defaultConfig();
  }

  /// Factory defaults for newly created text notes.
  factory TextBoxConfig.defaultConfig() {
    return const TextBoxConfig(
      text: '¡Nota importante!\nEscribe aquí tus ideas o recordatorios.',
      color: TextBoxColor.honey,
      fontSize: 14,
    );
  }

  /// Text content.
  final String text;

  /// Background color choice.
  final TextBoxColor color;

  /// Font size in logical pixels.
  final double fontSize;

  /// Creates a copy with optionally updated fields.
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

  /// Serializes to JSON string.
  String toJsonString() {
    return jsonEncode({
      'text': text,
      'color': color.name,
      'fontSize': fontSize,
    });
  }
}

/// Catalog definition for [TextBoxWidget].
///
/// What: Implements [AgendaWidgetDefinition] for the custom note/sticker element.
/// Why: Enables registration in the catalog registry for canvas element insertion.
class TextBoxDefinition extends AgendaWidgetDefinition {
  /// Const constructor for definition registration.
  const TextBoxDefinition();

  @override
  String get id => 'text_box';

  @override
  String get name => 'Nota de Texto';

  @override
  IconData get icon => Icons.sticky_note_2_rounded;

  @override
  Size get defaultSize => const Size(220, 180);

  @override
  String get initialConfigJson => TextBoxConfig.defaultConfig().toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    return TextBoxWidget(
      elementId: elementId,
      configJson: configJson,
      isInteractive: isInteractive,
      onConfigChanged: onConfigChanged,
    );
  }
}

/// Presentation widget rendering a customizable post-it sticker note or text block.
///
/// What: Allows editing text body, switching pastel background colors, and adjusting font size.
/// Why: Gives users freedom to annotate agenda pages with sticky notes matching the Honeyday palette.
class TextBoxWidget extends StatefulWidget {
  /// Constructs a [TextBoxWidget].
  const TextBoxWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  /// Unique canvas element UUID.
  final String elementId;

  /// JSON payload storing text and styling.
  final String configJson;

  /// Interactivity flag.
  final bool isInteractive;

  /// Persistence callback.
  final ValueChanged<String> onConfigChanged;

  @override
  State<TextBoxWidget> createState() => _TextBoxWidgetState();
}

class _TextBoxWidgetState extends State<TextBoxWidget> {
  static const List<double> _fontSizes = [12.0, 14.0, 17.0, 21.0];

  late TextBoxConfig _config;

  @override
  void initState() {
    super.initState();
    _config = TextBoxConfig.fromJsonString(widget.configJson);
  }

  @override
  void didUpdateWidget(TextBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configJson != widget.configJson) {
      _config = TextBoxConfig.fromJsonString(widget.configJson);
    }
  }

  void _setColor(TextBoxColor newColor) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(color: newColor);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _cycleFontSize() {
    if (!widget.isInteractive) return;

    final currentIndex = _fontSizes.indexOf(_config.fontSize);
    final nextIndex = (currentIndex + 1) % _fontSizes.length;
    final nextSize = _fontSizes[nextIndex];

    final newConfig = _config.copyWith(fontSize: nextSize);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _updateText(String val) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(text: val);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  @override
  Widget build(BuildContext context) {
    final isTransparent = _config.color == TextBoxColor.transparent;

    return Container(
      decoration: BoxDecoration(
        color: _config.color.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTransparent
              ? HoneydayTheme.paperBorder.withValues(alpha: 0.7)
              : HoneydayTheme.paperBorder,
        ),
        boxShadow: isTransparent
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Formatting Toolbar (Visible only in interactive mode)
          if (widget.isInteractive) ...[
            Row(
              children: [
                // Color palette circles
                ...TextBoxColor.values.map((c) {
                  final isSelected = c == _config.color;
                  return GestureDetector(
                    onTap: () => _setColor(c),
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c.color == Colors.transparent
                            ? Colors.white
                            : c.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? HoneydayTheme.honeyAmber
                              : const Color(0xFFCBD5E1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: c == TextBoxColor.transparent
                          ? const Center(
                              child: Icon(
                                Icons.block_rounded,
                                size: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
                const Spacer(),
                // Font Size Stepper
                InkWell(
                  onTap: _cycleFontSize,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_size_rounded,
                          size: 13,
                          color: HoneydayTheme.inkSlate,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_config.fontSize.toInt()}pt',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: HoneydayTheme.inkSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(
              height: 1,
              color: HoneydayTheme.paperBorder.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 6),
          ],

          // Text Content Area
          Expanded(
            child: widget.isInteractive
                ? TextFormField(
                    initialValue: _config.text,
                    key: ValueKey('text_${widget.elementId}'),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontSize: _config.fontSize,
                      height: 1.5,
                      color: HoneydayTheme.inkSlate,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Escribe tu nota aquí...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    onChanged: _updateText,
                  )
                : SingleChildScrollView(
                    child: Text(
                      _config.text,
                      style: TextStyle(
                        fontSize: _config.fontSize,
                        height: 1.5,
                        color: HoneydayTheme.inkSlate,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
