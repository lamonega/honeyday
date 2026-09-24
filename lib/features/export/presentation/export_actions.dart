import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/data/save_pdf.dart';
import 'package:honeyday/features/export/presentation/export_options_dialog.dart';
import 'package:honeyday/features/export/presentation/export_progress_dialog.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Runs the whole PDF export flow from an app bar action.
///
/// What: options dialog → opaque progress dialog over an offscreen capture
/// host → export loop → save/share → cleanup, with an error snackbar on
/// failure (cancellation exits silently).
/// Why: Presentation-only orchestration in one place so both viewer scaffolds
/// share the exact same behavior.
Future<void> runAgendaExport(
  BuildContext context,
  WidgetRef ref, {
  required String agendaId,
  required int pagesCount,
}) async {
  final options = await ExportOptionsDialog.show(
    context,
    pageCount: pagesCount + 1,
  );
  if (options == null || !context.mounted) return;

  // showDialog pushes on the root navigator; capturing it here (before any
  // await) is what lets us pop the progress dialog in every exit path.
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final service = ref.read(exportServiceProvider);
  final progress = ValueNotifier(
    ExportProgress(completed: 0, total: pagesCount + 1),
  );
  final cancelled = ValueNotifier(false);
  final host = OffscreenCaptureHost(context);
  final progressShown = ExportProgressDialog.show(
    context,
    progress: progress,
    onCancel: () => cancelled.value = true,
  );

  PdfExportResult? result;
  Object? failure;
  try {
    result = await service.export(
      agendaId: agendaId,
      options: options,
      capture: host.capture,
      onProgress: (completed, total) {
        progress.value = ExportProgress(completed: completed, total: total);
      },
      isCancelled: () => cancelled.value,
    );
  } on ExportCancelled {
    // User asked to stop — not an error.
  } on Object catch (error) {
    failure = error;
  } finally {
    host.dispose();
  }

  // Nothing else is pushed above the progress dialog while the export runs
  // (PopScope keeps system back from removing it early), so this pop is safe
  // on success, cancel and failure alike.
  if (rootNavigator.mounted) rootNavigator.pop();
  await progressShown;
  progress.dispose();
  cancelled.dispose();

  if (failure != null) {
    debugPrint('Honeyday: export failed: $failure');
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).exportError)),
      );
    }
    return;
  }
  if (result == null || !context.mounted) return;

  try {
    await savePdf(result.bytes, result.fileName);
  } on Object catch (error) {
    debugPrint('Honeyday: export save failed: $error');
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).exportError)),
      );
    }
  }
}
