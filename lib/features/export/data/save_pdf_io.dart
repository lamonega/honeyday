import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:share_plus/share_plus.dart';

/// Share sheet on Android/iOS/macOS, native save dialog on Windows/Linux.
///
/// What: A file-backed artifact is shared by *path*, and a byte-backed one
/// (never produced natively) falls back to `XFile.fromData`. The temp file is
/// deleted once the platform has it.
/// Why: `XFile.fromData` copies the whole PDF into a second buffer just to
/// hand it over — with a 10 MB document that was one of the two largest
/// memory peaks of the old export. A path costs nothing.
Future<void> savePdfImpl(PdfArtifact artifact, String fileName) async {
  final path = artifact.path;
  if (path != null) {
    try {
      await _saveFile(path, fileName);
    } finally {
      await _deleteQuietly(path);
    }
    return;
  }

  final bytes = artifact.bytes;
  if (bytes == null) {
    throw StateError('The exported PDF artifact is empty.');
  }
  await _saveBytes(bytes, fileName);
}

Future<void> _saveFile(String path, String fileName) async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf', name: fileName)],
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );
    return;
  }

  final location = await getSaveLocation(
    acceptedTypeGroups: const [XTypeGroup(label: 'PDF', extensions: ['pdf'])],
    suggestedName: fileName,
  );
  if (location == null) return; // user dismissed the dialog
  // Copy through a stream: the document can be far larger than the heap we
  // want to give it.
  await File(path).copy(location.path);
}

Future<void> _saveBytes(Uint8List bytes, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
      ],
      fileNameOverrides: [fileName],
      subject: fileName,
    ),
  );
}

Future<void> _deleteQuietly(String path) async {
  try {
    File(path).deleteSync();
  } on FileSystemException {
    // A leftover temp file is not worth failing an otherwise good export.
  }
}
