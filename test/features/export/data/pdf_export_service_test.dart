import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';
import 'package:honeyday/features/agendas/presentation/widgets/notebook_cover.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:honeyday/features/export/domain/export_phase.dart';

/// A tiny opaque page, enough to exercise the pipeline without real pixels.
CapturedPage tinyPage([int seed = 0]) {
  final rgba = Uint8List(2 * 2 * 4);
  for (var i = 0; i < rgba.length; i += 4) {
    rgba[i] = (seed * 17 + i) % 256;
    rgba[i + 1] = 0xFD;
    rgba[i + 2] = 0xF7;
    rgba[i + 3] = 0xFF;
  }
  return CapturedPage(rgba: rgba, width: 2, height: 2);
}

/// Collects the document so the tests can assert on it.
class _MemoryOutput implements PdfOutput {  final List<Uint8List> _chunks = [];
  bool discarded = false;

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
  Future<void> discard() => Future<void>.sync(() {
    discarded = true;
    _chunks.clear();
  });

  Uint8List get bytes {
    final total = _chunks.fold<int>(0, (sum, c) => sum + c.length);
    final joined = Uint8List(total);
    var at = 0;
    for (final chunk in _chunks) {
      joined.setRange(at, at + chunk.length, chunk);
      at += chunk.length;
    }
    return joined;
  }
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

/// [PdfOutput] that records the moment it is closed.
class _CloseWatchingOutput extends _MemoryOutput {
  _CloseWatchingOutput(this.events);

  final List<String> events;

  @override
  Future<PdfArtifact> close() {
    events.add('closed');
    return super.close();
  }
}

/// Minimal repository stub: only `getAgendaSnapshot` is exercised.
class _FakeRepository implements FullAgendaRepository {
  _FakeRepository(this.snapshot);

  final AgendaSnapshot? snapshot;

