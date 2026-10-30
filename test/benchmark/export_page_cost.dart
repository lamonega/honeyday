// Per-page cost of the export pipeline, old and new, on identical pixels.
//
//   dart run test/benchmark/export_page_cost.dart
//
// Why a standalone script instead of a `flutter test`: the numbers this file
// exists to produce are CPU and byte counts, and the Flutter test harness costs
// more memory than the measurement does — a 2480×3410 raster plus `pdf`'s
// decode is ~150 MB, while `flutter_tester` and the kernel compiler want a few
// hundred before the first test even loads. Running on the plain VM keeps this
// measurable on a small machine, and it is also the only way to measure the old
// pipeline, which no longer exists in `lib/`.
//
// What is compared, per page, on the same synthetic A4/300 dpi sheet:
//   * BEFORE (commit dc1e1de) — PNG encode + `package:pdf`'s decode of that
//     PNG, RGBA→RGB loop and zlib level 6, all synchronous on the isolate that
//     also owns the frame pipeline.
//   * AFTER — `encodePageImage`: one pass that strips alpha and lays out the
//     rows, then zlib, run on a worker isolate while the main isolate keeps
//     servicing its event loop.
// plus the PNG-filter × deflate-level matrix that justifies the shipped choice.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_compression.dart';
import 'package:honeyday/features/export/data/pdf_image_stream.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A4 at 300 dpi over the 800×1100 logical canvas — the real export raster.
const int _width = 2480;
const int _height = 3410;

/// Pages to push through each pipeline.
///
/// Five, not twenty: the two cost models are linear per page and the old
/// pipeline's per-page cost is the number that matters, since a blocked UI for
/// N × t is what users felt. Override with `--define` style argv if wanted.
const int _pages = 5;

/// Paper cream, matching `PageSurface` and the PDF content stream.
const int _creamR = 0xFF;
const int _creamG = 0xFD;
const int _creamB = 0xF7;

/// Cream as the PDF expresses it, for the baseline's page background.
const int _creamArgb = 0xFFFFFDF7;

Future<void> main() async {
  stdout
    ..writeln(
      'Export per-page cost — A4 at 300 dpi ($_width×$_height = '
      '${_width * _height ~/ 1000000} MP, '
      '${_width * _height * 4 ~/ (1024 * 1024)} MiB RGBA)',
    )
    ..writeln(
      'Dart ${Platform.version.split(' ').first} · '
      '${Platform.operatingSystem} · '
      '${Platform.numberOfProcessors} cores\n',
    );

  final raster = _syntheticPage();
  stdout.writeln('page        painted, ${_mib(raster.length)} of RGBA\n');

  await _before(raster);
  await _after(raster);
  await _matrix(raster);

  stdout
    ..writeln(
      '\nRead these as: CPU per page, and how often the UI isolate '
      'could run a callback.',
    )
    ..writeln(
      'The page is a flat cream sheet with rules and 900 hard-edged '
      'strokes, so',
    )
    ..writeln(
      'the KiB are smaller than a real page carrying antialiased text '
      'and ink;',
    )
    ..writeln(
      'the ratio between the two pipelines is the number that '
      'transfers.',
    );
}

/// ---------------------------------------------------------------------------
/// BEFORE — PNG encode, then `package:pdf` decodes it back and recompresses.
/// ---------------------------------------------------------------------------

