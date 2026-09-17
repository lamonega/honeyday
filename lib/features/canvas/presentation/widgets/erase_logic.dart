import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

/// Spatial calculation determining if [stroke] intersects with an eraser circle at [point].
bool strokeIntersectsPoint(
  InkStroke stroke,
  Offset point,
  double eraserRadius,
) {
  final totalRadius = (stroke.strokeWidth / 2) + eraserRadius;

  if (stroke.points.isNotEmpty) {
    final first = stroke.points.first;
    final last = stroke.points.last;
    final minX = first.x < last.x ? first.x : last.x;
    final maxX = first.x > last.x ? first.x : last.x;
    final minY = first.y < last.y ? first.y : last.y;
    final maxY = first.y > last.y ? first.y : last.y;
    final bounds = Rect.fromLTRB(
      minX - totalRadius,
      minY - totalRadius,
      maxX + totalRadius,
      maxY + totalRadius,
    );
    if (!bounds.contains(point)) {
      return false;
    }
  }

  final r2 = totalRadius * totalRadius;

  for (var i = 0; i < stroke.points.length - 1; i++) {
    final p1 = stroke.points[i];
    final p2 = stroke.points[i + 1];
    if (distanceSquaredToSegment(point, p1, p2) <= r2) {
      return true;
    }
  }

  if (stroke.points.length == 1) {
    final single = stroke.points.first;
    final dx = point.dx - single.x;
    final dy = point.dy - single.y;
    return (dx * dx + dy * dy) <= r2;
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
  var t =
      ((p.dx - a.x) * (b.x - a.x) + (p.dy - a.y) * (b.y - a.y)) / l2;
  t = t.clamp(0.0, 1.0);
  final projX = a.x + t * (b.x - a.x);
  final projY = a.y + t * (b.y - a.y);
  final dx = p.dx - projX;
  final dy = p.dy - projY;
  return dx * dx + dy * dy;
}
