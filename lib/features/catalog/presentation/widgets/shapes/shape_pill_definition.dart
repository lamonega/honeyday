import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for a pill/capsule badge shape.
///
/// Used by `CatalogRegistry` to register in the catalog sidebar.
final class ShapePillDefinition extends AgendaWidgetDefinition {
  const ShapePillDefinition();

  @override
  String get id => 'shape_pill';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeLabel;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeLabelDesc;

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.label_outline_rounded;

  @override
  Size get defaultSize => const Size(200, 48);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#D1FAE5',
    borderColorHex: '#059669',
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
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
      ),
    );
  }
}
