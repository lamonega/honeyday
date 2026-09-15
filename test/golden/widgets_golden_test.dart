import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/widgets/agenda_card.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

void main() {
  group('Catalog & Agenda Widgets Golden Tests', () {
    unawaited(
      goldenTest(
        'AgendaCard covers render properly',
        fileName: 'agenda_card_covers',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(
            maxWidth: 320,
            maxHeight: 380,
          ),
          children: [
            GoldenTestScenario(
              name: 'Honey Amber Cover',
              child: SizedBox(
                width: 300,
                height: 360,
                child: AgendaCard(
                  agenda: Agenda(
                    id: 'agenda-1',
                    title: 'Agenda Anual 2026',
                    coverStyle: 'honey',
                    pageCount: 12,
                    createdAt: DateTime(2026, 9, 11),
                    updatedAt: DateTime(2026, 9, 11),
                  ),
                  onOpenWriting: () {},
                  onOpenReading: () {},
                  onOpenEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Lavender Purple Cover',
              child: SizedBox(
                width: 300,
                height: 360,
                child: AgendaCard(
                  agenda: Agenda(
                    id: 'agenda-2',
                    title: 'Diario Personal',
                    coverStyle: 'lavender',
                    pageCount: 5,
                    createdAt: DateTime(2026, 9, 11),
                    updatedAt: DateTime(2026, 9, 11),
                  ),
                  onOpenWriting: () {},
                  onOpenReading: () {},
                  onOpenEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );

    unawaited(
      goldenTest(
        'Catalog modular widgets render properly',
        fileName: 'catalog_widgets_group',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(
            maxWidth: 380,
            maxHeight: 340,
          ),
          children: [
            GoldenTestScenario(
              name: 'Calendar Week Grid',
              child: SizedBox(
                width: 360,
                height: 300,
                child: Builder(
                  builder: (context) => CatalogRegistry.buildWidget(
                    context,
                    widgetType: 'calendar_grid',
                    elementId: 'elem-cal-1',
                    configJson: '{}',
                    isInteractive: true,
                    onConfigChanged: (_) {},
                  ),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Budget Calculator',
              child: SizedBox(
                width: 360,
                height: 300,
                child: Builder(
                  builder: (context) => CatalogRegistry.buildWidget(
                    context,
                    widgetType: 'budget_calculator',
                    elementId: 'elem-budget-1',
                    configJson: '{}',
                    isInteractive: true,
                    onConfigChanged: (_) {},
                  ),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Journal Entry Block',
              child: SizedBox(
                width: 360,
                height: 300,
                child: Builder(
                  builder: (context) => CatalogRegistry.buildWidget(
                    context,
                    widgetType: 'journal_block',
                    elementId: 'elem-journal-1',
                    configJson: '{}',
                    isInteractive: true,
                    onConfigChanged: (_) {},
                  ),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Sticker Text Box',
              child: SizedBox(
                width: 360,
                height: 300,
                child: Builder(
                  builder: (context) => CatalogRegistry.buildWidget(
                    context,
                    widgetType: 'text_box',
                    elementId: 'elem-text-1',
                    configJson: '{}',
                    isInteractive: true,
                    onConfigChanged: (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });
}
