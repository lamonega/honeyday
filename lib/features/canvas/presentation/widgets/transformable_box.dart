import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_action_bar.dart';
import 'package:honeyday/features/canvas/presentation/widgets/resize_handles.dart';

typedef OnTransformChanged = void Function(
  Offset position,
  Size size,
  double rotation,
);

/// Interactive container wrapping modular widgets with Canva-like transforms.
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

class _TransformableBoxState extends State<TransformableBox> {
  static const double _hMargin = 40;
  static const double _topMargin = 48;
  static const double _bottomMargin = 76;
  static const double _handleRadius = 7;

  Offset? _globalCenter;
  Offset? _dragPosition;
  bool _showColorPalette = false;
  SnappingResult? _lastSnapResult;
  bool _isSnapEnabled = true;

  void _updateGlobalCenter() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _globalCenter = renderBox.localToGlobal(
        Offset(
          _hMargin + widget.size.width / 2,
          _topMargin + widget.size.height / 2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.canvasMode == CanvasMode.edit;
    final colorScheme = Theme.of(context).colorScheme;

    if (!isEdit) {
      return Positioned(
        left: widget.position.dx,
        top: widget.position.dy,
        width: widget.size.width,
        height: widget.size.height,
        child: Transform.rotate(angle: widget.rotation, child: widget.child),
      );
    }

    final pageHeight = widget.pageSize?.height ?? 1100;
    final isLarge = widget.size.height > (pageHeight * 0.75);
    final isNearBottom =
        (widget.position.dy + widget.size.height) > (pageHeight - 90);

    final double barTop;
    if (isLarge) {
      barTop = _topMargin + 12;
    } else if (isNearBottom) {
      barTop = _topMargin - 44;
    } else {
      barTop = _topMargin + widget.size.height + 10;
    }

    return Positioned(
      left: widget.position.dx - _hMargin,
      top: widget.position.dy - _topMargin,
      width: widget.size.width + _hMargin * 2,
      height: widget.size.height + _topMargin + _bottomMargin,
      child: Transform.rotate(
        angle: widget.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _hMargin,
              top: _topMargin,
              width: widget.size.width,
              height: widget.size.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onTap: widget.onTap,
                onPanStart: _handleBodyPanStart,
                onPanUpdate: _handleBodyPanUpdate,
                onPanEnd: _handleBodyPanEnd,
                onPanCancel: _handleBodyPanEnd,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.isSelected
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.child,
                  ),
                ),
              ),
            ),

