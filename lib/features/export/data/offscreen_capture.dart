import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:honeyday/core/theme/theme_data.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';

/// Hosts offscreen page widgets under an app context and rasterizes them.
///
/// What: Renders one page at a time inside a root [OverlayEntry] positioned
/// at the origin (the opaque progress dialog covers it), waits for frames so
/// layout/fonts settle, then rasterizes it through a [RepaintBoundary] with
/// [RenderRepaintBoundary.toImage].
/// Why: Pages outside the viewer's lazy [PageView] must still be rendered
/// without entering the widget tree the user sees; an overlay keeps them
/// under a real app context (Theme, Localizations) while the page itself
/// stays a pure static composition with no ink layer.
class OffscreenCaptureHost {
  /// Creates a host that inserts its entry into the root navigator's overlay.
  OffscreenCaptureHost(BuildContext context)
    : _overlay = Navigator.of(context, rootNavigator: true).overlay!;

  final OverlayState _overlay;
  final GlobalKey _boundaryKey = GlobalKey();
  OverlayEntry? _entry;
  Widget? _page;

  /// Renders [page] in the overlay entry and waits until it is painted.
  ///
  /// Frame phase: inserts or refreshes the entry, then waits two frames —
  /// one to lay out and paint the new child, one so lazily fetched Google
  /// Fonts (applied asynchronously) are definitely in.
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

    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Rasterizes the currently shown page to PNG bytes at [pixelRatio].
  ///
  /// Engine phase: [RenderRepaintBoundary.toImage] plus PNG encoding.
  /// [pixelRatio] comes from `fitCanvas` so the image lands at export dpi;
  /// on texture-size failures it retries once at ×0.66 (~200 dpi).
  ///
  /// In widget tests this phase must run inside
  /// `TestWidgetsFlutterBinding.runAsync` (same mechanism the golden
  /// matcher uses); [capture] keeps production code in one call.
  Future<Uint8List> rasterize(double pixelRatio) async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Export capture boundary is not available.');
    }

    final image = await _toImage(boundary, pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Failed to encode the exported page as PNG.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Convenience: [show] followed by [rasterize] in a single call.
  Future<Uint8List> capture(Widget page, double pixelRatio) async {
    await show(page);
    return await rasterize(pixelRatio);
  }

  /// Removes the overlay entry; safe to call multiple times.
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
