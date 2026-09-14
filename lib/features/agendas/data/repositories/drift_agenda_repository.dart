import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:uuid/uuid.dart';

/// Drift SQLite implementation of [AgendaRepository].
///
/// Encapsulates all relational queries, transactions, and companion operations.
class DriftAgendaRepository implements AgendaRepository {
  /// Constructs a [DriftAgendaRepository] using the provided [AppDatabase].
  const DriftAgendaRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<Agenda>> watchAgendas() {
    return (_db.select(_db.agendas)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  @override
  Future<Agenda?> getAgenda(String id) {
    return (_db.select(_db.agendas)
          ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  @override
  Future<Agenda> createAgenda({
    required String title,
    String coverStyle = 'honey',
  }) async {
    final now = DateTime.now().toUtc();
    final agendaId = _uuid.v4();
    final pageId = _uuid.v4();

    return await _db.transaction(() async {
      final agendaCompanion = AgendasCompanion.insert(
        id: agendaId,
        title: title,
        coverStyle: Value(coverStyle),
        pageCount: const Value(1),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      );

      await _db.into(_db.agendas).insert(agendaCompanion);

      final pageCompanion = PagesCompanion.insert(
        id: pageId,
        agendaId: agendaId,
        pageNumber: 1,
        backgroundStyle: const Value('dotted'),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      );

      await _db.into(_db.pages).insert(pageCompanion);

      final created = await (_db.select(
        _db.agendas,
      )..where((tbl) => tbl.id.equals(agendaId))).getSingle();
      return created;
    });
  }

  @override
  Future<void> updateAgendaTitle(String id, String newTitle) async {
    await (_db.update(_db.agendas)..where((tbl) => tbl.id.equals(id))).write(
      AgendasCompanion(
        title: Value(newTitle),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> deleteAgenda(String id) async {
    await (_db.update(_db.agendas)..where((tbl) => tbl.id.equals(id))).write(
      AgendasCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Stream<List<AgendaPage>> watchPages(String agendaId) {
    return (_db.select(_db.pages)
          ..where(
            (tbl) =>
                tbl.agendaId.equals(agendaId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.pageNumber)]))
        .watch();
  }

  @override
  Future<AgendaPage> createPage({
    required String agendaId,
    required int pageNumber,
    String backgroundStyle = 'dotted',
  }) async {
    final now = DateTime.now().toUtc();
    final pageId = _uuid.v4();

    return await _db.transaction(() async {
      final pageCompanion = PagesCompanion.insert(
        id: pageId,
        agendaId: agendaId,
        pageNumber: pageNumber,
        backgroundStyle: Value(backgroundStyle),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      );

      await _db.into(_db.pages).insert(pageCompanion);

      final agenda = await (_db.select(
        _db.agendas,
      )..where((tbl) => tbl.id.equals(agendaId))).getSingle();

      await (_db.update(
        _db.agendas,
      )..where((tbl) => tbl.id.equals(agendaId))).write(
        AgendasCompanion(
          pageCount: Value(agenda.pageCount + 1),
          updatedAt: Value(now),
        ),
      );

      return await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).getSingle();
    });
  }

  @override
  Future<void> updatePageBackground(
    String pageId,
    String backgroundStyle,
  ) async {
    await (_db.update(_db.pages)..where((tbl) => tbl.id.equals(pageId))).write(
      PagesCompanion(
        backgroundStyle: Value(backgroundStyle),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> deletePage(String pageId) async {
    await (_db.update(_db.pages)..where((tbl) => tbl.id.equals(pageId))).write(
      PagesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> reorderPages(List<String> pageIdsInOrder) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      for (var i = 0; i < pageIdsInOrder.length; i++) {
        final pageId = pageIdsInOrder[i];
        await (_db.update(
          _db.pages,
        )..where((tbl) => tbl.id.equals(pageId))).write(
          PagesCompanion(pageNumber: Value(i + 1), updatedAt: Value(now)),
        );
      }
    });
  }

  @override
  Stream<List<CanvasElement>> watchCanvasElements(String pageId) {
    return (_db.select(_db.canvasElements)..where(
          (tbl) => tbl.pageId.equals(pageId) & tbl.isDeleted.equals(false),
        ))
        .watch();
  }

  @override
  Future<void> upsertCanvasElement(CanvasElementsCompanion element) async {
    await _db.into(_db.canvasElements).insertOnConflictUpdate(element);
  }

  @override
  Future<void> deleteCanvasElement(String id) async {
    await (_db.update(
      _db.canvasElements,
    )..where((tbl) => tbl.id.equals(id))).write(
      CanvasElementsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Stream<List<Stroke>> watchStrokes(String pageId) {
    return (_db.select(_db.strokes)
          ..where(
            (tbl) => tbl.pageId.equals(pageId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  @override
  Future<void> insertStroke(StrokesCompanion stroke) async {
    await _db.into(_db.strokes).insert(stroke);
  }

  @override
  Future<void> deleteStroke(String id) async {
    await (_db.delete(_db.strokes)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> clearStrokes(String pageId) async {
    await (_db.delete(
      _db.strokes,
    )..where((tbl) => tbl.pageId.equals(pageId))).go();
  }
}
