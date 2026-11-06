import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

void main() {
  late AppDatabase db;
  late DriftAgendaRepository repository;
  late String agendaId;
  late String sourceId;
  late String nextId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAgendaRepository(db);
    final agenda = await repository.createAgenda(title: 'Weekly planner');
    agendaId = agenda.id;
    sourceId = (await repository.watchPages(agendaId).first).single.id;
    nextId = (await repository.createPage(
      agendaId: agendaId,
      pageNumber: 2,
    )).id;
    await repository.updatePageBackground(sourceId, 'lined');
    await repository.upsertCanvasElement(
      CanvasWidgetData(
        id: 'element',
        pageId: sourceId,
        widgetType: 'text_box',
        position: const Offset(12, 24),
        size: const Size(250, 80),
        rotation: 0.25,
        configJson: '{"text":"My week"}',
      ),
    );
    await repository.upsertCanvasElement(
      CanvasWidgetData(
        id: 'deleted-element',
        pageId: sourceId,
        widgetType: 'text_box',
        position: Offset.zero,
        size: const Size(100, 100),
      ),
    );
    await repository.deleteCanvasElement('deleted-element');
    for (final id in ['stroke', 'deleted-stroke']) {
      await repository.insertStroke(
        InkStroke(
          id: id,
          pageId: sourceId,
          tool: InkToolType.highlighter,
          colorHex: '#80FFD977',
          strokeWidth: 9,
          points: [const StrokePoint(1.2, 3.4, 0.6)],
          createdAt: DateTime.utc(2025),
        ),
      );
    }
    await (db.update(db.strokes)..where((s) => s.id.equals('deleted-stroke')))
        .write(const StrokesCompanion(isDeleted: Value(true)));
  });

  tearDown(() => db.close());

  test(
    'inserts a copy after the source with independent editable content and ink',
    () async {
      final copy = await repository.duplicatePage(sourceId);
      final pages = await repository.watchPages(agendaId).first;
      expect(pages.map((p) => p.id), [sourceId, copy.id, nextId]);
      expect(pages.map((p) => p.pageNumber), [1, 2, 3]);
      expect(copy.agendaId, agendaId);
      expect(copy.backgroundStyle, 'lined');
      expect((await repository.getAgenda(agendaId))!.pageCount, 3);
      final elements = await repository.watchCanvasElements(copy.id).first;
      expect(elements, hasLength(1));
      final element = elements.single;
      expect(element.id, isNot('element'));
      expect(element.pageId, copy.id);
      expect(element.position, const Offset(12, 24));
      expect(element.size, const Size(250, 80));
      expect(element.rotation, 0.25);
      expect(element.configJson, '{"text":"My week"}');
      final strokes = await repository.watchStrokes(copy.id).first;
      expect(strokes, hasLength(1));
      final stroke = strokes.single;
      expect(stroke.id, isNot('stroke'));
      expect(stroke.pageId, copy.id);
      expect(stroke.tool, InkToolType.highlighter);
      expect(stroke.colorHex, '#80FFD977');
      expect(stroke.strokeWidth, 9);
      expect(stroke.points.single.x, 1.2);
      expect(stroke.points.single.pressure, 0.6);

      await repository.updateElementConfig(element.id, '{"text":"Next week"}');
      await repository.deleteStroke(stroke.id);
      expect(
        (await repository.watchCanvasElements(sourceId).first)
            .single
            .configJson,
        '{"text":"My week"}',
      );
      expect(await repository.watchStrokes(sourceId).first, hasLength(1));
    },
  );

  test('retries with the same copy id are idempotent', () async {
    final first = await repository.duplicatePage(sourceId, id: 'copy');
    final retry = await repository.duplicatePage(sourceId, id: 'copy');
    expect(retry.id, first.id);
    expect((await repository.getAgenda(agendaId))!.pageCount, 3);
    expect(await repository.watchPages(agendaId).first, hasLength(3));
    expect(await repository.watchCanvasElements(first.id).first, hasLength(1));
    expect(await repository.watchStrokes(first.id).first, hasLength(1));
  });

  test('a blank last page can be duplicated', () async {
    final copy = await repository.duplicatePage(nextId);
    expect(copy.pageNumber, 3);
    expect(await repository.watchCanvasElements(copy.id).first, isEmpty);
    expect(await repository.watchStrokes(copy.id).first, isEmpty);
  });

  test('a deleted source cannot be duplicated', () async {
    await repository.deletePage(sourceId);
    await expectLater(repository.duplicatePage(sourceId), throwsStateError);
    expect((await repository.getAgenda(agendaId))!.pageCount, 1);
    expect(await db.select(db.pages).get(), hasLength(2));
  });

  test('a source in a deleted agenda cannot be duplicated', () async {
    await repository.deleteAgenda(agendaId);
    await expectLater(repository.duplicatePage(sourceId), throwsStateError);
    expect(await db.select(db.pages).get(), hasLength(2));
  });

  test('missing source and reuse of the source id are rejected', () async {
    await expectLater(repository.duplicatePage('missing'), throwsStateError);
    await expectLater(
      repository.duplicatePage(sourceId, id: sourceId),
      throwsArgumentError,
    );
    expect((await repository.getAgenda(agendaId))!.pageCount, 2);
  });

  test('an id belonging to another agenda is never overwritten', () async {
    final other = await repository.createAgenda(title: 'Other');
    final page = (await repository.watchPages(other.id).first).single;
    await expectLater(
      repository.duplicatePage(sourceId, id: page.id),
      throwsStateError,
    );
    expect((await repository.getAgenda(agendaId))!.pageCount, 2);
    expect((await repository.watchPages(other.id).first).single.id, page.id);
  });

  test(
    'failure copying ink rolls back pages, numbering, elements and counts',
    () async {
      await db.customStatement('''
      CREATE TRIGGER reject_copied_ink BEFORE INSERT ON strokes
      BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END
    ''');
      await expectLater(
        repository.duplicatePage(sourceId, id: 'failed-copy'),
        throwsA(isA<Exception>()),
      );
      final pages = await repository.watchPages(agendaId).first;
      expect(pages.map((p) => p.id), [sourceId, nextId]);
      expect(pages.map((p) => p.pageNumber), [1, 2]);
      expect((await repository.getAgenda(agendaId))!.pageCount, 2);
      expect(await db.select(db.canvasElements).get(), hasLength(2));
      expect(await db.select(db.strokes).get(), hasLength(2));
    },
  );
}
