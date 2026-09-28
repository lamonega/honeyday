import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/domain/export_formats.dart';
import 'package:meta/meta.dart';

/// Version written in the `%PDF-` header.
///
/// Why: 1.4 is the lowest version that every reader understands, and the
/// document deliberately uses no object streams, so nothing needs 1.5.
const String kPdfVersion = '1.4';

/// `Producer`/`Creator` stamped on the document.
const String kPdfProducer = 'Honeyday';

/// Writes a minimal, valid PDF straight to a [PdfSink].
///
/// What: One `/Page` per captured page, each showing a single Flate-encoded
/// image XObject over a paper-cream rectangle, with a classic cross-reference
/// table and trailer. Objects are pre-numbered (1 catalog, 2 pages, 3 info,
/// then three objects per page) so a page skeleton and its image can be
/// emitted in any order — the xref maps number to offset, which is what makes
/// the streaming path possible.
///
/// Why: `package:pdf` cannot embed an already-compressed stream: its public
/// image factories all decode a PNG/JPEG and re-compress in pure Dart, and
/// `PdfImage`/`PdfObjectStream` are not exported. That decode-and-recompress
/// loop ran on the UI isolate and was the reported freeze. Writing the ~90
/// lines of PDF by hand removes it entirely.
class PdfWriter {
  /// Creates a writer for a document of [pageCount] pages on [pageBox].
  PdfWriter({
    required this.sink,
    required this.pageBox,
    required this.title,
    required this.pageCount,
  });

  /// Object number of the document catalog.
  static const int catalogObjectNumber = 1;

  /// Object number of the page tree root.
  static const int pagesObjectNumber = 2;

  /// Object number of the document information dictionary.
  static const int infoObjectNumber = 3;

  /// `/Type /Page` object number of the page at [index] (0-based).
  static int pageObjectNumber(int index) => 4 + 3 * index;

  /// Content-stream object number of the page at [index] (0-based).
  static int contentObjectNumber(int index) => 5 + 3 * index;

  /// Image XObject number of the page at [index] (0-based).
  static int imageObjectNumber(int index) => 6 + 3 * index;

  /// Highest object number in use, i.e. the trailer's `/Size` minus one.
  int get lastObjectNumber => 3 * pageCount + 3;

  /// Number of xref entries the trailer announces as `/Size`.
  int get objectCount => lastObjectNumber + 1;

  /// Where the document is written.
  final PdfSink sink;

  /// Media box stamped on every page.
  final PdfPageBox pageBox;

  /// Document title, escaped into the `/Info` dictionary.
  final String title;

  /// Number of pages, cover included.
  final int pageCount;

  final Map<int, int> _offsets = {};
  Future<void> _tail = Future<void>.value();
  int _offset = 0;
  bool _finished = false;

