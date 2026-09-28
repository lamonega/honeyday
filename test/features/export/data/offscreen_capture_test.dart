import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

import '../../../helpers/pump_app.dart';

/// Drives the frame phase of `show` with real pumps, mirroring how the
/// production loop runs frames, then rasterizes inside `runAsync` — the
/// same split `flutter_test`'s golden matcher uses for image work.
Future<CapturedPage> captureInTest(
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

/// A pump that models a window which stopped producing frames: it honours the
/// same deadline the real pump does, so a test can drive the failure without
/// waiting ten minutes for `pumpAndSettle` to give up.
class _StalledPump implements FramePump {
  int calls = 0;

  @override
  Future<void> settle({required int frames, required Duration timeout}) async {
    calls++;
    // The test zone's clock is fake, so the delay only completes when the test
    // advances it with `pump`.
    await Future<void>.delayed(timeout);
    throw ExportCaptureStalled(timeout);
  }
}

/// A pump that counts what it was asked for and completes right away.
class _CountingPump implements FramePump {
  final List<int> requested = [];

  @override
  Future<void> settle({required int frames, required Duration timeout}) async {
    requested.add(frames);
  }
}

/// Mounts a host in a throwaway app and returns its context.
Future<BuildContext> hostContextIn(WidgetTester tester) async {
  final holder = <BuildContext>[];
  await tester.pumpWidget(
    testMaterialApp(
      home: Builder(
        builder: (context) {
          holder.add(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return holder.single;
}

void main() {
  testWidgets(
    'rasterizes the page to raw RGBA at the full canvas size even when the '
    'screen is smaller',
    (tester) async {
      final host = OffscreenCaptureHost(await hostContextIn(tester));
      // The test surface is 800×600; the capture must still be 800×1100.
      final first = await captureInTest(
        tester,
        host,
        const ColoredBox(color: Color(0xFFFF0000)),
      );

      // A second capture reuses the same overlay entry (markNeedsBuild path).
      final second = await captureInTest(
        tester,
        host,
        const ColoredBox(color: Color(0xFF00FF00)),
      );

      host.dispose();
      await tester.pump();

      expect(first.width, kDefaultPageWidth);
      expect(first.height, kDefaultPageHeight);
      expect(first.byteLength, kDefaultPageWidth * kDefaultPageHeight * 4);
      expect(first.rgba, hasLength(first.byteLength));
      // Second capture kept the same geometry.
      expect(second.width, kDefaultPageWidth);
      expect(second.height, kDefaultPageHeight);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the raw buffer holds the pixels, not a PNG', (tester) async {
    final host = OffscreenCaptureHost(await hostContextIn(tester));

    final page = await captureInTest(
      tester,
      host,
      const ColoredBox(color: Color(0xFF3366FF)),
    );
    host.dispose();

    // Not a PNG: no PNG magic, and a fully opaque red-ish first pixel.
    expect(page.rgba.sublist(0, 4), isNot([0x89, 0x50, 0x4E, 0x47]));
    expect(page.rgba[0], 0x33);
    expect(page.rgba[1], 0x66);
    expect(page.rgba[2], 0xFF);
    expect(page.rgba[3], 0xFF, reason: 'a page surface is opaque');
  });

  testWidgets('waits two frames for fonts on the first page, one after', (
    tester,
  ) async {
    final pump = _CountingPump();
    final host = OffscreenCaptureHost(
      await hostContextIn(tester),
      framePump: pump,
    );

    await host.show(const ColoredBox(color: Color(0xFFFFFFFF)));
    expect(pump.requested, [2], reason: 'first page lets Google Fonts land');
    expect(host.lastFrameWait, 2);

    await host.show(const ColoredBox(color: Color(0xFFEEEEEE)));
    expect(pump.requested, [2, 1], reason: 'fonts are warm from here on');
    expect(host.lastFrameWait, 1);

    host.dispose();
  });

  testWidgets('fails fast instead of hanging when frames stop coming', (
    tester,
  ) async {
    // The second half of the reported bug: `endOfFrame` never resolves when
    // the desktop window is minimized, so the old export sat on the dialog
    // forever with no way out. Now it is a typed, localized failure.
    final pump = _StalledPump();
    final host = OffscreenCaptureHost(
      await hostContextIn(tester),
      framePump: pump,
      frameTimeout: const Duration(milliseconds: 50),
    );

    final showing = host.show(const ColoredBox(color: Color(0xFFFFFFFF)));
    // Attach the expectation before the clock moves, otherwise the rejection
    // lands with nobody listening and the zone reports it as unhandled.
    final stalls = expectLater(showing, throwsA(isA<ExportCaptureStalled>()));
    await tester.pump(const Duration(milliseconds: 100));
    await stalls;

    expect(pump.calls, 1);
    host.dispose();
  });

  testWidgets('the real pump gives up after its timeout', (tester) async {
    // Same guarantee with the production pump: a `Future.timeout` around
    // `endOfFrame` turns a dead window into an error instead of a hang.
    final host = OffscreenCaptureHost(
      await hostContextIn(tester),
      frameTimeout: const Duration(milliseconds: 50),
    );

    // No pumps: the fake clock is never advanced, so `endOfFrame` cannot
    // resolve — exactly the minimized-window situation.
    final showing = host.show(const ColoredBox(color: Color(0xFFFFFFFF)));
    // Attach the expectation before the clock moves, otherwise the rejection
    // lands with nobody listening and the zone reports it as unhandled.
    final stalls = expectLater(showing, throwsA(isA<ExportCaptureStalled>()));
    await tester.pump(const Duration(milliseconds: 100));
    await stalls;
    host.dispose();
  });

  testWidgets('dispose is safe to call twice', (tester) async {
    final host = OffscreenCaptureHost(await hostContextIn(tester));

    for (var i = 0; i < 2; i++) {
      host.dispose();
    }
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('rasterize without a mounted boundary is an error', (
    tester,
  ) async {
    final host = OffscreenCaptureHost(await hostContextIn(tester));

    await expectLater(host.rasterize(1), throwsStateError);
    host.dispose();
  });
}
