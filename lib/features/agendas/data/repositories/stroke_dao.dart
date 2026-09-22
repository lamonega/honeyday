import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart' hide Agenda, AgendaPage;
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';

/// Data Access Object for ink stroke operations.
///
/// Handles watching, inserting (single and batch), deleting, and clearing
/// freehand strokes drawn on Layer 3 of a page.
class StrokeDao {
  /// Constructs a [StrokeDao] backed by the given [AppDatabase].
  const StrokeDao(this._db);

  final AppDatabase _db;

  /// Watches all non-deleted strokes for [pageId], ordered by creation time.
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

  /// Converts an [InkStroke] domain model to a Drift [StrokesCompanion].
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

  /// Inserts a single stroke.
  Future<void> insertStroke(InkStroke stroke) async {
    await _db.into(_db.strokes).insert(_strokeToCompanion(stroke));
  }

  /// Inserts multiple strokes atomically in a batch transaction.
  Future<void> insertStrokesBatch(List<InkStroke> strokes) async {
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.strokes, strokes.map(_strokeToCompanion).toList());
      });
    });
  }

  /// Replaces all strokes belonging to [pageId] with [strokes] atomically.
  ///
  /// Delete and insert run in a single transaction so a failure mid-way can
  /// never leave a page with its ink half-erased.
  Future<void> replaceStrokes(String pageId, List<InkStroke> strokes) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.strokes,
      )..where((tbl) => tbl.pageId.equals(pageId))).go();
      if (strokes.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(_db.strokes, strokes.map(_strokeToCompanion).toList());
      });
    });
  }

  /// Permanently deletes the stroke identified by [id].
  Future<void> deleteStroke(String id) async {
    await (_db.delete(_db.strokes)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Permanently deletes all strokes belonging to [pageId].
  Future<void> clearStrokes(String pageId) async {
    await (_db.delete(
      _db.strokes,
    )..where((tbl) => tbl.pageId.equals(pageId))).go();
  }
}
