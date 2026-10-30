import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_constants.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_state.dart';

/// Mixin that provides all gesture handling logic for transform operations.
///
/// Implementers must supply the [transformState] and the current element
/// properties ([currentPosition], [currentSize], [currentRotation],
/// [minWidth], [minHeight], [pageSize], [siblingRects]) as well as the
/// callbacks that fire when a transform begins, updates, or ends.
///
/// The handlers are split into three categories:
/// * **Body pan** — dragging the element around the canvas.
/// * **Rotation** — rotating via the circular handle above the element.
/// * **Resize** — scaling from any of the four corner handles (NW, NE,
///   SW, SE).
mixin TransformGestureMixin {
  // ── Required context from the widget ──

  /// Mutable state shared across gesture handlers.
  TransformState get transformState;

  /// Current element position (may differ from [TransformState.dragPosition]
  /// during a drag).
  Offset get currentPosition;

  /// Current element size.
  Size get currentSize;

  /// Current rotation angle in radians.
  double get currentRotation;

  /// Minimum allowed element width.
  double get minWidth;

  /// Minimum allowed element height.
  double get minHeight;

  /// Page size used for snap calculations (nullable = no snapping).
  Size? get pageSize;

  /// Sibling rects used for snap calculations.
  List<Rect> get siblingRects;

  // ── Callbacks ──

  /// Called when a transform gesture starts.
  VoidCallback? get onTransformStarted;

  /// Called on every frame of a transform gesture.
  OnTransformChanged? get onTransformChanged;

  /// Called when a transform gesture ends.
  VoidCallback? get onTransformEnded;

  /// Called to update visible snap guide lines.
  ValueChanged<List<SnapGuideLine>>? get onSnapGuidesChanged;

  // ── Helpers ──

  /// Updates [TransformState.globalCenter] using the widget's render box.
  void updateGlobalCenter(RenderBox? renderBox) {
    if (renderBox == null) return;
    transformState.globalCenter = renderBox.localToGlobal(
      Offset(
        kTransformHMargin + currentSize.width / 2,
        kTransformTopMargin + currentSize.height / 2,
      ),
    );
  }

  // ── Body drag ──

  /// Handles the start of a body drag gesture.
  void handleBodyPanStart(DragStartDetails _) {
    transformState.dragPosition = currentPosition;
    transformState.isSnapEnabled =
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed;
    onTransformStarted?.call();
  }

  /// Handles updates during a body drag, applying rotation-corrected deltas
  /// and optional snapping.
  void handleBodyPanUpdate(DragUpdateDetails details) {
    var delta = details.delta;
    if (currentRotation != 0) {
      final cosTheta = math.cos(currentRotation);
      final sinTheta = math.sin(currentRotation);
      delta = Offset(
        delta.dx * cosTheta - delta.dy * sinTheta,
        delta.dx * sinTheta + delta.dy * cosTheta,
      );
    }

    final rawCandidate =
        (transformState.dragPosition ?? currentPosition) + delta;
    transformState.dragPosition = rawCandidate;

    if (pageSize != null && transformState.isSnapEnabled) {
      final snap = CanvasSnapping.calculateSnap(
        candidateRect: Rect.fromLTWH(
          rawCandidate.dx,
          rawCandidate.dy,
          currentSize.width,
          currentSize.height,
        ),
        pageSize: pageSize!,
        siblingRects: siblingRects,
        isCurrentlySnapped:
            transformState.lastSnapResult?.guides.isNotEmpty == true,
      );
      transformState.lastSnapResult = snap.guides.isNotEmpty ? snap : null;
      onTransformChanged?.call(
        snap.snappedPosition,
        currentSize,
        currentRotation,
      );
      onSnapGuidesChanged?.call(snap.guides);
    } else {
      transformState.lastSnapResult = null;
      onTransformChanged?.call(rawCandidate, currentSize, currentRotation);
      onSnapGuidesChanged?.call(const []);
    }
  }

  /// Handles the end (or cancel) of a body drag gesture.
  void handleBodyPanEnd([dynamic _]) {
    transformState.resetDrag();
    onSnapGuidesChanged?.call(const []);
    onTransformEnded?.call();
  }

  // ── Rotation ──

  /// Handles rotation updates based on the pointer's global angle relative
  /// to the element center.
  void handleRotationPanUpdate(DragUpdateDetails details) {
    final center = transformState.globalCenter;
    if (center == null) return;
    final dx = details.globalPosition.dx - center.dx;
    final dy = details.globalPosition.dy - center.dy;
    final angle = math.atan2(dy, dx) + (math.pi / 2);
    onTransformChanged?.call(currentPosition, currentSize, angle);
  }

  // ── Resize (corner handlers) ──

  void _resizeCorner(
    DragUpdateDetails details, {
    required bool fromLeft,
    required bool fromTop,
  }) {
    // The gesture delta is already in the rotated element's local axes.
    final oldSize = currentSize;
    final width = math.max(
      minWidth,
      oldSize.width + (fromLeft ? -details.delta.dx : details.delta.dx),
    );
    final height = math.max(
      minHeight,
      oldSize.height + (fromTop ? -details.delta.dy : details.delta.dy),
    );
    final newSize = Size(width, height);
    final dw = width - oldSize.width;
    final dh = height - oldSize.height;
    final localCenterShift = Offset(
      (fromLeft ? -dw : dw) / 2,
      (fromTop ? -dh : dh) / 2,
    );
    final cosine = math.cos(currentRotation);
    final sine = math.sin(currentRotation);
    final pageCenterShift = Offset(
      localCenterShift.dx * cosine - localCenterShift.dy * sine,
      localCenterShift.dx * sine + localCenterShift.dy * cosine,
    );
    final oldCenter =
        currentPosition + Offset(oldSize.width / 2, oldSize.height / 2);
    final newPosition =
        oldCenter +
        pageCenterShift -
        Offset(newSize.width / 2, newSize.height / 2);
    onTransformChanged?.call(newPosition, newSize, currentRotation);
  }

  /// Handles resize from the south-east corner.
  void handleResizeSE(DragUpdateDetails details) =>
      _resizeCorner(details, fromLeft: false, fromTop: false);

  /// Handles resize from the **south-west** corner (width shrinks from left,
  /// height grows downward).
  void handleResizeSW(DragUpdateDetails details) =>
      _resizeCorner(details, fromLeft: true, fromTop: false);

  /// Handles resize from the **north-east** corner (width grows rightward,
  /// height shrinks from top).
  void handleResizeNE(DragUpdateDetails details) =>
      _resizeCorner(details, fromLeft: false, fromTop: true);

  /// Handles resize from the **north-west** corner (width shrinks from left,
  /// height shrinks from top — both edges move).
  void handleResizeNW(DragUpdateDetails details) =>
      _resizeCorner(details, fromLeft: true, fromTop: true);
}
