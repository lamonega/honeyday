import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/data/pdf_image_stream.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/pdf_writer.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:honeyday/features/export/domain/export_formats.dart';

/// Collects everything the writer emits, for anatomy and offset assertions.
class _MemoryOutput implements PdfOutput {
  _MemoryOutput();

  final _MemorySink _memory = _MemorySink();

  @override
  PdfSink get sink => _memory;

  @override
  Future<PdfArtifact> close() async => PdfArtifact.bytes(_memory.bytes);

  @override
  Future<void> discard() async {}

  int get length => _memory.byteLength;

  Uint8List get bytes => _memory.bytes;
}

/// Keeps every chunk so a test can read the document as many times as it
/// likes (`BytesBuilder.toBytes` is destructive, which is a trap in a test).
class _MemorySink implements PdfSink {
  final List<Uint8List> _chunks = [];
  int byteLength = 0;

  @override
  Future<void> add(List<int> bytes) async {
    _chunks.add(Uint8List.fromList(bytes));
    byteLength += bytes.length;
  }

  @override
  Future<int> get length async => byteLength;

  Uint8List get bytes {
    final joined = Uint8List(byteLength);
    var at = 0;
    for (final chunk in _chunks) {
      joined.setRange(at, at + chunk.length, chunk);
      at += chunk.length;
    }
    return joined;
  }
}

/// A synthetic opaque page of [width] × [height] with a per-row gradient.
CapturedPage syntheticPage(int width, int height) {
  final quads = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      quads[i] = (x * 7 + y * 3) % 256;
      quads[i + 1] = (x * 5 + y * 11) % 256;
      quads[i + 2] = 0xF7;
      quads[i + 3] = 0xFF;
    }
  }
  return CapturedPage(rgba: quads, width: width, height: height);
}

/// Writes a complete document of [pageCount] pages on [pageBox].
Future<_MemoryOutput> _buildDocument({
  int pageCount = 2,
  String title = 'Mi agenda',
  PdfPageBox pageBox = PdfPageBox.a4,
  List<int>? order,
}) async {
  final output = _MemoryOutput();
  final writer = PdfWriter(
    sink: output.sink,
    pageBox: pageBox,
    title: title,
    pageCount: pageCount,
  );
  final fit = fitCanvas(pageBox: pageBox);
  final pages = [for (var i = 0; i < pageCount; i++) syntheticPage(4, 3)];

  await writer.writeHeader();
  for (var i = 0; i < pageCount; i++) {
    await writer.writePageSkeleton(i, fit: fit);
  }
  // Streams may arrive in any order; the default is page order.
  final delivery = order ?? [for (var i = 0; i < pageCount; i++) i];
  for (final index in delivery) {
    await writer.writeImage(
      index,
      width: pages[index].width,
      height: pages[index].height,
      flateStream: encodePageImage(
        pages[index],
        backgroundArgb: kExportCreamArgb,
      ),
    );
  }
  await writer.finish();
  return output;
}

/// The document as latin-1 text.
///
/// Why latin-1 and not utf-8: it maps every byte to exactly one code unit, so
/// a string index is also a byte index, which is what lets the assertions
/// below slice real streams out of the document. Binary stream bodies decode
/// to mojibake but are never matched against.
String documentText(Uint8List bytes) => latin1.decode(bytes);

/// Follows the cross-reference table and returns `{objectNumber: absolute
/// offset of the object}`.
///
/// This is the structural validation the old plan wanted from a PDF parser:
/// every offset the xref claims must actually land on `N 0 obj`, which is
/// what catches a mis-sized `/Length`, a missing object or a stale offset.
Map<int, int> resolveObjects(Uint8List bytes) {
  final text = documentText(bytes);
  final startXref = RegExp(
    r'startxref\s+(\d+)',
  ).firstMatch(text)!.group(1)!;
  final xrefOffset = int.parse(startXref);
  expect(
    text.substring(xrefOffset, xrefOffset + 4),
    'xref',
    reason: 'startxref must point at the xref table',
  );

  final header = RegExp(
    r'xref\s+0\s+(\d+)\s',
  ).firstMatch(text.substring(xrefOffset))!;
  final size = int.parse(header.group(1)!);
  final entriesAt = xrefOffset + header.end;

  final objects = <int, int>{};
  for (var number = 0; number < size; number++) {
    final entry = text.substring(
      entriesAt + number * 20,
      entriesAt + number * 20 + 20,
    );
    expect(entry.length, 20, reason: 'xref entries are exactly 20 bytes');
    expect(
      RegExp(r'^\d{10} \d{5} [nf] \n$').hasMatch(entry),
      isTrue,
      reason: 'malformed xref entry $number: ${jsonEncode(entry)}',
    );
    if (entry.endsWith('f \n')) continue;

    final offset = int.parse(entry.substring(0, 10));
    final match = RegExp(
      r'^(\d+) (\d+) obj\n',
    ).firstMatch(text.substring(offset));
    expect(
      match,
      isNotNull,
      reason: 'object $number offset $offset does not start an object',
    );
    expect(
      int.parse(match!.group(1)!),
      number,
      reason: 'object $number is stored under the wrong number',
    );
    objects[number] = offset;
  }
  return objects;
}

