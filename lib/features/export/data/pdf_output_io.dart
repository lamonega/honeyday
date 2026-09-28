import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';

/// Creates the native PDF destination: a temp file written as we go.
///
/// What: `createPdfOutput` opens a unique file under the system temp
/// directory and returns a [PdfOutput] whose `close` is just a flush.
/// Why: The previous pipeline held the finished PDF in a `Uint8List` and then
/// copied all of it again through `XFile.fromData` to share it. Writing
/// straight to a file removes both the duplicate and the peak: the largest
/// single object alive during an export becomes one page raster.
PdfOutput createPdfOutput() => FilePdfOutput();

/// [PdfOutput] backed by a temp file on disk.
class FilePdfOutput implements PdfOutput {
  /// Opens (and truncates) a fresh temp file to stream the document into.
  factory FilePdfOutput() {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'honeyday_export_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    final handle = file.openSync(mode: FileMode.write);
    return FilePdfOutput._(file, handle, _FileSink(handle));
  }

  FilePdfOutput._(this._file, this._handle, this.sink);

  final File _file;
  final RandomAccessFile _handle;

  @override
  final PdfSink sink;

  @override
  Future<PdfArtifact> close() async {
    await _handle.flush();
    await _handle.close();
    return PdfArtifact.file(_file.path);
  }

  @override
  Future<void> discard() async {
    try {
      await _handle.close();
    } on FileSystemException catch (error) {
      // Already closed, or never opened: the delete below is what matters.
      debugPrint('Honeyday: temp export already closed: $error');
    }
    try {
      await _file.delete();
    } on FileSystemException catch (error) {
      debugPrint('Honeyday: could not delete the temp export: $error');
    }
  }
}

/// Writes chunks straight to the open temp file.
class _FileSink implements PdfSink {
  _FileSink(this._handle);

  final RandomAccessFile _handle;

  @override
  Future<void> add(List<int> bytes) async {
    await _handle.writeFrom(bytes);
  }

  @override
  Future<int> get length => _handle.length();
}
