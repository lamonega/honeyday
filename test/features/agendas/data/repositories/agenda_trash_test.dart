import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/backup/data/drift_backup_repository.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

Future<String> _seed(AppDatabase db) async {
  final repository = DriftAgendaRepository(db);
  final agenda = await repository.createAgenda(
    title: 'Diario 🐝',
    coverStyle: 'rose',
  );
  final page = (await repository.watchPages(agenda.id).first).single;
  final removed = await repository.createPage(
    agendaId: agenda.id,
    pageNumber: 2,
  );
  for (final (index, pageId) in [page.id, page.id, removed.id].indexed) {
    final element = CanvasWidgetData(
      id: '${agenda.id}-element-$index',
      pageId: pageId,
      widgetType: 'text_box',
      position: const Offset(31, 47),
      size: const Size(240, 170),
      rotation: 0.35,
      configJson: '{"text":"Contenido $index"}',
    );
    await repository.upsertCanvasElement(element);
    await repository.insertStroke(
      InkStroke(
        id: '${agenda.id}-ink-$index',
        pageId: pageId,
        tool: InkToolType.highlighter,
        colorHex: '#80FF0000',
        strokeWidth: 17,
        points: const [StrokePoint(20, 30, 0.6), StrokePoint(70, 90)],
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    if (index == 1) {
      await repository.deleteCanvasElement(element.id);
      await (db.update(db.strokes)
            ..where((stroke) => stroke.id.equals('${agenda.id}-ink-$index')))
          .write(const StrokesCompanion(isDeleted: Value(true)));
    }
  }
  await repository.deletePage(removed.id);
  return agenda.id;
}

void main() {
  late AppDatabase db;
  late DriftAgendaRepository repository;
  Directory? tempDirectory;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAgendaRepository(db);
    tempDirectory = null;
  });
  tearDown(() async {
    await db.close();
    final directory = tempDirectory;
    if (directory != null) await directory.delete(recursive: true);
  });

  test(
    'restore preserves identity, geometry, content, ink and child tombstones',
    () async {
      final id = await _seed(db);
      final original = (await repository.getAgenda(id))!;
      final pages = await db.select(db.pages).get();
      final elements = await db.select(db.canvasElements).get();
      final strokes = await db.select(db.strokes).get();

      await repository.deleteAgenda(id);
      expect(await repository.getAgenda(id), isNull);
      expect(await repository.getAgendaSnapshot(id), isNull);
      expect(await repository.watchAgendas().first, isEmpty);
      expect((await repository.watchTrashedAgendas().first).single.id, id);
      expect(
        (await repository.watchTrashedAgendas().first).single.isDeleted,
        isTrue,
      );

      await repository.restoreAgenda(id);
      final restored = (await repository.getAgenda(id))!;
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.coverStyle, original.coverStyle);
      expect(restored.createdAt, original.createdAt);
      expect(restored.pageCount, original.pageCount);
      expect(restored.isDeleted, isFalse);
      expect(await repository.watchTrashedAgendas().first, isEmpty);
      expect(await db.select(db.pages).get(), unorderedEquals(pages));
      expect(
        await db.select(db.canvasElements).get(),
        unorderedEquals(elements),
      );
      expect(await db.select(db.strokes).get(), unorderedEquals(strokes));
      final snapshot = (await repository.getAgendaSnapshot(id))!;
      expect(snapshot.pages, hasLength(1));
      expect(snapshot.pages.single.elements, hasLength(1));
      expect(snapshot.pages.single.strokes, hasLength(1));
    },
  );

  test('trash streams react to move, restore and permanent deletion', () async {
    final id = await _seed(db);
    final iterator = StreamIterator(repository.watchTrashedAgendas());
    addTearDown(iterator.cancel);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);
    await repository.deleteAgenda(id);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single.id, id);
    await repository.restoreAgenda(id);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);
    await repository.deleteAgenda(id);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single.id, id);
    await repository.deleteAgendaPermanently(id);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);
  });

  test('permanent deletion removes all descendants and leaves other agendas intact', () async {
    final id = await _seed(db);
    final keepId = await _seed(db);
    final keepPages = (await db.select(db.pages).get())
        .where((page) => page.agendaId == keepId)
        .toList();
    final keepPageIds = keepPages.map((page) => page.id).toSet();
    final keepElements = (await db.select(db.canvasElements).get())
        .where((element) => keepPageIds.contains(element.pageId))
        .toList();
    final keepStrokes = (await db.select(db.strokes).get())
        .where((stroke) => keepPageIds.contains(stroke.pageId))
        .toList();
    await repository.deleteAgenda(id);
    await repository.deleteAgendaPermanently(id);
    expect((await db.select(db.agendas).get()).single.id, keepId);
    expect(await db.select(db.pages).get(), unorderedEquals(keepPages));
    expect(
      await db.select(db.canvasElements).get(),
      unorderedEquals(keepElements),
    );
    expect(await db.select(db.strokes).get(), unorderedEquals(keepStrokes));
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    await repository.restoreAgenda(id);
    expect(await repository.getAgenda(id), isNull);
  });

  test(
    'active or concurrently restored agendas cannot be permanently deleted',
    () async {
      final id = await _seed(db);
      await expectLater(
        repository.deleteAgendaPermanently(id),
        throwsStateError,
      );
      await repository.deleteAgenda(id);
      await repository.restoreAgenda(id);
      await expectLater(
        repository.deleteAgendaPermanently(id),
        throwsStateError,
      );
      expect(await db.select(db.pages).get(), hasLength(2));
      expect(await db.select(db.canvasElements).get(), hasLength(3));
      expect(await db.select(db.strokes).get(), hasLength(3));
    },
  );

  test(
    'failure deleting the root rolls back every descendant deletion',
    () async {
      final id = await _seed(db);
      await repository.deleteAgenda(id);
      final pages = await db.select(db.pages).get();
      final elements = await db.select(db.canvasElements).get();
      final strokes = await db.select(db.strokes).get();
      await db.customStatement('''
      CREATE TRIGGER reject_purge BEFORE DELETE ON agendas
      BEGIN SELECT RAISE(ABORT, 'simulated storage failure'); END;
    ''');
      await expectLater(
        repository.deleteAgendaPermanently(id),
        throwsException,
      );
      expect((await repository.watchTrashedAgendas().first).single.id, id);
      expect(await db.select(db.pages).get(), unorderedEquals(pages));
      expect(
        await db.select(db.canvasElements).get(),
        unorderedEquals(elements),
      );
      expect(await db.select(db.strokes).get(), unorderedEquals(strokes));
      await db.customStatement('DROP TRIGGER reject_purge');
      await repository.deleteAgendaPermanently(id);
      expect(await db.select(db.agendas).get(), isEmpty);
    },
  );

  test(
    'retries and missing identifiers are safe without reviving anything',
    () async {
      for (final id in ['missing', await _seed(db)]) {
        await repository.restoreAgenda(id);
        await repository.deleteAgenda(id);
        final first = await repository.watchTrashedAgendas().first;
        await repository.deleteAgenda(id);
        expect(
          (await repository.watchTrashedAgendas().first).map(
            (a) => a.updatedAt,
          ),
          first.map((a) => a.updatedAt),
        );
        await repository.deleteAgendaPermanently(id);
        await repository.deleteAgendaPermanently(id);
        await repository.restoreAgenda(id);
        expect(await repository.getAgenda(id), isNull);
      }
    },
  );

  test(
    'trash is ordered by last modification and excludes active agendas',
    () async {
      final older = await repository.createAgenda(title: 'Older');
      final newer = await repository.createAgenda(title: 'Newer');
      await repository.createAgenda(title: 'Active');
      for (final (agenda, year) in [(older, 2025), (newer, 2026)]) {
        await repository.deleteAgenda(agenda.id);
        await (db.update(db.agendas)..where((a) => a.id.equals(agenda.id)))
            .write(AgendasCompanion(updatedAt: Value(DateTime.utc(year))));
      }
      expect((await repository.watchTrashedAgendas().first).map((a) => a.id), [
        newer.id,
        older.id,
      ]);
    },
  );

  test('trashed agendas are excluded from backups until restored', () async {
    final id = await _seed(db);
    final backup = DriftBackupRepository(db);
    await repository.deleteAgenda(id);
    expect(backup.inspectBackup(await backup.exportBackup()).agendas, 0);
    await repository.restoreAgenda(id);
    final summary = backup.inspectBackup(await backup.exportBackup());
    expect(summary.agendas, 1);
    expect(summary.pages, 1);
    expect(summary.elements, 1);
    expect(summary.strokes, 1);
  });

  test(
    'trash, restoration and permanent deletion survive database reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'honeyday-trash-',
      );
      tempDirectory = directory;
      final file = File('${directory.path}/trash.sqlite');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      repository = DriftAgendaRepository(db);
      final id = await _seed(db);
      await repository.deleteAgenda(id);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      repository = DriftAgendaRepository(db);
      expect((await repository.watchTrashedAgendas().first).single.id, id);
      await repository.restoreAgenda(id);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      repository = DriftAgendaRepository(db);
      expect(
        (await repository.getAgendaSnapshot(id))!.pages.single.strokes,
        hasLength(1),
      );
      await repository.deleteAgenda(id);
      await repository.deleteAgendaPermanently(id);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect(await db.select(db.agendas).get(), isEmpty);
      expect(await db.select(db.pages).get(), isEmpty);
      expect(await db.select(db.canvasElements).get(), isEmpty);
      expect(await db.select(db.strokes).get(), isEmpty);
    },
  );
}
