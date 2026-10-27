import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/data/save_pdf.dart';
import 'package:honeyday/features/export/presentation/export_options_dialog.dart';
import 'package:honeyday/features/export/presentation/export_progress_dialog.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Whether an export is running anywhere in the app.
///
/// What: A plain listenable the viewer scaffolds bind their export button to.
/// Why: two app bars can offer the same export, and a second run started from
/// the other one would mount a second capture host and double the memory
/// ceiling. The service's own cancel flag cannot catch that race; a shared
/// flag can.
final ValueNotifier<bool> exportInProgress = ValueNotifier(false);

/// Runs the whole PDF export flow from an app bar action.
///
/// What: options dialog → progress dialog plus an independent capture tree
/// → export loop → save/share → cleanup, with an error snackbar on
/// failure (cancellation exits silently).
/// Why: Presentation-only orchestration in one place so both viewer scaffolds
/// share the exact same behavior.
Future<void> runAgendaExport(
  BuildContext context,
  WidgetRef ref, {
  required String agendaId,
  required int pagesCount,
}) async {
  if (exportInProgress.value) return;
  exportInProgress.value = true;

  OffscreenCaptureHost? host;
  ValueNotifier<ExportProgress>? progress;
  ValueNotifier<bool>? cancelled;
  try {
    final options = await ExportOptionsDialog.show(
      context,
      pageCount: pagesCount + 1,
    );
    if (options == null || !context.mounted) return;

    // Keep the exact root route so cleanup never pops an unrelated dialog.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final service = ref.read(exportServiceProvider);
    final progressNotifier = ValueNotifier(
      ExportProgress(
        phase: ExportPhase.capturing,
        completed: 0,
        total: pagesCount + 1,
      ),
    );
    progress = progressNotifier;
    final cancelFlag = ValueNotifier(false);
    cancelled = cancelFlag;
    host = OffscreenCaptureHost(context);
    final progressRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExportProgressDialog(
        progress: progressNotifier,
        onCancel: () => cancelFlag.value = true,
      ),
    );
    unawaited(rootNavigator.push<void>(progressRoute).then<void>((_) {}));

    PdfExportResult? result;
    Object? failure;
    try {
      result = await service.export(
        agendaId: agendaId,
        options: options,
        capture: host.capture,
        onProgress: (value) => progressNotifier.value = value,
        isCancelled: () => cancelFlag.value,
        // Drops the overlay and its layer tree as soon as the last page is in
        // hand, while the pool is still compressing in the background.
        onCapturesDone: host.dispose,
      );
    } on ExportCancelled {
      // User asked to stop — not an error.
    } on Object catch (error) {
      failure = error;
    } finally {
      host.dispose();
    }

    // Remove this exact route instead of popping whichever route happens to
    // be on top, then wait until its reverse transition has fully completed.
    try {
      if (rootNavigator.mounted && progressRoute.isActive) {
        rootNavigator.removeRoute(progressRoute);
      }
      await progressRoute.completed;
    } on Object catch (error) {
      debugPrint('Honeyday: progress dialog teardown failed: $error');
    }

    if (failure != null) {
      debugPrint('Honeyday: export failed: $failure');
      if (context.mounted) _reportExportError(context, failure);
      return;
    }
    if (result == null) return;

    // Saving needs no live `BuildContext`, and `savePdf` deletes the temp file
    // once the platform has taken it — so this runs even when the viewer was
    // popped while the export was in flight, instead of leaking the file.
    try {
      await savePdf(result.artifact, result.fileName);
    } on Object catch (error) {
      debugPrint('Honeyday: export save failed: $error');
      if (context.mounted) _reportExportError(context, error);
    }
  } on ExportCancelled {
    // Cancellation can also happen while the options/progress routes settle.
  } on Object catch (error) {
    debugPrint('Honeyday: export flow failed: $error');
    if (context.mounted) _reportExportError(context, error);
  } finally {
    host?.dispose();
    progress?.dispose();
    cancelled?.dispose();
    exportInProgress.value = false;
  }
}

/// Explains a failed export; a stalled capture gets its own actionable text
/// because "bring the window to the front" is the only thing that fixes it.
void _reportExportError(BuildContext context, Object error) {
  debugPrint('Honeyday: export error: $error');
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).exportError)),
  );
}
