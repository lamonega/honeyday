import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/export/domain/export_formats.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

void main() {
  group('pdfPageBoxFor', () {
    test('maps each format to its paper size in points', () {
      expect(pdfPageBoxFor(PdfExportFormat.a4).width, 595.28);
      expect(pdfPageBoxFor(PdfExportFormat.a4).height, 841.89);
      expect(pdfPageBoxFor(PdfExportFormat.letter).width, 612);
      expect(pdfPageBoxFor(PdfExportFormat.letter).height, 792);
    });
  });

  group('fitCanvas', () {
    test('A4 fits by width with centered vertical margins at ~300 dpi', () {
      final fit = fitCanvas(pageBox: PdfPageBox.a4);

      expect(fit.left, closeTo(0, 0.01));
      expect(fit.top, closeTo(11.7, 0.1));
      expect(fit.width, closeTo(595.28, 0.01));
      expect(fit.height, lessThan(PdfPageBox.a4.height));
      expect(fit.pixelRatio, closeTo(3.1, 0.01));
    });

    test('Letter fits by height with side margins at exactly 3.0', () {
      final fit = fitCanvas(pageBox: PdfPageBox.letter);

      expect(fit.top, closeTo(0, 0.01));
      expect(fit.left, closeTo(18, 0.01));
      expect(fit.height, closeTo(792, 0.01));
      expect(fit.width, lessThan(PdfPageBox.letter.width));
      expect(fit.pixelRatio, closeTo(3.0, 0.001));
    });

    test('preserves the canvas aspect ratio', () {
      final fit = fitCanvas(pageBox: PdfPageBox.a4);

      expect(
        fit.width / fit.height,
        closeTo(kDefaultPageWidth / kDefaultPageHeight, 0.0001),
      );
    });

    test('honors a custom dpi', () {
      final fit = fitCanvas(pageBox: PdfPageBox.a4, dpi: 150);

      expect(fit.pixelRatio, closeTo(1.55, 0.01));
    });

    test('rasterizes an A4 page at 300 dpi to about 8.5 megapixels', () {
      // The number the whole memory budget is built on: 2480 × 3410 px of
      // RGBA is 33.8 MB, which is why the export is bounded to two pages in
      // flight instead of accumulating all of them.
      final fit = fitCanvas(pageBox: PdfPageBox.a4);
      final width = (kDefaultPageWidth * fit.pixelRatio).round();
      final height = (kDefaultPageHeight * fit.pixelRatio).round();

      expect(width, 2480);
      expect(height, 3410);
      expect(width * height / 1e6, closeTo(8.46, 0.05));
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