  /// Writes the file header and the binary-marker comment.
  ///
  /// What: `%PDF-1.4` followed by a comment line carrying four bytes above
  /// 0x7F, which tells tools the file is binary and that line endings inside
  /// the streams must not be translated.
  Future<void> writeHeader() => _serial(() async {
    await _emit(utf8.encode('%PDF-$kPdfVersion\n'));
    await _emit(const <int>[0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);
  });

  /// Writes the page object and its content stream for [index].
  ///
  /// What: A `/Type /Page` with the media box, a resource dictionary naming
  /// the image `/Im{index}`, and a content stream that fills the sheet with
  /// paper cream and then places the image with a `cm` matrix.
  ///
  /// The matrix is `{fit.width} 0 0 {fit.height} {fit.left} {fit.top} cm`,
  /// with **no** vertical flip: in PDF image space row 0 of the image is the
  /// *top* row of the unit square, so an unflipped matrix already draws the
  /// page upright. Adding `1 0 0 -1` is the classic way to ship every page
  /// upside down.
  Future<void> writePageSkeleton(int index, {required CanvasFit fit}) =>
      _serial(() async {
        _assertNotFinished();
        final imageNumber = imageObjectNumber(index);
        final content = _contentStream(index, fit);

        await _beginObject(pageObjectNumber(index));
        await _emit(
          utf8.encode(
            '<< /Type /Page /Parent $pagesObjectNumber 0 R '
            '/MediaBox [0 0 ${_number(pageBox.width)} '
            '${_number(pageBox.height)}] '
            '/Resources << /XObject << /Im$index $imageNumber 0 R >> '
            '/ProcSet [/PDF /ImageB /ImageC] >> '
            '/Contents ${contentObjectNumber(index)} 0 R >>\nendobj\n',
          ),
        );

        await _beginObject(contentObjectNumber(index));
        final body = utf8.encode(content);
        await _emit(utf8.encode('<< /Length ${body.length} >>\nstream\n'));
        await _emit(body);
        await _emit(utf8.encode('endstream\nendobj\n'));
      });

  /// Writes the image XObject of the page at [index].
  ///
  /// What: A `/DeviceRGB` 8-bit image whose `/FlateDecode` stream is
  /// [flateStream] as produced by `encodePageImage`, announced with
  /// `/Predictor 15` so the reader undoes the "Up" row filter.
  /// Why: the image is written the moment its stream arrives, so the writer
  /// never holds more than one compressed page.
  Future<void> writeImage(
    int index, {
    required int width,
    required int height,
    required Uint8List flateStream,
  }) =>
      _serial(() async {
        _assertNotFinished();
        await _beginObject(imageObjectNumber(index));
        await _emit(
          utf8.encode(
            '<< /Type /XObject /Subtype /Image /Name /Im$index '
            '/Width $width /Height $height '
            '/ColorSpace /DeviceRGB /BitsPerComponent 8 '
            '/Filter /FlateDecode '
            '/DecodeParms << /Predictor 15 /Colors 3 '
            '/BitsPerComponent 8 /Columns $width >> '
            '/Length ${flateStream.length} >>\n'
            'stream\n',
          ),
        );
        await _emit(flateStream);
        await _emit(utf8.encode('\nendstream\nendobj\n'));
      });

  /// Writes the catalog, the page tree, the info dictionary, the
  /// cross-reference table and the trailer.
  ///
  /// What: A classic 20-byte-per-entry xref table (not an xref stream, so the
  /// document stays readable by PDF 1.4 tools), a trailer naming the catalog
  /// and the info dictionary, `startxref` and `%%EOF`.
  Future<void> finish() => _serial(() async {
    _assertNotFinished();
    _finished = true;

    final kids = [
      for (var index = 0; index < pageCount; index++)
        '${pageObjectNumber(index)} 0 R',
    ].join(' ');

    await _beginObject(catalogObjectNumber);
    await _emit(
      utf8.encode(
        '<< /Type /Catalog /Pages $pagesObjectNumber 0 R >>\nendobj\n',
      ),
    );

    await _beginObject(pagesObjectNumber);
    await _emit(
      utf8.encode(
        '<< /Type /Pages /Count $pageCount /Kids [$kids] >>\nendobj\n',
      ),
    );

    await _beginObject(infoObjectNumber);
    await _emit(
      utf8.encode(
        '<< /Title ${_textString(title)} '
        '/Producer ${_textString(kPdfProducer)} '
        '/Creator ${_textString(kPdfProducer)} >>\nendobj\n',
      ),
    );

    final xrefOffset = _offset;
    final size = objectCount;
    final table = StringBuffer('xref\n0 $size\n0000000000 65535 f \n');
    for (var number = 1; number < size; number++) {
      final offset = _offsets[number];
      table.write(
        offset == null
            ? '0000000000 65535 f \n'
            : '${offset.toString().padLeft(10, '0')} 00000 n \n',
      );
    }
    await _emit(utf8.encode(table.toString()));
    await _emit(
      utf8.encode(
        'trailer\n'
        '<< /Size $size /Root $catalogObjectNumber 0 R '
        '/Info $infoObjectNumber 0 R >>\n'
        'startxref\n$xrefOffset\n%%EOF\n',
      ),
    );
  });

  /// Byte offset each object was written at; exposed for the writer tests.
  @visibleForTesting
  Map<int, int> get writtenObjectOffsets => Map.unmodifiable(_offsets);

  /// Runs [body] as the next step of the writer's single write queue.
  ///
  /// Why the queue is not optional: the writer is entered from two places at
  /// once — the capture loop, which writes each page skeleton as soon as the
  /// page is rasterized, and the worker pool, which writes each image as its
  /// stream comes back. Both mutate the same byte offset, and the sink is
  /// equally sequential: `RandomAccessFile` rejects a second in-flight
  /// operation outright. Serializing here is what keeps the cross-reference
  /// table honest instead of producing a document that opens but renders
  /// garbage.
  Future<void> _serial(Future<void> Function() body) {
    final previous = _tail;
    final gate = Completer<void>();
    _tail = gate.future;
    return previous.then((_) async {
      try {
        await body();
      } finally {
        gate.complete();
      }
    });
  }

  String _contentStream(int index, CanvasFit fit) {
    final cream = _creamColorComponents;
    return 'q\n'
        '${_number(cream.r)} ${_number(cream.g)} ${_number(cream.b)} rg\n'
        '0 0 ${_number(pageBox.width)} ${_number(pageBox.height)} re\n'
        'f\n'
        'Q\n'
        'q\n'
        '${_number(fit.width)} 0 0 ${_number(fit.height)} '
        '${_number(fit.left)} ${_number(fit.top)} cm\n'
        '/Im$index Do\n'
        'Q\n';
  }

  void _assertNotFinished() {
    if (_finished) {
      throw StateError('The PDF writer was already finished.');
    }
  }

  Future<void> _beginObject(int number) async {
    _offsets[number] = _offset;
    await _emit(utf8.encode('$number 0 obj\n'));
  }

  Future<void> _emit(List<int> bytes) async {
    await sink.add(bytes);
    _offset += bytes.length;
  }
}

/// Red, green and blue of the paper cream (#FFFDF7) in 0..1 PDF units.
({double r, double g, double b}) get _creamColorComponents => (
  r: 255 / 255,
  g: 253 / 255,
  b: 247 / 255,
);

/// Formats [value] for a PDF number: fixed point, no exponent, no trailing
/// zeros, so `841.89` never comes out as `841.8899999999999`.
String _number(double value) {
  final text = value.toStringAsFixed(6);
  var end = text.length;
  while (end > 0 && text[end - 1] == '0') {
    end--;
  }
  if (end > 0 && text[end - 1] == '.') end--;
  final trimmed = text.substring(0, end);
  // `-0.000000` is a legal number but reads as garbage; normalize it.
  if (trimmed == '-0') return '0';
  return trimmed;
}

/// Encodes [value] as a PDF text string.
///
/// What: A literal `(…)` string for plain ASCII, with backslashes and
/// parentheses escaped; a UTF-16BE hex string with a byte-order mark for
/// anything else.
/// Why: Agenda titles are user input in any language. A literal string with
/// raw UTF-8 bytes is not what a PDF reader expects, and an unbalanced
/// parenthesis in a title would truncate the dictionary.
String _textString(String value) {
  final isAscii = value.codeUnits.every(
    (unit) => unit >= 0x20 && unit < 0x7F,
  );
  if (isAscii) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    return '($escaped)';
  }

  final units = <int>[];
  for (final rune in value.runes) {
    if (rune <= 0xFFFF) {
      units.add(rune);
    } else {
      final offset = rune - 0x10000;
      units
        ..add(0xD800 + (offset >> 10))
        ..add(0xDC00 + (offset & 0x3FF));
    }
  }

  final hex = StringBuffer();
  for (final unit in units) {
    hex
      ..write((unit >> 8).toRadixString(16).padLeft(2, '0'))
      ..write((unit & 0xFF).toRadixString(16).padLeft(2, '0'));
  }
  return '<FEFF$hex>';
}
