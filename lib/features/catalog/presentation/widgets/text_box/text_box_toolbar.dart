import 'package:flutter/material.dart';

/// A compact toolbar for the text box widget that exposes font-size controls.
///
/// Renders a single tappable chip displaying the current font size in points.
/// Tapping cycles through the predefined font sizes. The toolbar is
/// visually hidden when [isInteractive] is `false`.
class TextBoxToolbar extends StatelessWidget {
  const TextBoxToolbar({
    required this.fontSize,
    required this.isInteractive,
    required this.onCycleFontSize,
    super.key,
  });

  /// The current font size displayed on the toolbar chip.
  final double fontSize;

  /// Whether the user can interact with the toolbar.
  final bool isInteractive;

  /// Called when the user taps the font-size chip to cycle to the next size.
  final VoidCallback onCycleFontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isInteractive) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onCycleFontSize,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              '${fontSize.toInt()}pt',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
