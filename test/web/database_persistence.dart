// Browser entry point for tool/test_web_persistence.mjs, not a Flutter unit test.
import 'dart:convert';
import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:web/web.dart' show window;

@JS('honeydayPersistenceReport')
external set _report(JSString value);

class _ProbeDatabase extends GeneratedDatabase {
  _ProbeDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
}

class _Rollback implements Exception {
  const _Rollback();
}

Future<_ProbeDatabase> _open(String name) async {
  final opened = await WasmDatabase.open(
    databaseName: name,
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  if (opened.chosenImplementation !=
      WasmStorageImplementation.sharedIndexedDb) {
    throw StateError(
      'This regression must use sharedIndexedDb, not '
      '${opened.chosenImplementation}. Serve without isolation headers.',
    );
  }
  return _ProbeDatabase(opened.resolvedExecutor);
}

Future<void> _createTable(_ProbeDatabase database) => database.customStatement(
  'CREATE TABLE IF NOT EXISTS entries (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
);

Future<void> _write(
  _ProbeDatabase transactions,
  _ProbeDatabase returning,
) async {
  // Schema writes happen outside transactions so the old worker persists an
  // empty table. No later write/read may accidentally flush the committed rows.
  await _createTable(transactions);
  await transactions.transaction(() async {
    await transactions.customStatement(
      "INSERT INTO entries VALUES (1, 'committed')",
    );
    try {
      await transactions.transaction(() async {
        await transactions.customStatement(
          "INSERT INTO entries VALUES (2, 'rolled back')",
        );
        throw const _Rollback();
      });
    } on _Rollback {
      // The enclosing transaction still commits its other writes.
    }
    await transactions.customStatement(
      "INSERT INTO entries VALUES (3, 'after savepoint')",
    );
  });

  // A separate database prevents this statement flushing the previous case.
  await _createTable(returning);
  final row = await returning
      .customSelect("INSERT INTO entries VALUES (7, 'returning') RETURNING id")
      .getSingle();
  if (row.read<int>('id') != 7) {
    throw StateError('RETURNING did not return its id');
  }
}

Future<void> _verify(_ProbeDatabase database, List<String> expected) async {
  final rows = await database
      .customSelect('SELECT value FROM entries ORDER BY id')
      .get();
  final values = rows.map((row) => row.read<String>('value')).toList();
  if (jsonEncode(values) != jsonEncode(expected)) {
    throw StateError('Persisted values: $values; expected: $expected');
  }
}

Future<void> main() async {
  try {
    final transactions = await _open('honeyday_regression_transactions');
    final returning = await _open('honeyday_regression_returning');
    final verifying =
        window.localStorage.getItem('honeyday_regression_phase') == 'verify';
    if (!verifying) {
      await _write(transactions, returning);
      window.localStorage.setItem('honeyday_regression_phase', 'verify');
      // Intentionally do not close either database. A clean close would flush
      // the old worker and conceal the data-loss bug. The driver reloads now.
      _report = jsonEncode({'phase': 'written', 'storage': 'sharedIndexedDb'})
          .toJS;
    } else {
      try {
        await _verify(transactions, ['committed', 'after savepoint']);
        await _verify(returning, ['returning']);
        _report = jsonEncode({
          'phase': 'verified',
          'storage': 'sharedIndexedDb',
        }).toJS;
      } finally {
        await transactions.close();
        await returning.close();
      }
    }
  } on Object catch (error, stack) {
    _report = jsonEncode({
      'phase': 'error',
      'error': '$error',
      'stack': '$stack',
    }).toJS;
  }
}
