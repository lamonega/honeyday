import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';

import '../../../helpers/pump_app.dart';

/// Decodes the width/height stored in the PNG IHDR chunk (big-endian).
(int width, int height) pngSize(Uint8List bytes) {
  final width =
      (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final height =
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  return (width, height);
}

/// Drives the frame phase of `show` with real pumps, mirroring how the
/// production loop runs frames, then rasterizes inside `runAsync` — the
/// same split `flutter_test`'s golden matcher uses for image work.
Future<Uint8List> captureInTest(
  WidgetTester tester,
  OffscreenCaptureHost host,
  Widget page, {
  double pixelRatio = 1,
}) async {
  final showing = host.show(page);
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
  await showing;
  return (await tester.runAsync(() => host.rasterize(pixelRatio)))!;
}

void main() {
  testWidgets('rasterizes the page to PNG at the full canvas size even when '
      'the screen is smaller', (tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      testMaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final host = OffscreenCaptureHost(hostContext);
    // The test surface is 800×600; the capture must still be 800×1100.
    final firstBytes = await captureInTest(
      tester,
      host,
      const ColoredBox(color: Color(0xFFFF0000)),
    );

    // A second capture reuses the same overlay entry (markNeedsBuild path).
    final secondBytes = await captureInTest(
      tester,
      host,
      const ColoredBox(color: Color(0xFF00FF00)),
    );

    host.dispose();
    await tester.pump();

    expect(firstBytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]); // PNG magic
    expect(pngSize(firstBytes), (
      kDefaultPageWidth,
      kDefaultPageHeight,
    ), reason: 'capture must not be clamped to the window size');
    expect(pngSize(secondBytes), (kDefaultPageWidth, kDefaultPageHeight));
    expect(tester.takeException(), isNull);
  });
}
