import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas/canvas_gesture_layer.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas/canvas_grid_overlay.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas/canvas_page_shadow.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_toolbar.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/static_element_box.dart';
import 'package:honeyday/features/canvas/presentation/widgets/static_page_view.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';

import '../../../../helpers/pump_app.dart';

const _elements = [
  CanvasWidgetData(
    id: 'elem-1',
    pageId: 'page-1',
    widgetType: 'shape_box',
    position: Offset(40, 60),
    size: Size(160, 100),
    rotation: 0.2,
  ),
  CanvasWidgetData(
    id: 'elem-2',
    pageId: 'page-1',
    widgetType: 'text_box',
    position: Offset(120, 260),
    size: Size(120, 80),
  ),
];

/// Wraps [StaticPageView] in the fixed-size host a capture layer would use.
Widget _hostedPage({Widget Function(BuildContext, CanvasWidgetData)? builder}) {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: 400,
        height: 520,
        child: StaticPageView(
          paperStyle: PaperStyle.lined,
          elements: _elements,
          elementBuilder: builder,
        ),
      ),
    ),
  );
}

void main() {
  group('StaticPageView Tests', () {
    testWidgets('renders paper and one StaticElementBox per element', (
      tester,
    ) async {
      await tester.pumpWidget(testMaterialApp(home: _hostedPage()));

      expect(find.byType(PageSurface), findsOneWidget);
      expect(find.byType(StaticElementBox), findsNWidgets(2));

      final boxes = tester
          .widgetList<StaticElementBox>(find.byType(StaticElementBox))
          .toList();
      expect(boxes[0].position, const Offset(40, 60));
      expect(boxes[0].size, const Size(160, 100));
      expect(boxes[0].rotation, 0.2);
      expect(boxes[1].position, const Offset(120, 260));
      expect(boxes[1].rotation, 0);
    });

    testWidgets('renders an empty sized box when no elementBuilder is given', (
      tester,
    ) async {
      await tester.pumpWidget(testMaterialApp(home: _hostedPage()));

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(StaticElementBox), findsNWidgets(2));
    });

    testWidgets('mounts without Riverpod and without viewer chrome', (
      tester,
    ) async {
      // No ProviderScope above this tree: the widget must not touch providers.
      await tester.pumpWidget(
        testMaterialApp(
          home: _hostedPage(
            builder: (context, element) => Text(element.widgetType),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('shape_box'), findsOneWidget);
      expect(find.text('text_box'), findsOneWidget);

      // Deliberate exclusions: ink, snap guides, page shadow, toolbar.
      expect(find.byType(CanvasGestureLayer), findsNothing);
      expect(find.byType(CanvasGridOverlay), findsNothing);
      expect(find.byType(CanvasPageShadow), findsNothing);
      expect(find.byType(CanvasFloatingToolbar), findsNothing);
      expect(find.byType(TransformableBox), findsNothing);
    });
  });
}
