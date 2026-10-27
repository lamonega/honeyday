import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';

/// The ink input layer that sits above all canvas elements.
///
/// What: Wraps [InkCanvas] with visibility and pointer-blocking logic
/// so that ink strokes are only captured when the user is in writing mode
/// and strokes are enabled.
/// Why: Separates the mode-gating logic (edit vs writing) from the page
/// composition, keeping the page canvas focused on layout.
///
/// Layer position in the canvas stack:
/// 1. PageSurface          (background)
/// 2. TransformableBox[]   (elements)
/// 3. CanvasGridOverlay    (snap guides)
/// 4. CanvasGestureLayer   (ink input)  - this widget
class CanvasGestureLayer extends StatelessWidget {
  /// Constructs a [CanvasGestureLayer].
  const CanvasGestureLayer({
    required this.pageId,
    required this.activeTool,
    required this.activeColor,
    required this.activeStrokeWidth,
    required this.initialStrokes,
    required this.controller,
    required this.onStrokesChanged,
    required this.canvasMode,
    required this.strokesVisible,
    this.inputEnabled = true,
    super.key,
  });

  /// The page identifier forwarded to [InkCanvas].
  final String pageId;

  /// The currently active ink tool (pen, highlighter, eraser).
  final InkToolType activeTool;

  /// The currently selected ink colour.
  final Color activeColor;

  /// The stroke width for new ink strokes.
  final double activeStrokeWidth;

  /// Initial strokes to restore on mount.
  final List<InkStroke> initialStrokes;

  /// Controller for external undo/redo control.
  final InkCanvasController controller;

  /// Callback fired whenever the stroke list changes.
  final ValueChanged<List<InkStroke>> onStrokesChanged;

  /// The current canvas mode (edit, writing, reading).
  final CanvasMode canvasMode;

  /// Whether strokes should be visually rendered.
  final bool strokesVisible;

  /// Whether the active writing submode should capture pointer input.
  final bool inputEnabled;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring:
            canvasMode != CanvasMode.writing || !inputEnabled || !strokesVisible,
        child: Visibility(
          visible: strokesVisible,
          maintainState: true,
          child: InkCanvas(
            pageId: pageId,
            activeTool: activeTool,
            activeColor: activeColor,
            activeStrokeWidth: activeStrokeWidth,
            initialStrokes: initialStrokes,
            controller: controller,
            onStrokesChanged: onStrokesChanged,
            inputEnabled: canvasMode == CanvasMode.writing &&
                inputEnabled &&
                strokesVisible,
          ),
        ),
      ),
    );
  }
}
