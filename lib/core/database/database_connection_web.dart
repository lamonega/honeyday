import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:honeyday/core/database/persistent_storage_unavailable.dart';

/// Opens the browser database, rejecting a nonpersistent fallback.
DatabaseConnection openDatabaseConnection(String name) =>
    DatabaseConnection.delayed(_open(name));

Future<DatabaseConnection> _open(String name) async {
  try {
    final result = await WasmDatabase.open(
      databaseName: name,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    if (result.chosenImplementation != WasmStorageImplementation.inMemory) {
      return result.resolvedExecutor;
    }
    await result.resolvedExecutor.close();
    return _unavailable(const PersistentStorageUnavailable());
  } on Object catch (error) {
    return _unavailable(PersistentStorageUnavailable(error));
  }
}

// Resolve the deferred stream store even when the open fails. Queries then
// surface the error normally instead of leaving database streams loading.
DatabaseConnection _unavailable(PersistentStorageUnavailable error) =>
    DatabaseConnection(_UnavailableDatabase(error));

class _UnavailableDatabase extends LazyDatabase {
  _UnavailableDatabase(PersistentStorageUnavailable error)
    : super(() => throw error);

  @override
  Future<void> close() async {} // There is no underlying database to close.
}
