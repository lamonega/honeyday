import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyday/core/theme/design_tokens.dart';
import 'package:honeyday/core/utils/color_utils.dart';

/// A palette of cover color swatches for selecting an agenda cover color.
///
/// Displays a [Wrap] of circular color tiles. The currently selected swatch
/// shows a check icon and a border highlight. Tapping a swatch provides
/// haptic feedback and invokes [onColorSelected] with the hex string.
class AgendaCoverPicker extends StatelessWidget {
  /// Constructs an [AgendaCoverPicker].
  const AgendaCoverPicker({
    super.key,
    required this.colors,
    required this.selectedCover,
    required this.onColorSelected,
  });

  /// Hex color strings for each swatch in the palette.
  final List<String> colors;

  /// The hex string of the currently selected cover color.
  final String selectedCover;

  /// Called with the hex string when the user taps a color swatch.
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((hex) {
        final isSelected = selectedCover == hex;
        final color = hexToColor(hex);
        return GestureDetector(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            onColorSelected(hex);
          },
          child: AnimatedContainer(
            duration: DesignTokens.animationNormal,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: isSelected ? 2.5 : 0,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
