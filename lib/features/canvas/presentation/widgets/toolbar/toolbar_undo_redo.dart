import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/toolbar/toolbar_tool_selector.dart';

/// Undo / redo button pair that listens to an [InkCanvasController].
///
/// Each button is disabled when its action is unavailable (e.g. nothing to
/// undo). The widget rebuilds automatically when the controller notifies.
class ToolbarUndoRedo extends StatelessWidget {
  const ToolbarUndoRedo({
    required this.inkController,
    super.key,
  });

  /// The controller that manages undo/redo state and actions.
  final InkCanvasController inkController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: inkController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToolbarToolBtn(
              icon: Icons.undo_rounded,
              isEnabled: inkController.canUndo,
              onTap: inkController.canUndo ? inkController.undo : null,
            ),
            ToolbarToolBtn(
              icon: Icons.redo_rounded,
              isEnabled: inkController.canRedo,
              onTap: inkController.canRedo ? inkController.redo : null,
            ),
          ],
        );
      },
    );
  }
}
