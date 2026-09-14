import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart';
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
        isDeleted: false,
      ),
      AgendaPage(
        id: 'page-2',
        agendaId: 'agenda-1',
        pageNumber: 2,
        backgroundStyle: 'grid',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      ),
    ];

    testWidgets('renders pages and does NOT render Añadir Página button', (
      tester,
    ) async {
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
            ),
          ),
        ),
      );

      expect(find.text('Páginas (2)'), findsOneWidget);
      expect(find.text('Añadir Página'), findsNothing);
      expect(find.text('Página 1'), findsOneWidget);
      expect(find.text('Página 2'), findsOneWidget);
    });

    testWidgets(
      'moving page right triggers onReorderPages with updated order',
      (tester) async {
        List<String>? reordered;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageManagerSheet(
                pages: pages,
                currentPageIndex: 0,
                onSelectPage: (_) {},
                onDeletePage: (_) {},
                onChangePaperStyle: (_) {},
                onReorderPages: (newOrder) => reordered = newOrder,
              ),
            ),
          ),
        );

        // Find arrow forward button on page 1
        final moveRightButton = find.byTooltip('Mover a la derecha').first;
        await tester.tap(moveRightButton);
        await tester.pumpAndSettle();

        expect(reordered, ['page-2', 'page-1']);
      },
    );
  });
}
