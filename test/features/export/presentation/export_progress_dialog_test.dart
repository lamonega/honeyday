import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/presentation/export_progress_dialog.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the current page progress and total', (tester) async {
    final progress = ValueNotifier(
      const ExportProgress(completed: 1, total: 4),
    );

    await tester.pumpWidget(
      testMaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExportProgressDialog.show(
              context,
              progress: progress,
              onCancel: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Exportando…'), findsOneWidget);
    expect(find.text('Renderizando página 1 de 4'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.25,
    );
  });

  testWidgets('invokes onCancel when tapping Cancelar', (tester) async {
    final progress = ValueNotifier(
      const ExportProgress(completed: 0, total: 2),
    );
    var cancelled = false;

    await tester.pumpWidget(
      testMaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExportProgressDialog.show(
              context,
              progress: progress,
              onCancel: () => cancelled = true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(cancelled, isTrue);
  });

  testWidgets('cannot be dismissed by tapping the barrier', (tester) async {
    final progress = ValueNotifier(
      const ExportProgress(completed: 0, total: 2),
    );

    await tester.pumpWidget(
      testMaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExportProgressDialog.show(
              context,
              progress: progress,
              onCancel: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byType(ExportProgressDialog), findsOneWidget);
  });
}
