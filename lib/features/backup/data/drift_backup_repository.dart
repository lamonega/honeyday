import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/backup/data/backup_document.dart';
import 'package:honeyday/features/backup/domain/backup_repository.dart';
import 'package:uuid/uuid.dart';

class DriftBackupRepository implements BackupRepository {
  const DriftBackupRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Future<Uint8List> exportBackup() async {
    // All four reads share one snapshot, even if another window is writing.
    final document = await _db.transaction(() async {
      final agendas =
          await (_db.select(_db.agendas)
                ..where((a) => a.isDeleted.equals(false))
                ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
              .get();
      final pages =
          await (_db.select(_db.pages).join([
                  innerJoin(
                    _db.agendas,
                    _db.agendas.id.equalsExp(_db.pages.agendaId),
                  ),
                ])
                ..where(
                  _db.pages.isDeleted.equals(false) &
                      _db.agendas.isDeleted.equals(false),
                )
                ..orderBy([OrderingTerm.asc(_db.pages.pageNumber)]))
              .get();
      final elements =
          await (_db.select(_db.canvasElements).join([
                  innerJoin(
                    _db.pages,
                    _db.pages.id.equalsExp(_db.canvasElements.pageId),
                  ),
                  innerJoin(
                    _db.agendas,
                    _db.agendas.id.equalsExp(_db.pages.agendaId),
                  ),
                ])
                ..where(
                  _db.canvasElements.isDeleted.equals(false) &
                      _db.pages.isDeleted.equals(false) &
                      _db.agendas.isDeleted.equals(false),
                )
                ..orderBy([OrderingTerm.asc(_db.canvasElements.createdAt)]))
              .get();
      final strokes =
          await (_db.select(_db.strokes).join([
                  innerJoin(
                    _db.pages,
                    _db.pages.id.equalsExp(_db.strokes.pageId),
                  ),
                  innerJoin(
                    _db.agendas,
                    _db.agendas.id.equalsExp(_db.pages.agendaId),
                  ),
                ])
                ..where(
                  _db.strokes.isDeleted.equals(false) &
                      _db.pages.isDeleted.equals(false) &
                      _db.agendas.isDeleted.equals(false),
                )
                ..orderBy([OrderingTerm.asc(_db.strokes.createdAt)]))
              .get();

      final pagesByAgenda = <String, List<Page>>{};
      for (final result in pages) {
        final page = result.readTable(_db.pages);
        pagesByAgenda.putIfAbsent(page.agendaId, () => []).add(page);
      }
      final elementsByPage = <String, List<CanvasElement>>{};
      for (final result in elements) {
        final element = result.readTable(_db.canvasElements);
        elementsByPage.putIfAbsent(element.pageId, () => []).add(element);
      }
      final strokesByPage = <String, List<Stroke>>{};
      for (final result in strokes) {
        final stroke = result.readTable(_db.strokes);
        strokesByPage.putIfAbsent(stroke.pageId, () => []).add(stroke);
      }
      return BackupDocument([
        for (final agenda in agendas)
          BackupAgenda(agenda, [
            for (final page in pagesByAgenda[agenda.id] ?? <Page>[])
              BackupPage(
                page,
                elementsByPage[page.id] ?? const [],
                strokesByPage[page.id] ?? const [],
              ),
          ]),
      ]);
    });
    final bytes = document.encode();
    // Never offer a backup that the importer itself cannot read.
    BackupDocument.decode(bytes);
    return bytes;
  }

  @override
  BackupSummary inspectBackup(Uint8List bytes) =>
      BackupDocument.decode(bytes).summary;

  @override
  Future<int> restoreBackup(Uint8List bytes) async {
    // Validate *every* entry before the first write. The transaction also
    // protects against database failures after some valid entries were added.
    final document = BackupDocument.decode(bytes);
    await _db.transaction(() async {
      await _db.batch((batch) {
        for (final entry in document.agendas) {
          final agendaId = _uuid.v4();
          batch.insert(
            _db.agendas,
            entry.agenda
                .copyWith(id: agendaId, pageCount: entry.pages.length)
                .toCompanion(false),
          );
          for (final entryPage in entry.pages) {
            final pageId = _uuid.v4();
            batch
              ..insert(
                _db.pages,
                entryPage.page
                    .copyWith(id: pageId, agendaId: agendaId)
                    .toCompanion(false),
              )
              ..insertAll(_db.canvasElements, [
                for (final element in entryPage.elements)
                  element
                      .copyWith(id: _uuid.v4(), pageId: pageId)
                      .toCompanion(false),
              ])
              ..insertAll(_db.strokes, [
                for (final stroke in entryPage.strokes)
                  stroke
                      .copyWith(id: _uuid.v4(), pageId: pageId)
                      .toCompanion(false),
              ]);
          }
        }
      });
    });
    return document.agendas.length;
  }
}
