import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_compression.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

/// Paper cream (#FFFDF7) exported pages are composited over when they turn
/// out to be transparent.
///
/// Mirrors `PageSurface`, which paints the whole page with the paper colour
/// before anything else, and the `pg` operator of the PDF content stream.
const int kExportCreamArgb = 0xFFFFFDF7;

/// Bytes per source pixel (RGBA).
const int _bytesPerPixel = 4;

/// Bytes per output pixel (RGB).
const int _rgbBytesPerPixel = 3;

/// PNG filter type: None.
///
/// What every row of an exported page uses. See [encodePageImage] for why no
/// prediction is applied even though `/Predictor 15` is announced.
const int _filterNone = 0;

/// Self-describing rows of one page, plus whether it needed the alpha channel.
typedef FilteredPage = ({Uint8List rows, bool hadTransparency});

/// Turns a raw page into the exact bytes a PDF `/FlateDecode` stream holds.
///
/// What: RGB rows in the PNG filtered-row layout — one filter byte per row
/// followed by that row's pixels — with the alpha channel dropped, and
/// deflated. Every filter byte is [_filterNone], so the data is plain RGB.
///
/// Why no prediction: the design originally applied the PNG "Up" filter
/// (subtract the row above) on the theory that a sheet of paper makes every
/// row a copy of the previous one. Measured on real 2480×3410 pages, that is
/// backwards. A page is mostly a *flat* field, which deflate already crushes
/// for free, plus pen strokes, which the Up filter actively destroys by
/// turning each horizontal run of ink into scattered differences:
///
///   strokes/page   Up + level 1   None + level 1   None + level 6
///        40            175 KiB        154 KiB          62 KiB
///       200            344 KiB        250 KiB         154 KiB
///       900            996 KiB        617 KiB         505 KiB
///
/// (A4 at 300 dpi, 4 pages per row above. The 900-stroke row is what the
/// shipped benchmark paints, and its None/level-6 figure matches the old
/// pipeline's 504 KiB per page — the pipeline is back to size parity while
/// doing none of that work on the UI isolate.)
///
/// The filter byte is still emitted and `/Predictor 15` still announced, so
/// the row layout is self-describing and a reader never has to guess where a
/// row ends. It costs 3410 bytes per page, 0.02% of the stream.
Uint8List encodePageImage(
  CapturedPage page, {
  required int backgroundArgb,
}) {
  final first = filterPageRows(page);
  if (!first.hadTransparency) return deflatePdfStream(first.rows);

  // Transparent pages are a defence, not the norm (`PageSurface` fills the
  // whole sheet), so paying a second pass here keeps the common path at a
  // single traversal of 34 MB.
  final composited = filterPageRows(
    page,
    backgroundArgb: backgroundArgb,
  );
  return deflatePdfStream(composited.rows);
}

/// Same as [encodePageImage] but always compositing the page over a cream
/// background, ignoring whether the page happened to be opaque.
///
/// Exposed for the transparency tests, which need the composited bytes of a
/// page that [encodePageImage] would have taken the fast path for.
Uint8List encodePageImageWithCompositing(
  CapturedPage page, {
  required int creamR,
  required int creamG,
  required int creamB,
}) {
  final argb = (0xFF << 24) | (creamR << 16) | (creamG << 8) | creamB;
  return deflatePdfStream(
    filterPageRows(page, backgroundArgb: argb).rows,
  );
}

/// Drops the alpha channel and lays the page out as self-describing rows.
///
/// What: `[filter][RGB…]` per row. Without `backgroundArgb` the alpha is
/// discarded, which is only correct for opaque pages, and the returned
/// `hadTransparency` flag says whether that was the case. With
/// `backgroundArgb` every pixel is composited over that colour first, using
/// the premultiplied-alpha semantics documented for
/// `ui.ImageByteFormat.rawRgba`: `out = src + bg * (1 - a)`, computed as
/// `src + bg * (255 - a) / 255`.
///
/// Why one traversal: strip, composite and lay out the rows in a single pass,
/// so the hottest loop in the export touches each byte of the 34 MB raster
/// exactly once.
FilteredPage filterPageRows(CapturedPage page, {int? backgroundArgb}) {
  final rgba = page.rgba;
  final width = page.width;
  final height = page.height;
  final sourceRowBytes = width * _bytesPerPixel;
  final rows = Uint8List(height * (width * _rgbBytesPerPixel + 1));

  final background = backgroundArgb == null
      ? const <int>[0, 0, 0]
      : <int>[
          (backgroundArgb >> 16) & 0xFF, // ARGB: red
          (backgroundArgb >> 8) & 0xFF, // green
          backgroundArgb & 0xFF, // blue
        ];
  final composite = backgroundArgb != null;

  var hadTransparency = false;
  var source = 0;
  var target = 0;
  for (var y = 0; y < height; y++) {
    rows[target++] = _filterNone;
    for (var x = 0; x < width; x++) {
      final pixel = source + x * _bytesPerPixel;
      final alpha = rgba[pixel + 3];
      if (alpha != 0xFF) hadTransparency = true;

      for (var channel = 0; channel < _rgbBytesPerPixel; channel++) {
        var value = rgba[pixel + channel];
        if (composite && alpha != 0xFF) {
          value = (value + _blendOver(background[channel], alpha)) & 0xFF;
        }
        rows[target++] = value;
      }
    }
    source += sourceRowBytes;
  }

  return (rows: rows, hadTransparency: hadTransparency);
}

/// The background a premultiplied pixel lets through when composited with
/// "source over": `dst = src + bg * (1 - a)`, i.e. `bg * (255 - a) / 255`.
///
/// Why `(1 - a)`: `ui.ImageByteFormat.rawRgba` is documented as
/// *premultiplied*, so the source channels already carry their own alpha
/// weight; only the background has to be scaled by the transparency.
///
/// Why a real division and not `>> 8`: the shift truncates, and
/// `255 * 255 >> 8` is 254 — a fully transparent pixel would come out one
/// shade off the paper cream. This only runs for transparent pages, which
/// exported pages never are.
int _blendOver(int background, int alpha) =>
    background * (0xFF - alpha) ~/ 0xFF;

/// Bytes of [width] × [height] RGB rows plus one filter byte per row.
int filteredRowByteLength(int width, int height) =>
    height * (width * _rgbBytesPerPixel + 1);
