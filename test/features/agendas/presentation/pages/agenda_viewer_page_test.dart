import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/pages/agenda_viewer_page.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode_notifier.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
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
}
