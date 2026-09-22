import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for an aesthetic geometric circle or ellipse shape.
///
/// Used by [CatalogRegistry] to register in the catalog sidebar.
final class ShapeCircleDefinition extends AgendaWidgetDefinition {
  const ShapeCircleDefinition();

  @override
  String get id => 'shape_circle';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeCircle;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeCircleDesc;

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  Size get defaultSize => const Size(160, 160);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#EDE9FE',
    borderColorHex: '#7C3AED',
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
        shape: BoxShape.circle,
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
