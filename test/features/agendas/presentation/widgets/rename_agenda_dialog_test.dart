import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/presentation/widgets/rename_agenda_dialog.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late List<String> saved;
  late Future<void> Function(String) save;

  setUp(() {
    saved = [];
    save = (title) async => saved.add(title);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => RenameAgendaDialog(
                  initialTitle: 'Original',
                  onSave: (title) => save(title),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('prefills the existing title', (tester) async {
    await open(tester);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Original',
    );
    expect(find.text('Renombrar agenda'), findsOneWidget);
  });

  testWidgets('trims the new title and closes only after saving', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '  Mi diario 🐝  ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(saved, ['Mi diario 🐝']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('does not write an unchanged title', (tester) async {
    await open(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('rejects empty and whitespace-only titles', (tester) async {
    await open(tester);
    for (final title in ['', '   ']) {
      await tester.enterText(find.byType(TextFormField), title);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresá un título.'), findsOneWidget);
    }
    expect(saved, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('cancel leaves the original agenda untouched', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'New title');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('preserves input after a failed write and allows retry', (
    tester,
  ) async {
    var attempts = 0;
    save = (title) async {
      if (++attempts == 1) throw StateError('disk unavailable');
      saved.add(title);
    };
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'New title');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Conservamos tu título'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'New title',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(saved, ['New title']);
    expect(attempts, 2);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('disables input and duplicate submissions during a write', (
    tester,
  ) async {
    final gate = Completer<void>();
    var attempts = 0;
    save = (_) {
      attempts++;
      return gate.future;
    };
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'New title');
    await tester.tap(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(attempts, 1);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('keyboard submission saves the title', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'Keyboard');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(saved, ['Keyboard']);
  });

  testWidgets('an in-flight write can complete safely after unmount', (
    tester,
  ) async {
    final gate = Completer<void>();
    save = (_) => gate.future;
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'New title');
    await tester.tap(find.text('Guardar'));
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
