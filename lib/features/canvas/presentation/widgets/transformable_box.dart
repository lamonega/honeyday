import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_action_bar.dart';
import 'package:honeyday/features/canvas/presentation/widgets/resize_handles.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_constants.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_gestures.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_handles.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_state.dart';

/// Interactive container wrapping modular widgets with Canva-like transforms.
///
/// Delegates gesture logic to [TransformGestureMixin], selection chrome to
/// widgets in `transform_handles.dart`, resize corners to [ResizeHandles],
/// and the floating toolbar to [CanvasActionBar].
class TransformableBox extends StatefulWidget {
  const TransformableBox({
    required this.child,
    required this.position,
    required this.size,
    required this.canvasMode,
    super.key,
    this.rotation = 0,
    this.isSelected = true,
    this.pageSize,
    this.siblingRects = const [],
    this.onTransformChanged,
    this.onTransformStarted,
    this.onTransformEnded,
    this.onSnapGuidesChanged,
    this.onDelete,
    this.onTap,
    this.onAdaptToPage,
    this.onFitWidth,
    this.onCenter,
    this.onDuplicate,
    this.onColorChanged,
    this.currentColor,
    this.minWidth = 50,
    this.minHeight = 24,
  });

  final Widget child;
  final Offset position;
  final Size size;
  final double rotation;
  final CanvasMode canvasMode;
  final bool isSelected;
  final Size? pageSize;
  final List<Rect> siblingRects;
  final OnTransformChanged? onTransformChanged;
  final VoidCallback? onTransformStarted;
  final VoidCallback? onTransformEnded;
  final ValueChanged<List<SnapGuideLine>>? onSnapGuidesChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onAdaptToPage;
  final VoidCallback? onFitWidth;
  final VoidCallback? onCenter;
  final VoidCallback? onDuplicate;
  final void Function(Color fillColor, Color borderColor)? onColorChanged;
  final Color? currentColor;
  final double minWidth;
  final double minHeight;

  @override
  State<TransformableBox> createState() => _TransformableBoxState();
}

class _TransformableBoxState extends State<TransformableBox>
    with TransformGestureMixin {
  final _transformState = TransformState();

  // ── TransformGestureMixin overrides ──

  @override
  TransformState get transformState => _transformState;

  @override
  Offset get currentPosition => widget.position;

  @override
  Size get currentSize => widget.size;

  @override
  double get currentRotation => widget.rotation;

  @override
  double get minWidth => widget.minWidth;

  @override
  double get minHeight => widget.minHeight;

  @override
  Size? get pageSize => widget.pageSize;

  @override
  List<Rect> get siblingRects => widget.siblingRects;

  @override
  VoidCallback? get onTransformStarted => widget.onTransformStarted;

  @override
  OnTransformChanged? get onTransformChanged => widget.onTransformChanged;

  @override
  VoidCallback? get onTransformEnded => widget.onTransformEnded;

  @override
  ValueChanged<List<SnapGuideLine>>? get onSnapGuidesChanged =>
      widget.onSnapGuidesChanged;

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.canvasMode == CanvasMode.edit;

    if (!isEdit) {
      return Positioned(
        left: widget.position.dx,
        top: widget.position.dy,
        width: widget.size.width,
        height: widget.size.height,
        child: Transform.rotate(angle: widget.rotation, child: widget.child),
      );
    }

    final pageHeight = widget.pageSize?.height ?? kDefaultPageHeight;
    final isLarge =
        widget.size.height > (pageHeight * kLargeElementThreshold);
    final isNearBottom =
        (widget.position.dy + widget.size.height) >
        (pageHeight - kNearBottomThreshold);

    final double barTop;
    if (isLarge) {
      barTop = kTransformTopMargin + kBarTopOffsetLarge;
    } else if (isNearBottom) {
      barTop = kTransformTopMargin + kBarTopOffsetNearBottom;
    } else {
      barTop =
          kTransformTopMargin + widget.size.height + kBarTopOffsetDefault;
    }

    return Positioned(
      left: widget.position.dx - kTransformHMargin,
      top: widget.position.dy - kTransformTopMargin,
      width: widget.size.width + kTransformHMargin * 2,
      height: widget.size.height + kTransformTopMargin + kTransformBottomMargin,
      child: Transform.rotate(
        angle: widget.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Element body with drag gesture
            Positioned(
              left: kTransformHMargin,
              top: kTransformTopMargin,
              width: widget.size.width,
              height: widget.size.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onTap: widget.onTap,
                onPanStart: handleBodyPanStart,
                onPanUpdate: handleBodyPanUpdate,
                onPanEnd: handleBodyPanEnd,
                onPanCancel: handleBodyPanEnd,
                child: SelectionOutline(
                  isSelected: widget.isSelected,
                  child: widget.child,
                ),
              ),
            ),

            if (widget.isSelected) ...[
              // Stem + rotation handle
              Positioned(
                left: kTransformHMargin + widget.size.width / 2 - 1,
                top: kTransformTopMargin - kSelectionStemHeight,
                child: const SelectionStem(),
              ),
              Positioned(
                left: kTransformHMargin +
                    widget.size.width / 2 -
                    kHandleCircleSize / 2,
                top: kTransformTopMargin - kRotationHandleTopOffset,
                child: RotationHandle(
                  onPanStart: (_) {
                    updateGlobalCenter(context.findRenderObject() as RenderBox?);
                    widget.onTransformStarted?.call();
                  },
                  onPanUpdate: handleRotationPanUpdate,
                  onPanEnd: (_) => widget.onTransformEnded?.call(),
                  onPanCancel: () => widget.onTransformEnded?.call(),
                ),
              ),

              // Delete handle. Raised onto the same row as the rotation
              // handle: at the previous height it overlapped the NE resize
              // dot (which sits on the element's top-right corner and is
              // painted above it), swallowing taps meant for deletion.
              Positioned(
                left: kTransformHMargin +
                    widget.size.width -
                    kHandleCircleSize / 2,
                top: kTransformTopMargin - kRotationHandleTopOffset,
                child: DeleteHandle(onTap: widget.onDelete),
              ),

              // Corner resize handles
              Positioned(
                left: 0,
                top: 0,
                width: widget.size.width + kTransformHMargin * 2,
                height: widget.size.height +
                    kTransformTopMargin +
                    kTransformBottomMargin,
                child: ResizeHandles(
                  hMargin: kTransformHMargin,
                  topMargin: kTransformTopMargin,
                  size: widget.size,
                  handleRadius: kResizeHandleRadius,
                  onResizeNW: handleResizeNW,
                  onResizeNE: handleResizeNE,
                  onResizeSW: handleResizeSW,
                  onResizeSE: handleResizeSE,
                  onResizeStarted: widget.onTransformStarted,
                  onResizeEnded: widget.onTransformEnded,
                ),
              ),

              // Floating action bar
              Positioned(
                left: 0,
                right: 0,
                top: barTop,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: CanvasActionBar(
                      showColorPalette: _transformState.showColorPalette,
                      onTogglePalette: () {
                        setState(() =>
                            _transformState.showColorPalette =
                                !_transformState.showColorPalette);
                      },
                      currentColor: widget.currentColor,
                      onColorChanged: widget.onColorChanged,
                      onAdaptToPage: widget.onAdaptToPage,
                      onFitWidth: widget.onFitWidth,
                      onCenter: widget.onCenter,
                      onDuplicate: widget.onDuplicate,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
