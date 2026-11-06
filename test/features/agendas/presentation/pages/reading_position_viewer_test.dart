import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_viewer_page.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';

class _UnusedRepository implements FullAgendaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences preferences;
  final pages = [
    for (var i = 1; i <= 3; i++)
      AgendaPage(
        id: 'page-$i',
        agendaId: 'agenda',
        pageNumber: i,
        backgroundStyle: 'dotted',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpViewer(
    WidgetTester tester, {
    List<AgendaPage>? orderedPages,
    Stream<List<AgendaPage>>? pageStream,
    Future<SharedPreferences>? preferencesFuture,
    bool settle = true,
    String mode = 'reading',
  }) async {
    final container = ProviderContainer(
      overrides: [
        agendaRepositoryProvider.overrideWithValue(_UnusedRepository()),
        sharedPreferencesProvider.overrideWith(
          (ref) => preferencesFuture ?? Future.value(preferences),
        ),
        agendaPagesProvider('agenda').overrideWith(
          (ref) => pageStream ?? Stream.value(orderedPages ?? pages),
        ),
        for (final page in pages) ...[
          pageElementsProvider(page.id).overrideWith((ref) => Stream.value([])),
          pageStrokesProvider(page.id).overrideWith((ref) => Stream.value([])),
        ],
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testMaterialApp(
          home: AgendaViewerPage(agendaId: 'agenda', initialMode: mode),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  PageController pageController(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!;

  for (final mode in ['reading', 'writing', 'edit']) {
    testWidgets('restores the last page in $mode mode', (tester) async {
      await preferences.setString(PreferencesKeys.lastPage('agenda'), 'page-2');
      await pumpViewer(tester, mode: mode);
      expect(pageController(tester).page, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a reordered page is restored by identity, not its old index', (
    tester,
  ) async {
    await preferences.setString(PreferencesKeys.lastPage('agenda'), 'page-2');
    await pumpViewer(tester, orderedPages: [pages[1], pages[2], pages[0]]);
    expect(pageController(tester).page, 0);
  });

  testWidgets('a deleted or unknown bookmark falls back to the first page', (
    tester,
  ) async {
    await preferences.setString(
      PreferencesKeys.lastPage('agenda'),
      'deleted-page',
    );
    await pumpViewer(tester);
    expect(pageController(tester).page, 0);
  });

  testWidgets('navigation is remembered when reopening the viewer', (
    tester,
  ) async {
    await pumpViewer(tester);
    pageController(tester).jumpToPage(2);
    await tester.pumpAndSettle();
    expect(preferences.getString(PreferencesKeys.lastPage('agenda')), 'page-3');
    await tester.pumpWidget(const SizedBox());
    await pumpViewer(tester);
    expect(pageController(tester).page, 2);
  });

  testWidgets('waits for preferences before mounting an editable first page', (
    tester,
  ) async {
    await preferences.setString(PreferencesKeys.lastPage('agenda'), 'page-3');
    final gate = Completer<SharedPreferences>();
    await pumpViewer(tester, preferencesFuture: gate.future, settle: false);
    await tester.pump();
    expect(find.byType(PageViewCanvas), findsNothing);
    gate.complete(preferences);
    await tester.pumpAndSettle();
    expect(pageController(tester).page, 2);
  });

  testWidgets('uses the latest page order when preferences arrive late', (
    tester,
  ) async {
    await preferences.setString(PreferencesKeys.lastPage('agenda'), 'page-3');
    final updates = StreamController<List<AgendaPage>>();
    addTearDown(updates.close);
    final gate = Completer<SharedPreferences>();
    await pumpViewer(
      tester,
      pageStream: updates.stream,
      preferencesFuture: gate.future,
      settle: false,
    );
    updates.add(pages);
    await tester.pump();
    updates.add([pages[2], pages[0], pages[1]]);
    await tester.pump();
    gate.complete(preferences);
    await tester.pumpAndSettle();
    expect(pageController(tester).page, 0);
  });

  testWidgets('preference failures do not prevent reading the agenda', (
    tester,
  ) async {
    final gate = Completer<SharedPreferences>();
    await pumpViewer(tester, preferencesFuture: gate.future, settle: false);
    gate.completeError(StateError('preferences unavailable'));
    await tester.pumpAndSettle();
    expect(pageController(tester).page, 0);
    expect(find.byType(PageViewCanvas), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unmounting during position loading is safe', (tester) async {
    final gate = Completer<SharedPreferences>();
    await pumpViewer(tester, preferencesFuture: gate.future, settle: false);
    await tester.pumpWidget(const SizedBox());
    gate.complete(preferences);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
