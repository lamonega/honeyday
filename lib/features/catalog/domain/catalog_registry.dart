import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/presentation/widgets/budget_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar_grid_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal_block_widget.dart';
import 'package:honeyday/features/catalog/presentation/widgets/static_design_elements.dart';
import 'package:honeyday/features/catalog/presentation/widgets/text_box_widget.dart';

export 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
export 'package:honeyday/features/catalog/domain/element_config.dart';
export 'package:honeyday/features/catalog/presentation/widgets/static_design_elements.dart';

/// Central registry mapping widget type identifiers to concrete [AgendaWidgetDefinition]s.
abstract final class CatalogRegistry {
  static const Map<String, AgendaWidgetDefinition> _definitions = {
    'shape_box': ShapeBoxDefinition(),
    'shape_circle': ShapeCircleDefinition(),
    'shape_divider': ShapeDividerDefinition(),
    'shape_banner': ShapeBannerDefinition(),
    'shape_frame': ShapeFrameDefinition(),
    'shape_star': ShapeStarDefinition(),
    'shape_pill': ShapePillDefinition(),
    'planner_sticky_note': PlannerStickyNoteDefinition(),
    'planner_washi_tape': PlannerWashiTapeDefinition(),
    'planner_weekly_columns': PlannerWeeklyColumnsDefinition(),
    'planner_checklist': PlannerChecklistDefinition(),
    'planner_habit_tracker': PlannerHabitTrackerDefinition(),
    'planner_priorities': PlannerPrioritiesDefinition(),
    'planner_notes_lined': PlannerNotesLinedDefinition(),
    'planner_notes_grid': PlannerNotesGridDefinition(),
    'sticker_heart': StickerHeartDefinition(),
    'sticker_star': StickerStarDefinition(),
    'sticker_coffee': StickerCoffeeDefinition(),
    'sticker_pin': StickerPinDefinition(),
    'calendar_grid': CalendarGridDefinition(),
    'budget_calculator': BudgetWidgetDefinition(),
    'journal_block': JournalBlockDefinition(),
    'text_box': TextBoxDefinition(),
  };

  static List<AgendaWidgetDefinition> getAllDefinitions() {
    return List.unmodifiable(_definitions.values);
  }

  static List<AgendaWidgetDefinition> getDesignElements() {
    return _definitions.values
        .where((d) => d.category != ElementCategory.legacy)
        .toList();
  }

  static List<AgendaWidgetDefinition> getDefinitionsByCategory(
    ElementCategory category,
  ) {
    return _definitions.values
        .where((d) => d.category == category)
        .toList();
  }

  static AgendaWidgetDefinition? getDefinition(String widgetType) {
    return _definitions[widgetType];
  }

  static bool hasDefinition(String widgetType) {
    return _definitions.containsKey(widgetType);
  }

  /// Builds a registered widget matching [widgetType].
  ///
  /// If [widgetType] is unknown, renders a themed fallback card.
  static Widget buildWidget(
    BuildContext context, {
    required String widgetType,
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final definition = _definitions[widgetType];
    if (definition != null) {
      return definition.build(
        context,
        elementId: elementId,
        configJson: configJson,
        isInteractive: isInteractive,
        onConfigChanged: onConfigChanged,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Widget no reconocido: $widgetType',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
