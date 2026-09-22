import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';

/// Width of the slider widget.
const double kToolbarSliderWidth = 60;

/// Height of the slider widget.
const double kToolbarSliderHeight = 28;

/// Thickness of the slider track.
const double kToolbarSliderTrackHeight = 3;

/// Diameter of the slider thumb.
const double kToolbarSliderThumbSize = 14;

/// Horizontal offset to centre the thumb on the track position.
const double kToolbarSliderThumbOffset = 7;

/// Minimum stroke width for the pen tool.
const double kPenWidthMin = 1;

/// Maximum stroke width for the pen tool.
const double kPenWidthMax = 12;

/// Minimum stroke width for the highlighter tool.
const double kHighlighterWidthMin = 8;

/// Maximum stroke width for the highlighter tool.
const double kHighlighterWidthMax = 40;

/// A custom stroke-width slider that adapts its range to the active tool.
///
/// Dragging horizontally within the widget updates [strokeWidth] via
/// [onChanged]. The visible range is [kPenWidthMin]..[kPenWidthMax] for the
/// pen and [kHighlighterWidthMin]..[kHighlighterWidthMax] for the
/// highlighter.
class ToolbarStrokeWidthSlider extends StatelessWidget {
  const ToolbarStrokeWidthSlider({
    required this.strokeWidth,
    required this.tool,
    required this.onChanged,
    super.key,
  });

  /// Current stroke width value.
  final double strokeWidth;

  /// Active tool – determines the slider's min/max range.
  final InkToolType tool;

  /// Called when the user drags to a new value.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final min = tool == InkToolType.highlighter ? kHighlighterWidthMin : kPenWidthMin;
    final max = tool == InkToolType.highlighter ? kHighlighterWidthMax : kPenWidthMax;
    final clamped = strokeWidth.clamp(min, max);
    final ratio = (clamped - min) / (max - min);

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject()! as RenderBox;
        final localX = box.globalToLocal(details.globalPosition).dx;
        final barWidth = box.size.width;
        final newRatio = (localX / barWidth).clamp(0.0, 1.0);
        onChanged(min + (max - min) * newRatio);
      },
      child: SizedBox(
        width: kToolbarSliderWidth,
        height: kToolbarSliderHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Track
            Positioned(
              left: 0,
              right: 0,
              child: Container(
                height: kToolbarSliderTrackHeight,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Filled portion
            Positioned(
              left: 0,
              child: Container(
                width: kToolbarSliderWidth * ratio,
                height: kToolbarSliderTrackHeight,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: kToolbarSliderWidth * ratio - kToolbarSliderThumbOffset,
              child: Container(
                width: kToolbarSliderThumbSize,
                height: kToolbarSliderThumbSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
