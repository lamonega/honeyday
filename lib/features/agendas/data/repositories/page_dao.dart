import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/models/agenda_page_dto.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:uuid/uuid.dart';

/// Data Access Object for agenda page operations.
///
/// Handles reading, creating, updating, soft-deleting, and reordering pages
/// within a parent agenda.
class PageDao {
  /// Constructs a [PageDao] backed by the given [AppDatabase].
  const PageDao(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Watches all non-deleted pages for a non-deleted [agendaId], ordered by
  /// page number.
  Stream<List<AgendaPage>> watchPages(String agendaId) {
    final query =
        _db.select(_db.pages).join([
            innerJoin(
              _db.agendas,
              _db.agendas.id.equalsExp(_db.pages.agendaId),
            ),
          ])
          ..where(
            _db.pages.agendaId.equals(agendaId) &
                _db.pages.isDeleted.equals(false) &
                _db.agendas.isDeleted.equals(false),
          )
          ..orderBy([OrderingTerm.asc(_db.pages.pageNumber)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                AgendaPageDto.fromDrift(row.readTable(_db.pages)).toEntity(),
          )
          .toList(),
    );
  }

  /// Reads all non-deleted pages for [agendaId], ordered by page number.
  Future<List<AgendaPage>> getPages(String agendaId) async {
    final rows =
        await (_db.select(_db.pages)
              ..where(
                (tbl) =>
                    tbl.agendaId.equals(agendaId) & tbl.isDeleted.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.pageNumber)]))
            .get();
    return rows.map((r) => AgendaPageDto.fromDrift(r).toEntity()).toList();
  }

  Future<int> _countLivePages(String agendaId) {
    final liveCount = _db.pages.id.count();
    return (_db.selectOnly(_db.pages)
          ..addColumns([liveCount])
          ..where(
            _db.pages.agendaId.equals(agendaId) &
                _db.pages.isDeleted.equals(false),
          ))
        .map((row) => row.read(liveCount)!)
        .getSingle();
  }

  /// Creates a new page and atomically updates the parent agenda's page count.
  ///
  /// The effective page number is derived inside the transaction as
  /// `max(pageNumber, highest live number + 1)` so callers can never create
  /// duplicate numbers after an intermediate page was deleted.
  Future<AgendaPage> createPage({
    required String agendaId,
    required int pageNumber,
    String? id,
    String backgroundStyle = 'dotted',
  }) async {
    final now = DateTime.now().toUtc();
    final pageId = id ?? _uuid.v4();

    return await _db.transaction(() async {
      final agenda =
          await (_db.select(_db.agendas)..where(
                (tbl) => tbl.id.equals(agendaId) & tbl.isDeleted.equals(false),
              ))
              .getSingleOrNull();
      if (agenda == null) {
        throw StateError('The parent agenda does not exist.');
      }

      final existing = await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).getSingleOrNull();
      if (existing != null) {
        if (existing.agendaId != agendaId || existing.isDeleted) {
          throw StateError('The page identifier is already in use.');
        }
        return AgendaPageDto.fromDrift(existing).toEntity();
      }

      final latest =
          await (_db.select(_db.pages)
                ..where(
                  (tbl) =>
                      tbl.agendaId.equals(agendaId) &
                      tbl.isDeleted.equals(false),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.pageNumber)])
                ..limit(1))
              .getSingleOrNull();
      final nextNumber = math.max(pageNumber, (latest?.pageNumber ?? 0) + 1);

      final pageCompanion = PagesCompanion.insert(
        id: pageId,
        agendaId: agendaId,
        pageNumber: nextNumber,
        backgroundStyle: Value(backgroundStyle),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      );

      await _db.into(_db.pages).insert(pageCompanion);

      // Derive pageCount from live pages through Drift's typed API so the
      // DateTime is serialized consistently and pageCount stays accurate.
      final liveCount = await _countLivePages(agendaId);
      await (_db.update(
        _db.agendas,
      )..where((tbl) => tbl.id.equals(agendaId))).write(
        AgendasCompanion(pageCount: Value(liveCount), updatedAt: Value(now)),
      );

      final created = await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).getSingle();
      return AgendaPageDto.fromDrift(created).toEntity();
    });
  }

  /// Updates the background style of the page identified by [pageId] and
  /// bumps the parent agenda's `updatedAt` timestamp.
  Future<void> updatePageBackground(
    String pageId,
    String backgroundStyle,
  ) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final page =
          await (_db.select(_db.pages)..where(
                (tbl) => tbl.id.equals(pageId) & tbl.isDeleted.equals(false),
              ))
              .getSingleOrNull();
      if (page == null) return;
      await (_db.update(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).write(
        PagesCompanion(
          backgroundStyle: Value(backgroundStyle),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(_db.agendas)
            ..where((tbl) => tbl.id.equals(page.agendaId)))
          .write(AgendasCompanion(updatedAt: Value(now)));
    });
  }

  /// Soft-deletes the page identified by [pageId].
  ///
  /// Protects the last live page and updates the parent agenda's count in
  /// the same transaction, even if concurrent callers saw an older list.
  Future<void> deletePage(String pageId) async {
    await _db.transaction(() async {
      final page = await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).getSingleOrNull();
      if (page == null || page.isDeleted) return;

      final liveCount = _db.pages.id.count();
      final remainingBeforeDelete =
          await (_db.selectOnly(_db.pages)
                ..addColumns([liveCount])
                ..where(
                  _db.pages.agendaId.equals(page.agendaId) &
                      _db.pages.isDeleted.equals(false),
                ))
              .map((row) => row.read(liveCount)!)
              .getSingle();
      if (remainingBeforeDelete <= 1) return;

      final now = DateTime.now().toUtc();
      await (_db.update(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).write(
        PagesCompanion(isDeleted: const Value(true), updatedAt: Value(now)),
      );

      await (_db.update(
        _db.agendas,
      )..where((tbl) => tbl.id.equals(page.agendaId))).write(
        AgendasCompanion(
          pageCount: Value(remainingBeforeDelete - 1),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Copies a page and its live content, preserving content creation order.
  /// New identifiers isolate subsequent edits; one transaction covers page
  /// numbering, descendants and the parent count/timestamp.
  Future<AgendaPage> duplicatePage(String pageId, {String? id}) async {
    final copyId = id ?? _uuid.v4();
    if (copyId == pageId) {
      throw ArgumentError.value(id, 'id', 'The copy needs a new identifier.');
    }
    return await _db.transaction(() async {
      final source =
          await (_db.select(_db.pages)
                ..where((p) => p.id.equals(pageId) & p.isDeleted.equals(false)))
              .getSingleOrNull();
      if (source == null) throw StateError('The source page does not exist.');
      final agenda =
          await (_db.select(_db.agendas)..where(
                (a) => a.id.equals(source.agendaId) & a.isDeleted.equals(false),
              ))
              .getSingleOrNull();
      if (agenda == null) throw StateError('The source agenda does not exist.');
      final existing = await (_db.select(
        _db.pages,
      )..where((p) => p.id.equals(copyId))).getSingleOrNull();
      if (existing != null) {
        if (existing.agendaId != source.agendaId || existing.isDeleted) {
          throw StateError('The copy identifier is already in use.');
        }
        return AgendaPageDto.fromDrift(existing).toEntity();
      }
      final elements =
          await (_db.select(_db.canvasElements)
                ..where(
                  (e) => e.pageId.equals(pageId) & e.isDeleted.equals(false),
                )
                ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
              .get();
      final strokes =
          await (_db.select(_db.strokes)
                ..where(
                  (s) => s.pageId.equals(pageId) & s.isDeleted.equals(false),
                )
                ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
              .get();
      final now = DateTime.now().toUtc();
      await (_db.update(_db.pages)..where(
            (p) =>
                p.agendaId.equals(source.agendaId) &
                p.isDeleted.equals(false) &
                p.pageNumber.isBiggerThanValue(source.pageNumber),
          ))
          .write(
            PagesCompanion.custom(
              pageNumber: _db.pages.pageNumber + const Constant(1),
              updatedAt: Variable(now),
            ),
          );
      final copy = source.copyWith(
        id: copyId,
        pageNumber: source.pageNumber + 1,
        createdAt: now,
        updatedAt: now,
      );
      await _db.batch((batch) {
        batch
          ..insert(_db.pages, copy.toCompanion(false))
          ..insertAll(_db.canvasElements, [
            for (final element in elements)
              element
                  .copyWith(id: _uuid.v4(), pageId: copyId, updatedAt: now)
                  .toCompanion(false),
          ])
          ..insertAll(_db.strokes, [
            for (final stroke in strokes)
              stroke
                  .copyWith(id: _uuid.v4(), pageId: copyId, updatedAt: now)
                  .toCompanion(false),
          ]);
      });
      final liveCount = await _countLivePages(source.agendaId);
      await (_db.update(
        _db.agendas,
      )..where((a) => a.id.equals(source.agendaId))).write(
        AgendasCompanion(pageCount: Value(liveCount), updatedAt: Value(now)),
      );
      return AgendaPageDto.fromDrift(copy).toEntity();
    });
  }

  /// Reorders pages by assigning sequential page numbers in a transaction and
  /// bumps the parent agenda's `updatedAt` timestamp.
  Future<void> reorderPages(List<String> pageIdsInOrder) async {
    if (pageIdsInOrder.isEmpty) return;
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
      final firstPage = await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageIdsInOrder.first))).getSingleOrNull();
      if (firstPage != null) {
        await (_db.update(_db.agendas)
              ..where((tbl) => tbl.id.equals(firstPage.agendaId)))
            .write(AgendasCompanion(updatedAt: Value(now)));
      }
    });
  }
}
