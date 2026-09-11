import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Operational modes for the Honeyday canvas.
///
/// What: Controls user interaction priorities across canvas layers.
/// Why: Separates content navigation (reading), handwriting/drawing (writing),
/// and modular widget layout customization (edit) to prevent gesture conflicts.
enum CanvasMode {
  /// Reading mode: Touch/pointer gestures flip pages horizontally.
  /// Drawing and element transformations are disabled.
  reading,

  /// Writing mode: Vector ink engine is active for stylus and finger note-taking.
  /// Modular widget containers are locked in place.
  writing,

  /// Edit mode: Modular widget containers show transform handles (drag, resize,
  /// rotate, delete) and magnetic snapping guides. Ink drawing is disabled.
  edit,
}

/// Available freehand brush tools in writing mode.
///
/// What: Discriminator for vector stroke generation profiles.
/// Why: Different tools require distinct pressure curves, opacity blends, and stroke widths.
enum InkToolType {
  /// Solid vector stroke with dynamic pressure variation and thinning.
  pen,

  /// Semi-transparent wide stroke that highlights underlying text and grids.
  highlighter,

  /// Inverted brush that detects and deletes intersected vector strokes.
  eraser;

  /// Returns the recommended default stroke width for this tool.
  double get defaultStrokeWidth {
    switch (this) {
      case InkToolType.pen:
        return 3;
      case InkToolType.highlighter:
        return 18;
      case InkToolType.eraser:
        return 20;
    }
  }
}

/// State container for the active ink drawing brush configuration.
///
/// What: Holds the current tool type, stroke color, and brush width.
/// Why: Provides a single source of truth for the freehand vector ink engine.
@immutable
class InkToolState {
  /// Constructs an [InkToolState].
  const InkToolState({
    this.tool = InkToolType.pen,
    this.color = const Color(0xFF1E293B),
    this.strokeWidth = 3,
  });

  /// Standard brand palette colors available in the writing toolbar.
  static const List<Color> defaultPalette = [
    Color(0xFF1E293B), // Ink Slate
    Color(0xFFD97706), // Honey Amber
    Color(0xFF2563EB), // Royal Blue
    Color(0xFFDC2626), // Crimson Red
    Color(0xFF16A34A), // Forest Green
  ];

  /// Currently active brush tool.
  final InkToolType tool;

  /// Active stroke color (applied to pen and highlighter).
  final Color color;

  /// Thickness of the stroke in virtual points.
  final double strokeWidth;

  /// Creates a copy of this state with specified fields replaced.
  InkToolState copyWith({
    InkToolType? tool,
    Color? color,
    double? strokeWidth,
  }) {
    return InkToolState(
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InkToolState &&
        other.tool == tool &&
        other.color == color &&
        other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(tool, color, strokeWidth);
}

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

/// Manages the active drawing tool, brush color, and stroke width.
///
/// What: Exposes methods to toggle between pen, highlighter, and eraser.
/// Why: Decouples the brush controls in the toolbar from the ink canvas painter.
class InkToolNotifier extends Notifier<InkToolState> {
  @override
  InkToolState build() => const InkToolState();

  /// Changes the active tool and automatically sets its recommended default width.
  void selectTool(InkToolType tool) {
    state = state.copyWith(tool: tool, strokeWidth: tool.defaultStrokeWidth);
  }

  /// Sets the active stroke color.
  void setColor(Color color) {
    state = state.copyWith(color: color);
  }

  /// Sets the stroke thickness.
  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }
}

/// Application provider for [InkToolState].
final inkToolProvider = NotifierProvider<InkToolNotifier, InkToolState>(
  InkToolNotifier.new,
);
