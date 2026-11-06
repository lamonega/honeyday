import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';

const _indexes = {
  'idx_agendas_updated_at': ('agendas', 'updated_at'),
  'idx_pages_agenda_id': ('pages', 'agenda_id'),
  'idx_canvas_elements_page_id': ('canvas_elements', 'page_id'),
  'idx_strokes_page_id': ('strokes', 'page_id'),
};

Future<void> _expectCurrentSchema(AppDatabase db) async {
  final version = await db.customSelect('PRAGMA user_version').getSingle();
  expect(version.read<int>('user_version'), 2);
  final foreignKeys = await db.customSelect('PRAGMA foreign_keys').getSingle();
  expect(foreignKeys.read<int>('foreign_keys'), 1);
  for (final index in _indexes.entries) {
    final rows = await db
        .customSelect("PRAGMA index_list('${index.value.$1}')")
        .get();
    expect(
      rows.where((row) => row.read<String>('name') == index.key),
      hasLength(1),
    );
    final columns = await db
        .customSelect("PRAGMA index_info('${index.key}')")
        .get();
    expect(columns.map((column) => column.read<String>('name')), [
      index.value.$2,
    ]);
  }
}

void main() {
  late String v1Schema;

  setUp(() async {
    v1Schema = await File('test/fixtures/database/schema_v1.sql')
        .readAsString();
  });

  test(
    'v1 upgrade preserves metadata, editable elements, ink and tombstones',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(setup: (sqlite) => sqlite.execute(v1Schema)),
      );
      addTearDown(db.close);
      final repository = DriftAgendaRepository(db);

      final agenda = await repository.getAgenda('agenda-v1');
      expect(agenda!.title, 'Diario anterior 🐝');
      expect(agenda.coverStyle, 'lavender');
      expect(agenda.pageCount, 1);
      expect(agenda.createdAt.toUtc(), DateTime.utc(2025));
      expect(agenda.updatedAt.toUtc(), DateTime.utc(2025, 1, 2));
      final page = (await repository.watchPages(agenda.id).first).single;
      expect(page.id, 'page-v1');
      expect(page.backgroundStyle, 'grid');
      final element =
          (await repository.watchCanvasElements(page.id).first).single;
      expect(element.id, 'element-v1');
      expect(element.configJson, '{"text":"Do not lose me"}');
      expect(element.position.dx, 12.5);
      expect(element.size.width, 200);
      expect(element.rotation, 0.25);
      final stroke = (await repository.watchStrokes(page.id).first).single;
      expect(stroke.id, 'stroke-v1');
      expect(stroke.tool.name, 'highlighter');
      expect(stroke.colorHex, '#80FFD977');
      expect(stroke.strokeWidth, 9);
      expect(stroke.points.single.x, 1.2);
      expect(stroke.points.single.y, 3.4);
      expect(stroke.points.single.pressure, 0.6);
      expect(await repository.getAgenda('deleted-v1'), isNull);
      final deleted = await (db.select(
        db.agendas,
      )..where((a) => a.id.equals('deleted-v1'))).getSingle();
      expect(deleted.isDeleted, isTrue);
      final deletedPage = await (db.select(
        db.pages,
      )..where((p) => p.id.equals('deleted-page-v1'))).getSingle();
      expect(deletedPage.isDeleted, isTrue);
      await _expectCurrentSchema(db);
    },
  );

  test(
    'reopening an upgraded file does not try to recreate existing indexes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'honeyday-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/v1.sqlite');
      final first = AppDatabase(
        NativeDatabase(file, setup: (sqlite) => sqlite.execute(v1Schema)),
      );
      try {
        await _expectCurrentSchema(first);
      } finally {
        await first.close();
      }

      final reopened = AppDatabase(NativeDatabase(file));
      try {
        await _expectCurrentSchema(reopened);
        expect(
          (await reopened.select(reopened.strokes).get()).single.id,
          'stroke-v1',
        );
        final repository = DriftAgendaRepository(reopened);
        await repository.updateAgendaTitle('agenda-v1', 'Still editable');
        expect(
          (await repository.getAgenda('agenda-v1'))!.title,
          'Still editable',
        );
      } finally {
        await reopened.close();
      }
    },
  );

  test(
    'fresh v2 databases create the same indexes and enforce foreign keys',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _expectCurrentSchema(db);
      await expectLater(
        db
            .into(db.strokes)
            .insert(
              StrokesCompanion.insert(id: 'orphan', pageId: 'missing-page'),
            ),
        throwsA(isA<Exception>()),
      );
      expect(await db.select(db.strokes).get(), isEmpty);
    },
  );
}
