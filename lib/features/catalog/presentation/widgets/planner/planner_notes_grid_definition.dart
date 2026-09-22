/// A graph paper grid note block for structured writing and sketching.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A graph paper grid note block with evenly spaced horizontal and vertical
/// lines, rendered via a custom painter.
///
/// Useful for diagrams, sketches, mathematical notes, or any content that
/// benefits from a grid reference.
final class PlannerNotesGridDefinition extends AgendaWidgetDefinition {
  const PlannerNotesGridDefinition();

  @override
  String get id => 'planner_notes_grid';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogTemplateGridNotes;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogTemplateGridNotesDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.grid_3x3_rounded;

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
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: const CustomPaint(
          painter: _GridPainter(gridColor: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.gridColor});
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;
    const spacing = 18.0;

    for (var x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.gridColor != gridColor;
}
