import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/backup/data/backup_providers.dart';
import 'package:honeyday/features/backup/domain/backup_file_store.dart';
import 'package:honeyday/features/backup/domain/backup_repository.dart';

final backupControllerProvider = Provider<BackupController>((ref) {
  return BackupController(
    ref.watch(backupRepositoryProvider),
    ref.watch(backupFileStoreProvider),
  );
});

/// A validated preview. The file cannot be changed between preview and restore.
class PreparedBackup {
  PreparedBackup._(this._bytes, this.summary);
  final Uint8List _bytes;
  final BackupSummary summary;
}

class BackupController {
  const BackupController(this._repository, this._files);

  final BackupRepository _repository;
  final BackupFileStore _files;

  Future<bool> exportBackup() async {
    final bytes = await _repository.exportBackup();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    return await _files.saveBackup(bytes, 'honeyday-$stamp.honeyday');
  }

  Future<PreparedBackup?> prepareRestore() async {
    final selected = await _files.pickBackup();
    if (selected == null) return null;
    final bytes = Uint8List.fromList(selected).asUnmodifiableView();
    return PreparedBackup._(bytes, _repository.inspectBackup(bytes));
  }

  Future<int> restore(PreparedBackup backup) =>
      _repository.restoreBackup(backup._bytes);
}
