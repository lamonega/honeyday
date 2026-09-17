import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager_sheet.dart';

void main() {
  group('PageManagerSheet', () {
    final pages = [
      AgendaPage(
        id: 'page-1',
        agendaId: 'agenda-1',
        pageNumber: 1,
        backgroundStyle: 'dotted',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AgendaPage(
        id: 'page-2',
        agendaId: 'agenda-1',
        pageNumber: 2,
        backgroundStyle: 'grid',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets('renders pages, page count, and add button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (_) {},
              onDeletePage: (_) {},
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      expect(find.text('Páginas (2)'), findsOneWidget);
      expect(find.text('Añadir página'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tapping page thumbnail triggers onSelectPage', (tester) async {
      int? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (index) => selected = index,
              onDeletePage: (_) {},
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('tapping add button triggers onAddPage', (tester) async {
      var added = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (_) {},
              onDeletePage: (_) {},
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () => added = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Añadir página'));
      await tester.pumpAndSettle();

      expect(added, isTrue);
    });

    testWidgets('delete button shown when more than 1 page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (_) {},
              onDeletePage: (_) {},
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('delete confirmation dialog appears on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (_) {},
              onDeletePage: (_) {},
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar página?'), findsOneWidget);
    });

    testWidgets('confirming delete triggers onDeletePage', (tester) async {
      String? deletedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (_) {},
              onDeletePage: (id) => deletedId = id,
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(deletedId, 'page-1');
    });

    testWidgets('paper style dropdown shows current style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageManagerSheet(
              pages: pages,
              currentPageIndex: 0,
              onSelectPage: (_) {},
              onDeletePage: (_) {},
              onChangePaperStyle: (_) {},
              onReorderPages: (_) {},
              onAddPage: () {},
            ),
          ),
        ),
      );

      expect(find.text('Puntos'), findsNWidgets(2));
    });
  });
}
