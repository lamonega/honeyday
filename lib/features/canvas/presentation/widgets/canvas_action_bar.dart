import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

class CanvasActionBar extends StatelessWidget {
  const CanvasActionBar({
    required this.showColorPalette,
    required this.onTogglePalette,
    required this.currentColor,
    required this.onColorChanged,
    this.onAdaptToPage,
    this.onFitWidth,
    this.onCenter,
    this.onDuplicate,
    this.onDelete,
    super.key,
  });

  final bool showColorPalette;
  final VoidCallback onTogglePalette;
  final Color? currentColor;
  final void Function(Color fillColor, Color borderColor)? onColorChanged;
  final VoidCallback? onAdaptToPage;
  final VoidCallback? onFitWidth;
  final VoidCallback? onCenter;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showColorPalette)
          _PaletteRow(
            currentColor: currentColor,
            onColorChanged: onColorChanged,
          ),
        _buildActionBar(colorScheme),
      ],
    );
  }

  Widget _buildActionBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTogglePalette,
            child: Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  color: currentColor ?? colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  size: 14,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          Container(
            height: 16,
            width: 1,
            color: colorScheme.outline,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          if (onAdaptToPage != null)
            GestureDetector(
              onTap: onAdaptToPage,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.fit_screen_rounded,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          if (onFitWidth != null)
            GestureDetector(
              onTap: onFitWidth,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          if (onCenter != null)
            GestureDetector(
              onTap: onCenter,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.filter_center_focus_rounded,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          if (onDuplicate != null)
            GestureDetector(
              onTap: onDuplicate,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.content_copy_rounded,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.currentColor,
    required this.onColorChanged,
  });

  final Color? currentColor;
  final void Function(Color fillColor, Color borderColor)? onColorChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: kElementColorPresets.map((preset) {
            final isSelected = currentColor == preset.fillColor;
            return GestureDetector(
              onTap: () {
                onColorChanged?.call(
                  preset.fillColor,
                  preset.borderColor,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: preset.fillColor == Colors.transparent
                      ? colorScheme.surface
                      : preset.fillColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : preset.borderColor,
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
