import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/canvas/presentation/widgets/erase_logic.dart';

InkStroke _stroke(List<StrokePoint> points) => InkStroke(
  id: 'stroke',
  pageId: 'page',
  tool: InkToolType.pen,
  colorHex: '#000000',
  strokeWidth: 2,
  points: points,
  createdAt: DateTime(2026),
);

void main() {
  test('eraser intersects a curve far outside its endpoint bounds', () {
    final stroke = _stroke(const [
      StrokePoint(0, 0),
      StrokePoint(100, 100),
      StrokePoint(0, 1),
    ]);
    expect(strokeIntersectsPoint(stroke, const Offset(100, 100), 5), isTrue);
    expect(strokeIntersectsPoint(stroke, const Offset(200, 200), 5), isFalse);
  });

  test('empty strokes and single points are handled', () {
    expect(strokeIntersectsPoint(_stroke([]), Offset.zero, 5), isFalse);
    final dot = _stroke(const [StrokePoint(0, 0)]);
    expect(strokeIntersectsPoint(dot, const Offset(6, 0), 5), isTrue);
    expect(strokeIntersectsPoint(dot, const Offset(7, 0), 5), isFalse);
  });
}
