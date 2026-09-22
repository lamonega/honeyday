import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart' hide Agenda, AgendaPage;
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

  /// Watches all non-deleted pages for [agendaId], ordered by page number.
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

  /// Creates a new page and atomically increments the parent agenda's page count.
  ///
  /// The effective page number is derived inside the transaction as
  /// `max(pageNumber, highest live number + 1)` so callers can never create
  /// duplicate numbers after an intermediate page was deleted.
  Future<AgendaPage> createPage({
    required String agendaId,
    required int pageNumber,
    String backgroundStyle = 'dotted',
  }) async {
    final now = DateTime.now().toUtc();
    final pageId = _uuid.v4();

    return await _db.transaction(() async {
      final latest = await (_db.select(_db.pages)
            ..where(
              (tbl) =>
                  tbl.agendaId.equals(agendaId) & tbl.isDeleted.equals(false),
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

      // Increment the agenda's page count through Drift's typed API so the
      // DateTime is serialized consistently (raw SQL here previously wrote
      // milliseconds where drift stores seconds, corrupting updatedAt).
      final agenda = await (_db.select(_db.agendas)
            ..where((tbl) => tbl.id.equals(agendaId)))
          .getSingleOrNull();
      if (agenda != null) {
        await (_db.update(_db.agendas)
              ..where((tbl) => tbl.id.equals(agendaId)))
            .write(
          AgendasCompanion(
            pageCount: Value(agenda.pageCount + 1),
            updatedAt: Value(now),
          ),
        );
      }

      final created = await (_db.select(
        _db.pages,
      )..where((tbl) => tbl.id.equals(pageId))).getSingle();
      return AgendaPageDto.fromDrift(created).toEntity();
    });
  }

  /// Updates the background style of the page identified by [pageId].
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

  /// Soft-deletes the page identified by [pageId].
  ///
  /// Runs atomically with a decrement of the parent agenda's page count
  /// (never below 1) so the badge shown in the home list stays truthful.
  Future<void> deletePage(String pageId) async {
    await _db.transaction(() async {
      final page = await (_db.select(_db.pages)
            ..where((tbl) => tbl.id.equals(pageId)))
          .getSingleOrNull();
      if (page == null || page.isDeleted) return;

      final now = DateTime.now().toUtc();
      await (_db.update(_db.pages)..where((tbl) => tbl.id.equals(pageId)))
          .write(
        PagesCompanion(isDeleted: const Value(true), updatedAt: Value(now)),
      );

      final agenda = await (_db.select(_db.agendas)
            ..where((tbl) => tbl.id.equals(page.agendaId)))
          .getSingleOrNull();
      if (agenda != null && agenda.pageCount > 1) {
        await (_db.update(_db.agendas)
              ..where((tbl) => tbl.id.equals(page.agendaId)))
            .write(
          AgendasCompanion(
            pageCount: Value(agenda.pageCount - 1),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Reorders pages by assigning sequential page numbers in a transaction.
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
}
