import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode_notifier.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PageViewCanvas Multi-Layer Stack Tests', () {
    testWidgets('element mutations notify history listeners', (tester) async {
      PageCanvasController? controller;
      await tester.pumpWidget(
        ProviderScope(
          child: testMaterialApp(
            home: Scaffold(
              body: PageViewCanvas(
                pageId: 'page-1',
                onControllerCreated: (value) => controller = value,
              ),
            ),
          ),
        ),
      );
      var changes = 0;
      controller!.addListener(() => changes++);
      controller!.addElement(
        const CanvasWidgetData(
          id: 'element',
          pageId: 'page-1',
          widgetType: 'text_box',
          position: Offset.zero,
          size: Size(200, 150),
        ),
      );
      expect(changes, 1);
      expect(controller!.canUndoElements, isTrue);
      controller!.undoElements();
      expect(changes, 2);
      expect(controller!.canRedoElements, isTrue);
      controller!.redoElements();
      expect(changes, 3);
      expect(controller!.canUndoElements, isTrue);
      await tester.pump();
    });

    testWidgets(
      'renders all 3 primary layers (PageSurface, Modular Widgets, InkCanvas)',
      (tester) async {
        const sampleElement = CanvasWidgetData(
          id: 'elem-1',
          pageId: 'page-1',
          widgetType: 'calendar_grid',
          position: Offset(50, 50),
          size: Size(200, 150),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: testMaterialApp(
              home: const Scaffold(
                body: PageViewCanvas(
                  pageId: 'page-1',
                  initialElements: [sampleElement],
                ),
              ),
            ),
          ),
        );

        // Layer 0: PageSurface
        expect(find.byType(PageSurface), findsOneWidget);

        // Layer 1: Modular widget in TransformableBox
        expect(find.byType(TransformableBox), findsOneWidget);
        expect(find.text('calendar_grid'), findsOneWidget);

        // Layer 3: InkCanvas
        expect(find.byType(InkCanvas), findsOneWidget);
      },
    );

    testWidgets('switching to edit mode reveals transformation controls', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const sampleElement = CanvasWidgetData(
        id: 'elem-1',
        pageId: 'page-1',
        widgetType: 'budget_calc',
        position: Offset(50, 50),
        size: Size(200, 150),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testMaterialApp(
            home: const Scaffold(
              body: PageViewCanvas(
                pageId: 'page-1',
                initialElements: [sampleElement],
              ),
            ),
          ),
        ),
      );

      // In initial writing mode, handles should not be visible
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);

      // Switch to edit mode via provider
      container.read(canvasModeProvider.notifier).setEdit();
      await tester.pumpAndSettle();

      // Selection is intentionally not seeded with the first element, so
      // handles only appear once the user taps the element to select it.
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      await tester.tap(find.text('budget_calc'));
      await tester.pumpAndSettle();

      // Now edit handles must be visible
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
