import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_gestures.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_state.dart';

class _ResizeHarness with TransformGestureMixin {
  _ResizeHarness(this.currentRotation);

  @override
  final transformState = TransformState();
  @override
  Offset currentPosition = const Offset(100, 100);
  @override
  Size currentSize = const Size(200, 150);
  @override
  final double currentRotation;
  @override
  double get minWidth => 24;
  @override
  double get minHeight => 24;
  @override
  Size? get pageSize => null;
  @override
  List<Rect> get siblingRects => const [];
  @override
  VoidCallback? get onTransformStarted => null;
  @override
  VoidCallback? get onTransformEnded => null;
  @override
  ValueChanged<List<SnapGuideLine>>? get onSnapGuidesChanged => null;
  @override
  void Function(Offset, Size, double)? get onTransformChanged => (p, s, r) {
    currentPosition = p;
    currentSize = s;
  };

  Offset corner({required bool left, required bool top}) {
    final center =
        currentPosition + Offset(currentSize.width / 2, currentSize.height / 2);
    final local = Offset(
      (left ? -1 : 1) * currentSize.width / 2,
      (top ? -1 : 1) * currentSize.height / 2,
    );
    return center +
        Offset(
          local.dx * math.cos(currentRotation) -
              local.dy * math.sin(currentRotation),
          local.dx * math.sin(currentRotation) +
              local.dy * math.cos(currentRotation),
        );
  }
}

void main() {
  for (final angle in [0.0, math.pi / 4, math.pi / 2]) {
    for (final left in [false, true]) {
      for (final top in [false, true]) {
        test('resize keeps opposite corner fixed ($angle, $left, $top)', () {
          final harness = _ResizeHarness(angle);
          final fixed = harness.corner(left: !left, top: !top);
          final handler = left
              ? (top ? harness.handleResizeNW : harness.handleResizeSW)
              : (top ? harness.handleResizeNE : harness.handleResizeSE);
          handler(
            DragUpdateDetails(
              delta: const Offset(30, 20),
              globalPosition: Offset.zero,
            ),
          );
          expect(
            (harness.corner(left: !left, top: !top) - fixed).distance,
            lessThan(0.001),
          );
          handler(
            DragUpdateDetails(
              delta: const Offset(500, 500),
              globalPosition: Offset.zero,
            ),
          );
          expect(
            (harness.corner(left: !left, top: !top) - fixed).distance,
            lessThan(0.001),
          );
          expect(harness.currentSize.width, greaterThanOrEqualTo(24));
          expect(harness.currentSize.height, greaterThanOrEqualTo(24));
        });
      }
    }
  }
}
