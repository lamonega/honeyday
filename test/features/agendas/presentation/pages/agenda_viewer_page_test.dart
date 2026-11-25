import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_viewer_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/save_session_scope.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode_notifier.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';

class _UnusedRepository implements FullAgendaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('reading and writing retain the same canvas state', (
    tester,
  ) async {
    final now = DateTime(2026);
    final container = ProviderContainer(
      overrides: [
        agendaRepositoryProvider.overrideWithValue(_UnusedRepository()),
        agendaPagesProvider('agenda').overrideWith(
          (ref) => Stream.value([
            AgendaPage(
              id: 'page',
              agendaId: 'agenda',
              pageNumber: 1,
              backgroundStyle: 'dotted',
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
        pageElementsProvider('page').overrideWith((ref) => Stream.value([])),
        pageStrokesProvider('page').overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testMaterialApp(
          home: const AgendaViewerPage(agendaId: 'agenda'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final original = tester.state(find.byType(PageViewCanvas));
    container.read(canvasModeProvider.notifier).setReading();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(PageViewCanvas)), same(original));
    container.read(canvasModeProvider.notifier).setWriting();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(PageViewCanvas)), same(original));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'shows exit confirmation dialog on save failure with Retry and Discard',
    (tester) async {
      final now = DateTime.utc(2026);
      final router = GoRouter(
        initialLocation: '/viewer',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home Screen')),
          ),
          GoRoute(
            path: '/viewer',
            builder: (_, _) => const AgendaViewerPage(agendaId: 'agenda'),
          ),
        ],
      );
      addTearDown(router.dispose);

      final container = ProviderContainer(
        overrides: [
          agendaRepositoryProvider.overrideWithValue(_UnusedRepository()),
          viewerAgendaProvider('agenda').overrideWith(
            (ref) async => Agenda(
              id: 'agenda',
              title: 'Mi Agenda',
              coverStyle: 'honey',
              pageCount: 1,
              createdAt: now,
              updatedAt: now,
            ),
          ),
          agendaPagesProvider('agenda').overrideWith(
            (ref) => Stream.value([
              AgendaPage(
                id: 'page',
                agendaId: 'agenda',
                pageNumber: 1,
                backgroundStyle: 'dotted',
                createdAt: now,
                updatedAt: now,
              ),
            ]),
          ),
          pageElementsProvider('page').overrideWith((ref) => Stream.value([])),
          pageStrokesProvider('page').overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final session = SaveSessionScope.maybeOf(
        tester.element(find.byType(PageViewCanvas)),
      )!;
      var attempts = 0;
      await expectLater(
        session.enqueue(() async {
          attempts++;
          throw StateError('disk full');
        }),
        throwsStateError,
      );
      await tester.pump();

      // Tap back button -> exit confirmation dialog appears.
      final backTooltip = MaterialLocalizations.of(
        tester.element(find.byType(AppBar)),
      ).backButtonTooltip;
      await tester.tap(find.byTooltip(backTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);

      // Tap Retry -> retries failed write and re-shows dialog when still failing.
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Discard -> navigates home without trapping the user.
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    },
  );

  testWidgets('missing agenda shows not-found state with Go Home button', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/viewer',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: '/viewer',
          builder: (_, _) =>
              const AgendaViewerPage(agendaId: 'missing', initialMode: 'edit'),
        ),
      ],
    );
    addTearDown(router.dispose);

    final container = ProviderContainer(
      overrides: [
        agendaRepositoryProvider.overrideWithValue(_UnusedRepository()),
        viewerAgendaProvider('missing').overrideWith((ref) async => null),
        agendaPagesProvider('missing').overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    final exportButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.picture_as_pdf_outlined),
    );
    expect(exportButton.onPressed, isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