            if (widget.isSelected) ...[
              Positioned(
                left: _hMargin + widget.size.width / 2 - 1,
                top: _topMargin - 20,
                width: 2,
                height: 20,
                child: Container(color: colorScheme.primary),
              ),
              Positioned(
                left: _hMargin + widget.size.width / 2 - 12,
                top: _topMargin - 36,
                width: 24,
                height: 24,
                child: GestureDetector(
                  onPanStart: (_) {
                    _updateGlobalCenter();
                    widget.onTransformStarted?.call();
                  },
                  onPanUpdate: _handleRotationPanUpdate,
                  onPanEnd: (_) => widget.onTransformEnded?.call(),
                  onPanCancel: () => widget.onTransformEnded?.call(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _hMargin + widget.size.width - 12,
                top: _topMargin - 30,
                width: 24,
                height: 24,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colorScheme.onError,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: widget.size.width + _hMargin * 2,
                height: widget.size.height + _topMargin + _bottomMargin,
                child: ResizeHandles(
                  hMargin: _hMargin,
                  topMargin: _topMargin,
                  size: widget.size,
                  handleRadius: _handleRadius,
                  onResizeNW: _handleResizeNW,
                  onResizeNE: _handleResizeNE,
                  onResizeSW: _handleResizeSW,
                  onResizeSE: _handleResizeSE,
                  onResizeStarted: widget.onTransformStarted,
                  onResizeEnded: widget.onTransformEnded,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: barTop,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: CanvasActionBar(
                      showColorPalette: _showColorPalette,
                      onTogglePalette: () {
                        setState(() => _showColorPalette = !_showColorPalette);
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

  void _handleBodyPanStart(DragStartDetails details) {
    _dragPosition = widget.position;
    _isSnapEnabled =
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed;
    widget.onTransformStarted?.call();
  }

  void _handleBodyPanUpdate(DragUpdateDetails details) {
    var delta = details.delta;
    if (widget.rotation != 0) {
      final cosTheta = math.cos(widget.rotation);
      final sinTheta = math.sin(widget.rotation);
      delta = Offset(
        delta.dx * cosTheta - delta.dy * sinTheta,
        delta.dx * sinTheta + delta.dy * cosTheta,
      );
    }

    _dragPosition = (_dragPosition ?? widget.position) + delta;
    final rawCandidate = _dragPosition!;

    if (widget.pageSize != null && _isSnapEnabled) {
      final snap = CanvasSnapping.calculateSnap(
        candidateRect: Rect.fromLTWH(
          rawCandidate.dx,
          rawCandidate.dy,
          widget.size.width,
          widget.size.height,
        ),
        pageSize: widget.pageSize!,
        siblingRects: widget.siblingRects,
        isCurrentlySnapped: _lastSnapResult?.guides.isNotEmpty == true,
      );
      _lastSnapResult = snap.guides.isNotEmpty ? snap : null;
      widget.onTransformChanged?.call(
        snap.snappedPosition,
        widget.size,
        widget.rotation,
      );
      widget.onSnapGuidesChanged?.call(snap.guides);
    } else {
      _lastSnapResult = null;
      widget.onTransformChanged?.call(
        rawCandidate,
        widget.size,
        widget.rotation,
      );
      widget.onSnapGuidesChanged?.call(const []);
    }
  }

  void _handleBodyPanEnd([dynamic _]) {
    _dragPosition = null;
    _lastSnapResult = null;
    widget.onSnapGuidesChanged?.call(const []);
    widget.onTransformEnded?.call();
  }

  void _handleRotationPanUpdate(DragUpdateDetails details) {
    if (_globalCenter == null) return;
    final dx = details.globalPosition.dx - _globalCenter!.dx;
    final dy = details.globalPosition.dy - _globalCenter!.dy;
    final angle = math.atan2(dy, dx) + (math.pi / 2);
    widget.onTransformChanged?.call(widget.position, widget.size, angle);
  }

  void _handleResizeSE(DragUpdateDetails details) {
    final newWidth = math.max(
      widget.minWidth,
      widget.size.width + details.delta.dx,
    );
    final newHeight = math.max(
      widget.minHeight,
      widget.size.height + details.delta.dy,
    );
    widget.onTransformChanged?.call(
      widget.position,
      Size(newWidth, newHeight),
      widget.rotation,
    );
  }

  void _handleResizeSW(DragUpdateDetails details) {
    final newWidth = math.max(
      widget.minWidth,
      widget.size.width - details.delta.dx,
    );
    final newHeight = math.max(
      widget.minHeight,
      widget.size.height + details.delta.dy,
    );
    final deltaX = widget.size.width - newWidth;
    widget.onTransformChanged?.call(
      widget.position + Offset(deltaX, 0),
      Size(newWidth, newHeight),
      widget.rotation,
    );
  }

  void _handleResizeNE(DragUpdateDetails details) {
    final newWidth = math.max(
      widget.minWidth,
      widget.size.width + details.delta.dx,
    );
    final newHeight = math.max(
      widget.minHeight,
      widget.size.height - details.delta.dy,
    );
    final deltaY = widget.size.height - newHeight;
    widget.onTransformChanged?.call(
      widget.position + Offset(0, deltaY),
      Size(newWidth, newHeight),
      widget.rotation,
    );
  }

  void _handleResizeNW(DragUpdateDetails details) {
    final newWidth = math.max(
      widget.minWidth,
      widget.size.width - details.delta.dx,
    );
    final newHeight = math.max(
      widget.minHeight,
      widget.size.height - details.delta.dy,
    );
    final deltaX = widget.size.width - newWidth;
    final deltaY = widget.size.height - newHeight;
    widget.onTransformChanged?.call(
      widget.position + Offset(deltaX, deltaY),
      Size(newWidth, newHeight),
      widget.rotation,
    );
  }
}