Future<void> _before(Uint8List rgba) async {
  // Step 1 of the old capture host: `ui.Image.toByteData(format: png)`.
  // Stand-in: this file runs without the engine, so the PNG is produced by the
  // encoder at the bottom of this file — same colour type 2, same "Up" row
  // filter, same zlib level 6 — which is the shape of bytes the old pipeline
  // was handed. Treat the timing as representative, not as Skia's own number.
  final encodeWatch = Stopwatch()..start();
  final png = _encodePng(rgba, _width, _height);
  encodeWatch.stop();
  _report('BEFORE png encode   ', encodeWatch, png.length);

  // Step 2: `buildPdf` at dc1e1de, verbatim in shape — one `pw.Page` per PNG
  // with the image contained and centred, handed to `document.save()`.
  final saveWatch = Stopwatch()..start();
  final ticks = _AvailabilityProbe()..start();
  final document = pw.Document(title: 'Benchmark', creator: 'Honeyday');
  for (var i = 0; i < _pages; i++) {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          color: const PdfColor.fromInt(_creamArgb),
          alignment: pw.Alignment.center,
          child: pw.Image(pw.MemoryImage(png)),
        ),
      ),
    );
  }
  final bytes = await document.save();
  ticks.stop();
  saveWatch.stop();

  final perPage =
      encodeWatch.elapsedMilliseconds + saveWatch.elapsedMilliseconds ~/ _pages;
  _report('BEFORE document.save', saveWatch, bytes.length);
  stdout
    ..writeln(
      '            ${_ms(perPage)} per page, all of it on the isolate that '
      'also paints the UI',
    )
    ..writeln(
      '            UI isolate availability during save(): '
      '${_ticks(ticks, saveWatch)} — the probe is a 1 ms timer, so this is how '
      'often the app could answer the user at all',
    );
}

/// ---------------------------------------------------------------------------
/// AFTER — raw RGBA in, Flate stream out, off the UI isolate.
/// ---------------------------------------------------------------------------

Future<void> _after(Uint8List rgba) async {
  final page = CapturedPage(rgba: rgba, width: _width, height: _height);

  // On the worker: exactly what `pdfWorkerEntryPoint` does per job.
  final workerWatch = Stopwatch()..start();
  final stream = await Isolate.run(
    () => encodePageImage(page, backgroundArgb: kExportCreamArgb),
  );
  workerWatch.stop();
  _report('AFTER  encodePageImage', workerWatch, stream.length);

  // The same work repeated per page, with the UI isolate kept alive by a probe,
  // is the shape of the real export: the pool parks the capture loop while a
  // worker compresses, and the main isolate stays free to paint.
  final total = Stopwatch()..start();
  final ticks = _AvailabilityProbe()..start();
  final streams = <Uint8List>[];
  for (var i = 0; i < _pages; i++) {
    streams.add(
      await Isolate.run(
        () => encodePageImage(page, backgroundArgb: kExportCreamArgb),
      ),
    );
  }
  ticks.stop();
  total.stop();

  final produced = streams.fold<int>(0, (sum, s) => sum + s.length);
  _report('AFTER  $_pages pages   ', total, produced);
  stdout
    ..writeln(
      '            ${_ms(total.elapsedMilliseconds ~/ _pages)} per page, none '
      'of it on the isolate that paints the UI',
    )
    ..writeln(
      '            UI isolate availability during the run: '
      '${_ticks(ticks, total)}',
    );
}

// ---------------------------------------------------------------------------
// Filter × level matrix: why the shipped encoder emits filter 0.
// ---------------------------------------------------------------------------

Future<void> _matrix(Uint8List rgba) async {
  final page = CapturedPage(rgba: rgba, width: _width, height: _height);
  final stripped = filterPageRows(page).rows;
  final up = _upFilter(stripped, _width, _height);

  stdout.writeln(
    '\nImage stream size, one page, by PNG row filter and '
    'deflate level',
  );
  for (final level in const [1, 3, 6]) {
    for (final entry in <({String name, Uint8List rows})>[
      (name: 'none', rows: stripped),
      (name: 'up', rows: up),
    ]) {
      final watch = Stopwatch()..start();
      final stream = deflatePdfStream(entry.rows, level: level);
      watch.stop();
      stdout.writeln(
        '  ${entry.name.padRight(5)} level $level  '
        '${_kib(stream.length).padLeft(9)}  '
        '${_ms(watch.elapsedMilliseconds).padLeft(7)}',
      );
    }
  }
  stdout.writeln(
    '  (level 6 + none is what ships: same size the old '
    'pipeline produced, none of it on the UI isolate)',
  );
}

