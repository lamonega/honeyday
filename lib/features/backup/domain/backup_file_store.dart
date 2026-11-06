import 'dart:typed_data';

/// Platform dialogs/downloads are replaceable independently of persistence.
abstract interface class BackupFileStore {
  /// Returns null when the user cancels. Implementations reject oversized files
  /// before loading them into memory where the platform exposes their length.
  Future<Uint8List?> pickBackup();

  /// Returns false when the user cancels the save/share dialog.
  Future<bool> saveBackup(Uint8List bytes, String fileName);
}
