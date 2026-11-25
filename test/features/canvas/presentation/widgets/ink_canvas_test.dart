import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_painter.dart';

class _FakeInkCanvasHost implements InkCanvasHost {
  @override
  bool canUndo = true;

  @override
  bool canRedo = false;

  @override
  void undo() {}

  @override
  void redo() {}

  @override
  void clear() {}
}

void main() {
  group('InkCanvas & InkStroke Tests', () {
    test('InkStroke serializes to and from JSON points and colors', () {
      final stroke = InkStroke(
        id: 'stroke-1',
        pageId: 'page-1',
        tool: InkToolType.pen,
        colorHex: '#FF1E293B',
        strokeWidth: 4,
        points: const [
          StrokePoint(10, 20, 0.6),
          StrokePoint(15, 25, 0.8),
          StrokePoint(20, 30, 0.7),
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
      expect(reconstructed.usesDevicePressure, isFalse);
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
        colorHex: '#FF1E293B',
        strokeWidth: 6,
        points: const [StrokePoint(100, 100, 0.5), StrokePoint(100, 200, 0.5)],
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

    testWidgets('fast erasure crosses between samples and undoes as one step', (
      tester,
    ) async {
      final stroke = InkStroke(
        id: 'crossed',
        pageId: 'page',
        tool: InkToolType.pen,
        colorHex: '#FF000000',
        strokeWidth: 2,
        points: const [StrokePoint(100, 100), StrokePoint(100, 200)],
        createdAt: DateTime.utc(2026),
      );
      final controller = InkCanvasController();
      final writes = <List<InkStroke>>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InkCanvas(
            pageId: 'page',
            activeTool: InkToolType.eraser,
            activeColor: Colors.transparent,
            activeStrokeWidth: 10,
            initialStrokes: [stroke],
            controller: controller,
            onStrokesChanged: writes.add,
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(50, 150));
      await gesture.moveTo(const Offset(150, 150));
      expect(writes, isEmpty);
      await gesture.up();
      expect(writes, [isEmpty]);

      controller.undo();
      expect(writes.last, [stroke]);
      expect(controller.canUndo, isFalse);
    });

    testWidgets(
      'ignores secondary mouse input and normalizes stylus pressure',
      (tester) async {
        final writes = <List<InkStroke>>[];
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: InkCanvas(
              pageId: 'page',
              activeTool: InkToolType.pen,
              activeColor: Colors.black,
              activeStrokeWidth: 3,
              onStrokesChanged: writes.add,
            ),
          ),
        );
        const start = Offset(50, 50);
        final mouse = await tester.startGesture(
          start,
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await mouse.up();
        expect(writes, isEmpty);

        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 100,
            position: start,
            kind: PointerDeviceKind.stylus,
            pressure: 30,
            pressureMin: 10,
            pressureMax: 90,
          ),
        );
        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 100,
            position: start,
            kind: PointerDeviceKind.stylus,
          ),
        );
        final stroke = writes.single.single;
        expect(stroke.points.single.pressure, 0.25);
        final restored = InkStroke.fromDb(
          id: stroke.id,
          pageId: stroke.pageId,
          brushType: stroke.tool.name,
          colorHex: stroke.colorHex,
          strokeWidth: stroke.strokeWidth,
          pointsJson: stroke.toJsonPoints(),
          createdAt: stroke.createdAt,
        );
        expect(restored.usesDevicePressure, isTrue);
        expect(restored.points.single.pressure, 0.25);
      },
    );

    test('real pressure changes pen width for identical coordinates', () {
      double width(double pressure) => buildPath(
        [
          StrokePoint(30, 30, pressure),
          StrokePoint(30, 70, pressure),
          StrokePoint(30, 130, pressure),
        ],
        strokeWidth: 20,
        tool: InkToolType.pen,
        useDevicePressure: true,
      ).getBounds().width;

      expect(width(0.9), greaterThan(width(0.1)));
    });

    test('InkPainter shouldRepaint responds correctly to activePoints and strokes changes', () {
      final strokeA = InkStroke(
        id: 's1',
        pageId: 'p1',
        tool: InkToolType.pen,
        colorHex: '#FF000000',
        strokeWidth: 2,
        points: const [StrokePoint(0, 0, 0.5)],
        createdAt: DateTime.now(),
      );

      final idlePainter1 = InkPainter(strokes: [strokeA]);
      final idlePainter2 = InkPainter(strokes: [strokeA]);
      // When idle and unchanged, shouldRepaint must return false
      expect(idlePainter1.shouldRepaint(idlePainter2), isFalse);

      // When strokes change, shouldRepaint must return true
      final idlePainter3 = InkPainter(strokes: const []);
      expect(idlePainter1.shouldRepaint(idlePainter3), isTrue);

      // When activePoints are present on either painter, shouldRepaint must return true for live stroke
      final activePainter = InkPainter(
        strokes: [strokeA],
        activePoints: const [StrokePoint(10, 10, 0.5)],
      );
      expect(activePainter.shouldRepaint(idlePainter1), isTrue);
      expect(idlePainter1.shouldRepaint(activePainter), isTrue);
    });

    testWidgets(
      'InkCanvas renders live in-progress stroke during gesture movement',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 500,
                child: InkCanvas(
                  pageId: 'page-1',
                  activeTool: InkToolType.pen,
                  activeColor: Color(0xFF1E293B),
                  activeStrokeWidth: 3,
                ),
              ),
            ),
          ),
        );

        // Start drag gesture
        final gesture = await tester.startGesture(const Offset(50, 50));
        await tester.pump();
        await gesture.moveTo(const Offset(100, 100));
        await tester.pump();

        // Find CustomPaint widgets inside InkCanvas
        final customPaints = tester.widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(InkCanvas),
            matching: find.byType(CustomPaint),
          ),
        );

        // Second CustomPaint is the active stroke layer
        final activePaint = customPaints.last;
        expect(activePaint.painter, isNotNull);

        // Release pointer to commit stroke
        await gesture.up();
        await tester.pumpAndSettle();

        // First CustomPaint (completed strokes layer) now holds the committed stroke
        final completedPaints = tester.widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(InkCanvas),
            matching: find.byType(CustomPaint),
          ),
        );
        final completedPainter = completedPaints.first.painter! as InkPainter;
        expect(completedPainter.strokes.length, 1);
      },
    );

    test(
      'InkCanvasController.detach only clears when matching host detaches',
      () {
        final controller = InkCanvasController();
        final hostA = _FakeInkCanvasHost();
        final hostB = _FakeInkCanvasHost();

        controller.attach(hostA);
        expect(controller.canUndo, isTrue);

        controller
          ..attach(hostB)
          // Old host detaching must not clear hostB.
          ..detach(hostA);
        expect(controller.canUndo, isTrue);

        // Active host detaching clears it.
        controller.detach(hostB);
        expect(controller.canUndo, isFalse);
      },
    );

    testWidgets(
      'stylus input preempts active touch palm gesture and appends pointer-up point',
      (tester) async {
        final writes = <List<InkStroke>>[];
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: InkCanvas(
              pageId: 'page-1',
              activeTool: InkToolType.pen,
              activeColor: Colors.black,
              activeStrokeWidth: 3,
              onStrokesChanged: writes.add,
            ),
          ),
        );

        // Palm touch begins first.
        await tester.sendEventToBinding(
          const PointerDownEvent(pointer: 1, position: Offset(20, 20)),
        );
        await tester.sendEventToBinding(
          const PointerMoveEvent(pointer: 1, position: Offset(30, 30)),
        );

        // Stylus arrives and preempts the palm touch.
        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 2,
            position: Offset(100, 100),
            kind: PointerDeviceKind.stylus,
            pressure: 0.5,
            pressureMin: 0,
          ),
        );
        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 2,
            position: Offset(140, 160),
            kind: PointerDeviceKind.stylus,
            pressure: 0.5,
            pressureMin: 0,
          ),
        );
        // Palm lifts later — should be ignored.
        await tester.sendEventToBinding(
          const PointerUpEvent(pointer: 1, position: Offset(35, 35)),
        );

        expect(writes, hasLength(1));
        final stroke = writes.single.single;
        expect(stroke.points.first.x, 100);
        expect(stroke.points.first.y, 100);
        expect(stroke.points.last.x, 140);
        expect(stroke.points.last.y, 160);
      },
    );
  });
}
