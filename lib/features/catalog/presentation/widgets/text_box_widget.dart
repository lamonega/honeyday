import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/presentation/widgets/catalog_widget_mixin.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box/text_box_color_picker.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box/text_box_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box/text_box_toolbar.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// [AgendaWidgetDefinition] for the text-box widget.
///
/// Registers the widget metadata and delegates rendering to [TextBoxWidget].
class TextBoxDefinition extends AgendaWidgetDefinition {
  const TextBoxDefinition();

  @override
  String get id => 'text_box';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogTextboxName;

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

/// A rich-text sticky-note widget with configurable background colour
/// and font size.
///
/// The widget is composed of three extracted sub-components:
/// - [TextBoxColorPicker] – colour preset selector.
/// - [TextBoxToolbar] – font-size control.
/// - A text editing area that adapts to interactive / read-only modes.
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

  late CatalogConfigHelper<TextBoxConfig> _configHelper;

  TextBoxConfig get _config => _configHelper.config;

  @override
  void initState() {
    super.initState();
    _configHelper = CatalogConfigHelper<TextBoxConfig>(
      parseConfig: TextBoxConfig.fromJsonString,
      configToJson: (c) => c.toJsonString(),
      initialJson: widget.configJson,
    )..onConfigChanged = widget.onConfigChanged;
  }

  @override
  void didUpdateWidget(TextBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configHelper.onConfigChanged = widget.onConfigChanged;
    if (oldWidget.configJson != widget.configJson) {
      _configHelper.updateFromJson(widget.configJson);
    }
  }

  void _setColor(TextBoxColor newColor) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(color: newColor);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  void _cycleFontSize() {
    if (!widget.isInteractive) return;

    final currentIndex = _fontSizes.indexOf(_config.fontSize);
    final nextIndex = (currentIndex + 1) % _fontSizes.length;
    final nextSize = _fontSizes[nextIndex];

    final newConfig = _config.copyWith(fontSize: nextSize);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  void _updateText(String val) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(text: val);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTransparent = _config.color == TextBoxColor.transparent;
    final l10n = AppLocalizations.of(context);
    final isDefaultContent =
        _config.text.isEmpty || _config.text == l10n.catalogTextboxDefaultContent;
    final currentText =
        isDefaultContent ? l10n.catalogTextboxDefaultContent : _config.text;

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
                TextBoxColorPicker(
                  selectedColor: _config.color,
                  isInteractive: widget.isInteractive,
                  onColorSelected: _setColor,
                ),
                const Spacer(),
                TextBoxToolbar(
                  fontSize: _config.fontSize,
                  isInteractive: widget.isInteractive,
                  onCycleFontSize: _cycleFontSize,
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
                    initialValue: currentText,
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
                      hintText: l10n.catalogTextboxHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: _updateText,
                  )
                : SingleChildScrollView(
                    child: Text(
                      currentText,
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
