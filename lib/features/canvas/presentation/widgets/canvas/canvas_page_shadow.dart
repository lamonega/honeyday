import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Page shadow constants (used only here)
// ──────────────────────────────────────────────

/// Border radius of page container shadow.
const double kPageBorderRadius = 16;

/// Shadow opacity for page container.
const double kPageShadowAlpha = 0.12;

/// Shadow blur radius for page container.
const double kPageShadowBlur = 16;

/// Shadow Y offset for page container.
const double kPageShadowOffsetY = 6;

/// A styled container that renders the planner page with a drop shadow.
///
/// What: Wraps [child] in a rounded, elevated container that visually
/// represents a paper page floating above the canvas background.
/// Why: Centralises the page-level decoration (shadow, border radius,
/// surface colour) so the page canvas stays focused on composition.
class CanvasPageShadow extends StatelessWidget {
  /// Constructs a [CanvasPageShadow].
  const CanvasPageShadow({
    required this.child,
    required this.pageSize,
    required this.colorScheme,
    super.key,
  });

  /// The child widget rendered inside the page container.
  final Widget child;

  /// The logical size of the page (used to size the container).
  final Size pageSize;

  /// The current theme [ColorScheme] for surface and shadow colours.
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        width: pageSize.width,
        height: pageSize.height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(kPageBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: kPageShadowAlpha),
              blurRadius: kPageShadowBlur,
              offset: const Offset(0, kPageShadowOffsetY),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kPageBorderRadius),
          child: child,
        ),
      ),
    );
  }
}
