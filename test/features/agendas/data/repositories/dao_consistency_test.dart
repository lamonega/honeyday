import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';

void main() {
  late AppDatabase db;
  late FullAgendaRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAgendaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DAO consistency & trashed agenda guards', () {
    test(
      'trashed agenda returns empty watchPages and rejects createPage',
      () async {
        final agenda = await repository.createAgenda(title: 'Papelera');
        expect(await repository.watchPages(agenda.id).first, hasLength(1));

        await repository.deleteAgenda(agenda.id);

        expect(await repository.watchPages(agenda.id).first, isEmpty);
        await expectLater(
          repository.createPage(agendaId: agenda.id, pageNumber: 2),
          throwsStateError,
        );
        await expectLater(
          repository.createPage(agendaId: 'missing-agenda', pageNumber: 1),
          throwsStateError,
        );
      },
    );

    test('updateAgendaTitle ignores trashed agendas', () async {
      final agenda = await repository.createAgenda(title: 'Original');
      await repository.deleteAgenda(agenda.id);

      await repository.updateAgendaTitle(agenda.id, 'Renamed');

      final trashed = await repository.watchTrashedAgendas().first;
      expect(trashed.single.title, 'Original');
    });

    test(
      'createPage and duplicatePage derive pageCount from live pages',
      () async {
        final agenda = await repository.createAgenda(title: 'Conteo');
        await (db.update(db.agendas)..where((a) => a.id.equals(agenda.id)))
            .write(const AgendasCompanion(pageCount: Value(99)));

        final page2 = await repository.createPage(
          agendaId: agenda.id,
          pageNumber: 2,
        );
        expect((await repository.getAgenda(agenda.id))?.pageCount, 2);

        await (db.update(db.agendas)..where((a) => a.id.equals(agenda.id)))
            .write(const AgendasCompanion(pageCount: Value(42)));

        await repository.duplicatePage(page2.id);
        expect((await repository.getAgenda(agenda.id))?.pageCount, 3);
      },
    );

    test(
      'createPage idempotency rejects deleted or cross-agenda page ids',
      () async {
        final first = await repository.createAgenda(title: 'First');
        final second = await repository.createAgenda(title: 'Second');
        final existingPage =
            (await repository.watchPages(first.id).first).single;

        await expectLater(
          repository.createPage(
            id: existingPage.id,
            agendaId: second.id,
            pageNumber: 2,
          ),
          throwsStateError,
        );

        final extra = await repository.createPage(
          agendaId: first.id,
          pageNumber: 2,
        );
        await repository.deletePage(extra.id);
        await expectLater(
          repository.createPage(
            id: extra.id,
            agendaId: first.id,
            pageNumber: 3,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'updatePageBackground and reorderPages bump parent agenda updatedAt',
      () async {
        final agenda = await repository.createAgenda(title: 'Updates');
        final page1 = (await repository.watchPages(agenda.id).first).single;
        final page2 = await repository.createPage(
          agendaId: agenda.id,
          pageNumber: 2,
        );
        final past = DateTime.utc(2020);
        await (db.update(db.agendas)..where((a) => a.id.equals(agenda.id)))
            .write(AgendasCompanion(updatedAt: Value(past)));

        await repository.updatePageBackground(page1.id, 'grid');
        final afterBg = (await repository.getAgenda(agenda.id))!;
        expect(afterBg.updatedAt.isAfter(past), isTrue);

        await (db.update(db.agendas)..where((a) => a.id.equals(agenda.id)))
            .write(AgendasCompanion(updatedAt: Value(past)));

        await repository.reorderPages([page2.id, page1.id]);
        final afterReorder = (await repository.getAgenda(agenda.id))!;
        expect(afterReorder.updatedAt.isAfter(past), isTrue);
      },
    );
  });
}
