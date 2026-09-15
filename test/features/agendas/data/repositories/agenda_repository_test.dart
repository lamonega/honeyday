import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/agenda_repository.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

void main() {
  late AppDatabase db;
  late AgendaRepository repository;

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
          color: const Color(0xFFD97706),
          strokeWidth: 12,
          points: [const PointVector(1, 1, 0.5)],
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
}
