import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/snapping.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

/// Callback signature for transform updates on a modular canvas element.
typedef OnTransformChanged = void Function(
  Offset position,
  Size size,
  double rotation,
);

/// Interactive container wrapping Layer 1 & 2 modular widgets and Canva-like elements.
///
/// What: In [CanvasMode.edit], displays an amber selection border, 4 corner resize handles,
/// a rotation anchor handle, and quick action buttons (adapt to full page, fit width, center, duplicate, recolor).
/// In [CanvasMode.writing] and [CanvasMode.reading], simply renders the child element
/// at its configured position, dimensions, and rotation without interactive overlays.
/// Why: Provides Canva-like direct manipulation of agenda elements while guaranteeing
/// accidental shifts do not happen during note-taking or page flips.
class TransformableBox extends StatefulWidget {
  /// Constructs a [TransformableBox].
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

  /// The modular agenda widget to display within the transform box.
  final Widget child;

  /// Top-left position on the unscaled canvas coordinate system.
  final Offset position;

  /// Current width and height of the widget container.
  final Size size;

  /// Rotation angle around center in radians.
  final double rotation;

  /// Current active operational mode.
  final CanvasMode canvasMode;

  /// Whether this box is currently selected in edit mode.
  final bool isSelected;

  /// Dimensions of the parent page, used to compute center and margin snapping.
  final Size? pageSize;

  /// Bounding rectangles of sibling elements on the page for magnetic edge snapping.
  final List<Rect> siblingRects;

  /// Emits updated position, size, and rotation during gesture interaction.
  final OnTransformChanged? onTransformChanged;

  /// Emits active magnetic guidelines during drag for overlay rendering.
  final ValueChanged<List<SnapGuideLine>>? onSnapGuidesChanged;

  /// Triggered when the user taps the delete handle.
  final VoidCallback? onDelete;

  /// Triggered when the user taps this box to select it.
  final VoidCallback? onTap;

  /// Callback to adapt this element to cover the entire page.
  final VoidCallback? onAdaptToPage;

  /// Callback to stretch this element across the page width.
  final VoidCallback? onFitWidth;

  /// Callback to center this element on the page.
  final VoidCallback? onCenter;

  /// Callback to duplicate this element.
  final VoidCallback? onDuplicate;

  /// Callback to change the color attributes of this element.
  final void Function(Color fillColor, Color borderColor)? onColorChanged;

  /// Current fill color of the element for previewing in the toolbar.
  final Color? currentColor;

  /// Minimum allowable width when resizing.
  final double minWidth;

  /// Minimum allowable height when resizing.
  final double minHeight;

  @override
  State<TransformableBox> createState() => _TransformableBoxState();
}

class _TransformableBoxState extends State<TransformableBox> {
  static const double _hMargin = 40;
  static const double _topMargin = 48;
  static const double _bottomMargin = 76;
  static const double _handleRadius = 7;
  static const Color _accentColor = HoneydayTheme.honeyAmber;

  Offset? _globalCenter;
  bool _showColorPalette = false;

  /// Tracks the last snap result for dead zone logic.
  SnappingResult? _lastSnapResult;

  /// Whether snapping is currently enabled (toggled by Ctrl/Cmd).
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

    if (!isEdit) {
      // In reading or writing mode, render pure child positioned and rotated
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

    // In edit mode, allocate padding for handles and toolbar so hit testing never drops outside gestures
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
            // Body Content and Translation Drag Handle
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
                          ? _accentColor
                          : _accentColor.withValues(alpha: 0.5),
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
              // Stem connector for rotation handle
              Positioned(
                left: _hMargin + widget.size.width / 2 - 1,
                top: _topMargin - 20,
                width: 2,
                height: 20,
                child: Container(color: _accentColor),
              ),

              // Top Rotation Handle
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: _accentColor,
                    ),
                  ),
                ),
              ),

              // Top-Right Delete Action Button
              Positioned(
                left: _hMargin + widget.size.width - 12,
                top: _topMargin - 30,
                width: 24,
                height: 24,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: HoneydayTheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // NW Corner Resize Handle
              Positioned(
                left: _hMargin - _handleRadius,
                top: _topMargin - _handleRadius,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  onPanUpdate: _handleResizeNW,
                ),
              ),

              // NE Corner Resize Handle
              Positioned(
                left: _hMargin + widget.size.width - _handleRadius,
                top: _topMargin - _handleRadius,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  onPanUpdate: _handleResizeNE,
                ),
              ),

              // SW Corner Resize Handle
              Positioned(
                left: _hMargin - _handleRadius,
                top: _topMargin + widget.size.height - _handleRadius,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  onPanUpdate: _handleResizeSW,
                ),
              ),

              // SE Corner Resize Handle
              Positioned(
                left: _hMargin + widget.size.width - _handleRadius,
                top: _topMargin + widget.size.height - _handleRadius,
                child: _buildResizeHandle(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  onPanUpdate: _handleResizeSE,
                ),
              ),

              // Floating Canva-like Element Action Bar
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
                        if (_showColorPalette) _buildPaletteRow(),
                        _buildActionBar(),
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

  Widget _buildPaletteRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HoneydayTheme.paperBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
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
                widget.onColorChanged?.call(preset.fillColor, preset.borderColor);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: preset.fillColor == Colors.transparent
                      ? Colors.white
                      : preset.fillColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _accentColor : preset.borderColor,
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: HoneydayTheme.honeyDark)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HoneydayTheme.paperBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color picker swatch trigger
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
                      color: widget.currentColor ?? HoneydayTheme.honeyContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      size: 12,
                      color: HoneydayTheme.honeyDark,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 2),
            Container(
              height: 16,
              width: 1,
              color: const Color(0xFFCBD5E1),
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),

            // Adapt to full page button
            if (widget.onAdaptToPage != null)
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, size: 18),
                tooltip: 'Adaptar a toda la página',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF334155),
                onPressed: widget.onAdaptToPage,
              ),

            // Fit page width button
            if (widget.onFitWidth != null)
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                tooltip: 'Ajustar al ancho',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF334155),
                onPressed: widget.onFitWidth,
              ),

            // Center on page button
            if (widget.onCenter != null)
              IconButton(
                icon: const Icon(Icons.filter_center_focus_rounded, size: 18),
                tooltip: 'Centrar en la página',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF334155),
                onPressed: widget.onCenter,
              ),

            // Duplicate button
            if (widget.onDuplicate != null)
              IconButton(
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                tooltip: 'Duplicar elemento',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF334155),
                onPressed: widget.onDuplicate,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle({
    required MouseCursor cursor,
    required GestureDragUpdateCallback onPanUpdate,
  }) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: _handleRadius * 2,
          height: _handleRadius * 2,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _accentColor, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBodyPanStart(DragStartDetails details) {
    // Check Ctrl/Cmd at drag start to toggle snapping
    _isSnapEnabled = !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed;
  }

  void _handleBodyPanUpdate(DragUpdateDetails details) {
    // details.delta is already in local (canvas) coordinates via PointerEvent.localDelta
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
      // Snap disabled or no pageSize — free drag
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
    // Calculate angle in radians, +pi/2 because rotation handle sits directly above top center
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
