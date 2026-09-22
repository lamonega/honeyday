import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for a geometric star shape.
///
/// Used by [CatalogRegistry] to register in the catalog sidebar.
final class ShapeStarDefinition extends AgendaWidgetDefinition {
  const ShapeStarDefinition();

  @override
  String get id => 'shape_star';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeStar;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapeStarDesc;

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.star_outline_rounded;

  @override
  Size get defaultSize => const Size(100, 100);

  @override
  String get initialConfigJson => const ElementConfig().toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    return CustomPaint(
      painter: _StarPainter(
        fillColor: config.fillColor,
        borderColor: config.borderColor,
        borderWidth: config.borderWidth,
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) - borderWidth;
    final innerR = outerR * 0.45;
    const points = 5;
    const step = math.pi / points;

    for (var i = 0; i < 2 * points; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * step) - (math.pi / 2);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth;
}
