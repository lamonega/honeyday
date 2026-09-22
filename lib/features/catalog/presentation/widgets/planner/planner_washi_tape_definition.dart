/// A decorative washi tape element with jagged edges and diagonal stripe pattern.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Decorative washi tape with jagged left/right edges and a subtle diagonal
/// stripe pattern.
///
/// Commonly used as a divider, section header accent, or decorative element
/// in planner spreads.
final class PlannerWashiTapeDefinition extends AgendaWidgetDefinition {
  const PlannerWashiTapeDefinition();

  @override
  String get id => 'planner_washi_tape';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogShapeTape;

  @override
  String description(BuildContext context) => AppLocalizations.of(context).catalogShapeTapeDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.horizontal_distribute_rounded;

  @override
  Size get defaultSize => const Size(220, 36);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#FFEDD5', // Orange 100
    borderColorHex: '#EA580C',
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
    return Opacity(
      opacity: 0.85,
      child: CustomPaint(
        painter: _WashiTapePainter(
          color: config.fillColor,
          accentColor: config.borderColor,
        ),
      ),
    );
  }
}

class _WashiTapePainter extends CustomPainter {
  const _WashiTapePainter({required this.color, required this.accentColor});

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const jagged = 5;
    final step = size.height / jagged;

    // Left jagged edge
    path.moveTo(4, 0);
    for (var i = 1; i <= jagged; i++) {
      final x = i.isOdd ? 0.0 : 5.0;
      path.lineTo(x, i * step);
    }
    // Bottom edge
    path.lineTo(size.width - 4, size.height);
    // Right jagged edge
    for (var i = jagged - 1; i >= 0; i--) {
      final x = i.isOdd ? size.width : size.width - 5.0;
      path.lineTo(x, i * step);
    }
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Subtle diagonal stripe pattern
    final stripePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WashiTapePainter old) =>
      old.color != color || old.accentColor != accentColor;
}
