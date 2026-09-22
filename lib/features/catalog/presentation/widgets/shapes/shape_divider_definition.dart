import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for a decorative horizontal divider line.
///
/// Used by [CatalogRegistry] to register in the catalog sidebar.
final class ShapeDividerDefinition extends AgendaWidgetDefinition {
  const ShapeDividerDefinition();

  @override
  String get id => 'shape_divider';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeDivider;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeDividerDesc;

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.horizontal_rule_rounded;

  @override
  Size get defaultSize => const Size(320, 24);

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
    return Center(
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: config.borderWidth,
              decoration: BoxDecoration(
                color: config.borderColor,
                borderRadius: BorderRadius.circular(config.borderWidth),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: config.borderColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: config.borderWidth,
              decoration: BoxDecoration(
                color: config.borderColor,
                borderRadius: BorderRadius.circular(config.borderWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
