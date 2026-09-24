import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/presentation/widgets/notebook_cover.dart';

import '../../../../helpers/pump_app.dart';

/// Builds a [NotebookCover] sized like the home grid card.
Widget _cover({VoidCallback? onDelete}) {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        height: 360,
        child: NotebookCover(
          title: 'Diario Personal',
          coverStyle: 'honey',
          onDelete: onDelete,
        ),
      ),
    ),
  );
}

void main() {
  group('NotebookCover delete button', () {
    testWidgets('is shown when onDelete is provided', (tester) async {
      await tester.pumpWidget(testMaterialApp(home: _cover(onDelete: () {})));

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Diario Personal'), findsOneWidget);
    });

    testWidgets('is hidden when onDelete is null', (tester) async {
      await tester.pumpWidget(testMaterialApp(home: _cover()));

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.text('Diario Personal'), findsOneWidget);
    });
  });
}
