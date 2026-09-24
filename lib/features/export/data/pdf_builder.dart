import 'dart:typed_data';

import 'package:honeyday/features/export/domain/export_formats.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Paper cream field (#FFFDF7) painted behind the contained page image so
/// the format's margins continue the canvas paper instead of showing white.
const PdfColor _paperCream = PdfColor.fromInt(0xFFFFFDF7);

/// Assembles the captured PNG pages into the final PDF document bytes.
///
/// What: One PDF page per entry of [pagePngs], each image contained and
/// centered per [fitCanvas] for the chosen [PdfExportFormat], on a paper-cream
/// field; document metadata carries [title].
/// Why: Pure data → bytes, unit-testable without any widget tree.
Future<Uint8List> buildPdf({
  required List<Uint8List> pagePngs,
  required ExportOptions options,
  required String title,
}) {
  final pageFormat = pdfPageFormatFor(options.format);
  final fit = fitCanvas(pageFormat: pageFormat);
  final document = pw.Document(title: title, creator: 'Honeyday');

  for (final png in pagePngs) {
    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          width: pageFormat.width,
          height: pageFormat.height,
          color: _paperCream,
          alignment: pw.Alignment.center,
          child: pw.Image(
            pw.MemoryImage(png),
            width: fit.width,
            height: fit.height,
          ),
        ),
      ),
    );
  }

  return document.save();
}
