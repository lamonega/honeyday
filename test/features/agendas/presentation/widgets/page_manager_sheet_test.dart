import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/controllers/save_session.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager/page_manager_grid.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager_sheet.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PageManagerSheet', () {
    final pages = List.generate(
      2,
      (index) => AgendaPage(
        id: 'page-${index + 1}',
        agendaId: 'agenda-1',
        pageNumber: index + 1,
        backgroundStyle: index == 0 ? 'dotted' : 'grid',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    Future<void> pumpSheet(
      WidgetTester tester, {
      ValueChanged<int>? onSelectPage,
      ValueChanged<String>? onDeletePage,
      void Function(String, String)? onChangePaperStyle,
      ValueChanged<List<String>>? onReorderPages,
      VoidCallback? onAddPage,
    }) => tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(
          body: PageManagerSheet(
            pages: pages,
            currentPageIndex: 0,
            onSelectPage: onSelectPage ?? (_) {},
            onDeletePage: onDeletePage ?? (_) {},
            onChangePaperStyle: onChangePaperStyle ?? (_, _) {},
            onReorderPages: onReorderPages ?? (_) {},
            onAddPage: onAddPage ?? () {},
          ),
        ),
      ),
    );

    testWidgets('renders pages, page count, and add button', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Páginas (2)'), findsOneWidget);
      expect(find.text('Añadir página'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tapping page thumbnail triggers onSelectPage', (tester) async {
      int? selected;
      await pumpSheet(tester, onSelectPage: (index) => selected = index);
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('tapping add button triggers onAddPage', (tester) async {
      var added = false;
      await pumpSheet(tester, onAddPage: () => added = true);
      await tester.tap(find.text('Añadir página'));
      await tester.pumpAndSettle();
      expect(added, isTrue);
    });

    testWidgets('delete button shown when more than 1 page', (tester) async {
      await pumpSheet(tester);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('delete confirmation dialog appears on tap', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar página?'), findsOneWidget);
    });

    testWidgets('confirming delete triggers onDeletePage', (tester) async {
      String? deletedId;
      await pumpSheet(tester, onDeletePage: (id) => deletedId = id);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(deletedId, 'page-1');
    });

    testWidgets('paper style dropdown shows current style', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Puntos'), findsNWidgets(2));
    });

    testWidgets('queued paper changes retain page identity after reorder', (
      tester,
    ) async {
      final session = SaveSession();
      addTearDown(session.dispose);
      final reorder = Completer<void>();
      final firstStyle = Completer<void>();
      final writes = <String>[];
      var currentIndex = 0;
      await pumpSheet(
        tester,
        onReorderPages: (_) {
          unawaited(
            session.enqueue(() => reorder.future).then((_) {
              currentIndex = 1;
            }),
          );
        },
        onChangePaperStyle: (pageId, style) {
          unawaited(
            session.enqueue(() async {
              writes.add('$pageId:$style');
              if (writes.length == 1) await firstStyle.future;
            }),
          );
        },
      );
      tester
          .widget<PageManagerGrid>(find.byType(PageManagerGrid))
          .onReorder(0, 1);
      await tester.pump();
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      dropdown.onChanged!('lined');
      dropdown.onChanged!('blank');
      reorder.complete();
      await tester.pump();
      expect(currentIndex, 1);
      firstStyle.complete();
      await tester.pump();
      await session.drain();
      expect(writes, ['page-1:lined', 'page-1:blank']);
    });
  });
}
