import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_sink.dart';

/// Creates the web PDF destination: an in-memory byte builder.
///
/// What: `createPdfOutput` returns a [PdfOutput] whose `close` hands over the
/// accumulated bytes.
/// Why: The browser has no filesystem, and `savePdf` needs a `Blob`, so the
/// document must be in memory by then. Everything else about the pipeline
/// (raw capture, predictor, writer) is shared with the native build, so web
/// differs only in the destination and in having no isolates to compress on.
PdfOutput createPdfOutput() => _BytesOutput();

/// [PdfOutput] that accumulates the document in a [BytesBuilder].
class _BytesOutput implements PdfOutput {
  final _MemorySink _memory = _MemorySink();

  @override
  PdfSink get sink => _memory;

  @override
  Future<PdfArtifact> close() async => PdfArtifact.bytes(_memory.takeBytes());

  @override
  Future<void> discard() async => _memory.discard();
}

/// Appends chunks to a [BytesBuilder] and counts them.
class _MemorySink implements PdfSink {
  final BytesBuilder _builder = BytesBuilder(copy: false);
  int _length = 0;

  @override
  Future<void> add(List<int> bytes) async {
    _builder.add(bytes);
    _length += bytes.length;
  }

  @override
  Future<int> get length async => _length;

  /// The accumulated document; the builder can only be drained once.
  Uint8List takeBytes() => _builder.takeBytes();

  /// Drops everything accumulated so far.
  void discard() {
    _length = 0;
    _builder.clear();
  }
}
