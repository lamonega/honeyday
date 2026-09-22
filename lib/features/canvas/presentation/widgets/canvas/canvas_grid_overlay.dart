import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_painter.dart';

/// Renders magnetic snap-alignment guide lines over the canvas surface.
///
/// What: Draws vertical and horizontal guidelines that appear while
/// a modular widget is being dragged into alignment with page centres,
/// margins, or sibling element edges.
/// Why: Provides the visual feedback layer for the snapping system.
/// The overlay sits on top of all elements but below input consumers,
/// using [IgnorePointer] so it never intercepts touch events.
class CanvasGridOverlay extends StatelessWidget {
  /// Constructs a [CanvasGridOverlay].
  const CanvasGridOverlay({
    required this.guides,
    required this.guideColor,
    super.key,
  });

  /// The active snap guide lines to render.
  final List<SnapGuideLine> guides;

  /// Colour used for the guide strokes.
  final Color guideColor;

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: SnapGuideOverlayPainter(
            guides: guides,
            guideColor: guideColor,
          ),
        ),
      ),
    );
  }
}
