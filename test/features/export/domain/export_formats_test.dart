import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/domain/export_formats.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:pdf/pdf.dart';

void main() {
  group('fitCanvas', () {
    test('A4 fits by width with centered vertical margins at ~300 dpi', () {
      final fit = fitCanvas(pageFormat: PdfPageFormat.a4);

      expect(fit.left, closeTo(0, 0.01));
      expect(fit.top, closeTo(11.7, 0.1));
      expect(fit.width, closeTo(595.28, 0.01));
      expect(fit.height, lessThan(PdfPageFormat.a4.height));
      expect(fit.pixelRatio, closeTo(3.1, 0.01));
    });

    test('Letter fits by height with side margins at exactly 3.0', () {
      final fit = fitCanvas(pageFormat: PdfPageFormat.letter);

      expect(fit.top, closeTo(0, 0.01));
      expect(fit.left, closeTo(18, 0.01));
      expect(fit.height, closeTo(792, 0.01));
      expect(fit.width, lessThan(PdfPageFormat.letter.width));
      expect(fit.pixelRatio, closeTo(3.0, 0.001));
    });

    test('preserves the canvas aspect ratio', () {
      final fit = fitCanvas(pageFormat: PdfPageFormat.a4);

      expect(
        fit.width / fit.height,
        closeTo(kDefaultPageWidth / kDefaultPageHeight, 0.0001),
      );
    });

    test('honors a custom dpi', () {
      final fit = fitCanvas(pageFormat: PdfPageFormat.a4, dpi: 150);

      expect(fit.pixelRatio, closeTo(1.55, 0.01));
    });
  });

  group('exportFileName', () {
    test('keeps a clean title untouched', () {
      expect(exportFileName('Mi agenda'), 'Mi agenda — Honeyday.pdf');
    });

    test('strips characters illegal on common file systems', () {
      expect(exportFileName('a/b:c*?"<>| d'), 'abc d — Honeyday.pdf');
    });

    test('collapses whitespace and trims the edges', () {
      expect(
        exportFileName('  doble   espacio '),
        'doble espacio — Honeyday.pdf',
      );
    });

    test('falls back to Agenda when nothing remains', () {
      expect(exportFileName('???'), 'Agenda — Honeyday.pdf');
    });
  });

  group('PdfExportFormat.fileLabel', () {
    test('returns the locale-independent short names', () {
      expect(PdfExportFormat.a4.fileLabel, 'A4');
      expect(PdfExportFormat.letter.fileLabel, 'Letter');
    });
  });
}
