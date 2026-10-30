import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar_grid_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/catalog_widget_mixin.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal_block_widget.dart';

import '../../../../helpers/pump_app.dart';

Future<void> _pumpEditor(WidgetTester tester, Widget editor) =>
    tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(body: SizedBox(width: 400, height: 600, child: editor)),
      ),
    );

void main() {
  testWidgets('budget edits persist without submitting fields', (tester) async {
    String? saved;
    await _pumpEditor(
      tester,
      BudgetWidget(
        elementId: 'budget',
        configJson: BudgetConfig.defaultConfig().toJsonString(),
        isInteractive: true,
        onConfigChanged: (json) => saved = json,
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('desc_1')), 'Salary');
    await tester.enterText(find.byKey(const ValueKey('amt_1')), '123.50');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(CatalogConfigHelper.debounceDuration);
    final entry = BudgetConfig.fromJsonString(saved!).entries.first;
    expect(entry.description, 'Salary');
    expect(entry.amount, 123.5);
  });

  for (final raw in ['NaN', 'Infinity', '1e999', '-10', 'invalid']) {
    testWidgets('budget rejects invalid amount $raw', (tester) async {
      String? saved;
      await _pumpEditor(
        tester,
        BudgetWidget(
          elementId: 'budget',
          configJson: BudgetConfig.defaultConfig().toJsonString(),
          isInteractive: true,
          onConfigChanged: (json) => saved = json,
        ),
      );
      final amount = find.byKey(const ValueKey('amt_1'));
      await tester.enterText(amount, '123,50');
      await tester.pump(CatalogConfigHelper.debounceDuration);
      expect(BudgetConfig.fromJsonString(saved!).entries.first.amount, 123.5);
      final validJson = saved;
      await tester.enterText(amount, raw);
      await tester.pump(CatalogConfigHelper.debounceDuration);
      expect(tester.takeException(), isNull);
      expect(saved, validJson);
    });
  }

  testWidgets('habit title persists without submitting the field', (
    tester,
  ) async {
    String? saved;
    await _pumpEditor(
      tester,
      CalendarGridWidget(
        elementId: 'calendar',
        configJson: CalendarGridConfig.defaultConfig().toJsonString(),
        isInteractive: true,
        onConfigChanged: (json) => saved = json,
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Walk');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(CatalogConfigHelper.debounceDuration);
    expect(
      CalendarGridConfig.fromJsonString(saved!).habits.first.title,
      'Walk',
    );
  });

  testWidgets('journal date and priority persist without submission', (
    tester,
  ) async {
    String? saved;
    await _pumpEditor(
      tester,
      JournalBlockWidget(
        elementId: 'journal',
        configJson: JournalBlockConfig.defaultConfig().toJsonString(),
        isInteractive: true,
        onConfigChanged: (json) => saved = json,
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('date_journal')),
      'Monday',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('prio_1')),
      'Finish report',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('prio_1')), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(CatalogConfigHelper.debounceDuration);
    final config = JournalBlockConfig.fromJsonString(saved!);
    expect(config.date, 'Monday');
    expect(config.priorities.first.text, 'Finish report');
  });
}
