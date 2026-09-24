import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Immutable progress snapshot rendered by [ExportProgressDialog].
@immutable
class ExportProgress {
  /// Creates a snapshot of a run with [completed] of [total] captures done.
  const ExportProgress({required this.completed, required this.total});

  /// Captures finished so far (cover counts as one).
  final int completed;

  /// Total captures of this run (pages + cover).
  final int total;
}

/// Non-dismissible progress dialog shown while pages are being captured.
///
/// What: Renders the current page progress plus a cancel button; [PopScope]
/// blocks system back so the route can't disappear while the offscreen
/// capture host is mounted underneath it.
/// Why: Exports take seconds and the giant capture must stay hidden behind
/// an opaque barrier.
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
  /// flags the session, the service throws `ExportCancelled` at the next
  /// page boundary.
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
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: value.total == 0
                      ? null
                      : value.completed / value.total,
                ),
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
}
