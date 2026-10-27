import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart' hide Agenda, AgendaPage;
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

/// Data Access Object for canvas element operations.
///
/// Handles watching, upserting, and soft-deleting modular widgets
/// placed on a page's Layer 1.
class CanvasElementDao {
  /// Constructs a [CanvasElementDao] backed by the given [AppDatabase].
  const CanvasElementDao(this._db);

  final AppDatabase _db;

  /// Watches all non-deleted canvas elements for [pageId], ordered by creation time.
  Stream<List<CanvasWidgetData>> watchCanvasElements(String pageId) {
    return (_db.select(_db.canvasElements)
          ..where(
            (tbl) => tbl.pageId.equals(pageId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  /// Reads all live canvas elements across every live page of [agendaId],
  /// ordered by (pageNumber asc, createdAt asc) — i.e. page order and, within
  /// each page, the same z-order the viewer renders.
  Future<List<CanvasWidgetData>> getCanvasElementsForAgenda(
    String agendaId,
  ) async {
    final query = _db.select(_db.canvasElements).join([
      innerJoin(_db.pages, _db.pages.id.equalsExp(_db.canvasElements.pageId)),
    ])
      ..where(_db.pages.agendaId.equals(agendaId))
      ..where(_db.pages.isDeleted.equals(false))
      ..where(_db.canvasElements.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm.asc(_db.pages.pageNumber),
        OrderingTerm.asc(_db.canvasElements.createdAt),
      ]);
    final rows = await query.get();
    return rows.map((r) => _mapRow(r.readTable(_db.canvasElements))).toList();
  }

  /// Maps a Drift [CanvasElement] row onto its domain representation.
  CanvasWidgetData _mapRow(CanvasElement e) {
    return CanvasWidgetData(
      id: e.id,
      pageId: e.pageId,
      widgetType: e.widgetType,
      position: Offset(e.posX, e.posY),
      size: Size(e.width, e.height),
      rotation: e.rotation,
      configJson: e.configJson,
    );
  }

  /// Inserts or updates a canvas element using conflict resolution.
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

  /// Restores a soft-deleted element from an undo/redo snapshot.
  Future<void> restoreCanvasElement(CanvasWidgetData element) async {
    await _db.into(_db.canvasElements).insertOnConflictUpdate(
      CanvasElementsCompanion(
        id: Value(element.id),
        pageId: Value(element.pageId),
        widgetType: Value(element.widgetType),
        posX: Value(element.position.dx),
        posY: Value(element.position.dy),
        width: Value(element.size.width),
        height: Value(element.size.height),
        rotation: Value(element.rotation),
        configJson: Value(element.configJson),
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Updates only [configJson] (and `updatedAt`) for the element [id].
  ///
  /// Column-scoped so a debounced config flush can never revert geometry
  /// written concurrently by drags or transforms. Returns whether a
  /// live (non-deleted) row was updated.
  Future<bool> updateElementConfig(String id, String configJson) async {
    final count = await (_db.update(
      _db.canvasElements,
    )..where(
        (tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false),
      )).write(
      CanvasElementsCompanion(
        configJson: Value(configJson),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    return count > 0;
  }

  /// Soft-deletes the canvas element identified by [id].
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
}
