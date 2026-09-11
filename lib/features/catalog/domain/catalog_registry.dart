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
///
/// What: Maintains the catalog of available agenda canvas shapes, layout templates,
/// stickers, and legacy widgets, providing query and factory builder methods for the UI layer.
/// Why: Decouples canvas page rendering and element insertion dialogs from concrete element
/// implementations, facilitating modular Canva-like extensibility.
abstract final class CatalogRegistry {
  static const Map<String, AgendaWidgetDefinition> _definitions = {
    // Geometric Shapes (Formas básicas)
    'shape_box': ShapeBoxDefinition(),
    'shape_circle': ShapeCircleDefinition(),
    'shape_divider': ShapeDividerDefinition(),
    'shape_banner': ShapeBannerDefinition(),
    'shape_frame': ShapeFrameDefinition(),
    'shape_star': ShapeStarDefinition(),
    'shape_pill': ShapePillDefinition(),

    // Static Planner Templates (Plantillas de agenda)
    'planner_sticky_note': PlannerStickyNoteDefinition(),
    'planner_washi_tape': PlannerWashiTapeDefinition(),
    'planner_weekly_columns': PlannerWeeklyColumnsDefinition(),
    'planner_checklist': PlannerChecklistDefinition(),
    'planner_habit_tracker': PlannerHabitTrackerDefinition(),
    'planner_priorities': PlannerPrioritiesDefinition(),
    'planner_notes_lined': PlannerNotesLinedDefinition(),
    'planner_notes_grid': PlannerNotesGridDefinition(),

    // Decorative Stickers
    'sticker_heart': StickerHeartDefinition(),
    'sticker_star': StickerStarDefinition(),
    'sticker_coffee': StickerCoffeeDefinition(),
    'sticker_pin': StickerPinDefinition(),

    // Legacy modular widgets (preserved for backwards compatibility)
    'calendar_grid': CalendarGridDefinition(),
    'budget_calculator': BudgetWidgetDefinition(),
    'journal_block': JournalBlockDefinition(),
    'text_box': TextBoxDefinition(),
  };

  /// Returns an unmodifiable list of all registered widget definitions.
  static List<AgendaWidgetDefinition> getAllDefinitions() {
    return List.unmodifiable(_definitions.values);
  }

  /// Returns all design elements (shapes, planner templates, stickers), excluding legacy widgets.
  static List<AgendaWidgetDefinition> getDesignElements() {
    return _definitions.values
        .where((d) => d.category != ElementCategory.legacy)
        .toList();
  }

  /// Returns element definitions filtered by category.
  static List<AgendaWidgetDefinition> getDefinitionsByCategory(
    ElementCategory category,
  ) {
    return _definitions.values
        .where((d) => d.category == category)
        .toList();
  }

  /// Retrieves a specific widget definition by its discriminator [widgetType] ID.
  ///
  /// Returns `null` if the widget type is not registered.
  static AgendaWidgetDefinition? getDefinition(String widgetType) {
    return _definitions[widgetType];
  }

  /// Checks if a [widgetType] is recognized by the registry.
  static bool hasDefinition(String widgetType) {
    return _definitions.containsKey(widgetType);
  }

  /// Builds a registered widget matching [widgetType].
  ///
  /// If [widgetType] is unknown, renders a styled fallback card indicating the missing definition.
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

    // Graceful fallback for unrecognized widget types
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE11D48),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Widget no reconocido: $widgetType',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9F1239),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
