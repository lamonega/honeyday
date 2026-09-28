/// Raised when the user cancels an export.
///
/// What: The signal that a run must stop as soon as possible.
/// Why: Cancelling has to be honoured at *every* await — between pages, while
/// the pool drains, and while streams are being written — otherwise "cancel"
/// only took effect at the next page boundary and the assembly (the longest
/// phase) could not be interrupted at all.
class ExportCancelled implements Exception {
  /// Creates the cancellation signal.
  const ExportCancelled();

  @override
  String toString() => 'ExportCancelled()';
}
