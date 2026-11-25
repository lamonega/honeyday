import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar_grid_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/catalog_widget_mixin.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal_block_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box/text_box_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box_widget.dart';

import '../../../../helpers/pump_app.dart';

Future<void> _pumpEditor(WidgetTester tester, Widget editor) =>
    tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(body: SizedBox(width: 400, height: 600, child: editor)),
      ),
    );

String _fieldText(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .controller
    .text;

void main() {
  testWidgets('a note on light paper keeps dark ink in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      testMaterialApp(
        home: Theme(
          data: ThemeData.dark(),
          child: Scaffold(
            body: SizedBox(
              width: 220,
              height: 180,
              child: TextBoxWidget(
                elementId: 'note',
                configJson: '{"text":"Readable note","color":"transparent"}',
                isInteractive: false,
                onConfigChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final note = tester.widget<Text>(find.text('Readable note'));
    expect(note.style?.color, AppColors.inkPrimary);
  });

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

  testWidgets('clearing a budget row keeps fields empty and persists zero', (
    tester,
  ) async {
    final initial = BudgetConfig.defaultConfig();
    String? saved;
    Widget editor(String configJson) => BudgetWidget(
      elementId: 'budget',
      configJson: configJson,
      isInteractive: true,
      onConfigChanged: (json) => saved = json,
    );
    await _pumpEditor(tester, editor(initial.toJsonString()));
    final description = find.byKey(const ValueKey('desc_1'));
    final amount = find.byKey(const ValueKey('amt_1'));
    await tester.enterText(description, 'Salary');
    await tester.enterText(amount, '17,50');
    await tester.pump(CatalogConfigHelper.debounceDuration);
    await _pumpEditor(tester, editor(saved!));
    expect(_fieldText(tester, amount), '17,50');

    await tester.enterText(description, '');
    await tester.enterText(amount, '');
    await tester.pump(CatalogConfigHelper.debounceDuration);
    await _pumpEditor(tester, editor(saved!));

    expect(_fieldText(tester, description), isEmpty);
    expect(_fieldText(tester, amount), isEmpty);
    final entry = BudgetConfig.fromJsonString(saved!).entries.first;
    expect(entry.description, isEmpty);
    expect(entry.amount, 0);
  });

  testWidgets('habit field adopts external config without remounting', (
    tester,
  ) async {
    final initial = CalendarGridConfig.defaultConfig();
    Widget editor(CalendarGridConfig config) => CalendarGridWidget(
      elementId: 'calendar',
      configJson: config.toJsonString(),
      isInteractive: true,
      onConfigChanged: (_) {},
    );
    await _pumpEditor(tester, editor(initial));
    final modified = [
      initial.habits.first.copyWith(title: 'Reloaded'),
      ...initial.habits.skip(1),
    ];
    await _pumpEditor(tester, editor(initial.copyWith(habits: modified)));
    final field = find.byKey(const ValueKey('habit_1'));
    expect(_fieldText(tester, field), 'Reloaded');
  });

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

    for (final field in [
      find.byKey(const ValueKey('date_journal')),
      find.byKey(const ValueKey('prio_1')),
      find.byKey(const ValueKey('notes_journal')),
    ]) {
      await tester.enterText(field, 'draft');
      await tester.pump();
      await tester.enterText(field, '');
      await tester.pump();
      expect(_fieldText(tester, field), isEmpty);
    }
    await tester.pump(CatalogConfigHelper.debounceDuration);
    final cleared = JournalBlockConfig.fromJsonString(saved!);
    expect(cleared.date, isEmpty);
    expect(cleared.priorities.first.text, isEmpty);
    expect(cleared.notes, isEmpty);
  });

  testWidgets('CatalogConfigHelper.updateFromJson cancels pending debounce', (
    tester,
  ) async {
    final emitted = <String>[];
    final helper =
        CatalogConfigHelper<TextBoxConfig>(
            parseConfig: TextBoxConfig.fromJsonString,
            configToJson: (c) => c.toJsonString(),
            initialJson: TextBoxConfig.defaultConfig().toJsonString(),
          )
          ..onConfigChanged = emitted.add
          ..updateConfig(
            TextBoxConfig.defaultConfig().copyWith(text: 'stale draft'),
          )
          ..updateFromJson('{"text":"external undo","color":"rose"}');

    await tester.pump(CatalogConfigHelper.debounceDuration * 2);
    expect(emitted, isEmpty);
    expect(helper.config.text, 'external undo');
    expect(helper.config.color, TextBoxColor.rose);
    helper.dispose();
  });

  testWidgets('switching isInteractive to false flushes pending edits', (
    tester,
  ) async {
    String? saved;
    final initialJson = TextBoxConfig.defaultConfig().toJsonString();
    Widget buildBox({required bool interactive}) => TextBoxWidget(
      elementId: 'note-flush',
      configJson: initialJson,
      isInteractive: interactive,
      onConfigChanged: (json) => saved = json,
    );

    await _pumpEditor(tester, buildBox(interactive: true));
    await tester.enterText(
      find.byKey(const ValueKey('text_note-flush')),
      'Flush me',
    );
    expect(saved, isNull);

    await _pumpEditor(tester, buildBox(interactive: false));
    expect(saved, isNotNull);
    expect(TextBoxConfig.fromJsonString(saved!).text, 'Flush me');
  });

  test(
    'TextBoxConfig handles hex colors from CanvasActionBar and vice versa',
    () {
      final baseJson = TextBoxConfig.defaultConfig().toJsonString();

      // Hex matching existing preset maps back to the preset.
      final roseHexJson = ElementConfig.updateColorInJson(
        baseJson,
        fillColor: TextBoxColor.rose.color,
        borderColor: const Color(0xFFE11D48),
      );
      final roseConfig = TextBoxConfig.fromJsonString(roseHexJson);
      expect(roseConfig.color, TextBoxColor.rose);
      expect(roseConfig.customColor, isNull);
      expect(roseConfig.effectiveColor, TextBoxColor.rose.color);

      // Custom hex from CanvasActionBar (violet) is preserved and round-trips.
      const violet = Color(0xFFEDE9FE);
      final violetHexJson = ElementConfig.updateColorInJson(
        baseJson,
        fillColor: violet,
        borderColor: const Color(0xFF7C3AED),
      );
      final violetConfig = TextBoxConfig.fromJsonString(violetHexJson);
      expect(violetConfig.customColor, violet);
      expect(violetConfig.effectiveColor, violet);
      expect(
        TextBoxConfig.fromJsonString(violetConfig.toJsonString())
            .effectiveColor,
        violet,
      );

      // ElementConfig recognizes TextBoxColor named presets.
      expect(
        ElementConfig.fromJsonString('{"color":"rose"}').fillColor,
        TextBoxColor.rose.color,
      );
      expect(
        ElementConfig.fromJsonString('{"color":"sage"}').fillColor,
        TextBoxColor.sage.color,
      );
      expect(
        ElementConfig.fromJsonString('{"color":"transparent"}').fillColor,
        Colors.transparent,
      );
    },
  );

  testWidgets(
    'BudgetEntryRow resets invalid amount on unfocus and mode switch',
    (tester) async {
      final config = BudgetConfig.defaultConfig();
      Widget buildBudget({required bool interactive}) => BudgetWidget(
        elementId: 'budget-reset',
        configJson: config.toJsonString(),
        isInteractive: interactive,
        onConfigChanged: (_) {},
      );

      await _pumpEditor(tester, buildBudget(interactive: true));
      final amountField = find.byKey(const ValueKey('amt_1'));
      await tester.enterText(amountField, '123');
      await tester.pump();

      // Type invalid input then blur focus.
      await tester.enterText(amountField, '-99abc');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(_fieldText(tester, amountField), '123');

      // Type invalid input then transition isInteractive true -> false.
      await tester.enterText(amountField, 'NaN');
      await tester.pump();
      await _pumpEditor(tester, buildBudget(interactive: false));
      await _pumpEditor(tester, buildBudget(interactive: true));
      expect(_fieldText(tester, amountField), '123');
    },
  );

  testWidgets('deleting a budget row preserves sibling row ValueKey state', (
    tester,
  ) async {
    final config = BudgetConfig.defaultConfig();
    await _pumpEditor(
      tester,
      BudgetWidget(
        elementId: 'budget-keys',
        configJson: config.toJsonString(),
        isInteractive: true,
        onConfigChanged: (_) {},
      ),
    );

    // Edit second row description and amount.
    await tester.enterText(find.byKey(const ValueKey('desc_2')), 'Groceries');
    await tester.enterText(find.byKey(const ValueKey('amt_2')), '75');
    await tester.pump();

    // Delete first row.
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();

    expect(find.byKey(const ValueKey('desc_1')), findsNothing);
    expect(
      _fieldText(tester, find.byKey(const ValueKey('desc_2'))),
      'Groceries',
    );
    expect(_fieldText(tester, find.byKey(const ValueKey('amt_2'))), '75');
    await tester.pump(CatalogConfigHelper.debounceDuration);
  });
}