  @override
  Future<AgendaSnapshot?> getAgendaSnapshot(String agendaId) async => snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgendaSnapshot buildSnapshot({String title = 'Mi agenda', int pageCount = 1}) {
  final now = DateTime(2026);
  final agenda = Agenda(
    id: 'a1',
    title: title,
    coverStyle: 'honey',
    pageCount: pageCount,
    createdAt: now,
    updatedAt: now,
  );
  final pages = [
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
  ];
  return AgendaSnapshot(agenda: agenda, pages: pages);
}

/// A pool that compresses inline, so the service tests need no isolates.
PdfWorkerPool inlinePool({int workers = 2}) => PdfWorkerPool(
  maxWorkers: workers,
  builder: (index) async => PdfCompressionWorker(
    compress: (request) async => Uint8List.fromList([request.pageIndex]),
  ),
);

void main() {
  test('captures the cover first, then every page, and builds the PDF',
      () async {
    final output = _MemoryOutput();
    final service = PdfExportService(
      _FakeRepository(buildSnapshot(pageCount: 2)),
    );
    final captured = <Widget>[];
    final ratios = <double>[];
    final progress = <ExportProgress>[];

    final result = await service.export(
      agendaId: 'a1',
      options: const ExportOptions(),
      capture: (page, pixelRatio) async {
        captured.add(page);
        ratios.add(pixelRatio);
        return tinyPage(captured.length);
      },
      onProgress: progress.add,
      pool: inlinePool(),
      createOutput: () => output,
    );

    expect(captured, hasLength(3));
    expect(result.fileName, 'Mi agenda — Honeyday.pdf');
    expect(result.artifact.bytes, isNotNull);
    expect(result.artifact.path, isNull);

    // One progress event per capture, then one per phase change.
    expect(
      progress.take(3).map((p) => (p.phase, p.completed, p.total)),
      [
        (ExportPhase.capturing, 1, 3),
        (ExportPhase.capturing, 2, 3),
        (ExportPhase.capturing, 3, 3),
      ],
    );
    expect(progress[3].phase, ExportPhase.compressing);
    expect(progress.last.phase, ExportPhase.writing);
    expect(progress.last.completed, 3);
    expect(progress.last.total, 3);

    // First capture is the cover: FittedBox at design size over NotebookCover.
    final cover = (captured.first as ClipRect).child! as FittedBox;
    expect((cover.child! as SizedBox).child, isA<NotebookCover>());

    // A4 at 300 dpi ⇒ pixelRatio ≈ 3.10 on every capture.
    expect(ratios, everyElement(closeTo(3.1, 0.01)));
  });

  test('writes a document with one page per captured page', () async {
    final service = PdfExportService(
      _FakeRepository(buildSnapshot(pageCount: 3)),
    );

    final result = await service.export(
      agendaId: 'a1',
      options: const ExportOptions(),
      capture: (_, _) async => tinyPage(),
      pool: inlinePool(),
      createOutput: _MemoryOutput.new,
    );

    final text = String.fromCharCodes(result.artifact.bytes!);
    expect(text.substring(0, 5), '%PDF-');
    expect(text, contains('/Count 4'));
    expect(text, contains('/MediaBox [0 0 595.28 841.89]'));
    expect(text, contains('/Title (Mi agenda)'));
  });

  test('Letter output carries the Letter media box', () async {
    final service = PdfExportService(_FakeRepository(buildSnapshot()));
    final output = _MemoryOutput();

    await service.export(
      agendaId: 'a1',
      options: const ExportOptions(format: PdfExportFormat.letter),
      capture: (_, _) async => tinyPage(),
      pool: inlinePool(),
      createOutput: () => output,
    );

    expect(
      String.fromCharCodes(output.bytes),
      contains('/MediaBox [0 0 612 792]'),
    );
  });

  test('throws ExportCancelled between pages when the user cancels', () async {
    var cancelled = false;
    var captures = 0;
    final service = PdfExportService(_FakeRepository(buildSnapshot()));

    await expectLater(
      service.export(
        agendaId: 'a1',
        options: const ExportOptions(),
        capture: (page, pixelRatio) async {
          captures++;
          cancelled = true; // cancel right after the first capture
          return tinyPage();
        },
        isCancelled: () => cancelled,
        pool: inlinePool(),
        createOutput: _MemoryOutput.new,
      ),
      throwsA(isA<ExportCancelled>()),
    );

    expect(captures, 1); // cover captured, page never started
  });

  test('cancels while waiting for the last streams to arrive', () async {
    // The phase that used to be uncancellable: the assembly.
    final output = _MemoryOutput();
    final service = PdfExportService(_FakeRepository(buildSnapshot()));
    var cancelled = false;
    final started = <int>[];

    final pool = PdfWorkerPool(
      maxWorkers: 1,
      builder: (index) async => PdfCompressionWorker(
        compress: (request) async {
          started.add(request.pageIndex);
          // Cancel as soon as the only page's compression is under way.
          cancelled = true;
          await Future<void>.delayed(Duration.zero);
          return Uint8List.fromList([request.pageIndex]);
        },
      ),
    );

    await expectLater(
      service.export(
        agendaId: 'a1',
        options: const ExportOptions(),
        capture: (_, _) async => tinyPage(),
        isCancelled: () => cancelled,
        pool: pool,
        createOutput: () => output,
      ),
      throwsA(isA<ExportCancelled>()),
    );

    expect(started, isNotEmpty);
    expect(
      output.discarded,
      isTrue,
      reason: 'a cancelled run must not leave a half-written document',
    );
  });

  test('releases the capture host before the document is closed', () async {
    // The host holds the last page's layer tree; dropping it as soon as the
    // final raster is in hand frees it while the pool is still compressing.
    final events = <String>[];
    final output = _CloseWatchingOutput(events);
    final service = PdfExportService(_FakeRepository(buildSnapshot(pageCount: 2)));

    await service.export(
      agendaId: 'a1',
      options: const ExportOptions(),
      capture: (_, _) async {
        events.add('capture');
        return tinyPage();
      },
      onCapturesDone: () => events.add('captures-done'),
      pool: inlinePool(),
      createOutput: () => output,
    );

    expect(
      events,
      [
        'capture',
        'capture',
        'capture',
        'captures-done',
        'closed',
      ],
      reason: 'the host must be released after the last page is rasterized and '
          'before the document is handed over',
    );
  });

  test('throws StateError when the agenda does not exist', () async {
    final service = PdfExportService(_FakeRepository(null));

    await expectLater(
      service.export(
        agendaId: 'missing',
        options: const ExportOptions(),
        capture: (_, _) async => tinyPage(),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('surfaces a worker failure and discards the document', () async {
    final output = _MemoryOutput();
    final service = PdfExportService(_FakeRepository(buildSnapshot()));

    final pool = PdfWorkerPool(
      maxWorkers: 1,
      builder: (index) async => PdfCompressionWorker(
        compress: (request) async => throw StateError('worker exploded'),
      ),
    );

    await expectLater(
      service.export(
        agendaId: 'a1',
        options: const ExportOptions(),
        capture: (_, _) async => tinyPage(),
        pool: pool,
        createOutput: () => output,
      ),
      throwsStateError,
    );
    expect(output.discarded, isTrue);
  });
}
