import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'captures a full-size page without inserting it into the visible tree',
    (tester) async {
      late BuildContext appContext;
      await tester.pumpWidget(
        testMaterialApp(
          home: Builder(
            builder: (context) {
              appContext = context;
              return const Scaffold(body: Text('VISIBLE_APP'));
            },
          ),
        ),
      );

      final host = OffscreenCaptureHost(appContext, waitForFonts: () async {});
      try {
        final page = await tester.runAsync(
          () => host.capture(
            const ColoredBox(
              color: Color(0xFFFF0000),
              child: Center(child: Text('EXPORT_ONLY_PAGE')),
            ),
            1,
          ),
        );

        expect(page, isNotNull);
        expect(page!.width, kDefaultPageWidth);
        expect(page.height, kDefaultPageHeight);
        expect(page.byteLength, kDefaultPageWidth * kDefaultPageHeight * 4);
        expect(page.rgba.sublist(0, 4), [0xFF, 0, 0, 0xFF]);
        expect(find.text('VISIBLE_APP'), findsOneWidget);
        expect(find.text('EXPORT_ONLY_PAGE'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        host.dispose();
      }
    },
  );

  testWidgets('reuses the independent tree for consecutive pages', (
    tester,
  ) async {
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

    final host = OffscreenCaptureHost(appContext, waitForFonts: () async {});
    try {
      final first = await tester.runAsync(
        () => host.capture(const ColoredBox(color: Colors.red), 1),
      );
      final second = await tester.runAsync(
        () => host.capture(const ColoredBox(color: Colors.green), 1),
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.width, kDefaultPageWidth);
      expect(second!.height, kDefaultPageHeight);
      expect(tester.takeException(), isNull);
    } finally {
      host.dispose();
    }
  });

  testWidgets('rasterize without a mounted page is an error', (tester) async {
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

    final host = OffscreenCaptureHost(appContext, waitForFonts: () async {});
    try {
      await expectLater(host.rasterize(1), throwsStateError);
    } finally {
      host.dispose();
    }
  });

  testWidgets('dispose is idempotent', (tester) async {
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

    OffscreenCaptureHost(appContext, waitForFonts: () async {})
      ..dispose()
      ..dispose();
    expect(tester.takeException(), isNull);
  });
}
