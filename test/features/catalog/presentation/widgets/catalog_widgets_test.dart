import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_page_dialog.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar_grid_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal_block_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box_widget.dart';

void main() {
  group('CatalogRegistry Tests', () {
    test(
      'contains geometric shapes, static planner templates, and stickers',
      () {
        final definitions = CatalogRegistry.getAllDefinitions();
        expect(definitions.length, greaterThanOrEqualTo(20));

        final ids = definitions.map((d) => d.id).toList();
        // Shapes
        expect(ids, contains('shape_box'));
        expect(ids, contains('shape_circle'));
        expect(ids, contains('shape_divider'));
        expect(ids, contains('shape_banner'));
        expect(ids, contains('shape_frame'));
        expect(ids, contains('shape_star'));
        expect(ids, contains('shape_pill'));

        // Planner templates
        expect(ids, contains('planner_sticky_note'));
        expect(ids, contains('planner_washi_tape'));
        expect(ids, contains('planner_weekly_columns'));
        expect(ids, contains('planner_checklist'));
        expect(ids, contains('planner_habit_tracker'));
        expect(ids, contains('planner_priorities'));
        expect(ids, contains('planner_notes_lined'));
        expect(ids, contains('planner_notes_grid'));

        // Stickers
        expect(ids, contains('sticker_heart'));
        expect(ids, contains('sticker_star'));
        expect(ids, contains('sticker_coffee'));
        expect(ids, contains('sticker_pin'));

        // Legacy
        expect(ids, contains('calendar_grid'));
        expect(ids, contains('budget_calculator'));
        expect(ids, contains('journal_block'));
        expect(ids, contains('text_box'));
      },
    );

    test('getDefinitionsByCategory filters correctly', () {
      final shapes = CatalogRegistry.getDefinitionsByCategory(
        ElementCategory.shapes,
      );
      expect(shapes.length, 7);

      final planner = CatalogRegistry.getDefinitionsByCategory(
        ElementCategory.planner,
      );
      expect(planner.length, 8);

      final stickers = CatalogRegistry.getDefinitionsByCategory(
        ElementCategory.stickers,
      );
      expect(stickers.length, 4);
    });

    test('getDefinition returns correct instance or null for unknown', () {
      expect(
        CatalogRegistry.getDefinition('shape_box'),
        isA<ShapeBoxDefinition>(),
      );
      expect(
        CatalogRegistry.getDefinition('planner_sticky_note'),
        isA<PlannerStickyNoteDefinition>(),
      );
      expect(
        CatalogRegistry.getDefinition('calendar_grid'),
        isA<CalendarGridDefinition>(),
      );
      expect(
        CatalogRegistry.getDefinition('budget_calculator'),
        isA<BudgetWidgetDefinition>(),
      );
      expect(
        CatalogRegistry.getDefinition('journal_block'),
        isA<JournalBlockDefinition>(),
      );
      expect(
        CatalogRegistry.getDefinition('text_box'),
        isA<TextBoxDefinition>(),
      );
      expect(CatalogRegistry.getDefinition('unknown_widget'), isNull);
    });

    testWidgets('buildWidget renders fallback for unknown widget type', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => CatalogRegistry.buildWidget(
                context,
                widgetType: 'alien_widget',
                elementId: 'elem-1',
                configJson: '{}',
                isInteractive: false,
                onConfigChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Widget no reconocido: alien_widget'), findsOneWidget);
    });
  });

  group('CalendarGridWidget & CalendarGridConfig Tests', () {
    test('Config parsing with fallback', () {
      final config = CalendarGridConfig.fromJsonString('');
      expect(config.title, 'Hábitos Semanales');
      expect(config.habits.length, 3);
      expect(config.habits.first.checks.length, 7);

      final corruptConfig = CalendarGridConfig.fromJsonString('{invalid json');
      expect(corruptConfig.habits.length, 3);
    });

    testWidgets(
      'Renders days of week and allows toggling in interactive mode',
      (tester) async {
        String? updatedJson;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 350,
                height: 300,
                child: CalendarGridWidget(
                  elementId: 'cal-1',
                  configJson: CalendarGridConfig.defaultConfig().toJsonString(),
                  isInteractive: true,
                  onConfigChanged: (json) => updatedJson = json,
                ),
              ),
            ),
          ),
        );

        // Check day headers
        expect(find.text('L'), findsWidgets);
        expect(find.text('D'), findsWidgets);
        expect(find.text('Hábitos Semanales'), findsOneWidget);

        // Tap first day checkbox of first habit
        final checkIcons = find.byType(GestureDetector);
        expect(checkIcons, findsWidgets);
        await tester.tap(checkIcons.first);
        await tester.pumpAndSettle();

        expect(updatedJson, isNotNull);
        final newConfig = CalendarGridConfig.fromJsonString(updatedJson!);
        expect(newConfig.habits.isNotEmpty, isTrue);
      },
    );
  });

  group('BudgetWidget & BudgetConfig Tests', () {
    test('Live net balance and totals calculation', () {
      const config = BudgetConfig(
        title: 'Mi Presupuesto',
        currency: r'$',
        entries: [
          BudgetEntryItem(
            id: '1',
            description: 'Salario',
            amount: 3000,
            type: BudgetEntryType.income,
          ),
          BudgetEntryItem(
            id: '2',
            description: 'Freelance',
            amount: 500,
            type: BudgetEntryType.income,
          ),
          BudgetEntryItem(
            id: '3',
            description: 'Renta',
            amount: 1200,
            type: BudgetEntryType.expense,
          ),
        ],
      );

      expect(config.totalIncome, 3500.0);
      expect(config.totalExpenses, 1200.0);
      expect(config.netBalance, 2300.0);
    });

    testWidgets('Renders summary banner and supports adding entry', (
      tester,
    ) async {
      String? updatedJson;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: BudgetWidget(
                elementId: 'budget-1',
                configJson: BudgetConfig.defaultConfig().toJsonString(),
                isInteractive: true,
                onConfigChanged: (json) => updatedJson = json,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Presupuesto'), findsOneWidget);
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);

      // Tap 'Nueva entrada'
      final addBtn = find.text('Nueva entrada');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(updatedJson, isNotNull);
      final newConfig = BudgetConfig.fromJsonString(updatedJson!);
      expect(newConfig.entries.length, 4);
    });
  });

  group('JournalBlockWidget & JournalBlockConfig Tests', () {
    test('Config parsing and serialization', () {
      final config = JournalBlockConfig.defaultConfig();
      final jsonStr = config.toJsonString();
      final decoded = JournalBlockConfig.fromJsonString(jsonStr);

      expect(decoded.mood, '😊');
      expect(decoded.priorities.length, 3);
    });

    testWidgets('Allows selecting mood in interactive mode', (tester) async {
      String? updatedJson;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 350,
              child: JournalBlockWidget(
                elementId: 'journal-1',
                configJson: JournalBlockConfig.defaultConfig().toJsonString(),
                isInteractive: true,
                onConfigChanged: (json) => updatedJson = json,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Prioridades del Día'), findsOneWidget);
      expect(find.text('Notas & Reflexión'), findsOneWidget);

      // Tap '⚡' mood
      final boltMood = find.text('⚡');
      expect(boltMood, findsOneWidget);
      await tester.tap(boltMood);
      await tester.pumpAndSettle();

      expect(updatedJson, isNotNull);
      final newConfig = JournalBlockConfig.fromJsonString(updatedJson!);
      expect(newConfig.mood, '⚡');
    });
  });

  group('TextBoxWidget & TextBoxConfig Tests', () {
    test('Color parsing and default sizes', () {
      expect(TextBoxColor.fromString('rose'), TextBoxColor.rose);
      expect(TextBoxColor.fromString('sage'), TextBoxColor.sage);
      expect(TextBoxColor.fromString('unknown'), TextBoxColor.honey);

      final config = TextBoxConfig.defaultConfig();
      expect(config.fontSize, 14.0);
      expect(config.color, TextBoxColor.honey);
    });

    testWidgets('Renders text and allows editing in interactive mode', (
      tester,
    ) async {
      String? updatedJson;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250,
              height: 200,
              child: TextBoxWidget(
                elementId: 'text-1',
                configJson: TextBoxConfig.defaultConfig().toJsonString(),
                isInteractive: true,
                onConfigChanged: (json) => updatedJson = json,
              ),
            ),
          ),
        ),
      );

      // Check toolbar presence
      expect(find.byIcon(Icons.format_size_rounded), findsOneWidget);

      // Tap font size to cycle
      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();

      expect(updatedJson, isNotNull);
      final newConfig = TextBoxConfig.fromJsonString(updatedJson!);
      expect(newConfig.fontSize, 17.0);
    });
  });

  group('NewPageDesignDialog Tests', () {
    testWidgets(
      'renders 4 paper design options (Líneas, Puntos, En blanco, Cuadrícula)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: NewPageDesignDialog())),
        );

        expect(find.text('Diseño de la Página'), findsOneWidget);
        expect(find.text('Líneas'), findsOneWidget);
        expect(find.text('Puntos'), findsOneWidget);
        expect(find.text('En blanco'), findsOneWidget);
        expect(find.text('Cuadrícula'), findsOneWidget);
        expect(find.text('Crear Página'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting option and tapping Crear Página returns selected style',
      (tester) async {
        String? chosen;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    chosen = await showNewPageDesignDialog(context);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Tap 'Líneas'
        await tester.tap(find.text('Líneas'));
        await tester.pumpAndSettle();

        // Tap 'Crear Página'
        await tester.tap(find.text('Crear Página'));
        await tester.pumpAndSettle();

        expect(chosen, 'lined');
      },
    );
  });

  group('StaticDesignElements Rendering Tests', () {
    testWidgets('renders static shapes without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 100,
                  child: Builder(
                    builder: (context) => CatalogRegistry.buildWidget(
                      context,
                      widgetType: 'shape_box',
                      elementId: 'box-1',
                      configJson: '{}',
                      isInteractive: false,
                      onConfigChanged: (_) {},
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Builder(
                    builder: (context) => CatalogRegistry.buildWidget(
                      context,
                      widgetType: 'shape_circle',
                      elementId: 'circle-1',
                      configJson: '{}',
                      isInteractive: false,
                      onConfigChanged: (_) {},
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 150,
                  child: Builder(
                    builder: (context) => CatalogRegistry.buildWidget(
                      context,
                      widgetType: 'planner_sticky_note',
                      elementId: 'note-1',
                      configJson: '{}',
                      isInteractive: false,
                      onConfigChanged: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });
  });
}
