import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

void main() {
  late AppDatabase db;
  late FullAgendaRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAgendaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AgendaRepository & Drift SQLite Tests', () {
    test(
      'createAgenda creates an agenda and initializes its first page',
      () async {
        final agenda = await repository.createAgenda(
          title: 'Mi Agenda 2026',
          coverStyle: 'lavender',
        );

        expect(agenda.title, 'Mi Agenda 2026');
        expect(agenda.coverStyle, 'lavender');
        expect(agenda.pageCount, 1);

        final pages = await repository.watchPages(agenda.id).first;
        expect(pages.length, 1);
        expect(pages.first.pageNumber, 1);
        expect(pages.first.backgroundStyle, 'dotted');
      },
    );

    test(
      'createPage adds subsequent page and increments agenda pageCount',
      () async {
        final agenda = await repository.createAgenda(title: 'Trabajo');

        final page2 = await repository.createPage(
          agendaId: agenda.id,
          pageNumber: 2,
          backgroundStyle: 'grid',
        );

        expect(page2.pageNumber, 2);
        expect(page2.backgroundStyle, 'grid');

        final pages = await repository.watchPages(agenda.id).first;
        expect(pages.length, 2);

        final updatedAgenda = await repository.getAgenda(agenda.id);
        expect(updatedAgenda?.pageCount, 2);
      },
    );

    test('createPage keeps updatedAt within a plausible range', () async {
      final agenda = await repository.createAgenda(title: 'Timestamps');
      await repository.createPage(agendaId: agenda.id, pageNumber: 2);

      final updated = await repository.getAgenda(agenda.id);
      final updatedAt = updated!.updatedAt;
      expect(
        updatedAt.isBefore(DateTime.now().toUtc().add(const Duration(days: 1))),
        isTrue,
        reason: 'updatedAt must not be written in the wrong epoch unit',
      );
      expect(
        updatedAt.isAfter(
          DateTime.now().toUtc().subtract(const Duration(days: 1)),
        ),
        isTrue,
      );
    });

    test(
      'deletePage soft-deletes the page and decrements agenda pageCount',
      () async {
        final agenda = await repository.createAgenda(title: 'Borrado');
        final page2 = await repository.createPage(
          agendaId: agenda.id,
          pageNumber: 2,
        );

        await repository.deletePage(page2.id);

        final pages = await repository.watchPages(agenda.id).first;
        expect(pages.length, 1);

        final updated = await repository.getAgenda(agenda.id);
        expect(updated?.pageCount, 1);
      },
    );

    test(
      'createPage never collides after an intermediate page was deleted',
      () async {
        final agenda = await repository.createAgenda(title: 'Colisiones');
        final page2 = await repository.createPage(
          agendaId: agenda.id,
          pageNumber: 2,
        );
        await repository.createPage(agendaId: agenda.id, pageNumber: 3);

        // Delete middle page; live pages are now 1 and 3.
        await repository.deletePage(page2.id);

        // A stale caller-supplied number (2) must not collide with page 3.
        final page4 = await repository.createPage(
          agendaId: agenda.id,
          pageNumber: 2,
        );
        expect(page4.pageNumber, 4);

        final pages = await repository.watchPages(agenda.id).first;
        expect(pages.map((p) => p.pageNumber).toList(), [1, 3, 4]);
      },
    );

    test(
      'replaceStrokes atomically swaps the full stroke set of a page',
      () async {
        final agenda = await repository.createAgenda(title: 'Tinta');
        final pageId = (await repository.watchPages(agenda.id).first).first.id;

        InkStroke stroke(String id) => InkStroke(
          id: id,
          pageId: pageId,
          tool: InkToolType.pen,
          colorHex: '#FF1E293B',
          strokeWidth: 3,
          points: [const StrokePoint(1, 1, 0.5)],
          createdAt: DateTime.now().toUtc(),
        );

        await repository.insertStrokesBatch([stroke('a'), stroke('b')]);
        expect((await repository.watchStrokes(pageId).first).length, 2);

        await repository.replaceStrokes(pageId, [stroke('c')]);
        final swapped = await repository.watchStrokes(pageId).first;
        expect(swapped.length, 1);
        expect(swapped.single.id, 'c');

        await repository.replaceStrokes(pageId, []);
        expect((await repository.watchStrokes(pageId).first).isEmpty, isTrue);
      },
    );

    test(
      'upsertCanvasElement adds and updates modular widgets on a page',
      () async {
        final agenda = await repository.createAgenda(title: 'Estudios');
        final pages = await repository.watchPages(agenda.id).first;
        final pageId = pages.first.id;

        const elementId = 'elem-uuid-1';
        await repository.upsertCanvasElement(
          CanvasWidgetData(
            id: elementId,
            pageId: pageId,
            widgetType: 'budget_calc',
            position: const Offset(50, 100),
            size: const Size(300, 200),
            configJson: '{"total": 500}',
          ),
        );

        var elements = await repository.watchCanvasElements(pageId).first;
        expect(elements.length, 1);
        expect(elements.first.widgetType, 'budget_calc');
        expect(elements.first.position.dx, 50);

        // Update position
        await repository.upsertCanvasElement(
          CanvasWidgetData(
            id: elementId,
            pageId: pageId,
            widgetType: 'budget_calc',
            position: const Offset(120, 180),
            size: const Size(300, 200),
          ),
        );

        elements = await repository.watchCanvasElements(pageId).first;
        expect(elements.first.position.dx, 120);
        expect(elements.first.position.dy, 180);
      },
    );

    test('restoring a soft-deleted element makes it live again', () async {
      final agenda = await repository.createAgenda(title: 'Restaurar');
      final page = (await repository.watchPages(agenda.id).first).first;
      const element = CanvasWidgetData(
        id: 'restore-me',
        pageId: 'page-placeholder',
        widgetType: 'text_box',
        position: Offset(10, 20),
        size: Size(100, 80),
      );
      final saved = element.copyWith(pageId: page.id);
      await repository.upsertCanvasElement(saved);
      await repository.deleteCanvasElement(saved.id);
      expect(await repository.watchCanvasElements(page.id).first, isEmpty);

      await repository.restoreCanvasElement(saved);
      final restored = await repository.watchCanvasElements(page.id).first;
      expect(restored, hasLength(1));
      expect(restored.single.id, saved.id);
    });

    test('strokes insertion, query, and deletion work properly', () async {
      final agenda = await repository.createAgenda(title: 'Bocetos');
      final pages = await repository.watchPages(agenda.id).first;
      final pageId = pages.first.id;

      const strokeId = 'stroke-uuid-1';
      await repository.insertStroke(
        InkStroke(
          id: strokeId,
          pageId: pageId,
          tool: InkToolType.highlighter,
          colorHex: '#FFD97706',
          strokeWidth: 12,
          points: [const StrokePoint(1, 1, 0.5)],
          createdAt: DateTime.now().toUtc(),
        ),
      );

      var strokes = await repository.watchStrokes(pageId).first;
      expect(strokes.length, 1);
      expect(strokes.first.tool, InkToolType.highlighter);

      await repository.deleteStroke(strokeId);
      strokes = await repository.watchStrokes(pageId).first;
      expect(strokes.isEmpty, isTrue);
    });

    test('soft-deleting an agenda hides it from watchAgendas', () async {
      final agenda = await repository.createAgenda(title: 'Para Borrar');

      var list = await repository.watchAgendas().first;
      expect(list.any((a) => a.id == agenda.id), isTrue);

      await repository.deleteAgenda(agenda.id);

      list = await repository.watchAgendas().first;
      expect(list.any((a) => a.id == agenda.id), isFalse);
    });

    test('reorderPages updates page sequence and ordering properly', () async {
      final agenda = await repository.createAgenda(title: 'Organizador');
      final page1 = (await repository.watchPages(agenda.id).first).first;

      final page2 = await repository.createPage(
        agendaId: agenda.id,
        pageNumber: 2,
        backgroundStyle: 'grid',
      );

      final page3 = await repository.createPage(
        agendaId: agenda.id,
        pageNumber: 3,
        backgroundStyle: 'lined',
      );

      var pages = await repository.watchPages(agenda.id).first;
      expect(pages.map((p) => p.id).toList(), [page1.id, page2.id, page3.id]);
      expect(pages.map((p) => p.pageNumber).toList(), [1, 2, 3]);

      // Reorder: page3, page1, page2
      await repository.reorderPages([page3.id, page1.id, page2.id]);

      pages = await repository.watchPages(agenda.id).first;
      expect(pages.map((p) => p.id).toList(), [page3.id, page1.id, page2.id]);
      expect(pages[0].pageNumber, 1);
      expect(pages[1].pageNumber, 2);
      expect(pages[2].pageNumber, 3);
    });
  });

  group('getAgendaSnapshot Tests', () {
    /// Inserts an element with an explicit [createdAt] so ordering
    /// assertions are independent of insert timing.
    Future<void> insertElement({
      required String id,
      required String pageId,
      required DateTime createdAt,
    }) {
      return db.into(db.canvasElements).insert(
        CanvasElementsCompanion.insert(
          id: id,
          pageId: pageId,
          widgetType: 'text_box',
          posX: const Value(10),
          posY: const Value(20),
          width: const Value(220),
          height: const Value(180),
          rotation: const Value(0),
          configJson: const Value('{}'),
          createdAt: Value(createdAt),
          updatedAt: Value(createdAt),
        ),
      );
    }

    test('returns pages in order and elements grouped in viewer z-order', () async {
      final agenda = await repository.createAgenda(title: 'Snapshot');
      final page1 = (await repository.watchPages(agenda.id).first).first;
      final page2 = await repository.createPage(
        agendaId: agenda.id,
        pageNumber: 2,
        backgroundStyle: 'lined',
      );

      final base = DateTime.utc(2026, 9, 24, 12);
      // Inserted out of createdAt order on purpose: the snapshot must order
      // elements by createdAt, not by insertion.
      await insertElement(
        id: 'el-b',
        pageId: page1.id,
        createdAt: base.add(const Duration(minutes: 2)),
      );
      await insertElement(
        id: 'el-a',
        pageId: page1.id,
        createdAt: base.add(const Duration(minutes: 1)),
      );
      await insertElement(
        id: 'el-c',
        pageId: page2.id,
        createdAt: base.add(const Duration(minutes: 3)),
      );

      final snapshot = await repository.getAgendaSnapshot(agenda.id);

      expect(snapshot, isNotNull);
      expect(snapshot!.agenda.id, agenda.id);
      expect(snapshot.agenda.title, 'Snapshot');
      expect(
        snapshot.pages.map((p) => p.page.pageNumber).toList(),
        [1, 2],
      );
      expect(snapshot.pages[0].page.id, page1.id);
      expect(snapshot.pages[1].page.id, page2.id);
      expect(
        snapshot.pages[0].elements.map((e) => e.id).toList(),
        ['el-a', 'el-b'],
      );
      expect(snapshot.pages[1].elements.map((e) => e.id).toList(), ['el-c']);

      // Contract: identical z-order to the viewer's per-page stream.
      final watched = await repository.watchCanvasElements(page1.id).first;
      expect(
        snapshot.pages[0].elements.map((e) => e.id).toList(),
        watched.map((e) => e.id).toList(),
      );
    });

    test('excludes soft-deleted pages and elements', () async {
      final agenda = await repository.createAgenda(title: 'Borrados');
      final page1 = (await repository.watchPages(agenda.id).first).first;
      final page2 = await repository.createPage(
        agendaId: agenda.id,
        pageNumber: 2,
      );

      await insertElement(
        id: 'el-keep',
        pageId: page1.id,
        createdAt: DateTime.utc(2026, 9, 24, 10),
      );
      await insertElement(
        id: 'el-gone',
        pageId: page1.id,
        createdAt: DateTime.utc(2026, 9, 24, 11),
      );
      await insertElement(
        id: 'el-page2',
        pageId: page2.id,
        createdAt: DateTime.utc(2026, 9, 24, 12),
      );

      await repository.deleteCanvasElement('el-gone');
      await repository.deletePage(page2.id);

      final snapshot = await repository.getAgendaSnapshot(agenda.id);

      expect(snapshot, isNotNull);
      expect(snapshot!.pages, hasLength(1));
      expect(snapshot.pages.single.page.id, page1.id);
      expect(
        snapshot.pages.single.elements.map((e) => e.id).toList(),
        ['el-keep'],
      );
    });

    test('returns null for unknown or soft-deleted agendas', () async {
      expect(await repository.getAgendaSnapshot('missing-id'), isNull);

      final agenda = await repository.createAgenda(title: 'Para borrar');
      await repository.deleteAgenda(agenda.id);

      expect(await repository.getAgendaSnapshot(agenda.id), isNull);
    });

    test('returns empty element lists for an agenda without elements', () async {
      final agenda = await repository.createAgenda(title: 'Vacía');

      final snapshot = await repository.getAgendaSnapshot(agenda.id);

      expect(snapshot, isNotNull);
      expect(snapshot!.pages, hasLength(1));
      expect(snapshot.pages.single.elements, isEmpty);
      expect(snapshot.pages.single.page.backgroundStyle, 'dotted');
    });
  });
}
