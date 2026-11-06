import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/agendas/presentation/controllers/home_controller.dart';

void main() {
  late AppDatabase db;
  late DriftAgendaRepository repository;
  late HomeController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAgendaRepository(db);
    controller = HomeController(repository);
  });

  tearDown(() => db.close());

  test('rename trims the title and preserves identity and pages', () async {
    final agenda = await repository.createAgenda(
      title: 'Original',
      coverStyle: 'rose',
    );
    final pages = await repository.watchPages(agenda.id).first;
    await controller.renameAgenda(agenda.id, '  Nuevo título 🐝  ');
    final updated = await repository.getAgenda(agenda.id);
    expect(updated!.title, 'Nuevo título 🐝');
    expect(updated.id, agenda.id);
    expect(updated.coverStyle, 'rose');
    expect(updated.pageCount, agenda.pageCount);
    expect(
      (await repository.watchPages(agenda.id).first).single.id,
      pages.single.id,
    );
    expect(
      (await repository.watchAgendas().first).single.title,
      'Nuevo título 🐝',
    );
  });

  test('invalid titles are rejected without modifying storage', () async {
    final agenda = await repository.createAgenda(title: 'Keep me');
    for (final title in ['', '  ', '\n\t', '\u2003']) {
      await expectLater(
        controller.renameAgenda(agenda.id, title),
        throwsArgumentError,
      );
    }
    expect((await repository.getAgenda(agenda.id))!.title, 'Keep me');
  });
}
