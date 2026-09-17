import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';

/// Minimal floating toolbar for ink tools.
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
      borderRadius: BorderRadius.circular(28),
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolBtn(
              icon: Icons.edit_outlined,
              isSelected: inkState.tool == InkToolType.pen,
              onTap: () => ref.read(inkToolProvider.notifier).selectTool(InkToolType.pen),
            ),
            _ToolBtn(
              icon: Icons.brush_outlined,
              isSelected: inkState.tool == InkToolType.highlighter,
              onTap: () => ref.read(inkToolProvider.notifier).selectTool(InkToolType.highlighter),
            ),
            _ToolBtn(
              icon: Icons.auto_fix_normal_outlined,
              isSelected: inkState.tool == InkToolType.eraser,
              onTap: () => ref.read(inkToolProvider.notifier).selectTool(InkToolType.eraser),
            ),

            if (showWidthSlider) ...[
              const _Divider(),
              _WidthSlider(
                strokeWidth: inkState.strokeWidth,
                tool: inkState.tool,
                onChanged: (w) => ref.read(inkToolProvider.notifier).setStrokeWidth(w),
              ),
            ],

            const _Divider(),

            // Color palette
            ...InkToolState.defaultPalette.map((c) {
              final sel = inkState.color == c;
              return GestureDetector(
                onTap: () => ref.read(inkToolProvider.notifier).setColor(c),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: sel
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : Border.all(
                            color: colorScheme.onSurface.withValues(alpha: 0.12),
                          ),
                  ),
                ),
              );
            }),

            const _Divider(),

            ListenableBuilder(
              listenable: inkController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolBtn(
                      icon: Icons.undo_rounded,
                      isEnabled: inkController.canUndo,
                      onTap: inkController.canUndo ? inkController.undo : null,
                    ),
                    _ToolBtn(
                      icon: Icons.redo_rounded,
                      isEnabled: inkController.canRedo,
                      onTap: inkController.canRedo ? inkController.redo : null,
                    ),
                  ],
                );
              },
            ),

            if (onCloseWriting != null) ...[
              const _Divider(),
              _ToolBtn(
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

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isEnabled = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer)
          : null,
      color: !isEnabled
          ? colorScheme.onSurface.withValues(alpha: 0.2)
          : isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.6),
      onPressed: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: 20,
        width: 1,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
      ),
    );
  }
}

class _WidthSlider extends StatelessWidget {
  const _WidthSlider({
    required this.strokeWidth,
    required this.tool,
    required this.onChanged,
  });

  final double strokeWidth;
  final InkToolType tool;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final min = tool == InkToolType.highlighter ? 8.0 : 1.0;
    final max = tool == InkToolType.highlighter ? 40.0 : 12.0;
    final clamped = strokeWidth.clamp(min, max);

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject()! as RenderBox;
        final localX = box.globalToLocal(details.globalPosition).dx;
        final barWidth = box.size.width;
        final ratio = (localX / barWidth).clamp(0.0, 1.0);
        final newValue = min + (max - min) * ratio;
        onChanged(newValue);
      },
      child: SizedBox(
        width: 60,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Track
            Positioned(
              left: 0,
              right: 0,
              child: Container(
                height: 3,
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
                width: 60 * ((clamped - min) / (max - min)),
                height: 3,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: 60 * ((clamped - min) / (max - min)) - 7,
              child: Container(
                width: 14,
                height: 14,
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
