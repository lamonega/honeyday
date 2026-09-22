/// A notebook-ruled note block with horizontal writing lines.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A notebook-ruled note block with evenly spaced horizontal lines.
///
/// Provides a clean writing surface for freeform notes, journaling, or
/// longer-form content.
final class PlannerNotesLinedDefinition extends AgendaWidgetDefinition {
  const PlannerNotesLinedDefinition();

  @override
  String get id => 'planner_notes_lined';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogTemplateLinedNotes;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogTemplateLinedNotesDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.view_headline_rounded;

  @override
  Size get defaultSize => const Size(280, 220);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#FFFFFF',
    borderColorHex: '#CBD5E1',
    borderWidth: 1,
  ).toJsonString();

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          8,
          (_) => Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
