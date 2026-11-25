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

/// Spatial calculation determining if [stroke] intersects a swept eraser
/// capsule from [start] to [end] with radius [eraserRadius].
bool strokeIntersectsSegment(
  InkStroke stroke,
  Offset start,
  Offset end,
  double eraserRadius,
) {
  if (start == end) {
    return strokeIntersectsPoint(stroke, end, eraserRadius);
  }
  final points = stroke.points;
  if (points.isEmpty) return false;
  final totalRadius = stroke.strokeWidth / 2 + eraserRadius;
  final radiusSquared = totalRadius * totalRadius;

  final segA = StrokePoint(start.dx, start.dy, 0.5);
  final segB = StrokePoint(end.dx, end.dy, 0.5);

  if (points.length == 1) {
    final p = Offset(points.single.x, points.single.y);
    return distanceSquaredToSegment(p, segA, segB) <= radiusSquared;
  }

  for (var i = 0; i < points.length - 1; i++) {
    final p1 = points[i];
    final p2 = points[i + 1];
    if (_segmentsIntersect(start, end, Offset(p1.x, p1.y), Offset(p2.x, p2.y))) {
      return true;
    }
    if (distanceSquaredToSegment(start, p1, p2) <= radiusSquared ||
        distanceSquaredToSegment(end, p1, p2) <= radiusSquared ||
        distanceSquaredToSegment(Offset(p1.x, p1.y), segA, segB) <=
            radiusSquared ||
        distanceSquaredToSegment(Offset(p2.x, p2.y), segA, segB) <=
            radiusSquared) {
      return true;
    }
  }
  return false;
}

bool _segmentsIntersect(Offset a, Offset b, Offset c, Offset d) {
  final d1 = _cross(c, d, a);
  final d2 = _cross(c, d, b);
  final d3 = _cross(a, b, c);
  final d4 = _cross(a, b, d);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }
  return false;
}

double _cross(Offset o, Offset a, Offset b) {
  return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
}
