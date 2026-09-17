import 'package:flutter/material.dart';

class ResizeHandles extends StatelessWidget {
  const ResizeHandles({
    required this.hMargin,
    required this.topMargin,
    required this.size,
    required this.handleRadius,
    required this.onResizeNW,
    required this.onResizeNE,
    required this.onResizeSW,
    required this.onResizeSE,
    this.onResizeStarted,
    this.onResizeEnded,
    super.key,
  });

  final double hMargin;
  final double topMargin;
  final Size size;
  final double handleRadius;
  final GestureDragUpdateCallback onResizeNW;
  final GestureDragUpdateCallback onResizeNE;
  final GestureDragUpdateCallback onResizeSW;
  final GestureDragUpdateCallback onResizeSE;
  final VoidCallback? onResizeStarted;
  final VoidCallback? onResizeEnded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildHandle(
          left: hMargin - handleRadius,
          top: topMargin - handleRadius,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          onPanUpdate: onResizeNW,
          onPanStart: onResizeStarted,
          onPanEnd: onResizeEnded,
          colorScheme: colorScheme,
          handleRadius: handleRadius,
        ),
        _buildHandle(
          left: hMargin + size.width - handleRadius,
          top: topMargin - handleRadius,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
          onPanUpdate: onResizeNE,
          onPanStart: onResizeStarted,
          onPanEnd: onResizeEnded,
          colorScheme: colorScheme,
          handleRadius: handleRadius,
        ),
        _buildHandle(
          left: hMargin - handleRadius,
          top: topMargin + size.height - handleRadius,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
          onPanUpdate: onResizeSW,
          onPanStart: onResizeStarted,
          onPanEnd: onResizeEnded,
          colorScheme: colorScheme,
          handleRadius: handleRadius,
        ),
        _buildHandle(
          left: hMargin + size.width - handleRadius,
          top: topMargin + size.height - handleRadius,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          onPanUpdate: onResizeSE,
          onPanStart: onResizeStarted,
          onPanEnd: onResizeEnded,
          colorScheme: colorScheme,
          handleRadius: handleRadius,
        ),
      ],
    );
  }

  static Widget _buildHandle({
    required double left,
    required double top,
    required MouseCursor cursor,
    required GestureDragUpdateCallback onPanUpdate,
    required ColorScheme colorScheme,
    required double handleRadius,
    VoidCallback? onPanStart,
    VoidCallback? onPanEnd,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart != null ? (_) => onPanStart() : null,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd != null ? (_) => onPanEnd() : null,
          onPanCancel: onPanEnd,
          child: Container(
            width: handleRadius * 2,
            height: handleRadius * 2,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
