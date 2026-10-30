import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  for (final id in ['budget_calculator', 'calendar_grid', 'journal_block']) {
    testWidgets('$id resolves distinct labels for each default item', (
      tester,
    ) async {
      final definition = CatalogRegistry.getDefinition(id)!;
      late AppLocalizations l10n;
      await tester.pumpWidget(
        testMaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: Builder(
                builder: (context) {
                  l10n = AppLocalizations.of(context);
                  return definition.build(
                    context,
                    elementId: 'element',
                    configJson: definition.initialConfigJson,
                    isInteractive: false,
                    onConfigChanged: (_) {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      final labels = switch (id) {
        'budget_calculator' => [
          l10n.catalogBudgetDefaultIncome,
          l10n.catalogBudgetDefaultExpense1,
          l10n.catalogBudgetDefaultExpense2,
        ],
        'calendar_grid' => [
          l10n.catalogHabitsDefault1,
          l10n.catalogHabitsDefault2,
          l10n.catalogHabitsDefault3,
        ],
        _ => [
          l10n.catalogJournalPriority1,
          l10n.catalogJournalPriority2,
          l10n.catalogJournalPriority3,
        ],
      };
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  }
}
