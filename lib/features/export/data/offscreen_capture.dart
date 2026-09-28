import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:honeyday/core/theme/theme_data.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

/// Raised when the engine stops producing frames during an export.
///
/// What: The frame pump could not complete within its deadline.
/// Why: `WidgetsBinding.instance.endOfFrame` never resolves if the window is
/// minimized or loses focus, because the engine stops scheduling vsync. The
/// old code awaited it with no timeout, so the dialog sat there forever with
/// no way out and the only fix was restarting the app — the second, worse
/// half of the reported bug. A typed failure with an actionable message is
/// strictly better than an infinite wait.
class ExportCaptureStalled implements Exception {
  /// Creates the failure for a pump that waited [timeout].
  const ExportCaptureStalled(this.timeout);

  /// How long the pump waited before giving up.
  final Duration timeout;

  @override
  String toString() => 'ExportCaptureStalled(${timeout.inMilliseconds}ms)';
}

/// Drives the frame pipeline to a known state before rasterizing.
abstract interface class FramePump {
  /// Waits for [frames] frames to be produced, or fails after [timeout].
  Future<void> settle({required int frames, required Duration timeout});
}

/// [FramePump] backed by the real scheduler.
class SchedulerFramePump implements FramePump {
  /// Creates a pump that uses [WidgetsBinding].
  const SchedulerFramePump();

  @override
  Future<void> settle({required int frames, required Duration timeout}) async {
    for (var frame = 0; frame < frames; frame++) {
      // Request a frame explicitly: the engine throttles vsync to the display
      // and a just-built overlay may not be dirty yet.
      SchedulerBinding.instance.scheduleFrame();
      try {
        await SchedulerBinding.instance.endOfFrame.timeout(timeout);
      } on TimeoutException {
        throw ExportCaptureStalled(timeout);
      }
    }
  }
}

/// Hosts offscreen page widgets under an app context and rasterizes them.
///
/// What: Renders one page at a time inside a root [OverlayEntry] positioned
/// at the origin (the opaque progress dialog covers it), waits for frames so
/// layout/fonts settle, then rasterizes it through a [RepaintBoundary] with
/// [RenderRepaintBoundary.toImage] as **raw RGBA**, not PNG.
/// Why: Pages outside the viewer's lazy [PageView] must still be rendered
/// without entering the widget tree the user sees; an overlay keeps them
/// under a real app context (Theme, Localizations) while the page itself
/// stays a pure static composition with no ink layer. Reading raw pixels
/// skips the PNG encode/decode round trip that used to dominate the export.
class OffscreenCaptureHost {
  /// Creates a host that inserts its entry into the root navigator's overlay.
  ///
  /// [_framePump] and [_frameTimeout] are seams for the stall tests.
  OffscreenCaptureHost(
    BuildContext context, {
    this._framePump = const SchedulerFramePump(),
    this._frameTimeout = const Duration(seconds: 10),
  }) : _overlay = Navigator.of(context, rootNavigator: true).overlay!;

  final OverlayState _overlay;
  final FramePump _framePump;
  final Duration _frameTimeout;
  final GlobalKey _boundaryKey = GlobalKey();
  OverlayEntry? _entry;
  Widget? _page;
  bool _fontsSettled = false;
  int _lastFrameWait = 0;

  /// Frames the most recent [show] waited for.
  ///
  /// Exposed so the tests can assert the first capture still gives lazily
  /// loaded Google Fonts time to land.
  @visibleForTesting
  int get lastFrameWait => _lastFrameWait;

  /// Renders [page] in the overlay entry and waits until it is painted.
  ///
  /// Frame phase: inserts or refreshes the entry, then waits for frames — two
  /// on the very first page (one to lay out and paint, one so lazily fetched
  /// Google Fonts are definitely in) and one afterwards, because from then on
  /// the font cache is already warm and the page only changed.
  Future<void> show(Widget page) async {
    _page = page;
    final entry = _entry;
    if (entry == null) {
      final created = OverlayEntry(builder: _buildEntry);
      _entry = created;
      _overlay.insert(created);
    } else {
      entry.markNeedsBuild();
    }

    _lastFrameWait = _fontsSettled ? 1 : 2;
    await _framePump.settle(frames: _lastFrameWait, timeout: _frameTimeout);
    _fontsSettled = true;
  }

  /// Rasterizes the currently shown page to raw RGBA at [pixelRatio].
  ///
  /// Engine phase: [RenderRepaintBoundary.toImage] plus
  /// `toByteData(rawRgba)`, which is a plain copy of the engine's pixels —
  /// no PNG encoder in the way. [pixelRatio] comes from `fitCanvas` so the
  /// image lands at export dpi; on texture-size failures it retries once at
  /// ×0.66 (~200 dpi).
  ///
  /// The [ui.Image] is disposed before returning even when the read fails, so
  /// a 34 MB raster is never leaked. In widget tests this phase must run
  /// inside `TestWidgetsFlutterBinding.runAsync`; [capture] keeps production
  /// code in one call.
  Future<CapturedPage> rasterize(double pixelRatio) async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Export capture boundary is not available.');
    }

    final image = await _toImage(boundary, pixelRatio);
    try {
      final data = await image.toByteData(
        // Keep the format explicit at this API boundary even though Flutter
        // currently declares raw RGBA as the default.
        // ignore: avoid_redundant_argument_values
        format: ui.ImageByteFormat.rawRgba,
      );
      if (data == null) {
        throw StateError('Failed to read the exported page pixels.');
      }
      return CapturedPage(
        rgba: data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
    }
  }

  /// Convenience: [show] followed by [rasterize] in a single call.
  Future<CapturedPage> capture(Widget page, double pixelRatio) {
    return show(page).then((_) => rasterize(pixelRatio));
  }

  /// Removes the overlay entry; safe to call multiple times.
  ///
  /// Called by the export service as soon as the last page is rasterized: the
  /// captured page is still in the layer tree at that point, and dropping it
  /// frees both the widget subtree and its cached raster.
  void dispose() {
    _entry?.remove();
    _entry = null;
    _page = null;
  }

  Future<ui.Image> _toImage(
    RenderRepaintBoundary boundary,
    double pixelRatio,
  ) async {
    try {
      return await boundary.toImage(pixelRatio: pixelRatio);
    } on Object catch (error) {
      // Some GPUs cap the maximum texture size; the ×0.66 retry lands at
      // ~200 dpi, still comfortably above print resolution.
      debugPrint('Honeyday: export capture retry after error: $error');
      return await boundary.toImage(pixelRatio: pixelRatio * 0.66);
    }
  }

  Widget _buildEntry(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox(
          width: kDefaultPageWidth,
          height: kDefaultPageHeight,
          // Deterministic output regardless of the user's theme or text
          // scale: the exported PDF must look the same on every device.
          child: Theme(
            data: HoneydayTheme.lightTheme(),
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.noScaling),
              child: _page ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
