import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for a decorative page frame / border.
///
/// Used by [CatalogRegistry] to register in the catalog sidebar.
final class ShapeFrameDefinition extends AgendaWidgetDefinition {
  const ShapeFrameDefinition();

  @override
  String get id => 'shape_frame';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeFrame;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeFrameDesc;

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.crop_square_rounded;

  @override
  Size get defaultSize => const Size(320, 420);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: 'transparent',
    borderWidth: 2,
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
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: config.fillColor,
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: config.borderColor.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
