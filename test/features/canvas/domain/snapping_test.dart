import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/snapping.dart';

void main() {
  group('CanvasSnapping Alignment Tests', () {
    const pageSize = Size(800, 1000);

    test('snaps candidate center to page horizontal center', () {
      // Page width 800 -> center is 400.
      // Candidate width 100. Center would be 400 if left is 350.
      // Suppose candidate left is 353 (center = 403, delta = -3 <= threshold 8)
      const candidateRect = Rect.fromLTWH(353, 100, 100, 100);

      final result = CanvasSnapping.calculateSnap(
        candidateRect: candidateRect,
        pageSize: pageSize,
      );

      // Should snap to 350 so candidate center matches 400
      expect(result.snappedPosition.dx, 350);
      expect(
        result.guides.any((g) => g.orientation == SnapOrientation.vertical),
        isTrue,
      );
      expect(result.guides.any((g) => (g.start.dx - 400).abs() < 0.5), isTrue);
    });

    test('snaps candidate top to page vertical margin', () {
      // Margin = 24. Candidate top = 26 (delta = -2 <= threshold 8)
      const candidateRect = Rect.fromLTWH(100, 26, 100, 100);

      final result = CanvasSnapping.calculateSnap(
        candidateRect: candidateRect,
        pageSize: pageSize,
      );

      expect(result.snappedPosition.dy, 24);
      expect(
        result.guides.any((g) => g.orientation == SnapOrientation.horizontal),
        isTrue,
      );
    });

    test('snaps to sibling widget left and right edges', () {
      // Sibling at left: 200, width: 150 -> right = 350
      const siblingRect = Rect.fromLTWH(200, 200, 150, 150);

      // Candidate left at 354 (delta = -4 to sibling right edge)
      const candidateRect = Rect.fromLTWH(354, 300, 80, 80);

      final result = CanvasSnapping.calculateSnap(
        candidateRect: candidateRect,
        pageSize: pageSize,
        siblingRects: const [siblingRect],
      );

      expect(result.snappedPosition.dx, 350);
      expect(result.guides.isNotEmpty, isTrue);
    });

    test('does not snap if candidate is beyond threshold', () {
      // Pick coordinates far from margin (24), center (400, 500), and right/bottom margin
      const candidateRect = Rect.fromLTWH(123, 157, 100, 100);

      final result = CanvasSnapping.calculateSnap(
        candidateRect: candidateRect,
        pageSize: pageSize,
      );

      expect(result.snappedPosition.dx, 123);
      expect(result.snappedPosition.dy, 157);
      expect(result.guides.isEmpty, isTrue);
    });
  });
}
