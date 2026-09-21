/// Shared constants for the canvas feature.
///
/// Only constants used across 2+ canvas files are kept here.
/// All single-use constants live at the top of the file that consumes them.

// ---------------------------------------------------------------------------
// Shared canvas constants (used in 2+ files)
// ---------------------------------------------------------------------------

/// Default page margin used for snap anchors and fit-to-width operations.
/// Referenced by: page_view_canvas.dart, snapping.dart, page_surface.dart
const double kCanvasMargin = 24;

/// Default page height in points.
/// Referenced by: page_view_canvas.dart, transformable_box.dart
const double kDefaultPageHeight = 1100;

/// Maximum number of undo states retained for strokes and elements.
/// Referenced by: element_history.dart, ink_canvas.dart
const int kMaxUndoSize = 50;
