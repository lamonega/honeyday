import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_toolbar.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

// ──────────────────────────────────────────────
// Action bar constants (used only here)
// ──────────────────────────────────────────────

/// Border radius of the floating action bar.
const double kActionBarBorderRadius = 24;

/// Size of the color palette toggle button.
const double kPaletteButtonSize = 28;

/// Icon size inside the palette toggle button.
const double kPaletteToggleIconSize = 14;

/// Height of divider between action bar buttons.
const double kActionBarDividerHeight = 16;

/// Icon size for action bar buttons.
const double kActionBarIconSize = 18;

/// Border radius of expanded palette row.
const double kPaletteRowBorderRadius = 20;

/// Diameter of individual palette color dots.
const double kPaletteDotSize = 22;

/// Check icon size inside selected palette dot.
const double kPaletteCheckIconSize = 12;

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
    final l10n = AppLocalizations.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showColorPalette)
          _PaletteRow(
            currentColor: currentColor,
            onColorChanged: onColorChanged,
          ),
        _buildActionBar(colorScheme, l10n, isSpanish: isSpanish),
      ],
    );
  }

  Widget _buildActionBar(
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required bool isSpanish,
  }) {
    final fillColor = currentColor ?? colorScheme.primaryContainer;
    final paletteIconColor = _contrastingIconColor(fillColor, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(kActionBarBorderRadius),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: horizontallyScrollableInkControls(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: l10n.canvasActionColor,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onTogglePalette,
                  child: Container(
                    width: kPaletteButtonSize,
                    height: kPaletteButtonSize,
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        size: kPaletteToggleIconSize,
                        color: paletteIconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: kActionBarDividerHeight,
              width: 1,
              color: colorScheme.outline,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
            if (onAdaptToPage != null)
              _ActionBarIconButton(
                icon: Icons.fit_screen_rounded,
                color: colorScheme.onSurface,
                tooltip: isSpanish ? 'Adaptar a la página' : 'Adapt to page',
                onTap: onAdaptToPage!,
              ),
            if (onFitWidth != null)
              _ActionBarIconButton(
                icon: Icons.swap_horiz_rounded,
                color: colorScheme.onSurface,
                tooltip: isSpanish ? 'Ajustar al ancho' : 'Fit width',
                onTap: onFitWidth!,
              ),
            if (onCenter != null)
              _ActionBarIconButton(
                icon: Icons.filter_center_focus_rounded,
                color: colorScheme.onSurface,
                tooltip: isSpanish ? 'Centrar' : 'Center',
                onTap: onCenter!,
              ),
            if (onDuplicate != null)
              _ActionBarIconButton(
                icon: Icons.content_copy_rounded,
                color: colorScheme.onSurface,
                tooltip: l10n.canvasActionDuplicate,
                onTap: onDuplicate!,
              ),
            if (onDelete != null)
              _ActionBarIconButton(
                icon: Icons.delete_outline_rounded,
                color: colorScheme.error,
                tooltip: l10n.commonDelete,
                onTap: onDelete!,
              ),
          ],
        ),
      ),
    );
  }
}

Color _contrastingIconColor(Color background, ColorScheme colorScheme) {
  if (background.a < 0.5) return colorScheme.onSurface;
  return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}

class _ActionBarIconButton extends StatelessWidget {
  const _ActionBarIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: kActionBarIconSize, color: color),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip, child: child);
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.currentColor, required this.onColorChanged});

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
        borderRadius: BorderRadius.circular(kPaletteRowBorderRadius),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: horizontallyScrollableInkControls(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: kElementColorPresets.map((preset) {
            final isSelected = currentColor == preset.fillColor;
            final swatchColor = preset.fillColor == Colors.transparent
                ? colorScheme.surface
                : preset.fillColor;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onColorChanged?.call(preset.fillColor, preset.borderColor);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: kPaletteDotSize,
                  height: kPaletteDotSize,
                  decoration: BoxDecoration(
                    color: swatchColor,
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
                          size: kPaletteCheckIconSize,
                          color: _contrastingIconColor(
                            swatchColor,
                            colorScheme,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