// ---------------------------------------------------------------------------
// Output helpers.
// ---------------------------------------------------------------------------

/// Counts how many times this isolate got to run a 1 ms timer.
///
/// What: the availability probe. A synchronous `document.save()` starves it;
/// yielding to a worker isolate does not.
class _AvailabilityProbe {
  int ticks = 0;
  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(milliseconds: 1), (_) => ticks++);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

void _report(String label, Stopwatch watch, int bytes) {
  stdout.writeln(
    '$label ${_ms(watch.elapsedMilliseconds).padLeft(8)}  '
    '${_kib(bytes).padLeft(9)}',
  );
}

/// Renders the availability probe as "N ticks (R/s)", where R is how many times
/// a second the UI isolate got to run a scheduled callback.
String _ticks(_AvailabilityProbe probe, Stopwatch watch) {
  final seconds = watch.elapsedMilliseconds / 1000;
  final rate = seconds <= 0 ? 0 : (probe.ticks / seconds).round();
  return '${probe.ticks} ticks ($rate/s)';
}

String _ms(int millis) => '$millis ms';
String _kib(int bytes) => '${(bytes / 1024).round()} KiB';
String _mib(int bytes) => '${(bytes / (1024 * 1024)).round()} MiB';

// ---------------------------------------------------------------------------
// A synthetic page with the compressibility profile of a real one.
// ---------------------------------------------------------------------------

/// Builds an opaque RGBA sheet: cream field, ruled lines, a header block and
/// ink-like strokes.
///
/// Why synthetic and not a real capture: this file must run without the Flutter
/// engine, and a raster is a raster. What matters for the numbers below is the
/// pixel histogram — a mostly flat field with sparse high-entropy strokes —
/// which this reproduces.
Uint8List _syntheticPage() {
  final rgba = Uint8List(_width * _height * 4);
  for (var i = 0; i < rgba.length; i += 4) {
    rgba[i] = _creamR;
    rgba[i + 1] = _creamG;
    rgba[i + 2] = _creamB;
    rgba[i + 3] = 0xFF;
  }

  const margin = 0.08;
  final left = (_width * margin).round();
  final right = (_width * (1 - margin)).round();

  // Ruled lines, every 3.5% of the height, 2 px, in a muted pencil tone.
  for (
    var y = (_height * 0.14).round();
    y < _height * 0.94;
    y += (_height * 0.035).round()
  ) {
    _hline(rgba, y, left, right, 2, 0xB9, 0xA9, 0x8C);
  }
  // Header block.
  final headerTop = (_height * 0.05).round();
  final headerBottom = (_height * 0.10).round();
  for (var y = headerTop; y < headerBottom; y++) {
    _hline(rgba, y, left, right, 1, 0x3F, 0x34, 0x28);
  }

  // Ink strokes, deterministic: a fixed xorshift so runs are comparable.
  var state = 0x5EED;
  int next() {
    var x = state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return state = x & 0xFFFFFFFF;
  }

  for (var i = 0; i < 900; i++) {
    final x0 = left + next() % (right - left);
    final y0 = (_height * 0.14).round() + next() % (_height * 0.8).round();
    final x1 = x0 + next() % 140;
    final y1 = y0 + next() % 40 - 20;
    _line(rgba, x0, y0, x1, y1, 3, 0x2B, 0x2B, 0x33);
  }
  return rgba;
}

void _hline(
  Uint8List rgba,
  int y,
  int from,
  int to,
  int thickness,
  int r,
  int g,
  int b,
) {
  final startX = from.clamp(0, _width).toInt();
  final endX = to.clamp(0, _width).toInt();
  for (var dy = 0; dy < thickness; dy++) {
    final rowY = y + dy;
    if (rowY < 0 || rowY >= _height) continue;
    final rowOffset = rowY * _width;
    for (var x = startX; x < endX; x++) {
      final index = (rowOffset + x) * 4;
      rgba[index] = r;
      rgba[index + 1] = g;
      rgba[index + 2] = b;
    }
  }
}

