import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:honeyday/features/export/domain/export_phase.dart';

/// A raster big enough that compressing it is real work, small enough to keep
/// the suite quick: 248 × 341 px is 0.32 MP, 1/26 of an A4 page at 300 dpi.
CapturedPage syntheticPage([int seed = 0]) {
  const width = 248;
  const height = 341;
  final bytes = Uint8List(width * height * 4);
  // Deterministic, non-flat pixels: a flat page deflates to almost nothing and
  // the test would be measuring scheduling rather than real work.
  var state = (seed * 2654435761) & 0x7FFFFFFF;
  for (var i = 0; i < bytes.length; i += 4) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    bytes[i] = (state >> 16) & 0xFF;
    bytes[i + 1] = 0xF7;
    bytes[i + 2] = (state >> 8) & 0xFF;
    bytes[i + 3] = 0xFF;
  }
  return CapturedPage(rgba: bytes, width: width, height: height);
}

/// In-memory output, so the second test measures scheduling only and no real
/// file IO can perturb the frame count.
class _MemoryOutput implements PdfOutput {
  final List<Uint8List> _chunks = [];

  @override
  PdfSink get sink => _MemorySink(_chunks);

  @override
  Future<PdfArtifact> close() async {
    final total = _chunks.fold<int>(0, (sum, c) => sum + c.length);
    final joined = Uint8List(total);
    var at = 0;
    for (final chunk in _chunks) {
      joined.setRange(at, at + chunk.length, chunk);
      at += chunk.length;
    }
    return PdfArtifact.bytes(joined);
  }

  @override
  Future<void> discard() async => _chunks.clear();
}

class _MemorySink implements PdfSink {
  _MemorySink(this._chunks);

  final List<Uint8List> _chunks;

  @override
  Future<void> add(List<int> bytes) async =>
      _chunks.add(Uint8List.fromList(bytes));

  @override
  Future<int> get length async {
    var total = 0;
    for (final chunk in _chunks) {
      total += chunk.length;
    }
    return total;
  }
}

class _FakeRepository implements FullAgendaRepository {
  _FakeRepository(this.snapshot);

  final AgendaSnapshot? snapshot;

  @override
  Future<AgendaSnapshot?> getAgendaSnapshot(String agendaId) async => snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgendaSnapshot snapshotOf(int pageCount) {
  final now = DateTime(2026);
  final agenda = Agenda(
    id: 'a1',
    title: 'Responsive',
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

void main() {
  testWidgets('the UI isolate keeps serving the event loop while exporting', (
    tester,
  ) async {
    // The regression guard for the reported bug: "exportar el pdf tomó mucho
    // tiempo y congeló la aplicación de una forma extraña". The old pipeline
    // ran `PdfDocument.save()` on the UI isolate: per page that meant decoding
    // a PNG, two per-pixel loops and a zlib level 6 encode of ~25 MB, all
    // synchronous. The isolate could not answer a single timer, let alone
    // paint a frame.
    //
    // What is measured is availability, not speed: a *real* 1 ms timer must
    // keep firing for the entire run. The threshold is deliberately generous
    // — this asserts "the isolate was never blocked", not "the export is fast".
    const pages = 3;
    final service = PdfExportService(_FakeRepository(snapshotOf(pages)));
    final phases = <ExportPhase>[];

    var ticks = 0;
    Object? failure;
    var produced = false;

    // The probe is created *inside* `runAsync` on purpose: a timer started in
    // the test's zone is a fake timer that only advances with `pump()`, so it
    // would report zero no matter what the code under test did.
    await tester.runAsync(() async {
      final probe = Timer.periodic(
        const Duration(milliseconds: 1),
        (_) => ticks++,
      );
      try {
        final result = await service.export(
          agendaId: 'a1',
          options: const ExportOptions(),
          capture: (_, _) async => syntheticPage(pages),
          onProgress: (progress) => phases.add(progress.phase),
        );
        final path = result.artifact.path;
        produced = path != null
            ? File(path).lengthSync() > 0
            : (result.artifact.bytes?.isNotEmpty ?? false);
        if (path != null) await File(path).delete();
      } on Object catch (error) {
        failure = error;
      } finally {
        probe.cancel();
      }
    });

    expect(failure, isNull, reason: 'the export must succeed');
    expect(produced, isTrue, reason: 'a non-empty document must be produced');
    expect(
      phases,
      containsAll(<ExportPhase>[
        ExportPhase.capturing,
        ExportPhase.compressing,
        ExportPhase.writing,
      ]),
      reason: 'every phase must be reported so the dialog can show it',
    );
    expect(
      ticks,
      greaterThanOrEqualTo(5),
      reason:
          'the event loop went unserved while the PDF was being produced; '
          'the compression is back on the UI isolate',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('the frame pipeline keeps being pumped for the whole export', (
    tester,
  ) async {
    // The companion assertion with teeth: count how many times the export
    // yields so the binding can produce another frame. The old assembly ran in
    // a single synchronous block, so the run finished without ever yielding.
    //
    // The output is in memory here on purpose: real file IO would add its own
    // awaits and make the frame count a measurement of the filesystem.
    const pages = 3;
    final service = PdfExportService(_FakeRepository(snapshotOf(pages)));

    Object? failure;
    var done = false;
    var cancelled = false;
    late Future<void> run;
    // Create the export in the real async zone. Starting it in the test's
    // fake zone also creates its timers/worker callbacks there, so crossing
    // runAsync/pump boundaries can leave it waiting forever on CI.
    await tester.runAsync(() async {
      run = service
          .export(
            agendaId: 'a1',
            options: const ExportOptions(),
            capture: (_, _) async => syntheticPage(pages),
            createOutput: _MemoryOutput.new,
            isCancelled: () => cancelled,
          )
          .then<void>(
            (_) => done = true,
            onError: (Object error) {
              failure = error;
              done = true;
            },
          );
    });

    var pumped = 0;
    // The cap is a runaway guard, not an expectation: the real bar is the
    // `>= 5` assertion. Keeping it low also keeps the suite quick, because
    // every iteration costs a real 1 ms turn.
    while (!done && pumped < 2000) {
      await tester.pump();
      pumped++;
      // Hand the real event loop a turn so the worker isolates can answer.
      // `runAsync` is strictly serial, hence the await.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
    final completedWithinBudget = done;
    if (!done) cancelled = true;
    // Never await an unfinished export without a bound after the pump cap.
    await tester.runAsync(() => run.timeout(const Duration(seconds: 10)));

    expect(
      completedWithinBudget,
      isTrue,
      reason: 'export exceeded the pump budget',
    );
    expect(failure, isNull, reason: 'the export must succeed');
    expect(
      pumped,
      greaterThanOrEqualTo(5),
      reason:
          'the export finished after only $pumped frames; the frame '
          'pipeline is being starved again',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
