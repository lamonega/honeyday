import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/theme/theme_data.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Renders an export page in an independent, non-visible Flutter render tree.
///
/// The tree is never inserted into an app Overlay or presented by the window,
/// so page-sized content cannot cover UI or intercept input.
class OffscreenCaptureHost {
  static Future<void> _loadPendingFonts() async {
    await GoogleFonts.pendingFonts();
  }

  OffscreenCaptureHost(
    BuildContext context, {
    Future<void> Function()? waitForFonts,
  }) : _waitForFonts = waitForFonts ?? _loadPendingFonts,
       _locale = Localizations.localeOf(context),
       _direction = Directionality.of(context),
       _theme = HoneydayTheme.lightTheme() {
    _buildOwner = BuildOwner(focusManager: _focusManager);
    _renderView = RenderView(
      view: View.of(context),
      configuration: const ViewConfiguration(
        logicalConstraints: BoxConstraints.tightFor(
          width: kDefaultPageWidth,
          height: kDefaultPageHeight,
        ),
        physicalConstraints: BoxConstraints.tightFor(
          width: kDefaultPageWidth,
          height: kDefaultPageHeight,
        ),
        devicePixelRatio: 1,
      ),
      child: _boundary,
    );
    _pipelineOwner.rootNode = _renderView;
    _renderView.prepareInitialFrame();
  }

  final Future<void> Function() _waitForFonts;
  final Locale _locale;
  final TextDirection _direction;
  final ThemeData _theme;
  final FocusManager _focusManager = FocusManager();
  final PipelineOwner _pipelineOwner = PipelineOwner();
  final RenderRepaintBoundary _boundary = RenderRepaintBoundary();

  late final BuildOwner _buildOwner;
  late final RenderView _renderView;
  RenderObjectToWidgetElement<RenderBox>? _root;
  bool _disposed = false;
  bool _capturing = false;

  void _checkAlive() {
    if (_disposed) throw StateError('Export capture host is disposed.');
  }

  Widget _wrap(Widget page) {
    return Localizations(
      locale: _locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: Directionality(
        textDirection: _direction,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(kDefaultPageWidth, kDefaultPageHeight),
            devicePixelRatio: 1,
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: _theme,
            child: TickerMode(
              enabled: false,
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: kDefaultPageWidth,
                  height: kDefaultPageHeight,
                  child: KeyedSubtree(
                    key: UniqueKey(),
                    child: page,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mount(Widget page) {
    _root = RenderObjectToWidgetAdapter<RenderBox>(
      container: _boundary,
      child: _wrap(page),
    ).attachToRenderTree(_buildOwner, _root);
  }

  void _flush() {
    final root = _root;
    if (root == null) throw StateError('No export page is mounted.');

    _buildOwner.buildScope(root);
    _pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    _buildOwner.finalizeTree();
  }

  /// Mounts [page], waits for requested Google Fonts, then lays it out again.
  Future<void> show(Widget page) async {
    _checkAlive();
    _mount(page);
    _flush();

    // A fixed number of display frames is not proof that an async font has
    // arrived. Wait on the font package's actual pending requests instead.
    try {
      await _waitForFonts().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      debugPrint('Honeyday: export font loading timed out; using fallback.');
    } on Object catch (error) {
      debugPrint('Honeyday: export font loading failed; using fallback: $error');
    }

    _checkAlive();
    _mount(page);
    _flush();
  }

  /// Rasterizes the current page at [pixelRatio] and returns raw RGBA pixels.
  Future<CapturedPage> rasterize(double pixelRatio) async {
    _checkAlive();
    if (_root == null) throw StateError('No export page is mounted.');
    if (!pixelRatio.isFinite || pixelRatio <= 0) {
      throw ArgumentError.value(pixelRatio, 'pixelRatio');
    }

    final image = await _boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (data == null) {
        throw StateError('Failed to read exported page pixels.');
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

  /// Captures one page. The host deliberately serializes captures.
  Future<CapturedPage> capture(Widget page, double pixelRatio) async {
    _checkAlive();
    if (_capturing) {
      throw StateError('Concurrent captures are not supported.');
    }

    _capturing = true;
    try {
      await Future<void>.delayed(Duration.zero);
      await show(page);
      return await rasterize(pixelRatio);
    } finally {
      _capturing = false;
    }
  }

  /// Unmounts the independent tree and releases rendering resources.
  void dispose() {
    if (_disposed) return;
    if (_capturing) {
      throw StateError('Cannot dispose during an active capture.');
    }

    final root = _root;
    if (root != null) {
      RenderObjectToWidgetAdapter<RenderBox>(
        container: _boundary,
      ).attachToRenderTree(_buildOwner, root);
      _buildOwner.buildScope(root);
      _buildOwner.finalizeTree();
      _root = null;
    }

    _renderView.child = null;
    _pipelineOwner.rootNode = null;
    _boundary.dispose();
    _renderView.dispose();
    _pipelineOwner.dispose();
    _focusManager.dispose();
    _disposed = true;
  }
}
