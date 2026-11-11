import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_trash_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/agenda_action_dialog.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

class _Repository implements FullAgendaRepository {
  _Repository({bool trashed = true, String title = 'Mi diario'})
    : items = [
        Agenda(
          id: 'agenda',
          title: title,
          coverStyle: 'honey',
          pageCount: 2,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          isDeleted: trashed,
        ),
      ];

  final List<Agenda> items;
  final _changes = StreamController<void>.broadcast(sync: true);
  Future<void> Function()? beforeMutation;
  bool failLoading = false;
  int restores = 0;
  int purges = 0;
  int moves = 0;

  Stream<List<Agenda>> _watch({required bool deleted}) async* {
    if (failLoading) throw StateError('simulated read failure');
    yield items.where((item) => item.isDeleted == deleted).toList();
    await for (final _ in _changes.stream) {
      yield items.where((item) => item.isDeleted == deleted).toList();
    }
  }

  @override
  Stream<List<Agenda>> watchAgendas() => _watch(deleted: false);
  @override
  Stream<List<Agenda>> watchTrashedAgendas() => _watch(deleted: true);

  Future<void> _change(String id, {bool? deleted}) async {
    final operation = beforeMutation;
    if (operation != null) await operation();
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    if (deleted == null) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(isDeleted: deleted);
    }
    _changes.add(null);
  }

  @override
  Future<void> deleteAgenda(String id) {
    moves++;
    return _change(id, deleted: true);
  }

  @override
  Future<void> restoreAgenda(String id) {
    restores++;
    return _change(id, deleted: false);
  }

  @override
  Future<void> deleteAgendaPermanently(String id) {
    purges++;
    return _change(id);
  }

  Future<void> close() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _pump(
  WidgetTester tester,
  _Repository repository, {
  bool direct = true,
  double textScale = 1,
}) async {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [agendaRepositoryProvider.overrideWithValue(repository)],
  );
  final router = container.read(routerProvider);
  addTearDown(repository.close);
  addTearDown(container.dispose);
  addTearDown(router.dispose);
  if (direct) router.go(AgendaTrashPage.routePath);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
    'home moves an agenda to trash and restores it with the same ID',
    (tester) async {
      final repository = _Repository(trashed: false);
      final router = await _pump(tester, repository, direct: false);
      await tester.tap(find.byTooltip('Mover agenda a la papelera'));
      await tester.pumpAndSettle();
      expect(find.text('¿Mover agenda a la papelera?'), findsOneWidget);
      await tester.tap(find.text('Mover a la papelera'));
      await tester.pumpAndSettle();
      expect(repository.moves, 1);
      expect(find.text('Sin agendas'), findsOneWidget);
      await tester.tap(find.byTooltip('Papelera'));
      await tester.pumpAndSettle();
      expect(find.text('Mi diario'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        AgendaTrashPage.routePath,
      );
      await tester.tap(find.byTooltip('Restaurar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
      await tester.pumpAndSettle();
      expect(repository.restores, 1);
      expect(repository.items.single.id, 'agenda');
      expect(repository.items.single.isDeleted, isFalse);
      expect(find.text('La papelera está vacía'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Sin agendas'), findsNothing);
    },
  );

  testWidgets('permanent deletion requires confirmation and supports cancel', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    await tester.tap(find.byTooltip('Eliminar definitivamente'));
    await tester.pumpAndSettle();
    expect(repository.purges, 0);
    expect(find.textContaining('cancelá y restaurá'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.purges, 0);
    expect(find.text('Mi diario'), findsOneWidget);
    await tester.tap(find.byTooltip('Eliminar definitivamente'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Eliminar definitivamente'),
    );
    await tester.pumpAndSettle();
    expect(repository.purges, 1);
    expect(repository.items, isEmpty);
    expect(find.text('La papelera está vacía'), findsOneWidget);
  });

  testWidgets('a failed mutation stays open and can be retried', (
    tester,
  ) async {
    final repository = _Repository()
      ..beforeMutation = () async => throw StateError('simulated failure');
    await _pump(tester, repository);
    await tester.tap(find.byTooltip('Restaurar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
    await tester.pumpAndSettle();
    expect(find.byType(AgendaActionDialog), findsOneWidget);
    expect(find.textContaining('La operación falló'), findsOneWidget);
    expect(repository.items.single.isDeleted, isTrue);
    repository.beforeMutation = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
    await tester.pumpAndSettle();
    expect(repository.restores, 2);
    expect(find.byType(AgendaActionDialog), findsNothing);
    expect(repository.items.single.isDeleted, isFalse);
  });

  testWidgets('pending deletion blocks repeated submissions, cancel and back', (
    tester,
  ) async {
    final repository = _Repository();
    final pending = Completer<void>();
    repository.beforeMutation = () => pending.future;
    await _pump(tester, repository);
    await tester.tap(find.byTooltip('Eliminar definitivamente'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(
      FilledButton,
      'Eliminar definitivamente',
    );
    await tester.tap(confirm);
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<PopScope>(
            find
                .ancestor(
                  of: find.byType(AlertDialog),
                  matching: find.byType(PopScope),
                )
                .first,
          )
          .canPop,
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AgendaActionDialog), findsOneWidget);
    expect(repository.purges, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AgendaActionDialog), findsNothing);
    expect(repository.items, isEmpty);
  });

  testWidgets('finishing after unmount does not update a disposed dialog', (
    tester,
  ) async {
    final repository = _Repository();
    final pending = Completer<void>();
    repository.beforeMutation = () => pending.future;
    await _pump(tester, repository);
    await tester.tap(find.byTooltip('Restaurar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.completeError(StateError('late failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'loading errors can be retried without exposing storage details',
    (tester) async {
      final repository = _Repository()..failLoading = true;
      await _pump(tester, repository);
      expect(find.text('No se pudo cargar la papelera.'), findsOneWidget);
      expect(find.textContaining('simulated read failure'), findsNothing);
      repository.failLoading = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Mi diario'), findsOneWidget);
    },
  );

  testWidgets('direct trash URL can return home without navigation history', (
    tester,
  ) async {
    final router = await _pump(tester, _Repository());
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.byTooltip('Papelera'), findsOneWidget);
  });

  testWidgets(
    'narrow layout and large text keep the list and confirmation usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository(
        title: List.filled(20, 'Título largo').join(' '),
      );
      await _pump(tester, repository, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byTooltip('Eliminar definitivamente'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Eliminar definitivamente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final confirm = find.widgetWithText(
        FilledButton,
        'Eliminar definitivamente',
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(repository.purges, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
