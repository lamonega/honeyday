import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for a versatile geometric box/card element.
///
/// Used by [CatalogRegistry] to register in the catalog sidebar.
final class ShapeBoxDefinition extends AgendaWidgetDefinition {
  const ShapeBoxDefinition();

  @override
  String get id => 'shape_box';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeRectangle;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeRectangleDesc;

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.check_box_outline_blank_rounded;

  @override
  Size get defaultSize => const Size(260, 180);

  @override
  String get initialConfigJson =>
      const ElementConfig(cornerRadius: 16).toJsonString();

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
        borderRadius: BorderRadius.circular(config.cornerRadius),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