/// The bytes of a stream object, read exactly as its `/Length` says.
Uint8List streamBodyOf(Uint8List bytes, int objectNumber) {
  final text = documentText(bytes);
  final offset = resolveObjects(bytes)[objectNumber]!;
  final header = RegExp(
    r'/Length (\d+)',
  ).firstMatch(text.substring(offset))!;
  final declared = int.parse(header.group(1)!);
  final start = text.indexOf('stream\n', offset) + 'stream\n'.length;
  expect(
    declared,
    greaterThan(0),
    reason: 'object $objectNumber declares an empty stream',
  );
  return Uint8List.sublistView(bytes, start, start + declared);
}

void main() {
  group('anatomy', () {
    test('produces a complete, cross-referenceable document', () async {
      final output = await _buildDocument();
      final text = documentText(output.bytes);

      expect(text, startsWith('%PDF-1.4\n'));
      expect(text, contains('/Type /Catalog'));
      expect(text, contains('/Type /Pages'));
      expect(text, contains('/Count 2'));
      expect(text, contains('/Type /Page'));
      expect(text, contains('/Type /XObject'));
      expect(text, contains('/Subtype /Image'));
      expect(text, contains('/Predictor 15'));
      expect(text, contains('/Colors 3'));
      expect(text, contains('/Filter /FlateDecode'));
      expect(text, contains('/ColorSpace /DeviceRGB'));
      expect(text, contains('/BitsPerComponent 8'));
      expect(text, contains('/Title'));
      expect(text, contains('/Producer (Honeyday)'));
      expect(text, contains('/Creator (Honeyday)'));
      expect(text, contains('startxref'));
      expect(text, endsWith('%%EOF\n'));
      expect(RegExp('/Type /Page[^s]').allMatches(text), hasLength(2));
      expect(RegExp('/Type /XObject').allMatches(text), hasLength(2));
    });

    test('every xref offset lands on the object it claims', () async {
      final output = await _buildDocument(pageCount: 3);
      final objects = resolveObjects(output.bytes);

      // 3 fixed objects + 3 per page, numbered 1..12, all present.
      expect(objects.keys, [for (var i = 1; i <= 12; i++) i]);
    });

    test('declares its exact object count in the trailer', () async {
      for (final pages in [1, 2, 5]) {
        final output = await _buildDocument(pageCount: pages);
        final text = documentText(output.bytes);
        final size = RegExp(
          r'/Size (\d+)',
        ).firstMatch(text)!.group(1)!;
        expect(int.parse(size), 3 * pages + 4);
        expect(
          resolveObjects(output.bytes),
          hasLength(3 * pages + 3),
          reason: '$pages pages must have ${3 * pages + 3} objects',
        );
      }
    });

    test('each stream length matches the bytes actually written', () async {
      final output = await _buildDocument();
      final bytes = output.bytes;
      final text = documentText(bytes);
      final objects = resolveObjects(bytes);

      var checked = 0;
      for (final entry in objects.entries) {
        final offset = entry.value;
        // Bound the search to this object: its dictionary ends at the first
        // `endobj`, so an unbounded regex would happily match a `/Length`
        // belonging to a *later* object.
        final end = text.indexOf('endobj', offset);
        final extent = text.substring(offset, end);
        final streamAt = extent.indexOf('stream\n');
        if (streamAt == -1) continue;

        final declared = RegExp(
          r'/Length (\d+)',
        ).firstMatch(extent.substring(0, streamAt));
        expect(declared, isNotNull, reason: 'object ${entry.key} has a stream '
            'but no /Length');
        final length = int.parse(declared!.group(1)!);
        final start = offset + streamAt + 'stream\n'.length;
        // `/Length` never counts the EOL that must precede `endstream`.
        expect(
          text.startsWith('endstream', start + length) ||
              text.startsWith('\nendstream', start + length),
          isTrue,
          reason: 'object ${entry.key}: /Length $length does not end the '
              'stream',
        );
        checked++;
      }
      // One content stream and one image per page.
      expect(checked, 4);
    });

    test('every declared image stream inflates to the declared geometry',
        () async {
      final output = await _buildDocument();

      for (var index = 0; index < 2; index++) {
        final body = streamBodyOf(
          output.bytes,
          6 + 3 * index,
        );
        expect(
          ZLibCodec().decode(body).length,
          3 * (4 * 3 + 1),
          reason: 'image $index must decode to 3 filtered rows of 4 px',
        );
      }
    });
  });

  group('page geometry', () {
    test('A4 uses the A4 media box', () async {
      final output = await _buildDocument(pageCount: 1);

      expect(documentText(output.bytes), contains('/MediaBox [0 0 595.28 841.89]'));
    });

    test('Letter uses the Letter media box', () async {
      final output = await _buildDocument(
        pageCount: 1,
        pageBox: PdfPageBox.letter,
      );

      expect(documentText(output.bytes), contains('/MediaBox [0 0 612 792]'));
    });

    test('the content stream paints the cream field', () async {
      final output = await _buildDocument(pageCount: 1);
      final content = documentText(streamBodyOf(output.bytes, 5));

      // #FFFDF7 = (255, 253, 247) normalized to 0..1.
      expect(content, contains('1 0.992157 0.968627 rg'));
      expect(content, contains('0 0 595.28 841.89 re'));
      expect(content, contains('f\n'));
    });

    test('the image is placed with an unflipped cm matrix', () async {
      final output = await _buildDocument(pageCount: 1);
      final content = documentText(streamBodyOf(output.bytes, 5));
      final fit = fitCanvas(pageBox: PdfPageBox.a4);

      // 595.28 × 818.51 centered: left 0, top (841.89 - 818.51) / 2.
      expect(
        content,
        contains(
          '${_n(fit.width)} 0 0 ${_n(fit.height)} '
          '${_n(fit.left)} ${_n(fit.top)} cm',
        ),
      );
      // A flipped image would need a negative d or f component.
      expect(content, isNot(contains('1 0 0 -1')));
      expect(content, contains('/Im0 Do'));
    });

    test('the resource name matches the XObject name on every page', () async {
      final output = await _buildDocument(pageCount: 3);
      final text = documentText(output.bytes);

      for (var index = 0; index < 3; index++) {
        expect(text, contains('/Name /Im$index'));
        expect(text, contains('/XObject << /Im$index '));
        expect(
          documentText(streamBodyOf(output.bytes, 5 + 3 * index)),
          contains('/Im$index Do'),
        );
      }
    });

    test('image dimensions match the captured raster', () async {
      final output = await _buildDocument(pageCount: 1);
      final text = documentText(output.bytes);

      expect(text, contains('/Width 4 /Height 3'));
      expect(text, contains('/Columns 4'));
    });
  });

  group('titles', () {
    test('a plain ASCII title becomes a literal string', () async {
      final output = await _buildDocument(title: 'Trip 2026');
      expect(documentText(output.bytes), contains('/Title (Trip 2026)'));
    });

    test('parentheses and backslashes are kept out of a literal string',
        () async {
      final output = await _buildDocument(pageCount: 1, title: r'a(b)c\d');

      expect(documentText(output.bytes), contains(r'/Title (a\(b\)c\\d)'));
    });

    test('a non-ASCII title becomes a UTF-16BE hex string', () async {
      final output = await _buildDocument(title: 'Agenda año 2026');
      final text = documentText(output.bytes);

      expect(text, contains('/Title <FEFF'));
      // "Age" is 0041 0067 0065 in UTF-16BE.
      expect(text, contains('004100670065'));
    });
  });

  group('streaming', () {
    test('accepts image streams delivered in reverse order', () async {
      final output = await _buildDocument(pageCount: 3, order: [2, 1, 0]);
      final objects = resolveObjects(output.bytes);

      expect(objects.keys, [for (var i = 1; i <= 12; i++) i]);
      expect(documentText(output.bytes), contains('/Count 3'));
    });

    test('the sink sees the document grow monotonically', () async {
      final output = _MemoryOutput();
      final writer = PdfWriter(
        sink: output.sink,
        pageBox: PdfPageBox.a4,
        title: 'x',
        pageCount: 1,
      );

      var previous = 0;
      Future<void> track(Future<void> step) async {
        await step;
        final now = await output.sink.length;
        expect(now, greaterThan(previous));
        previous = now;
      }

      await track(writer.writeHeader());
      await track(writer.writePageSkeleton(0, fit: fitCanvas(pageBox: PdfPageBox.a4)));
      await track(
        writer.writeImage(
          0,
          width: 1,
          height: 1,
          flateStream: encodePageImage(
            syntheticPage(1, 1),
            backgroundArgb: kExportCreamArgb,
          ),
        ),
      );
      await track(writer.finish());

      expect(await output.sink.length, previous);
    });

    test('refuses to write after finish', () async {
      final output = _MemoryOutput();
      final writer = PdfWriter(
        sink: output.sink,
        pageBox: PdfPageBox.a4,
        title: 'x',
        pageCount: 1,
      );
      await writer.writeHeader();
      await writer.finish();

      expect(
        () => writer.writePageSkeleton(0, fit: fitCanvas(pageBox: PdfPageBox.a4)),
        throwsStateError,
      );
    });

    test('serializes writes entered from two places at once', () async {
      // The writer is entered from the capture loop (page skeletons) and from
      // the worker pool (images) at the same time. Both mutate one byte
      // offset, and the sink is equally sequential: `RandomAccessFile`
      // rejects a second in-flight operation outright. Without the write
      // queue this produced "An async operation is currently pending" and,
      // in the milder case, a cross-reference table full of wrong offsets.
      final output = _MemoryOutput();
      const pages = 4;
      final writer = PdfWriter(
        sink: output.sink,
        pageBox: PdfPageBox.a4,
        title: 'Concurrent',
        pageCount: pages,
      );
      final fit = fitCanvas(pageBox: PdfPageBox.a4);

      await writer.writeHeader();
      final skeletons = <Future<void>>[];
      for (var index = 0; index < pages; index++) {
        skeletons
          ..add(writer.writePageSkeleton(index, fit: fit))
          // Fire the image write without awaiting: this is what the pool does.
          ..add(
            writer.writeImage(
              index,
              width: 4,
              height: 3,
              flateStream: encodePageImage(
                syntheticPage(4, 3),
                backgroundArgb: kExportCreamArgb,
              ),
            ),
          );
      }
      await Future.wait(skeletons);
      await writer.finish();

      // The document is still structurally perfect: every xref offset points
      // at the object it claims.
      expect(resolveObjects(output.bytes), hasLength(3 * pages + 3));
      expect(documentText(output.bytes), contains('/Count $pages'));
    });
  });

  group('end to end', () {
    test('a captured page survives the whole data pipeline', () async {
      final output = _MemoryOutput();
      const pageBox = PdfPageBox.a4;
      final writer = PdfWriter(
        sink: output.sink,
        pageBox: pageBox,
        title: 'Round trip',
        pageCount: 1,
      );
      final fit = fitCanvas(pageBox: pageBox);
      final page = syntheticPage(4, 3);

      await writer.writeHeader();
      await writer.writePageSkeleton(0, fit: fit);
      await writer.writeImage(
        0,
        width: page.width,
        height: page.height,
        flateStream: encodePageImage(page, backgroundArgb: kExportCreamArgb),
      );
      await writer.finish();

      // Read the image stream back the way a reader would and compare pixels.
      final body = streamBodyOf(output.bytes, 6);
      final inflated = ZLibCodec().decode(body);
      expect(inflated.length, 3 * (4 * 3 + 1));
      // Row 0 is stored verbatim: filter byte 0, then the first row's RGB
      // (the alpha channel is gone — that is the whole point of the strip).
      expect(inflated[0], 0, reason: 'first row uses the None filter');
      expect(inflated.sublist(1, 13), <int>[
        0, 0, 0xF7, //
        7, 5, 0xF7,
        14, 10, 0xF7,
        21, 15, 0xF7,
      ]);
    });
  });
}

/// Mirrors the writer's number formatting for the content-stream assertion.
String _n(double value) {
  final text = value.toStringAsFixed(6);
  var end = text.length;
  while (end > 0 && text[end - 1] == '0') {
    end--;
  }
  if (end > 0 && text[end - 1] == '.') end--;
  return text.substring(0, end);
}
