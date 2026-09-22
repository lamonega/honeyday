import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';

/// Margin between color palette dots.
const double kToolbarPaletteDotMargin = 2;

/// Diameter of a single color palette dot.
const double kToolbarPaletteDotSize = 18;

/// A horizontal row of tappable color dots.
///
/// Displays every color in [InkToolState.defaultPalette] and highlights the
/// one matching [selectedColor]. Tapping a dot calls [onColorSelected].
class ToolbarColorPalette extends StatelessWidget {
  const ToolbarColorPalette({
    required this.selectedColor,
    required this.onColorSelected,
    super.key,
  });

  /// The currently active color.
  final Color selectedColor;

  /// Callback when a color dot is tapped.
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: InkToolState.defaultPalette.map((c) {
        final isSelected = selectedColor == c;
        return GestureDetector(
          onTap: () => onColorSelected(c),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: kToolbarPaletteDotMargin),
            width: kToolbarPaletteDotSize,
            height: kToolbarPaletteDotSize,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
