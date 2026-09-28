import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/presentation/export_progress_dialog.dart';

import '../../../helpers/pump_app.dart';

/// Opens the dialog over a trivial app and returns the tester.
///
/// `pumpAndSettle` is deliberately *not* used: while the pipeline is busy the
/// progress bar is indeterminate, which animates forever by design — the
/// visible proof the app is alive. Settling would wait for an animation that
/// never ends, so the route transition is advanced with fixed pumps instead.
Future<void> openDialog(
  WidgetTester tester,
  ValueNotifier<ExportProgress> progress, {
  VoidCallback? onCancel,
}) async {
  await tester.pumpWidget(
    testMaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => ExportProgressDialog.show(
            context,
            progress: progress,
            onCancel: onCancel ?? () {},
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The `value` of the progress bar, or `null` when it is animating.
double? barValue(WidgetTester tester) =>
    tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value;

void main() {
  testWidgets('renders the current page progress and total', (tester) async {
    final progress = ValueNotifier(
      const ExportProgress(
        phase: ExportPhase.capturing,
        completed: 1,
        total: 4,
      ),
    );

    await openDialog(tester, progress);

    expect(find.text('Exportando…'), findsOneWidget);
    expect(find.text('Renderizando página 1 de 4'), findsOneWidget);
    expect(barValue(tester), isNull, reason: 'the slow phases animate');
  });

  testWidgets('names the phase so working never looks like hanging', (
    tester,
  ) async {
    final progress = ValueNotifier(
      const ExportProgress(
        phase: ExportPhase.capturing,
        completed: 0,
        total: 2,
      ),
    );

    await openDialog(tester, progress);
    expect(find.text('Renderizando las páginas'), findsOneWidget);

    progress.value = const ExportProgress(
      phase: ExportPhase.compressing,
      completed: 2,
      total: 2,
    );
    await tester.pump();
    expect(find.text('Comprimiendo las imágenes…'), findsOneWidget);
    expect(
      barValue(tester),
      isNull,
      reason: 'an indeterminate bar is the visible proof the app is alive',
    );

    progress.value = const ExportProgress(
      phase: ExportPhase.writing,
      completed: 2,
      total: 2,
    );
    await tester.pump();
    expect(find.text('Escribiendo el PDF…'), findsOneWidget);
    expect(barValue(tester), 1, reason: 'the last phase has a real ratio');
  });

  testWidgets('reacts to progress pushed while the dialog is open', (
    tester,
  ) async {
    final progress = ValueNotifier(
      const ExportProgress(
        phase: ExportPhase.capturing,
        completed: 0,
        total: 3,
      ),
    );

    await openDialog(tester, progress);
    expect(find.text('Renderizando página 0 de 3'), findsOneWidget);

    progress.value = const ExportProgress(
      phase: ExportPhase.capturing,
      completed: 2,
      total: 3,
    );
    await tester.pump();

    expect(find.text('Renderizando página 2 de 3'), findsOneWidget);
  });

  testWidgets('invokes onCancel when tapping Cancelar', (tester) async {
    final progress = ValueNotifier(
      const ExportProgress(
        phase: ExportPhase.capturing,
        completed: 0,
        total: 2,
      ),
    );
    var cancelled = false;

    await openDialog(tester, progress, onCancel: () => cancelled = true);
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(cancelled, isTrue);
  });

  testWidgets('keeps cancel available while compressing', (tester) async {
    // Cancelling has to be possible during the phase that used to be
    // uncancellable, so the button must never be disabled.
    final progress = ValueNotifier(
      const ExportProgress(
        phase: ExportPhase.capturing,
        completed: 1,
        total: 9,
      ),
    );
    var cancels = 0;

    await openDialog(tester, progress, onCancel: () => cancels++);

    progress.value = const ExportProgress(
      phase: ExportPhase.compressing,
      completed: 9,
      total: 9,
    );
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(cancels, 1);
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar')).onPressed,
      isNotNull,
    );
  });

  testWidgets('cannot be dismissed by tapping the barrier', (tester) async {
    final progress = ValueNotifier(
      const ExportProgress(
        phase: ExportPhase.capturing,
        completed: 0,
        total: 2,
      ),
    );

    await openDialog(tester, progress);
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExportProgressDialog), findsOneWidget);
  });
}
