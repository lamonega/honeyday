import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/toolbar/toolbar_color_palette.dart';
import 'package:honeyday/features/canvas/presentation/widgets/toolbar/toolbar_stroke_width_slider.dart';
import 'package:honeyday/features/canvas/presentation/widgets/toolbar/toolbar_tool_selector.dart';
import 'package:honeyday/features/canvas/presentation/widgets/toolbar/toolbar_undo_redo.dart';

/// Border radius of the floating ink toolbar.
const double kToolbarBorderRadius = 28;

/// Minimal floating toolbar for ink tools.
///
/// Composes the tool selector, colour palette, stroke-width slider and
/// undo / redo buttons into a single compact row.
class CanvasFloatingToolbar extends ConsumerWidget {
  const CanvasFloatingToolbar({
    required this.inkController,
    this.onCloseWriting,
    super.key,
  });

  final InkCanvasController inkController;
  final VoidCallback? onCloseWriting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inkState = ref.watch(inkToolProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final showWidthSlider = inkState.tool != InkToolType.eraser;

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(kToolbarBorderRadius),
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kToolbarBorderRadius),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToolbarToolSelector(
              selectedTool: inkState.tool,
              onToolSelected: (tool) =>
                  ref.read(inkToolProvider.notifier).selectTool(tool),
            ),

            if (showWidthSlider) ...[
              const ToolbarDivider(),
              ToolbarStrokeWidthSlider(
                strokeWidth: inkState.strokeWidth,
                tool: inkState.tool,
                onChanged: (w) =>
                    ref.read(inkToolProvider.notifier).setStrokeWidth(w),
              ),
            ],

            const ToolbarDivider(),

            ToolbarColorPalette(
              selectedColor: inkState.color,
              onColorSelected: (c) =>
                  ref.read(inkToolProvider.notifier).setColor(c),
            ),

            const ToolbarDivider(),

            ToolbarUndoRedo(inkController: inkController),

            if (onCloseWriting != null) ...[
              const ToolbarDivider(),
              ToolbarToolBtn(
                icon: Icons.check_rounded,
                onTap: onCloseWriting,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
