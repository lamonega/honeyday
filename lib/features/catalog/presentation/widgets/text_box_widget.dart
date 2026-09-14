import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

enum TextBoxColor {
  honey(Color(0xFFFEF3C7), 'Miel'),
  rose(Color(0xFFFFE4E6), 'Rosa'),
  sage(Color(0xFFDCFCE7), 'Salvia'),
  transparent(Colors.transparent, 'Transparente');

  TextBoxColor(this.color, this.label);

  final Color color;
  final String label;

  static TextBoxColor fromString(String? val) {
    return TextBoxColor.values.firstWhere(
      (e) => e.name == val?.toLowerCase(),
      orElse: () => TextBoxColor.honey,
    );
  }
}

@immutable
class TextBoxConfig {
  const TextBoxConfig({
    required this.text,
    required this.color,
    required this.fontSize,
  });

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
    } on Object catch (_) {}
    return TextBoxConfig.defaultConfig();
  }

  factory TextBoxConfig.defaultConfig() {
    return const TextBoxConfig(
      text: '¡Nota importante!\nEscribe aquí tus ideas o recordatorios.',
      color: TextBoxColor.honey,
      fontSize: 14,
    );
  }

  final String text;
  final TextBoxColor color;
  final double fontSize;

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

  String toJsonString() {
    return jsonEncode({
      'text': text,
      'color': color.name,
      'fontSize': fontSize,
    });
  }
}

class TextBoxDefinition extends AgendaWidgetDefinition {
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

class TextBoxWidget extends StatefulWidget {
  const TextBoxWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  final String elementId;
  final String configJson;
  final bool isInteractive;
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
    final colorScheme = Theme.of(context).colorScheme;
    final isTransparent = _config.color == TextBoxColor.transparent;

    return Container(
      decoration: BoxDecoration(
        color: _config.color.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTransparent
              ? colorScheme.outline.withValues(alpha: 0.7)
              : colorScheme.outline,
        ),
        boxShadow: isTransparent
            ? null
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isInteractive) ...[
            Row(
              children: [
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
                            ? colorScheme.surface
                            : c.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: c == TextBoxColor.transparent
                          ? Center(
                              child: Icon(
                                Icons.block_rounded,
                                size: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
                const Spacer(),
                InkWell(
                  onTap: _cycleFontSize,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_size_rounded,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_config.fontSize.toInt()}pt',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
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
              color: colorScheme.outline.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 6),
          ],
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
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Escribe tu nota aquí...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
