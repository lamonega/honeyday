import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/snapping.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

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
                  onPanStart: (_) => _updateGlobalCenter(),
                  onPanUpdate: _handleRotationPanUpdate,
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
              _buildResizeHandle(
                left: _hMargin - _handleRadius,
                top: _topMargin - _handleRadius,
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                onPanUpdate: _handleResizeNW,
                colorScheme: colorScheme,
              ),
              _buildResizeHandle(
                left: _hMargin + widget.size.width - _handleRadius,
                top: _topMargin - _handleRadius,
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                onPanUpdate: _handleResizeNE,
                colorScheme: colorScheme,
              ),
              _buildResizeHandle(
                left: _hMargin - _handleRadius,
                top: _topMargin + widget.size.height - _handleRadius,
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                onPanUpdate: _handleResizeSW,
                colorScheme: colorScheme,
              ),
              _buildResizeHandle(
                left: _hMargin + widget.size.width - _handleRadius,
                top: _topMargin + widget.size.height - _handleRadius,
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                onPanUpdate: _handleResizeSE,
                colorScheme: colorScheme,
              ),
              Positioned(
                left: 0,
                right: 0,
                top: barTop,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showColorPalette)
                          _buildPaletteRow(colorScheme),
                        _buildActionBar(colorScheme),
                      ],
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

  Widget _buildPaletteRow(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: kElementColorPresets.map((preset) {
            final isSelected = widget.currentColor == preset.fillColor;
            return GestureDetector(
              onTap: () {
                widget.onColorChanged?.call(
                  preset.fillColor,
                  preset.borderColor,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: preset.fillColor == Colors.transparent
                      ? colorScheme.surface
                      : preset.fillColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : preset.borderColor,
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
                        size: 12,
                        color: colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Cambiar color',
              child: InkWell(
                onTap: () {
                  setState(() => _showColorPalette = !_showColorPalette);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: widget.currentColor ?? colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              height: 16,
              width: 1,
              color: colorScheme.outline,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
            if (widget.onAdaptToPage != null)
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, size: 18),
                tooltip: 'Adaptar a toda la página',
                visualDensity: VisualDensity.compact,
                color: colorScheme.onSurface,
                onPressed: widget.onAdaptToPage,
              ),
            if (widget.onFitWidth != null)
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                tooltip: 'Ajustar al ancho',
                visualDensity: VisualDensity.compact,
                color: colorScheme.onSurface,
                onPressed: widget.onFitWidth,
              ),
            if (widget.onCenter != null)
              IconButton(
                icon: const Icon(Icons.filter_center_focus_rounded, size: 18),
                tooltip: 'Centrar en la página',
                visualDensity: VisualDensity.compact,
                color: colorScheme.onSurface,
                onPressed: widget.onCenter,
              ),
            if (widget.onDuplicate != null)
              IconButton(
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                tooltip: 'Duplicar elemento',
                visualDensity: VisualDensity.compact,
                color: colorScheme.onSurface,
                onPressed: widget.onDuplicate,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle({
    required double left,
    required double top,
    required MouseCursor cursor,
    required GestureDragUpdateCallback onPanUpdate,
    required ColorScheme colorScheme,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanUpdate: onPanUpdate,
          child: Container(
            width: _handleRadius * 2,
            height: _handleRadius * 2,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBodyPanStart(DragStartDetails details) {
    _isSnapEnabled = !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed;
  }

  void _handleBodyPanUpdate(DragUpdateDetails details) {
    final rawCandidate = widget.position + details.delta;
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
    _lastSnapResult = null;
    widget.onSnapGuidesChanged?.call(const []);
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
