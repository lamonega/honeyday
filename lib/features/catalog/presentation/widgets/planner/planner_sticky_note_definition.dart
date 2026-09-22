/// A sticky post-it note element with an aesthetic shadow and top pin accent.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A sticky post-it note with aesthetic shadow, subtle writing lines, and a
/// decorative pin or tape accent at the top.
///
/// Suitable for quick notes, reminders, and decorative annotations on a
/// planner page.
final class PlannerStickyNoteDefinition extends AgendaWidgetDefinition {
  const PlannerStickyNoteDefinition();

  @override
  String get id => 'planner_sticky_note';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogShapeStickyNote;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeStickyNoteDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.note_rounded;

  @override
  Size get defaultSize => const Size(220, 200);

  @override
  String get initialConfigJson =>
      const ElementConfig(borderWidth: 1).toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    return Container(
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle horizontal writing lines
          Padding(
            padding: const EdgeInsets.only(
              top: 36,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (_) => Container(
                  height: 1,
                  color: config.borderColor.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // Top pin or tape accent
          Center(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 38,
                height: 12,
                decoration: BoxDecoration(
                  color: config.borderColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
