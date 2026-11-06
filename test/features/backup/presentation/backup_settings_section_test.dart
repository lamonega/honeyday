import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/backup/data/backup_providers.dart';
import 'package:honeyday/features/backup/domain/backup_file_store.dart';
import 'package:honeyday/features/backup/domain/backup_repository.dart';
import 'package:honeyday/features/backup/presentation/backup_controller.dart';
import 'package:honeyday/features/backup/presentation/backup_settings_section.dart';

import '../../../helpers/pump_app.dart';

class _Repository implements BackupRepository {
  BackupSummary summary = const BackupSummary(
    agendas: 1,
    pages: 2,
    elements: 3,
    strokes: 4,
  );
  int exports = 0;
  int restores = 0;
  Uint8List? restoredBytes;
  Object? failure;
  Completer<Uint8List>? exportGate;

  @override
  Future<Uint8List> exportBackup() async {
    exports++;
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    final gate = exportGate;
    if (gate != null) return await gate.future;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  BackupSummary inspectBackup(Uint8List bytes) {
    final error = failure;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    return summary;
  }

  @override
  Future<int> restoreBackup(Uint8List bytes) async {
    restores++;
    restoredBytes = bytes;
    return summary.agendas;
  }
}

class _Files implements BackupFileStore {
  Uint8List? selected = Uint8List.fromList([1, 2, 3]);
  bool saveResult = true;
  int saves = 0;
  String? fileName;

  @override
  Future<Uint8List?> pickBackup() async => selected;

  @override
  Future<bool> saveBackup(Uint8List bytes, String fileName) async {
    saves++;
    this.fileName = fileName;
    return saveResult;
  }
}

void main() {
  late _Repository repository;
  late _Files files;

  setUp(() {
    repository = _Repository();
    files = _Files();
  });

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupRepositoryProvider.overrideWithValue(repository),
          backupFileStoreProvider.overrideWithValue(files),
        ],
        child: testMaterialApp(
          home: const Scaffold(
            body: SingleChildScrollView(child: BackupSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('preview freezes the selected bytes before confirmation', () async {
    final controller = BackupController(repository, files);
    final prepared = await controller.prepareRestore();
    files.selected![0] = 99;
    await controller.restore(prepared!);
    expect(repository.restoredBytes, [1, 2, 3]);
    expect(() => repository.restoredBytes![0] = 7, throwsUnsupportedError);
  });

  testWidgets('explains scope and that backups are unencrypted', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.textContaining('no está cifrado'), findsOneWidget);
    expect(find.text('Crear copia de seguridad'), findsOneWidget);
    expect(find.text('Importar copia de seguridad'), findsOneWidget);
  });

  testWidgets('exports a portable filename and reports handoff', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.pumpAndSettle();
    expect(repository.exports, 1);
    expect(files.saves, 1);
    expect(files.fileName, startsWith('honeyday-'));
    expect(files.fileName, endsWith('.honeyday'));
    expect(files.fileName, isNot(contains(':')));
    expect(
      find.text('Archivo de copia de seguridad preparado.'),
      findsOneWidget,
    );
  });

  testWidgets('save cancellation does not report success', (tester) async {
    files.saveResult = false;
    await pumpSection(tester);
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('requires confirmation and previews content counts', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.text('Importar copia de seguridad'));
    await tester.pumpAndSettle();
    expect(repository.restores, 0);
    expect(find.text('¿Importar estas agendas?'), findsOneWidget);
    expect(
      find.textContaining(
        'Agendas: 1\nPáginas: 2\nElementos: 3\nTrazos de tinta: 4',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('no se modificarán'), findsOneWidget);

    await tester.tap(find.text('Importar copias'));
    await tester.pumpAndSettle();
    expect(repository.restores, 1);
    expect(find.text('Se importó 1 agenda.'), findsOneWidget);
  });

  testWidgets('canceling confirmation never writes to storage', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Importar copia de seguridad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.restores, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('canceling the file picker does nothing', (tester) async {
    files.selected = null;
    await pumpSection(tester);
    await tester.tap(find.text('Importar copia de seguridad'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.restores, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('invalid input shows an error without import confirmation', (
    tester,
  ) async {
    repository.failure = const FormatException('unsupported version');
    await pumpSection(tester);
    await tester.tap(find.text('Importar copia de seguridad'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no es una copia de Honeyday válida'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.restores, 0);
  });

  testWidgets('empty backups are explained without asking to import', (
    tester,
  ) async {
    repository.summary = const BackupSummary(
      agendas: 0,
      pages: 0,
      elements: 0,
      strokes: 0,
    );
    await pumpSection(tester);
    await tester.tap(find.text('Importar copia de seguridad'));
    await tester.pumpAndSettle();
    expect(
      find.text('Esta copia de seguridad no contiene agendas.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.restores, 0);
  });

  testWidgets('disables both actions while exporting and rejects double taps', (
    tester,
  ) async {
    final gate = Completer<Uint8List>();
    repository.exportGate = gate;
    await pumpSection(tester);
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.pump();
    expect(repository.exports, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) {
      expect(tile.onTap, isNull);
    }
    gate.complete(Uint8List.fromList([1]));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('finishing an export after unmount does not use its context', (
    tester,
  ) async {
    final gate = Completer<Uint8List>();
    repository.exportGate = gate;
    await pumpSection(tester);
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.pumpWidget(const SizedBox());
    gate.complete(Uint8List.fromList([1]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('storage failures re-enable actions for a retry', (tester) async {
    repository.failure = StateError('disk unavailable');
    await pumpSection(tester);
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La operación falló.'), findsOneWidget);
    repository.failure = null;
    await tester.tap(find.text('Crear copia de seguridad'));
    await tester.pumpAndSettle();
    expect(files.saves, 1);
  });
}
