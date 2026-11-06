@Tags(['benchmark'])
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';
import 'package:honeyday/features/export/data/pdf_compression.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/data/pdf_image_stream.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:honeyday/features/export/domain/export_phase.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Pages exported by the end-to-end run.
///
/// Override with `--dart-define=honeyday.benchPages=8` on machines without the
/// memory for a full 20-page agenda: the pipeline holds two 34 MB rasters plus
/// one per worker, so the ceiling is the machine's commit limit, not the code.
const int kBenchPages =
    int.fromEnvironment('honeyday.benchPages', defaultValue: 20);

/// Pages assembled by the `dc1e1de` baseline.
///
/// Lower than [kBenchPages] on purpose: the old pipeline holds a decoded
/// `ui.Image`-sized RGBA buffer *and* the RGB buffer *and* the deflated stream
/// per page, and the docs quote its per-page cost rather than its total.
const int kBenchBaselinePages =
    int.fromEnvironment('honeyday.benchBaselinePages', defaultValue: 5);

/// Workers used by the end-to-end run; 0 means "whatever the platform suggests".
const int kBenchWorkers = int.fromEnvironment('honeyday.benchWorkers');

/// Paper cream the exported pages sit on.
const Color _cream = Color(0xFFFFFDF7);

/// A4 at 300 dpi over the 800×1100 logical canvas.
const int _benchWidth = 2480;
const int _benchHeight = 3410;

/// Deterministic xorshift, so every run paints the same page and the numbers
/// stay comparable across commits.
class _Rng {
  _Rng(this._state);

  int _state;

  int next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return _state = x & 0xFFFFFFFF;
  }
}

/// Paints something with the same statistics as a real agenda page: a mostly
/// flat cream sheet with ruled lines, a header block and ink-like strokes.
///
/// What: A deterministic raster with a low-entropy background and
/// high-entropy strokes, i.e. the compressibility profile of a real page.
/// Why: A flat white sheet would understate the deflate cost and a pure noise
/// bitmap would overstate it; neither is a fair measurement.
void _paintPage(Canvas canvas, int width, int height) {
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = _cream,
  );

  final rng = _Rng(0x5EED);
  final ruled = Paint()
    ..color = const Color(0xFFB9A98C)
    ..strokeWidth = 2;

  const margin = 0.08;
  final left = width * margin;
  final right = width * (1 - margin);
  var y = height * 0.14;
  while (y < height * 0.94) {
    canvas.drawLine(Offset(left, y), Offset(right, y), ruled);
    y += height * 0.035;
  }

  canvas.drawRect(
    Rect.fromLTWH(left, height * 0.05, right - left, height * 0.05),
    Paint()..color = const Color(0xFF3F3428),
  );

  final ink = Paint()
    ..color = const Color(0xFF2B2B33)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (var i = 0; i < 900; i++) {
    final x0 = left + rng.next() % (right - left).round();
    final yy = height * 0.14 + rng.next() % (height * 0.8).round();
    canvas.drawPath(
      Path()
        ..moveTo(x0, yy)
        ..quadraticBezierTo(
          x0 + rng.next() % 90,
          yy + rng.next() % 40 - 20,
          x0 + rng.next() % 140,
          yy + rng.next() % 20 - 10,
        ),
      ink,
    );
  }
}

/// One rasterized page, in both shapes the two pipelines start from.
typedef _Raster = ({CapturedPage raw, Uint8List png});

