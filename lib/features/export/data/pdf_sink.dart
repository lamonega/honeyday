import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Append-only byte destination for the PDF writer.
///
/// What: Accepts chunks and reports how many bytes have been written, which
/// is exactly the byte offset the cross-reference table records.
/// Why: The writer must never materialize the whole document before starting
/// to write it. On native platforms the PDF goes straight to a temp file, and
/// writing it incrementally is also what lets an image XObject be emitted the
/// moment its compressed stream arrives — so the 34 MB raster and the 25 MB
/// filtered rows are never all alive at the same time.
abstract interface class PdfSink {
  /// Appends [bytes] to the sink.
  Future<void> add(List<int> bytes);

  /// Total number of bytes written so far.
  Future<int> get length;
}

/// The finished PDF, in whichever form the platform can hand over.
@immutable
class PdfArtifact {
  /// Creates an in-memory artifact (the web path).
  const PdfArtifact.bytes(this.bytes) : path = null;

  /// Creates a file-backed artifact (the native path).
  const PdfArtifact.file(this.path) : bytes = null;

  /// Whole document in memory, or `null` for a file-backed artifact.
  final Uint8List? bytes;

  /// Absolute path of the temporary file, or `null` for an in-memory one.
  final String? path;

  /// Whether the document lives in a temp file rather than in memory.
  ///
  /// Why: Sharing a path avoids `XFile.fromData`, which copies the entire
  /// PDF a second time just to hand it to the platform — one of the two
  /// largest memory peaks of the old pipeline.
  bool get isFile => path != null;
}

/// A [PdfSink] plus the platform glue needed to finish the document.
abstract interface class PdfOutput {
  /// The sink the writer streams into.
  PdfSink get sink;

  /// Flushes and returns the finished document.
  Future<PdfArtifact> close();

  /// Abandons the document and releases whatever it holds.
  ///
  /// Called when an export is cancelled or fails: a half-written temp file is
  /// megabytes of garbage nobody will ever open, and a 20-page run the user
  /// aborted must not leave one behind on every attempt.
  Future<void> discard();
}
