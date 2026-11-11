import 'package:drift/wasm.dart';

/// Rebuild when updating Drift so the worker matches the application's lockfile.
///
/// dart compile js -O4 --no-source-maps -o web/drift_worker.js tool/drift_worker.dart
void main() {
  WasmDatabase.workerMainForOpen();
}
