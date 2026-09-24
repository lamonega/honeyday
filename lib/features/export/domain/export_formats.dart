import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:pdf/pdf.dart';

/// Export raster resolution (dots per inch) applied to every captured page.
const double kExportDpi = 300;

/// Points per inch in PDF user space.
const double kPointsPerInch = 72;

/// Maps [PdfExportFormat] to the concrete [PdfPageFormat] of the document.
///
/// Adding a size to the table (e.g. A5) only requires a new enum value here
/// and in the format dialog — fit math and capture stay generic.
PdfPageFormat pdfPageFormatFor(PdfExportFormat format) => switch (format) {
  PdfExportFormat.a4 => PdfPageFormat.a4,
  PdfExportFormat.letter => PdfPageFormat.letter,
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

/// Contain-fits the logical canvas into [pageFormat], centered both ways.
///
/// What: Computes the fitted rect (points) and the capture [CanvasFit.pixelRatio]
/// needed to rasterize the canvas at [dpi] of printed resolution.
/// Why: Single source of truth shared by the PDF builder (where to place the
/// image) and the capture service (how many pixels to render).
CanvasFit fitCanvas({
  required PdfPageFormat pageFormat,
  double dpi = kExportDpi,
  Size canvasSize = const Size(kDefaultPageWidth, kDefaultPageHeight),
}) {
  final pointsPerUnit = math.min(
    pageFormat.width / canvasSize.width,
    pageFormat.height / canvasSize.height,
  );
  final width = canvasSize.width * pointsPerUnit;
  final height = canvasSize.height * pointsPerUnit;
  return CanvasFit(
    width: width,
    height: height,
    left: (pageFormat.width - width) / 2,
    top: (pageFormat.height - height) / 2,
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
