import 'package:flutter/widgets.dart';

/// Categorization for catalog elements and widgets.
enum ElementCategory {
  /// Basic geometric shapes (rectangles, circles, dividers, banners, frames).
  shapes('Formas', 'Formas geométricas básicas'),

  /// Static planner layout templates (weekly columns, checklists, habits, notes).
  planner('Agenda', 'Plantillas y estructuras para agendas'),

  /// Decorative aesthetic stickers and icons.
  stickers('Stickers', 'Stickers y elementos decorativos'),

  /// Legacy interactive widgets (calendar, budget, etc.).
  legacy('Otros', 'Otros bloques');

  ElementCategory(this.label, this.description);

  /// User-facing short label for category tabs and chips.
  final String label;

  /// Explanatory description.
  final String description;
}

/// Abstract contract defining a modular, reusable agenda canvas widget.
///
/// What: Specifies widget identification, display metadata, initial sizing,
/// default configuration serialization, and an instantiation builder.
/// Why: Decouples the freeform canvas layout engine from widget-specific
/// presentation and editing logic, allowing new catalog items to be registered
/// without modifying core canvas renderers.
abstract class AgendaWidgetDefinition {
  /// Const constructor allowing subclasses to have const declarations.
  const AgendaWidgetDefinition();

  /// Unique discriminator identifier persisted in `CanvasElements.widgetType`
  /// (e.g., `'shape_box'`, `'planner_sticky_note'`, `'calendar_grid'`).
  String get id;

  /// Human-readable title displayed in widget catalog pickers and inspector toolbars.
  String get name;

  /// Brief description explaining what the element is used for.
  String get description => '';

  /// Category grouping for sidebar tabs and discovery.
  ElementCategory get category => ElementCategory.legacy;

  /// Representative icon for catalog sheets, insertion dialogs, and mode toolbars.
  IconData get icon;

  /// Default unscaled virtual dimensions (width and height) when first dropped onto a page.
  Size get defaultSize;

  /// Initial default JSON configuration payload used when instantiating a new element.
  String get initialConfigJson;

  /// Builds the widget tree for the canvas element.
  ///
  /// - [context]: Build context from the enclosing canvas element wrapper.
  /// - [elementId]: Unique UUID of the canvas element row in Drift SQLite.
  /// - [configJson]: Current JSON state payload storing widget contents.
  /// - [isInteractive]: True when in writing mode (interactive inputs enabled);
  ///   false when in reading or layout edit mode (controls disabled or read-only).
  /// - [onConfigChanged]: Callback invoked when user edits widget data,
  ///   passing back updated serialized JSON for debounced persistence.
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  });
}
