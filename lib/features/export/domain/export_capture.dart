import 'dart:typed_data';

import 'package:meta/meta.dart';

/// One page rasterized to raw, unencoded pixels.
///
/// What: A [CapturedPage] is exactly what the engine hands back from
/// `ui.Image.toByteData(format: ui.ImageByteFormat.rawRgba)`: 4 bytes per
/// pixel, row-major, alpha last, plus the dimensions the engine chose.
/// Why: The PDF only needs RGB rows, so encoding a PNG first and decoding it
/// later (what the previous pipeline did) is pure duplicated work: PNG
/// encoding cost 0.4 s/page and PNG decoding another 0.8-1.5 s/page on the
/// UI isolate, both to end up with the same bytes. Keeping the raster raw
/// also removes the "decode to re-compress" step that used to throw away
/// Skia's row filters, which is why the old PDFs were larger than they needed
/// to be.
@immutable
class CapturedPage {
  /// Creates a captured page from an engine RGBA buffer.
  const CapturedPage({
    required this.rgba,
    required this.width,
    required this.height,
  });

  /// Raw RGBA pixels, row-major, 4 bytes per pixel, alpha last.
  ///
  /// Produced by `ui.Image.toByteData(format: ui.ImageByteFormat.rawRgba)`,
  /// which documents *premultiplied* alpha. That is irrelevant for exported
  /// pages — `PageSurface` paints an opaque cream rectangle over the whole
  /// page — but the transparent-page fallback in `pdf_image_stream.dart`
  /// honours it.
  final Uint8List rgba;

  /// Raster width in pixels.
  final int width;

  /// Raster height in pixels.
  final int height;

  /// Size of [rgba] in bytes.
  int get byteLength => width * height * 4;
}
