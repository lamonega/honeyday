import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';

void main() {
  group('TransformableBox Tests', () {
    testWidgets(
      'renders pure child without transform handles in writing mode',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TransformableBox(
                    position: Offset(50, 50),
                    size: Size(200, 150),
                    canvasMode: CanvasMode.writing,
                    child: Text('Child Content'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Child Content'), findsOneWidget);
        // Handles (refresh icon for rotation, close icon for delete) must not be present
        expect(find.byIcon(Icons.refresh_rounded), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
      },
    );

    testWidgets('renders selection border and handles in edit mode', (
      tester,
    ) async {
      var deleteClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TransformableBox(
                  position: const Offset(50, 50),
                  size: const Size(200, 150),
                  canvasMode: CanvasMode.edit,
                  onDelete: () {
                    deleteClicked = true;
                  },
                  child: const Text('Editable Widget'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Editable Widget'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(deleteClicked, isTrue);
    });

    testWidgets('dragging body triggers onTransformChanged', (tester) async {
      Offset? updatedPos;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TransformableBox(
                  position: const Offset(100, 100),
                  size: const Size(200, 150),
                  canvasMode: CanvasMode.edit,
                  onTransformChanged: (pos, size, rot) {
                    updatedPos = pos;
                  },
                  child: const Text('Drag Me'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.text('Drag Me'), const Offset(20, 30));
      expect(updatedPos, isNotNull);
      expect(updatedPos!.dx, greaterThan(100));
      expect(updatedPos!.dy, greaterThan(100));
    });

    testWidgets(
      'renders Canva action toolbar (adapt to page, fit width, center, color)',
      (tester) async {
        var adaptCalled = false;
        var fitWidthCalled = false;
        var centerCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TransformableBox(
                    position: const Offset(100, 100),
                    size: const Size(200, 150),
                    canvasMode: CanvasMode.edit,
                    onAdaptToPage: () => adaptCalled = true,
                    onFitWidth: () => fitWidthCalled = true,
                    onCenter: () => centerCalled = true,
                    child: const Text('Element'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify buttons exist
        expect(find.byIcon(Icons.fit_screen_rounded), findsOneWidget);
        expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
        expect(find.byIcon(Icons.filter_center_focus_rounded), findsOneWidget);
        expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

        // Tap adapt to page
        await tester.tap(find.byIcon(Icons.fit_screen_rounded));
        expect(adaptCalled, isTrue);

        // Tap fit width
        await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
        expect(fitWidthCalled, isTrue);

        // Tap center
        await tester.tap(find.byIcon(Icons.filter_center_focus_rounded));
        expect(centerCalled, isTrue);

        // Tap color palette icon to toggle palette
        await tester.tap(find.byIcon(Icons.palette_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(GestureDetector), findsWidgets);
      },
    );
  });
}
