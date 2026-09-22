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
