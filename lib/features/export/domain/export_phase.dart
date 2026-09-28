import 'package:flutter/foundation.dart';

/// Coarse stage of an export run, reported to the progress dialog.
///
/// What: The three things the user actually waits for, in order: turning
/// widgets into pixels, squeezing those pixels, and emitting the file.
/// Why: The old dialog showed a determinate bar that stopped at 100% while
/// the assembler was still running for tens of seconds, so "working" and
/// "hung" looked identical. Naming the phase tells the user which of the
/// two slow parts is in progress.
enum ExportPhase {
  /// Rasterizing pages through the engine; [ExportProgress.completed] ticks.
  capturing,

  /// Waiting for the outstanding image streams to come back from the workers.
  compressing,

  /// Flushing the cross-reference table and trailer; the last, short step.
  writing,
}

/// Immutable progress snapshot of one export run.
@immutable
class ExportProgress {
  /// Creates a snapshot of a run with [completed] of [total] pages done.
  const ExportProgress({
    required this.phase,
    required this.completed,
    required this.total,
  });

  /// What the export is doing right now.
  final ExportPhase phase;

  /// Pages fully processed so far (the cover counts as one).
  final int completed;

  /// Total pages of this run (pages + cover).
  final int total;

  /// Whether the bar must animate instead of showing a ratio.
  ///
  /// Why: [completed] only moves while pages are rasterized, and the last two
  /// phases have no meaningful ratio — animating is the honest signal that
  /// the app is alive and busy.
  bool get isIndeterminate => phase != ExportPhase.writing;

  /// Determinate ratio for the writing phase, clamped to `0..1`.
  double get ratio {
    if (total <= 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }
}
