import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box/text_box_config.dart';

/// A horizontal row of circular colour-preset chips for the text box widget.
///
/// Each chip represents one [TextBoxColor]. The currently active preset is
/// highlighted with a thicker primary-coloured border. When
/// [isInteractive] is `true` the user can tap a chip to select it;
/// otherwise the chips are displayed as read-only indicators.
class TextBoxColorPicker extends StatelessWidget {
  const TextBoxColorPicker({
    required this.selectedColor,
    required this.isInteractive,
    required this.onColorSelected,
    super.key,
  });

  /// The currently selected colour preset.
  final TextBoxColor selectedColor;

  /// Whether the user can tap to change the colour.
  final bool isInteractive;

  /// Called when the user taps a colour chip.
  final ValueChanged<TextBoxColor> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TextBoxColor.values.map((c) {
        final isSelected = c == selectedColor;
        return Tooltip(
          message: c.localizedLabel(context),
          child: GestureDetector(
            onTap: isInteractive ? () => onColorSelected(c) : null,
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
          ),
        );
      }).toList(),
    );
  }
}
