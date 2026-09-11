import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

void main() {
  group('InkCanvas & InkStroke Tests', () {
    test('InkStroke serializes to and from JSON points and colors', () {
      final stroke = InkStroke(
        id: 'stroke-1',
        pageId: 'page-1',
        tool: InkToolType.pen,
        color: const Color(0xFF1E293B),
        strokeWidth: 4,
        points: const [
          PointVector(10, 20, 0.6),
          PointVector(15, 25, 0.8),
          PointVector(20, 30, 0.7),
        ],
        createdAt: DateTime.utc(2026, 9, 11),
      );

      final jsonPoints = stroke.toJsonPoints();
      expect(jsonPoints, contains('"x":10'));
      expect(jsonPoints, contains('"y":20'));
      expect(stroke.toHexColor(), '#FF1E293B');

      final reconstructed = InkStroke.fromDb(
        id: stroke.id,
        pageId: stroke.pageId,
        brushType: 'pen',
        colorHex: stroke.toHexColor(),
        strokeWidth: stroke.strokeWidth,
        pointsJson: jsonPoints,
        createdAt: stroke.createdAt,
      );

      expect(reconstructed.id, stroke.id);
      expect(reconstructed.points.length, 3);
      expect(reconstructed.points.first.x, 10.0);
      expect(reconstructed.points.first.y, 20.0);
      expect(reconstructed.tool, InkToolType.pen);
    });

    test('InkStroke generates valid non-empty Path and bounds', () {
      final stroke = InkStroke(
        id: 'stroke-2',
        pageId: 'page-1',
        tool: InkToolType.pen,
        color: const Color(0xFFD97706),
        strokeWidth: 5,
        points: const [
          PointVector(50, 50, 0.5),
          PointVector(100, 100, 0.5),
          PointVector(150, 150, 0.5),
        ],
        createdAt: DateTime.now(),
      );

      expect(stroke.path, isNotNull);
      expect(stroke.bounds.width, greaterThan(50));
      expect(stroke.bounds.height, greaterThan(50));
    });

    testWidgets(
      'InkCanvas drawing gesture creates strokes and calls onStrokesChanged',
      (tester) async {
        List<InkStroke>? recordedStrokes;
        final controller = InkCanvasController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 500,
                child: InkCanvas(
                  pageId: 'page-1',
                  activeTool: InkToolType.pen,
                  activeColor: const Color(0xFF1E293B),
                  activeStrokeWidth: 3,
                  controller: controller,
                  onStrokesChanged: (strokes) {
                    recordedStrokes = strokes;
                  },
                ),
              ),
            ),
          ),
        );

        // Perform a drag stroke
        await tester.drag(find.byType(InkCanvas), const Offset(80, 80));
        await tester.pumpAndSettle();

        expect(recordedStrokes, isNotNull);
        expect(recordedStrokes!.length, 1);
        expect(controller.canUndo, isTrue);
        expect(controller.canRedo, isFalse);

        // Test undo
        controller.undo();
        await tester.pumpAndSettle();
        expect(recordedStrokes!.isEmpty, isTrue);
        expect(controller.canRedo, isTrue);

        // Test redo
        controller.redo();
        await tester.pumpAndSettle();
        expect(recordedStrokes!.length, 1);
      },
    );

    testWidgets('Eraser tool deletes intersecting strokes', (tester) async {
      List<InkStroke>? currentStrokes;
      final initialStroke = InkStroke(
        id: 'stroke-to-erase',
        pageId: 'page-1',
        tool: InkToolType.pen,
        color: const Color(0xFF1E293B),
        strokeWidth: 6,
        points: const [PointVector(100, 100, 0.5), PointVector(100, 200, 0.5)],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: InkCanvas(
                pageId: 'page-1',
                activeTool: InkToolType.eraser,
                activeColor: Colors.transparent,
                activeStrokeWidth: 20,
                initialStrokes: [initialStroke],
                onStrokesChanged: (strokes) {
                  currentStrokes = strokes;
                },
              ),
            ),
          ),
        ),
      );

      // Tap or swipe directly on the stroke at (100, 150)
      final gesture = await tester.startGesture(const Offset(100, 150));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(currentStrokes, isNotNull);
      expect(currentStrokes!.isEmpty, isTrue);
    });
  });
}