/// Rasterizes one realistic page through the real Flutter engine.
///
/// Why both formats: the current pipeline starts from raw RGBA, and the
/// `dc1e1de` baseline starts from the PNG the old capture host encoded. Taking
/// one picture of both keeps the two measurements honest — identical pixels.
Future<_Raster> _engineRaster(int width, int height) async {
  final recorder = ui.PictureRecorder();
  _paintPage(
    Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ),
    width,
    height,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final raw = await image.toByteData(
      // Explicit for the same reason `OffscreenCaptureHost.rasterize` is:
      // this call is the pipeline's entry point, and the format it means is
      // load-bearing even while the SDK happens to default to it.
      // ignore: avoid_redundant_argument_values
      format: ui.ImageByteFormat.rawRgba,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return (
      raw: CapturedPage(
        rgba: raw!.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
        width: image.width,
        height: image.height,
      ),
      png: png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// Counts how many times the UI isolate was free to run a scheduled callback.
///
/// What: a 1 ms real-zone [Timer]. A blocked isolate fires zero.
/// Why: the reported bug is the app freezing, so the metric that matters is
/// the availability of the UI isolate, not CPU time.
///
/// The probe must be started *inside* `runAsync`: a timer created in the
/// test's own zone is a fake timer that only advances with `pump()`, and would
/// report zero no matter what the code under test did.
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

/// In-memory sink, so the benchmark measures the pipeline and not the disk.
class _MemoryOutput implements PdfOutput {
  final BytesBuilder _builder = BytesBuilder();
  int _length = 0;

  @override
  PdfSink get sink => _MemorySink(this);

  @override
  Future<PdfArtifact> close() async => PdfArtifact.bytes(_builder.toBytes());

  @override
  Future<void> discard() async => _builder.clear();

  int get length => _length;
}

class _MemorySink implements PdfSink {
  _MemorySink(this._output);

  final _MemoryOutput _output;

  @override
  Future<void> add(List<int> bytes) async {
    _output._builder.add(bytes);
    _output._length += bytes.length;
  }

  @override
  Future<int> get length async => _output._length;
}

class _FakeRepository implements FullAgendaRepository {
  _FakeRepository(this.snapshot);

  final AgendaSnapshot? snapshot;

  @override
  Future<AgendaSnapshot?> getAgendaSnapshot(
    String agendaId, {
    bool includeInk = true,
  }) async => snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [kBenchPages]-page agenda plus its cover, i.e. the plan's headline
/// scenario.
AgendaSnapshot _agendaOf(int pageCount) {
  final now = DateTime(2026);
  final agenda = Agenda(
    id: 'a1',
    title: 'Benchmark agenda',
    coverStyle: 'honey',
    pageCount: pageCount,
    createdAt: now,
    updatedAt: now,
  );
  return AgendaSnapshot(
    agenda: agenda,
    pages: [
      for (var i = 1; i <= pageCount; i++)
        AgendaPageSnapshot(
          page: AgendaPage(
            id: 'p$i',
            agendaId: 'a1',
            pageNumber: i,
            backgroundStyle: 'blank',
            createdAt: now,
            updatedAt: now,
          ),
          elements: const [],
        ),
    ],
  );
}

/// Renders one line of the docs table.
void _log(String line) => debugPrint('BENCH | $line');

/// Renders a size in KiB, the unit the size table is written in.
String _kib(int bytes) => '${(bytes / 1024).round()} KiB';

void main() {
  testWidgets(
    'after: raw capture, pooled compression, streaming writer',
    (tester) async {
      // ---- Input: what the capture stage produces. -------------------------
      final rasterStopwatch = Stopwatch()..start();
      final template = (await tester.runAsync<_Raster>(
        () => _engineRaster(_benchWidth, _benchHeight),
      ))!;
      rasterStopwatch.stop();
      final raster = rasterStopwatch.elapsedMilliseconds;
      _log(
        'raster           $raster ms '
        '(${template.raw.width}×${template.raw.height}, '
        '${template.raw.byteLength ~/ (1024 * 1024)} MiB rgba, '
        '${_kib(template.png.length)} png)',
      );

      // The export reuses one raster for every page: the capture cost is
      // reported separately, and both pipelines face identical input, so the
      // comparison stays honest without holding 21 × 34 MB in the heap.
      final service = PdfExportService(_FakeRepository(_agendaOf(kBenchPages)));
      final output = _MemoryOutput();
      final phases = <ExportPhase, int>{};

      final pool = kBenchWorkers == 0
          ? PdfWorkerPool(inFlightByteBudget: 2 * 34 * 1024 * 1024)
          : PdfWorkerPool(
              maxWorkers: kBenchWorkers,
              inFlightByteBudget: 2 * 34 * 1024 * 1024,
            );
      var peakInFlight = 0;
      Timer? watchInFlight;

      final total = Stopwatch()..start();
      final probe = _AvailabilityProbe();
      Object? failure;
      await tester.runAsync(() async {
        probe.start();
        // Started in here, not in the test body: a `Timer.periodic` built in the
        // test's own zone is a fake timer that only advances with `pump()`, so
        // it would never fire and would report a peak of zero.
        watchInFlight = Timer.periodic(const Duration(milliseconds: 2), (_) {
          if (pool.inFlightBytes > peakInFlight) {
            peakInFlight = pool.inFlightBytes;
          }
        });
        try {
          await service.export(
            agendaId: 'a1',
            options: const ExportOptions(),
            capture: (_, _) async => template.raw,
            onProgress: (progress) => phases.update(
              progress.phase,
              (value) => value + 1,
              ifAbsent: () => 1,
            ),
            pool: pool,
            createOutput: () => output,
          );
        } on Object catch (error) {
          failure = error;
        } finally {
          probe.stop();
          watchInFlight?.cancel();
        }
      });
      total.stop();

      expect(failure, isNull, reason: 'the export must succeed');

      // The cover is a full image too, so the per-image figure has to divide by
      // pages + 1 or every size comes out understated by a page.
      const images = kBenchPages + 1;

      _log('pages            $kBenchPages (+1 cover) at '
          '$_benchWidth×$_benchHeight');
      _log('workers          ${pool.maxWorkers}');
      _log('pipeline total   ${total.elapsedMilliseconds} ms '
          'for $kBenchPages pages');
      _log(
        'per page         '
        '${(total.elapsedMilliseconds / kBenchPages).round()} ms',
      );
      _log(
        'throughput       '
        '${(kBenchPages * 1000 / total.elapsedMilliseconds).toStringAsFixed(2)}'
        ' pages/s',
      );
      _log('document         ${output.length ~/ 1024} KiB '
          '(${_kib(output.length ~/ images)} per image, $images images)');
      _log('ui ticks         ${probe.ticks} during the whole run');
      _log(
        'peak in-flight   ${peakInFlight ~/ (1024 * 1024)} MiB of raster '
        '(budget ${pool.inFlightByteBudget ~/ (1024 * 1024)} MiB)',
      );
      _log(
        'phases           '
        '${phases.entries.map((e) => '${e.key.name}×${e.value}').join(', ')}',
      );
      _log(
        'end to end       '
        '${total.elapsedMilliseconds + raster * (kBenchPages + 1)} ms if all '
        '${kBenchPages + 1} pages were really rasterized',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );

  testWidgets(
    'before (dc1e1de): PNG + package:pdf, all on the UI isolate',
    (tester) async {
      final template = (await tester.runAsync<_Raster>(
        () => _engineRaster(_benchWidth, _benchHeight),
      ))!;

      final total = Stopwatch()..start();
      final probe = _AvailabilityProbe();
      Uint8List? document;
      Object? failure;
      await tester.runAsync(() async {
        probe.start();
        try {
          // Byte-for-byte the composition `pdf_builder.dart` did at dc1e1de:
          // one `pw.Page` per PNG, the page image contained and centered, the
          // whole thing handed to `document.save()`.
          final pdf = pw.Document(
            title: 'Benchmark agenda',
            creator: 'Honeyday',
          );
          for (var i = 0; i < kBenchBaselinePages; i++) {
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: pw.EdgeInsets.zero,
                build: (_) => pw.Container(
                  width: PdfPageFormat.a4.width,
                  height: PdfPageFormat.a4.height,
                  color: const PdfColor.fromInt(0xFFFFFDF7),
                  alignment: pw.Alignment.center,
                  child: pw.Image(
                    pw.MemoryImage(template.png),
                    width: 595.28 * 0.971,
                    height: 595.28 * 0.971 / (595.28 / 841.89),
                  ),
                ),
              ),
            );
          }
          document = await pdf.save();
        } on Object catch (error) {
          failure = error;
        } finally {
          probe.stop();
        }
      });
      total.stop();

      expect(failure, isNull, reason: 'the baseline must succeed');
      final bytes = document!;

      _log('BEFORE pages     $kBenchBaselinePages (+1 cover equivalent)');
      _log(
        'BEFORE total     ${total.elapsedMilliseconds} ms '
        '(${total.elapsedMilliseconds ~/ kBenchBaselinePages} ms per page)',
      );
      _log(
        'BEFORE document  ${_kib(bytes.length)} '
        '(${_kib(bytes.length ~/ kBenchBaselinePages)} per page)',
      );
      _log('BEFORE ui ticks  ${probe.ticks} during the whole run');
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );

  testWidgets(
    'page encoding: PNG filter x deflate level on one real page',
    (tester) async {
      final template = (await tester.runAsync<_Raster>(
        () => _engineRaster(_benchWidth, _benchHeight),
      ))!;
      final page = template.raw;

      // Strip alpha once; the filter choice is what varies below.
      final stripped = filterPageRows(page).rows;

      for (final level in [1, 3, 6]) {
        for (final entry in <({String name, Uint8List rows})>[
          (name: 'none', rows: stripped),
          (name: 'up', rows: _upFilter(stripped, page.width, page.height)),
        ]) {
          final stopwatch = Stopwatch()..start();
          final stream = deflatePdfStream(entry.rows, level: level);
          stopwatch.stop();
          _log(
            'filter ${entry.name.padRight(5)} level $level  '
            '${_kib(stream.length).padRight(9)} '
            '${stopwatch.elapsedMilliseconds.toString().padLeft(4)} ms',
          );
        }
      }

      // The shipped path, end to end, for reference.
      final shipped = Stopwatch()..start();
      final stream = encodePageImage(page, backgroundArgb: kExportCreamArgb);
      shipped.stop();
      _log(
        'shipped encodePageImage  ${_kib(stream.length).padRight(9)} '
        '${shipped.elapsedMilliseconds.toString().padLeft(4)} ms',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

/// Rewrites [rows] (filter-None layout, as produced by `filterPageRows`) into
/// the PNG "Up" layout the plan originally specified, so the two predictors can
/// be compared on identical pixels.
Uint8List _upFilter(Uint8List rows, int width, int height) {
  final stride = width * 3 + 1;
  final out = Uint8List.fromList(rows);
  for (var y = height - 1; y > 0; y--) {
    final current = y * stride;
    final previous = current - stride;
    out[current] = 2; // PNG filter "Up".
    for (var i = 1; i < stride; i++) {
      out[current + i] = (out[current + i] - out[previous + i]) & 0xFF;
    }
  }
  return out;
}
