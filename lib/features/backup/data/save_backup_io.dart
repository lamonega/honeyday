import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

const String _backupShareFolderPrefix = 'honeyday_backup_share_';
const Duration _staleBackupShareAge = Duration(minutes: 10);

/// Exposed for tests so staged backup files can be isolated from system temp.
@visibleForTesting
Directory Function() debugBackupShareTempDirectory = () => Directory.systemTemp;

/// Exposed for tests so stale-folder sweeps can be verified deterministically.
@visibleForTesting
DateTime Function() debugBackupShareClock = DateTime.now;

Future<bool> saveBackupFile(Uint8List bytes, String fileName) async {
  final shareOnMobile = switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
  if (shareOnMobile) {
    return await _shareBackup(bytes, fileName);
  }
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Honeyday backup', extensions: ['honeyday']),
    ],
  );
  if (location == null) return false;
  await File(location.path).writeAsBytes(bytes, flush: true);
  return true;
}

Future<bool> _shareBackup(Uint8List bytes, String fileName) async {
  final parent = debugBackupShareTempDirectory();
  await _cleanupStaleBackupShareFolders(parent);
  final folder = await parent.createTemp(_backupShareFolderPrefix);
  final stagedFile = File('${folder.path}${Platform.pathSeparator}$fileName');
  var keepStagedFile = false;
  try {
    await stagedFile.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(stagedFile.path, mimeType: 'application/json')],
        subject: fileName,
      ),
    );
    // On iOS, share extensions may read the file asynchronously after the sheet
    // completes; leave it for the next lazy sweep unless the user dismissed it.
    keepStagedFile =
        defaultTargetPlatform == TargetPlatform.iOS &&
        result.status != ShareResultStatus.dismissed;
    return result.status != ShareResultStatus.dismissed;
  } finally {
    if (!keepStagedFile) {
      await _deleteQuietly(stagedFile);
      await _deleteQuietly(folder);
    }
  }
}

Future<void> _cleanupStaleBackupShareFolders(Directory parent) async {
  final cutoff = debugBackupShareClock().subtract(_staleBackupShareAge);
  try {
    await for (final entity in parent.list()) {
      if (entity is! Directory) continue;
      final name = entity.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .lastOrNull;
      if (name == null || !name.startsWith(_backupShareFolderPrefix)) continue;
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
    // A leftover temp file is not worth failing an otherwise good backup.
  }
}
