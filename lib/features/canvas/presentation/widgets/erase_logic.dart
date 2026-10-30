import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

/// Spatial calculation determining if [stroke] intersects with an eraser circle at [point].
bool strokeIntersectsPoint(
  InkStroke stroke,
  Offset point,
  double eraserRadius,
) {
  final points = stroke.points;
  if (points.isEmpty) return false;
  final totalRadius = stroke.strokeWidth / 2 + eraserRadius;
  final radiusSquared = totalRadius * totalRadius;

  if (points.length == 1) {
    final dx = point.dx - points.single.x;
    final dy = point.dy - points.single.y;
    return dx * dx + dy * dy <= radiusSquared;
  }

  for (var i = 0; i < points.length - 1; i++) {
    if (distanceSquaredToSegment(point, points[i], points[i + 1]) <=
        radiusSquared) {
      return true;
    }
  }
  return false;
}

/// Returns the squared distance from point [p] to the line segment [a]–[b].
double distanceSquaredToSegment(Offset p, StrokePoint a, StrokePoint b) {
  final l2 = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y);
  if (l2 == 0) {
    final dx = p.dx - a.x;
    final dy = p.dy - a.y;
    return dx * dx + dy * dy;
  }
  var t = ((p.dx - a.x) * (b.x - a.x) + (p.dy - a.y) * (b.y - a.y)) / l2;
  t = t.clamp(0.0, 1.0);
  final projX = a.x + t * (b.x - a.x);
  final projY = a.y + t * (b.y - a.y);
  final dx = p.dx - projX;
  final dy = p.dy - projY;
  return dx * dx + dy * dy;
}
