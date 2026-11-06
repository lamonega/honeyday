import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/widgets/agenda_card.dart';

import '../../../../helpers/pump_app.dart';

/// Builds an [AgendaCard] sized like the home grid card.
Widget _card(
  int pageCount, {
  VoidCallback? onRename,
  VoidCallback? onOpenWriting,
  double width = 300,
}) {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: 360,
        child: AgendaCard(
          agenda: Agenda(
            id: 'agenda-$pageCount',
            title: 'Diario Personal',
            coverStyle: 'honey',
            pageCount: pageCount,
            createdAt: DateTime(2026, 9, 11),
            updatedAt: DateTime(2026, 9, 11),
          ),
          onOpenWriting: onOpenWriting ?? () {},
          onRename: onRename,
          onOpenReading: () {},
          onOpenEdit: () {},
          onDelete: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('rename is accessible without opening the agenda', (
    tester,
  ) async {
    var renames = 0;
    var opens = 0;
    await tester.pumpWidget(
      testMaterialApp(
        home: _card(
          123,
          width: 260,
          onRename: () => renames++,
          onOpenWriting: () => opens++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Renombrar agenda'));
    await tester.pumpAndSettle();
    expect(renames, 1);
    expect(opens, 0);
    expect(tester.takeException(), isNull);
  });

  group('AgendaCard page-count badge', () {
    // gen_l10n does not substitute the ICU `#` character: it only selects the
    // plural branch. The ARB must interpolate {count}, otherwise the badge
    // renders a literal "#" (regression guard for the home page counter).
    testWidgets('interpolates the count in the plural branch', (tester) async {
      await tester.pumpWidget(testMaterialApp(home: _card(12)));

      expect(find.text('12 págs.'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('renders the singular branch for a single page', (
      tester,
    ) async {
      await tester.pumpWidget(testMaterialApp(home: _card(1)));

      expect(find.text('1 pág.'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
    });
  });
}
