import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/export/data/export_page_builder.dart';
import 'package:honeyday/features/export/data/pdf_output.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/data/pdf_writer.dart';
import 'package:honeyday/features/export/domain/export_cancellation.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';
import 'package:honeyday/features/export/domain/export_formats.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:honeyday/features/export/domain/export_phase.dart';

export 'package:honeyday/features/export/domain/export_cancellation.dart'
    show ExportCancelled;

/// Rasterizes a page widget at the given pixel ratio.
///
/// What: returns the raw RGBA pixels plus their dimensions, *not* encoded
/// bytes — compression happens later, off the UI isolate.
/// Why: Implemented by `OffscreenCaptureHost`; injected so the service stays
/// testable with a fake that records the widgets it receives.
typedef ExportCaptureFn = Future<CapturedPage> Function(
  Widget page,
  double pixelRatio,
);

/// Result of a successful export run: the document plus a suggested name.
@immutable
class PdfExportResult {
  /// Creates a result from a finished document.
  const PdfExportResult({required this.artifact, required this.fileName});

  /// The generated PDF, as a temp file on native platforms and as bytes on
  /// the web. Exactly one of the two is set.
  final PdfArtifact artifact;

  /// Suggested on-disk name (already sanitized, ends in `.pdf`).
  final String fileName;
}

/// Orchestrates a full-agenda PDF export.
///
/// What: reads one consistent `AgendaSnapshot`, streams the cover and every
/// page through the capture callback into a worker pool, and writes the PDF into
/// [PdfOutput] incrementally as the compressed streams come back.
/// Why: Owns the loop / progress / cancel contract so presentation code only
/// drives dialogs and saving. All the CPU lives in [PdfWorkerPool], and the
/// writer only appends bytes, so the isolate that owns the frame pipeline
/// produces roughly one frame per page instead of blocking for tens of
/// seconds — the reported freeze.
class PdfExportService {
  /// Creates a service backed by the agendas repository.
  PdfExportService(this._repository);

  final FullAgendaRepository _repository;

  /// Exports [agendaId] as a PDF honoring [options].
  ///
  /// [onProgress] is called after every capture and once per phase change.
  /// [isCancelled] is polled between pages and while the last streams are
  /// being awaited; once it returns `true` the run stops with
  /// [ExportCancelled]. [onCapturesDone] is invoked as soon as the last page
  /// is rasterized, so the caller can release its independent capture tree
  /// while the pool finishes. [pool] and [createOutput] are test seams.
  Future<PdfExportResult> export({
    required String agendaId,
    required ExportOptions options,
    required ExportCaptureFn capture,
    void Function(ExportProgress progress)? onProgress,
    bool Function()? isCancelled,
    FutureOr<void> Function()? onCapturesDone,
    PdfWorkerPool? pool,
    PdfOutput Function()? createOutput,
  }) async {
    final cancelled = isCancelled ?? () => false;
    if (cancelled()) throw const ExportCancelled();
    final snapshot = await _repository.getAgendaSnapshot(agendaId);
    if (snapshot == null) {
      throw StateError('Agenda $agendaId not found for export.');
    }

    final pageBox = pdfPageBoxFor(options.format);
    final fit = fitCanvas(pageBox: pageBox);
    final total = snapshot.pages.length + 1; // cover first, then pages

    void checkCancelled() {
      if (cancelled()) throw const ExportCancelled();
    }

    checkCancelled();

    // Start conservatively: one captured raster is allowed in the pipeline
    // at a time until device profiling justifies more memory/concurrency.
    final workers = pool ?? PdfWorkerPool(maxWorkers: 1);
    final output = (createOutput ?? createPdfOutput)();
    final writer = PdfWriter(
      sink: output.sink,
      pageBox: pageBox,
      title: snapshot.agenda.title,
      pageCount: total,
    );
    // Only the image dimensions ride along; the rasters go to the pool and
    // are dropped there, never accumulated the way the old pipeline did.
    final dimensions = List<({int width, int height})?>.filled(total, null);

    workers.onStream = (pageIndex, flateStream) async {
      final size = dimensions[pageIndex]!;
      await writer.writeImage(
        pageIndex,
        width: size.width,
        height: size.height,
        flateStream: flateStream,
      );
    };

    try {
      await workers.start();
      await writer.writeHeader();

      for (var index = 0; index < total; index++) {
        checkCancelled();

        // Wait before allocating another full-resolution raster. The previous
        // compressed stream and PDF image write must have completed first.
        await workers.waitUntilIdle(isCancelled: cancelled);
        checkCancelled();
        await Future<void>.delayed(Duration.zero);

        final pageWidget = index == 0
            ? buildExportCover(snapshot.agenda)
            : buildExportPage(snapshot.pages[index - 1], options);
        final page = await capture(pageWidget, fit.pixelRatio);
        checkCancelled();
        dimensions[index] = (width: page.width, height: page.height);
        await writer.writePageSkeleton(index, fit: fit);
        await workers.submit(index, page, isCancelled: cancelled);
        onProgress?.call(
          ExportProgress(
            phase: ExportPhase.capturing,
            completed: index + 1,
            total: total,
          ),
        );
      }

      await onCapturesDone?.call();
      onProgress?.call(
        ExportProgress(
          phase: ExportPhase.compressing,
          completed: total,
          total: total,
        ),
      );
      checkCancelled();
      await workers.close(isCancelled: cancelled);

      onProgress?.call(
        ExportProgress(
          phase: ExportPhase.writing,
          completed: total,
          total: total,
        ),
      );
      await writer.finish();
      return PdfExportResult(
        artifact: await output.close(),
        fileName: exportFileName(snapshot.agenda.title),
      );
    } on Object {
      // A cancelled or failed run must not leave a half-written temp file nor
      // a pool of isolates behind. Every cleanup step is attempted, and the
      // original export error is rethrown below even if one of those steps
      // itself fails.
      await _discardAfterFailure(workers, output);
      rethrow;
    } finally {
      try {
        await workers.dispose();
      } on Object catch (error) {
        debugPrint('Honeyday: export worker cleanup failed: $error');
      }
    }
  }
}

Future<void> _discardAfterFailure(
  PdfWorkerPool workers,
  PdfOutput output,
) async {
  try {
    await workers.dispose(cancel: true);
  } on Object catch (error) {
    debugPrint('Honeyday: export worker cancellation failed: $error');
  }
  try {
    await output.discard();
  } on Object catch (error) {
    debugPrint('Honeyday: export output cleanup failed: $error');
  }
}

/// Application-wide provider for [PdfExportService].
final exportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService(ref.watch(agendaRepositoryProvider));
});
