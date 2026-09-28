import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

/// Export raster resolution (dots per inch) applied to every captured page.
const double kExportDpi = 300;

/// Points per inch in PDF user space.
const double kPointsPerInch = 72;

/// Media box of one exported PDF page, in PostScript points.
///
/// What: The `/MediaBox` rectangle written into every page object, i.e. the
/// physical sheet the content is fitted onto.
/// Why: The app writes the PDF itself, so it owns this table. The values are
/// the same ones `package:pdf` used, so the exported geometry is unchanged.
@immutable
class PdfPageBox {
  /// Creates a page box of [width] × [height] points.
  const PdfPageBox({required this.width, required this.height});

  /// ISO 216 A4 (210 × 297 mm).
  static const PdfPageBox a4 = PdfPageBox(width: 595.28, height: 841.89);

  /// ANSI/US Letter (8.5 × 11 in).
  static const PdfPageBox letter = PdfPageBox(width: 612, height: 792);

  /// Sheet width in points.
  final double width;

  /// Sheet height in points.
  final double height;
}

/// Maps [PdfExportFormat] to the concrete page box of the document.
///
/// Adding a size to the table (e.g. A5) only requires a new enum value here
/// and in the format dialog — fit math and capture stay generic.
PdfPageBox pdfPageBoxFor(PdfExportFormat format) => switch (format) {
  PdfExportFormat.a4 => PdfPageBox.a4,
  PdfExportFormat.letter => PdfPageBox.letter,
};

/// How the logical canvas fits onto one paper size.
@immutable
class CanvasFit {
  /// Creates a fit result in PDF points (except [pixelRatio]).
  const CanvasFit({
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    required this.pixelRatio,
  });

  /// Fitted content width in PDF points.
  final double width;

  /// Fitted content height in PDF points.
  final double height;

  /// Left margin of the contained content in PDF points.
  final double left;

  /// Top margin of the contained content in PDF points.
  final double top;

  /// `RenderRepaintBoundary.toImage` ratio yielding [kExportDpi] over the
  /// fitted size (≈ 3.10 on A4, 3.00 on Letter).
  final double pixelRatio;
}

/// Contain-fits the logical canvas into [pageBox], centered both ways.
///
/// What: Computes the fitted rect (points) and the capture [CanvasFit.pixelRatio]
/// needed to rasterize the canvas at [dpi] of printed resolution.
/// Why: Single source of truth shared by the PDF writer (where to place the
/// image) and the capture service (how many pixels to render).
CanvasFit fitCanvas({
  required PdfPageBox pageBox,
  double dpi = kExportDpi,
  Size canvasSize = const Size(kDefaultPageWidth, kDefaultPageHeight),
}) {
  final pointsPerUnit = math.min(
    pageBox.width / canvasSize.width,
    pageBox.height / canvasSize.height,
  );
  final width = canvasSize.width * pointsPerUnit;
  final height = canvasSize.height * pointsPerUnit;
  return CanvasFit(
    width: width,
    height: height,
    left: (pageBox.width - width) / 2,
    top: (pageBox.height - height) / 2,
    pixelRatio: pointsPerUnit * dpi / kPointsPerInch,
  );
}

/// Suggested on-disk name for an exported agenda PDF.
///
/// Strips characters that are illegal on common file systems and falls back
/// to `Agenda` when the title becomes empty after sanitizing.
String exportFileName(String agendaTitle) {
  final sanitized = agendaTitle
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final base = sanitized.isEmpty ? 'Agenda' : sanitized;
  return '$base — Honeyday.pdf';
}
