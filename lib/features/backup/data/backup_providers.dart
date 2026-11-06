import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/database/database_provider.dart';
import 'package:honeyday/features/backup/data/backup_file_store.dart';
import 'package:honeyday/features/backup/data/drift_backup_repository.dart';
import 'package:honeyday/features/backup/domain/backup_file_store.dart';
import 'package:honeyday/features/backup/domain/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return DriftBackupRepository(ref.watch(databaseProvider));
});

final backupFileStoreProvider = Provider<BackupFileStore>((ref) {
  return const PlatformBackupFileStore();
});
