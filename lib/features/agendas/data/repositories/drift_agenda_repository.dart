import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/models/agenda_dto.dart';
import 'package:honeyday/features/agendas/data/models/agenda_page_dto.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
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
        .watch()
        .map(
          (rows) => rows.map((r) => AgendaDto.fromDrift(r).toEntity()).toList(),
        );
  }

  @override
  Future<Agenda?> getAgenda(String id) async {
    final row =
        await (_db.select(_db.agendas)
              ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
            .getSingleOrNull();
    return row == null ? null : AgendaDto.fromDrift(row).toEntity();
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
      return AgendaDto.fromDrift(created).toEntity();
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
        .watch()
        .map(
          (rows) =>
              rows.map((r) => AgendaPageDto.fromDrift(r).toEntity()).toList(),
        );
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

      // Atomic increment: avoids an extra SELECT
      await _db.customStatement(
        'UPDATE agendas SET page_count = page_count + 1, updated_at = ? WHERE id = ?',
        [now.millisecondsSinceEpoch, agendaId],
      );

      final created = await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).getSingle();
      return AgendaPageDto.fromDrift(created).toEntity();
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
      await _db.batch((batch) {
        for (var i = 0; i < pageIdsInOrder.length; i++) {
          batch.update(
            _db.pages,
            PagesCompanion(pageNumber: Value(i + 1), updatedAt: Value(now)),
            where: (tbl) => tbl.id.equals(pageIdsInOrder[i]),
          );
        }
      });
    });
  }

  @override
  Stream<List<CanvasWidgetData>> watchCanvasElements(String pageId) {
    return (_db.select(_db.canvasElements)
          ..where(
            (tbl) => tbl.pageId.equals(pageId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (e) => CanvasWidgetData(
                  id: e.id,
                  pageId: e.pageId,
                  widgetType: e.widgetType,
                  position: Offset(e.posX, e.posY),
                  size: Size(e.width, e.height),
                  rotation: e.rotation,
                  configJson: e.configJson,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> upsertCanvasElement(CanvasWidgetData element) async {
    final companion = CanvasElementsCompanion(
      id: Value(element.id),
      pageId: Value(element.pageId),
      widgetType: Value(element.widgetType),
      posX: Value(element.position.dx),
      posY: Value(element.position.dy),
      width: Value(element.size.width),
      height: Value(element.size.height),
      rotation: Value(element.rotation),
      configJson: Value(element.configJson),
      updatedAt: Value(DateTime.now().toUtc()),
    );
    await _db.into(_db.canvasElements).insertOnConflictUpdate(companion);
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
  Stream<List<InkStroke>> watchStrokes(String pageId) {
    return (_db.select(_db.strokes)
          ..where(
            (tbl) => tbl.pageId.equals(pageId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (s) => InkStroke.fromDb(
                  id: s.id,
                  pageId: s.pageId,
                  brushType: s.brushType,
                  colorHex: s.colorHex,
                  strokeWidth: s.strokeWidth,
                  pointsJson: s.pointsJson,
                  createdAt: s.createdAt,
                ),
              )
              .toList(),
        );
  }

  StrokesCompanion _strokeToCompanion(InkStroke stroke) {
    return StrokesCompanion.insert(
      id: stroke.id,
      pageId: stroke.pageId,
      brushType: Value(stroke.tool.name),
      colorHex: Value(stroke.toHexColor()),
      strokeWidth: Value(stroke.strokeWidth),
      pointsJson: Value(stroke.toJsonPoints()),
      createdAt: Value(stroke.createdAt),
      updatedAt: Value(DateTime.now().toUtc()),
    );
  }

  @override
  Future<void> insertStroke(InkStroke stroke) async {
    await _db.into(_db.strokes).insert(_strokeToCompanion(stroke));
  }

  @override
  Future<void> insertStrokesBatch(List<InkStroke> strokes) async {
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.strokes, strokes.map(_strokeToCompanion).toList());
      });
    });
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
