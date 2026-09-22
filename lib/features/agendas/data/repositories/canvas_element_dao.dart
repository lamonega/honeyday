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
