import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:share_plus/share_plus.dart';

const String _shareFolderPrefix = 'honeyday_share_';
const Duration _staleShareAge = Duration(minutes: 10);

/// Exposed for tests so stale-folder sweeps can be verified deterministically.
@visibleForTesting
DateTime Function() debugPdfShareClock = DateTime.now;

/// Share sheet on Android/iOS, native save dialog on macOS/Windows/Linux.
///
/// What: A file-backed artifact is shared by *path*, and a byte-backed one
/// (never produced natively) falls back to `XFile.fromData`. The temp file is
/// deleted once the platform has it.
/// Why: Sharing by path avoids loading a second PDF-sized buffer in Dart.
Future<void> savePdfImpl(PdfArtifact artifact, String fileName) async {
  final shareOnMobile = switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
  final path = artifact.path;
  if (path != null) {
    try {
      final file = File(path);
      if (shareOnMobile) {
        await _shareFile(file, fileName);
      } else {
        final location = await _getSaveLocation(fileName);
        if (location != null) await file.copy(location.path);
      }
    } finally {
      await _deleteQuietly(File(path));
    }
    return;
  }

  final bytes = artifact.bytes;
  if (bytes == null) {
    throw StateError('The exported PDF artifact is empty.');
  }
  final file = XFile.fromData(bytes, mimeType: 'application/pdf');
  if (shareOnMobile) {
    await _share(file, fileName, nameOverride: fileName);
  } else {
    final location = await _getSaveLocation(fileName);
    if (location != null) await file.saveTo(location.path);
  }
}

Future<FileSaveLocation?> _getSaveLocation(String fileName) => getSaveLocation(
  acceptedTypeGroups: const [
    XTypeGroup(label: 'PDF', extensions: ['pdf']),
  ],
  suggestedName: fileName,
);

Future<void> _shareFile(File file, String fileName) async {
  await _cleanupStaleShareFolders(file.parent);
  // share_plus uses the actual basename for a path-backed file and ignores
  // fileNameOverrides. Rename on the same filesystem without buffering the PDF
  // or clashing with another export of an agenda with the same title.
  final folder = await file.parent.createTemp(_shareFolderPrefix);
  final namedFile = File('${folder.path}${Platform.pathSeparator}$fileName');
  var keepStagedFile = false;
  try {
    await file.rename(namedFile.path);
    final result = await _share(
      XFile(namedFile.path, mimeType: 'application/pdf'),
      fileName,
    );
    // On iOS, share extensions may read the file asynchronously after the sheet
    // completes; leave it for the next lazy sweep unless the user dismissed it.
    keepStagedFile =
        defaultTargetPlatform == TargetPlatform.iOS &&
        result.status != ShareResultStatus.dismissed;
  } finally {
    if (!keepStagedFile) {
      await _deleteQuietly(namedFile);
      await _deleteQuietly(folder);
    }
  }
}

Future<ShareResult> _share(
  XFile file,
  String fileName, {
  String? nameOverride,
}) => SharePlus.instance.share(
  ShareParams(
    files: [file],
    fileNameOverrides: nameOverride == null ? null : [nameOverride],
    subject: fileName,
  ),
);

Future<void> _cleanupStaleShareFolders(Directory parent) async {
  final cutoff = debugPdfShareClock().subtract(_staleShareAge);
  try {
    await for (final entity in parent.list()) {
      if (entity is! Directory) continue;
      final name = entity.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .lastOrNull;
      if (name == null || !name.startsWith(_shareFolderPrefix)) continue;
      try {
        final stat = entity.statSync();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete(recursive: true);
        }
      } on FileSystemException {
        // Ignore races with the OS cleaning up temporary directories.
      }
    }
  } on FileSystemException {
    // Listing temp is best-effort; never block a user export.
  }
}

Future<void> _deleteQuietly(FileSystemEntity entity) async {
  try {
    await entity.delete();
  } on FileSystemException {
    // A leftover temp file is not worth failing an otherwise good export.
  }
}
