import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart' hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/models/agenda_dto.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:uuid/uuid.dart';

/// Data Access Object for agenda CRUD operations.
///
/// Handles creating, reading, updating, and soft-deleting agendas.
/// All mutating methods use the provided [AppDatabase] for persistence.
class AgendaDao {
  /// Constructs an [AgendaDao] backed by the given [AppDatabase].
  const AgendaDao(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Watches all non-deleted agendas, ordered by most recently updated.
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

  /// Fetches a single non-deleted agenda by [id], or `null` if not found.
  Future<Agenda?> getAgenda(String id) async {
    final row =
        await (_db.select(_db.agendas)
              ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
            .getSingleOrNull();
    return row == null ? null : AgendaDto.fromDrift(row).toEntity();
  }

  /// Creates a new agenda with one initial page inside a transaction.
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

  /// Updates the title of the agenda identified by [id].
  Future<void> updateAgendaTitle(String id, String newTitle) async {
    await (_db.update(_db.agendas)..where((tbl) => tbl.id.equals(id))).write(
      AgendasCompanion(
        title: Value(newTitle),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Soft-deletes the agenda identified by [id].
  Future<void> deleteAgenda(String id) async {
    await (_db.update(_db.agendas)..where((tbl) => tbl.id.equals(id))).write(
      AgendasCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
