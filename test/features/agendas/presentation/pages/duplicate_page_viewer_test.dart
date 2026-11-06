import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/controllers/save_session.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_viewer_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/save_session_scope.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';

AgendaPage _page(String id, int number) => AgendaPage(
  id: id,
  agendaId: 'agenda',
  pageNumber: number,
  backgroundStyle: 'dotted',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _CopyRepository implements FullAgendaRepository {
  final List<String> events = [];
  final List<String?> copyIds = [];
  bool failOnce = false;

  @override
  Future<AgendaPage> duplicatePage(String pageId, {String? id}) async {
    expect(pageId, 'page-1');
    copyIds.add(id);
    if (failOnce) {
      failOnce = false;
      throw StateError('temporary write failure');
    }
    events.add('copied');
    return _page(id!, 2);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CopyRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _CopyRepository();
  });

  Future<SaveSession> open(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        agendaRepositoryProvider.overrideWithValue(repository),
        agendaPagesProvider('agenda').overrideWith(
          (ref) => Stream.value([_page('page-1', 1), _page('page-2', 2)]),
        ),
        for (final id in ['page-1', 'page-2']) ...[
          pageElementsProvider(id).overrideWith((ref) => Stream.value([])),
          pageStrokesProvider(id).overrideWith((ref) => Stream.value([])),
        ],
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testMaterialApp(
          home: const AgendaViewerPage(agendaId: 'agenda', initialMode: 'edit'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return SaveSessionScope.maybeOf(
      tester.element(find.byType(PageViewCanvas).first),
    )!;
  }

  Future<void> requestCopy(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Duplicar página'));
  }

  testWidgets('flushes and waits for pending field edits before copying', (
    tester,
  ) async {
    final session = await open(tester);
    final gate = Completer<void>();
    void flush() {
      session.unregisterEditor(flush);
      unawaited(
        session.enqueue(() async {
          await gate.future;
          repository.events.add('field saved');
        }),
      );
    }

    session.registerEditor(flush);
    await requestCopy(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(repository.copyIds, isEmpty);
    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.events, ['field saved', 'copied']);
    expect(repository.copyIds.single, isNotEmpty);
    expect(repository.copyIds.single, isNot('page-1'));
    expect(session.status, SaveStatus.saved);
    expect(
      find.text('Se duplicó la página después de la original.'),
      findsOneWidget,
    );
  });

  testWidgets('failed copies retry with the same operation id', (tester) async {
    repository.failOnce = true;
    final session = await open(tester);
    await requestCopy(tester);
    await tester.pumpAndSettle();
    expect(session.status, SaveStatus.failed);
    expect(repository.copyIds, hasLength(1));
    await tester.tap(find.byTooltip('Error al guardar. Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.copyIds, hasLength(2));
    expect(repository.copyIds[0], repository.copyIds[1]);
    expect(repository.events, ['copied']);
    expect(session.status, SaveStatus.saved);
  });
}
