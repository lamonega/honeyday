import 'dart:typed_data';

/// Counts shown before importing an editable backup.
class BackupSummary {
  const BackupSummary({
    required this.agendas,
    required this.pages,
    required this.elements,
    required this.strokes,
  });

  final int agendas;
  final int pages;
  final int elements;
  final int strokes;
}

/// Portable backups of live agendas, including their editable content and ink.
///
/// Restore always creates independent copies with new identifiers. Existing
/// agendas are never replaced or deleted, even when importing the same file.
abstract interface class BackupRepository {
  Future<Uint8List> exportBackup();

  /// Validates the entire file without changing storage.
  /// Throws [FormatException] for malformed or unsupported backups.
  BackupSummary inspectBackup(Uint8List bytes);

  /// Validates again and restores all agendas in one transaction.
  /// Returns the number of agendas created; a failure creates none.
  Future<int> restoreBackup(Uint8List bytes);
}