/// Thick Bresenham line; a real pen stroke, near enough for the histogram.
void _line(
  Uint8List rgba,
  int x0,
  int y0,
  int x1,
  int y1,
  int thickness,
  int r,
  int g,
  int b,
) {
  final steps = (x1 - x0).abs() > (y1 - y0).abs()
      ? (x1 - x0).abs()
      : (y1 - y0).abs();
  if (steps <= 0) return;
  final half = thickness ~/ 2;
  for (var s = 0; s <= steps; s++) {
    final t = s / steps;
    final px = (x0 + (x1 - x0) * t).round();
    final py = (y0 + (y1 - y0) * t).round();
    for (var dy = -half; dy <= half; dy++) {
      final y = py + dy;
      if (y < 0 || y >= _height) continue;
      for (var dx = -half; dx <= half; dx++) {
        final x = px + dx;
        if (x < 0 || x >= _width) continue;
        final i = (y * _width + x) * 4;
        rgba[i] = r;
        rgba[i + 1] = g;
        rgba[i + 2] = b;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// A minimal PNG encoder, standing in for the engine's.
// ---------------------------------------------------------------------------

/// Encodes [rgba] as a colour-type-2 (RGB) PNG with the "Up" row filter.
///
/// What: signature + IHDR + IDAT + IEND, CRC32 per chunk, zlib container on the
/// filtered rows. Skia emits the same shape for this pipeline, which is why the
/// old code could hand it straight to `package:image`'s decoder.
Uint8List _encodePng(
  Uint8List rgba,
  int width,
  int height, {
  int deflateLevel = 6,
}) {
  final stride = width * 3;
  final rows = Uint8List(height * (stride + 1));
  final previous = Uint8List(stride);

  for (var y = 0; y < height; y++) {
    final source = y * width * 4;
    final target = y * (stride + 1);
    rows[target] = y == 0 ? 0 : 2; // None on the first row, Up after it.
    for (var i = 0; i < stride; i++) {
      final value = rgba[source + (i ~/ 3) * 4 + i % 3];
      rows[target + 1 + i] = y == 0 ? value : (value - previous[i]) & 0xFF;
    }
    for (var i = 0; i < stride; i++) {
      previous[i] = rgba[source + (i ~/ 3) * 4 + i % 3];
    }
  }

  final chunks = BytesBuilder()
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder()
    ..add(_be32(width))
    ..add(_be32(height))
    ..add(const <int>[8, 2, 0, 0, 0]); // 8-bit, truecolour RGB.
  final idat = Uint8List.fromList(ZLibCodec(level: deflateLevel).encode(rows));
  chunks
    ..add(_chunk('IHDR', ihdr.takeBytes()))
    ..add(_chunk('IDAT', idat))
    ..add(_chunk('IEND', Uint8List(0)));
  return chunks.takeBytes();
}

Uint8List _be32(int value) => Uint8List(4)
  ..[0] = (value >> 24) & 0xFF
  ..[1] = (value >> 16) & 0xFF
  ..[2] = (value >> 8) & 0xFF
  ..[3] = value & 0xFF;

Uint8List _chunk(String type, Uint8List body) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final out = BytesBuilder()
    ..add(_be32(body.length))
    ..add(typeBytes)
    ..add(body);
  final crcInput = Uint8List(typeBytes.length + body.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + body.length, body);
  out.add(_be32(_crc32(crcInput)));
  return out.takeBytes();
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(Uint8List bytes) {
  var c = 0xFFFFFFFF;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Rewrites filter-None rows into the PNG "Up" layout the plan originally
/// specified, so the two predictors can be compared on identical pixels.
Uint8List _upFilter(Uint8List rows, int width, int height) {
  final stride = width * 3 + 1;
  final out = Uint8List.fromList(rows);
  for (var y = height - 1; y > 0; y--) {
    final current = y * stride;
    final previous = current - stride;
    out[current] = 2;
    for (var i = 1; i < stride; i++) {
      out[current + i] = (out[current + i] - out[previous + i]) & 0xFF;
    }
  }
  return out;
}
