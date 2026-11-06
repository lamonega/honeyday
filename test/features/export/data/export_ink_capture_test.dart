import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/static_page_view.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

import '../../../helpers/pump_app.dart';

InkStroke _stroke({
  String color = '#FFFF0000',
  InkToolType tool = InkToolType.pen,
}) => InkStroke(
  id: 'ink-${tool.name}',
  pageId: 'p1',
  tool: tool,
  colorHex: color,
  strokeWidth: 24,
  points: const [StrokePoint(100, 80, 0.5), StrokePoint(300, 80, 0.5)],
  createdAt: DateTime.utc(2026),
);

List<int> _pixel(CapturedPage page, int x, int y) {
  final offset = (y * page.width + x) * 4;
  return page.rgba.sublist(offset, offset + 4);
}

Future<CapturedPage> _capture(WidgetTester tester, Widget page) async {
  late BuildContext appContext;
  await tester.pumpWidget(
    testMaterialApp(
      home: Builder(
        builder: (context) {
          appContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  final host = OffscreenCaptureHost(appContext);
  try {
    final result = await tester.runAsync(() => host.capture(page, 1));
    expect(tester.takeException(), isNull);
    return result!;
  } finally {
    host.dispose();
  }
}

void main() {
  const element = CanvasWidgetData(
    id: 'element',
    pageId: 'p1',
    widgetType: 'test',
    position: Offset(50, 50),
    size: Size(300, 150),
  );

  testWidgets('completed pen strokes paint above page elements', (
    tester,
  ) async {
    final image = await _capture(
      tester,
      StaticPageView(
        paperStyle: PaperStyle.blank,
        elements: const [element],
        elementBuilder: (_, _) => const ColoredBox(color: Colors.blue),
        strokes: [_stroke()],
      ),
    );
    expect(_pixel(image, 60, 60), [0x21, 0x96, 0xF3, 0xFF]);
    expect(_pixel(image, 200, 80), [0xFF, 0, 0, 0xFF]);
  });

  testWidgets('highlighter preserves opacity and ink creation order', (
    tester,
  ) async {
    final image = await _capture(
      tester,
      StaticPageView(
        paperStyle: PaperStyle.blank,
        strokes: [
          _stroke(),
          _stroke(color: '#FF00FF00', tool: InkToolType.highlighter),
        ],
      ),
    );
    final blended = _pixel(image, 200, 80);
    expect(blended[0], closeTo(153, 1));
    expect(blended[1], closeTo(102, 1));
    expect(blended[2], 0);
    expect(blended[3], 255);
  });

  testWidgets('ink outside the page is clipped rather than leaking', (
    tester,
  ) async {
    final image = await _capture(
      tester,
      ColoredBox(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            height: 200,
            child: StaticPageView(
              paperStyle: PaperStyle.blank,
              strokes: [_stroke()],
            ),
          ),
        ),
      ),
    );
    expect(_pixel(image, 150, 80), [255, 0, 0, 255]);
    expect(_pixel(image, 250, 80), [255, 255, 255, 255]);
  });
}
