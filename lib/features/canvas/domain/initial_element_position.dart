import 'dart:math' as math;
import 'dart:ui';

/// Places a new element inside the page whenever its size permits it.
Offset initialElementPosition({
  required Size elementSize,
  required Size pageSize,
  Offset preferred = const Offset(120, 100),
}) {
  final maxX = math.max(0.0, pageSize.width - elementSize.width);
  final maxY = math.max(0.0, pageSize.height - elementSize.height);
  return Offset(
    preferred.dx.clamp(0.0, maxX).toDouble(),
    preferred.dy.clamp(0.0, maxY).toDouble(),
  );
}
