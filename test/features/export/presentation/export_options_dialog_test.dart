import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/domain/export_options.dart';
import 'package:honeyday/features/export/presentation/export_options_dialog.dart';

import '../../../helpers/pump_app.dart';

/// Pumps a home button that opens the options dialog for `pageCount` pages
/// and records the result (plus whether the dialog future resolved) through
/// the `onResolved` / `markResolved` callbacks.
Future<void> pumpHost(
  WidgetTester tester, {
  required int pageCount,
  required void Function(ExportOptions?) onResolved,
  required void Function() markResolved,
}) {
  return tester.pumpWidget(
    testMaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await ExportOptionsDialog.show(
              context,
              pageCount: pageCount,
            );
            onResolved(result);
            markResolved();
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('defaults to A4 with typed content included', (tester) async {
    var resolved = false;
    ExportOptions? chosen;
    await pumpHost(
      tester,
      pageCount: 5,
      onResolved: (result) => chosen = result,
      markResolved: () => resolved = true,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Exportar a PDF'), findsOneWidget);
    final segmented = tester.widget<SegmentedButton<PdfExportFormat>>(
      find.byType(SegmentedButton<PdfExportFormat>),
    );
    expect(segmented.selected, {PdfExportFormat.a4});
    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);
    expect(find.text('5 páginas · 300 dpi'), findsOneWidget);
    expect(resolved, isFalse); // still open
    expect(chosen, isNull); // nothing resolved yet
  });

  testWidgets('returns the chosen options on Exportar', (tester) async {
    var resolved = false;
    ExportOptions? chosen;
    await pumpHost(
      tester,
      pageCount: 3,
      onResolved: (result) => chosen = result,
      markResolved: () => resolved = true,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(chosen, isNotNull);
    expect(chosen!.format, PdfExportFormat.letter);
    expect(chosen!.includeTypedContent, isFalse);
  });

  testWidgets('returns null on Cancelar', (tester) async {
    var resolved = false;
    ExportOptions? chosen;
    await pumpHost(
      tester,
      pageCount: 3,
      onResolved: (result) => chosen = result,
      markResolved: () => resolved = true,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(chosen, isNull);
  });
}
