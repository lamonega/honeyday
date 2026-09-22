import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';

/// Manages the global [CanvasMode] state.
///
/// What: Switches between reading, writing, and edit modes.
/// Why: Synchronizes interaction behavior across all canvas layers.
class CanvasModeNotifier extends Notifier<CanvasMode> {
  @override
  CanvasMode build() => CanvasMode.writing;

  /// Updates the canvas mode to [mode].
  void setMode(CanvasMode mode) {
    if (state != mode) {
      state = mode;
    }
  }

  /// Convenience helper to switch to reading mode.
  void setReading() => state = CanvasMode.reading;

  /// Convenience helper to switch to writing mode.
  void setWriting() => state = CanvasMode.writing;

  /// Convenience helper to switch to edit mode.
  void setEdit() => state = CanvasMode.edit;
}

/// Application provider for [CanvasMode].
final canvasModeProvider = NotifierProvider<CanvasModeNotifier, CanvasMode>(
  CanvasModeNotifier.new,
);
