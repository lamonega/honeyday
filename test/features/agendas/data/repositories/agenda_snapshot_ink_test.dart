import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

InkStroke _stroke(String id, String pageId, {int second = 0}) => InkStroke(
  id: id,
  pageId: pageId,
  tool: InkToolType.highlighter,
  colorHex: '#FF2563EB',
  strokeWidth: 18,
  points: const [StrokePoint(10, 20, 0.4), StrokePoint(50, 20, 0.8)],
  createdAt: DateTime.utc(2026, 9, 24, 10, 0, second),
);

void main() {
  late AppDatabase db;
  late DriftAgendaRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAgendaRepository(db);
  });
  tearDown(() async {
    await db.close();
  });

  test(
    'captures ink by page in the same creation order as the viewer',
    () async {
      final agenda = await repository.createAgenda(title: 'Con tinta');
      final first = (await repository.watchPages(agenda.id).first).single;
      final second = await repository.createPage(
        agendaId: agenda.id,
        pageNumber: 2,
      );
      final other = await repository.createAgenda(title: 'Otra agenda');
      final otherPage = (await repository.watchPages(other.id).first).single;
      await repository.insertStrokesBatch([
        _stroke('later', first.id, second: 2),
        _stroke('earlier', first.id, second: 1),
        _stroke('tie-z', first.id, second: 1),
        _stroke('tie-a', first.id, second: 1),
        _stroke('second', second.id),
        _stroke('other', otherPage.id),
      ]);

      final snapshot = (await repository.getAgendaSnapshot(agenda.id))!;
      expect(snapshot.pages[0].strokes.map((s) => s.id), [
        'earlier',
        'tie-z',
        'tie-a',
        'later',
      ]);
      expect(snapshot.pages[1].strokes.map((s) => s.id), ['second']);
      final watched = await repository.watchStrokes(first.id).first;
      expect(
        snapshot.pages[0].strokes.map((s) => s.id),
        watched.map((s) => s.id),
      );
      final stroke = snapshot.pages[0].strokes.first;
      expect(stroke.tool, InkToolType.highlighter);
      expect(stroke.colorHex, '#FF2563EB');
      expect(stroke.strokeWidth, 18);
      expect(stroke.points.map((p) => (p.x, p.y, p.pressure)), [
        (10, 20, 0.4),
        (50, 20, 0.8),
      ]);
    },
  );

  test('excludes deleted strokes and ink belonging to deleted pages', () async {
    final agenda = await repository.createAgenda(title: 'Borrados');
    final first = (await repository.watchPages(agenda.id).first).single;
    final second = await repository.createPage(
      agendaId: agenda.id,
      pageNumber: 2,
    );
    await repository.insertStrokesBatch([
      _stroke('keep', first.id),
      _stroke('gone', first.id),
      _stroke('hidden-page', second.id),
    ]);
    await (db.update(db.strokes)..where((s) => s.id.equals('gone'))).write(
      const StrokesCompanion(isDeleted: Value(true)),
    );
    await repository.deletePage(second.id);

    final snapshot = (await repository.getAgendaSnapshot(agenda.id))!;
    expect(snapshot.pages, hasLength(1));
    expect(snapshot.pages.single.strokes.map((s) => s.id), ['keep']);
  });

  test(
    'lazy ink is stable after later database edits and repeated reads',
    () async {
      final agenda = await repository.createAgenda(title: 'Instantánea');
      final page = (await repository.watchPages(agenda.id).first).single;
      await repository.insertStroke(_stroke('original', page.id));
      final snapshot = (await repository.getAgendaSnapshot(agenda.id))!;
      final ink = snapshot.pages.single.strokes;
      expect(ink, isNot(isA<List<InkStroke>>()));

      // Do not iterate the captured ink until after the original row is gone.
      await repository.replaceStrokes(page.id, [
        _stroke('replacement', page.id),
      ]);
      final original = ink.single;
      expect(original.id, 'original');
      expect(original.points, hasLength(2));
      original.points.clear();
      expect(ink.single.points, hasLength(2));
      expect(ink.single, isNot(same(original)));
      expect(
        (await repository.watchStrokes(page.id).first).single.id,
        'replacement',
      );
    },
  );

  test(
    'omitting ink preserves metadata and elements without geometry',
    () async {
      final agenda = await repository.createAgenda(title: 'Plantilla');
      final page = (await repository.watchPages(agenda.id).first).single;
      await repository.insertStroke(_stroke('private', page.id));
      final snapshot = (await repository.getAgendaSnapshot(
        agenda.id,
        includeInk: false,
      ))!;
      expect(snapshot.agenda.id, agenda.id);
      expect(snapshot.pages.single.page.id, page.id);
      expect(snapshot.pages.single.strokes, isEmpty);
      expect(await repository.watchStrokes(page.id).first, hasLength(1));
    },
  );
}
