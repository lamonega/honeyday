import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:honeyday/features/backup/data/backup_document.dart';
import 'package:honeyday/features/backup/data/save_backup_io.dart'
    if (dart.library.js_interop) 'package:honeyday/features/backup/data/save_backup_web.dart';
import 'package:honeyday/features/backup/domain/backup_file_store.dart';

class PlatformBackupFileStore implements BackupFileStore {
  const PlatformBackupFileStore();

  @override
  Future<Uint8List?> pickBackup() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Honeyday backup',
          extensions: ['honeyday', 'json'],
          mimeTypes: ['application/json', 'application/octet-stream'],
          uniformTypeIdentifiers: ['public.json', 'public.data'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > BackupDocument.maxBytes) {
      throw const FormatException('Backup exceeds the 50 MiB limit.');
    }
    return await file.readAsBytes();
  }

  @override
  Future<bool> saveBackup(Uint8List bytes, String fileName) =>
      saveBackupFile(bytes, fileName);
}
