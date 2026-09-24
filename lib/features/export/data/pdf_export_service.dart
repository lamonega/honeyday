import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/export/data/export_page_builder.dart';
import 'package:honeyday/features/export/data/pdf_builder.dart';
import 'package:honeyday/features/export/domain/export_formats.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

/// Renders a page widget offscreen to PNG at the given pixel ratio.
///
/// Implemented by `OffscreenCaptureHost`; injected so the service stays
/// testable with a fake that records the widgets it receives.
typedef ExportCaptureFn = Future<Uint8List> Function(
  Widget page,
  double pixelRatio,
);

/// Raised when the user cancels an export between pages.
class ExportCancelled implements Exception {
  /// Creates the cancellation signal.
  const ExportCancelled();
}

/// Result of a successful export run: bytes plus suggested file name.
@immutable
class PdfExportResult {
  /// Creates a result with the generated document and its file name.
  const PdfExportResult({required this.bytes, required this.fileName});

  /// The generated PDF document.
  final Uint8List bytes;

  /// Suggested on-disk name (already sanitized, ends in `.pdf`).
  final String fileName;
}

/// Orchestrates a full-agenda PDF export.
///
/// What: Reads one consistent `AgendaSnapshot`, captures the cover plus every
/// page through `capture`, and assembles the PDF.
/// Why: Owns the loop/progress/cancel contract so presentation code only
/// drives dialogs and saving.
class PdfExportService {
  /// Creates a service backed by the agendas repository.
  PdfExportService(this._repository);

  final FullAgendaRepository _repository;

  /// Exports [agendaId] as a PDF honoring [options].
  ///
  /// [onProgress] reports `(completed, total)` after each capture, where
  /// total = pages + cover. [isCancelled] is polled between pages; once it
  /// returns `true` an [ExportCancelled] is thrown.
  Future<PdfExportResult> export({
    required String agendaId,
    required ExportOptions options,
    required ExportCaptureFn capture,
    void Function(int completed, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final cancelled = isCancelled ?? () => false;
    final snapshot = await _repository.getAgendaSnapshot(agendaId);
    if (snapshot == null) {
      throw StateError('Agenda $agendaId not found for export.');
    }

    final pageFormat = pdfPageFormatFor(options.format);
    final fit = fitCanvas(pageFormat: pageFormat);
    final total = snapshot.pages.length + 1; // cover first, then pages
    final images = <Uint8List>[];

    void checkCancelled() {
      if (cancelled()) throw const ExportCancelled();
    }

    checkCancelled();
    images.add(
      await capture(buildExportCover(snapshot.agenda), fit.pixelRatio),
    );
    onProgress?.call(images.length, total);

    for (final page in snapshot.pages) {
      checkCancelled();
      images.add(await capture(buildExportPage(page, options), fit.pixelRatio));
      onProgress?.call(images.length, total);
    }

    final bytes = await buildPdf(
      pagePngs: images,
      options: options,
      title: snapshot.agenda.title,
    );
    return PdfExportResult(
      bytes: bytes,
      fileName: exportFileName(snapshot.agenda.title),
    );
  }
}

/// Application-wide provider for [PdfExportService].
final exportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService(ref.watch(agendaRepositoryProvider));
});
