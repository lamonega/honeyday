import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:honeyday/features/export/domain/export_phase.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

export 'package:honeyday/features/export/domain/export_phase.dart'
    show ExportPhase, ExportProgress;

/// Non-dismissible progress dialog shown while the PDF is being produced.
///
/// What: Renders the current phase plus a progress bar, and a cancel button
/// that is never disabled; [PopScope] blocks system back so the route can't
/// disappear while the offscreen capture host is mounted underneath it.
/// Why: exports take seconds and the giant capture must stay hidden behind an
/// opaque barrier, but a *static* bar over a silent 30-second stall is
/// indistinguishable from a hang. The bar animates while the pipeline is busy
/// compressing, and the phase label says which step is running.
class ExportProgressDialog extends StatelessWidget {
  /// Creates the dialog widget (use [show] to open it as a route).
  const ExportProgressDialog({
    required this.progress,
    required this.onCancel,
    super.key,
  });

  /// Opens the progress dialog on the root navigator.
  ///
  /// The caller pops it explicitly when the export run ends; [onCancel] only
  /// flags the session, and the service turns that into `ExportCancelled` at
  /// its next checkpoint.
  static Future<void> show(
    BuildContext context, {
    required ValueListenable<ExportProgress> progress,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ExportProgressDialog(progress: progress, onCancel: onCancel),
    );
  }

  /// Live progress of the running export.
  final ValueListenable<ExportProgress> progress;

  /// Flagged when the user taps cancel.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.exportProgressTitle),
        content: ValueListenableBuilder<ExportProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.exportProgressPage(value.completed, value.total)),
                const SizedBox(height: 4),
                Text(
                  _phaseLabel(l10n, value.phase),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                // `null` makes the bar animate, which is the visible proof
                // that the UI isolate is still alive during the slow phases.
                LinearProgressIndicator(value: value.isIndeterminate ? null : value.ratio),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: onCancel, child: Text(l10n.commonCancel)),
        ],
      ),
    );
  }

  String _phaseLabel(AppLocalizations l10n, ExportPhase phase) =>
      switch (phase) {
        ExportPhase.capturing => l10n.exportPhaseCapturing,
        ExportPhase.compressing => l10n.exportPhaseCompressing,
        ExportPhase.writing => l10n.exportPhaseWriting,
      };
}
