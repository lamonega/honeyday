import 'package:drift/wasm.dart';

/// Rebuild when updating Drift so the worker matches the application's lockfile.
///
/// dart run tool/build_drift_worker.dart
void main() {
  WasmDatabase.workerMainForOpen();
}
