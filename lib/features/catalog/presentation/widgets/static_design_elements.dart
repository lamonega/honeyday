import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

// =============================================================================
// SHAPES (Formas Geométricas)
// =============================================================================

/// Definition for a versatile geometric box/card element.
class ShapeBoxDefinition extends AgendaWidgetDefinition {
  const ShapeBoxDefinition();

  @override
  String get id => 'shape_box';

  @override
  String get name => 'Caja / Rectángulo';

  @override
  String get description => 'Tarjeta o contenedor para estructurar secciones';

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.check_box_outline_blank_rounded;

  @override
  Size get defaultSize => const Size(260, 180);

  @override
  String get initialConfigJson => const ElementConfig(
        cornerRadius: 16,
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

/// Definition for an aesthetic geometric circle or ellipse shape.
class ShapeCircleDefinition extends AgendaWidgetDefinition {
  const ShapeCircleDefinition();

  @override
  String get id => 'shape_circle';

  @override
  String get name => 'Círculo / Óvalo';

  @override
  String get description => 'Forma circular o elíptica estética';

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

/// Definition for a decorative horizontal divider line.
class ShapeDividerDefinition extends AgendaWidgetDefinition {
  const ShapeDividerDefinition();

  @override
  String get id => 'shape_divider';

  @override
  String get name => 'Línea Divisoria';

  @override
  String get description => 'Línea separadora estética para la página';

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

/// Definition for a decorative banner / ribbon header shape.
class ShapeBannerDefinition extends AgendaWidgetDefinition {
  const ShapeBannerDefinition();

  @override
  String get id => 'shape_banner';

  @override
  String get name => 'Banderín / Ribbon';

  @override
  String get description => 'Cinta de encabezado estilo Canva';

  @override
  ElementCategory get category => ElementCategory.shapes;

  @override
  IconData get icon => Icons.bookmark_outline_rounded;

  @override
  Size get defaultSize => const Size(280, 52);

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
      painter: _BannerPainter(
        fillColor: config.fillColor,
        borderColor: config.borderColor,
        borderWidth: config.borderWidth,
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  const _BannerPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 16.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - cut, size.height / 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(cut, size.height / 2)
      ..close();

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
  bool shouldRepaint(covariant _BannerPainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth;
}

/// Definition for a decorative page frame / border.
class ShapeFrameDefinition extends AgendaWidgetDefinition {
  const ShapeFrameDefinition();

  @override
  String get id => 'shape_frame';

  @override
  String get name => 'Marco Decorativo';

  @override
  String get description => 'Marco perimetral elegante adaptable a toda la página';

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

/// Definition for a geometric star shape.
class ShapeStarDefinition extends AgendaWidgetDefinition {
  const ShapeStarDefinition();

  @override
  String get id => 'shape_star';

  @override
  String get name => 'Estrella';

  @override
  String get description => 'Estrella geométrica decorativa';

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

/// Definition for a pill/capsule badge shape.
class ShapePillDefinition extends AgendaWidgetDefinition {
  const ShapePillDefinition();

  @override
  String get id => 'shape_pill';

  @override
  String get name => 'Cápsula / Etiqueta';

  @override
  String get description => 'Forma alargada con extremos redondeados';

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

// =============================================================================
// PLANNER TEMPLATES (Plantillas Estáticas de Agenda)
// =============================================================================

/// Definition for a sticky post-it note with aesthetic shadow and pin.
class PlannerStickyNoteDefinition extends AgendaWidgetDefinition {
  const PlannerStickyNoteDefinition();

  @override
  String get id => 'planner_sticky_note';

  @override
  String get name => 'Nota Adhesiva (Post-It)';

  @override
  String get description => 'Nota de papel estática con chincheta y líneas para escribir';

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.note_rounded;

  @override
  Size get defaultSize => const Size(220, 200);

  @override
  String get initialConfigJson => const ElementConfig(
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
            padding: const EdgeInsets.only(top: 36, left: 16, right: 16, bottom: 12),
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

/// Definition for decorative washi tape with jagged edges.
class PlannerWashiTapeDefinition extends AgendaWidgetDefinition {
  const PlannerWashiTapeDefinition();

  @override
  String get id => 'planner_washi_tape';

  @override
  String get name => 'Cinta Washi Tape';

  @override
  String get description => 'Tira decorativa semitransparente con diseño';

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
  const _WashiTapePainter({
    required this.color,
    required this.accentColor,
  });

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

/// Definition for a 7-day weekly layout spread (Lunes a Domingo).
class PlannerWeeklyColumnsDefinition extends AgendaWidgetDefinition {
  const PlannerWeeklyColumnsDefinition();

  @override
  String get id => 'planner_weekly_columns';

  @override
  String get name => 'Columnas Semanales (L-D)';

  @override
  String get description => 'Estructura de 7 días para planificar la semana a mano';

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.view_week_outlined;

  @override
  Size get defaultSize => const Size(720, 280);

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
    const days = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

    return Container(
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor, width: config.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(7, (index) {
          final isWeekend = index >= 5;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: index < 6
                    ? Border(
                        right: BorderSide(
                          color: config.borderColor.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
              child: Column(
                children: [
                  // Day header badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isWeekend
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(index == 0 ? 15 : 0),
                        topRight: Radius.circular(index == 6 ? 15 : 0),
                      ),
                    ),
                    child: Text(
                      days[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isWeekend
                            ? const Color(0xFFB45309)
                            : const Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Ruled writing lines
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (_) => Container(
                            height: 1,
                            color: config.borderColor.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Definition for a static aesthetic checklist template.
class PlannerChecklistDefinition extends AgendaWidgetDefinition {
  const PlannerChecklistDefinition();

  @override
  String get id => 'planner_checklist';

  @override
  String get name => 'Bloque Checklist';

  @override
  String get description => 'Lista con casillas de verificación estéticas para escribir tareas';

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.checklist_rounded;

  @override
  Size get defaultSize => const Size(260, 300);

  @override
  String get initialConfigJson => const ElementConfig(
        colorHex: '#FFFFFF',
        borderColorHex: '#E2E8F0',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor, width: config.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CHECKLIST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Checkbox lines
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF94A3B8),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Definition for a habit tracker grid template.
class PlannerHabitTrackerDefinition extends AgendaWidgetDefinition {
  const PlannerHabitTrackerDefinition();

  @override
  String get id => 'planner_habit_tracker';

  @override
  String get name => 'Tracker de Hábitos';

  @override
  String get description => 'Matriz de seguimiento semanal para colorear con el lápiz';

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.calendar_view_month_rounded;

  @override
  Size get defaultSize => const Size(320, 200);

  @override
  String get initialConfigJson => const ElementConfig(
        colorHex: '#FFFFFF',
        borderColorHex: '#E2E8F0',
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
    const dayHeaders = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor, width: config.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline_rounded, size: 14, color: Color(0xFFE11D48)),
              const SizedBox(width: 6),
              const Text(
                'HÁBITOS DE LA SEMANA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              ...dayHeaders.map(
                (d) => SizedBox(
                  width: 22,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (row) {
                return Row(
                  children: [
                    // Line for habit title
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 7 day bubbles
                    ...List.generate(
                      7,
                      (_) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Definition for a top priorities block.
class PlannerPrioritiesDefinition extends AgendaWidgetDefinition {
  const PlannerPrioritiesDefinition();

  @override
  String get id => 'planner_priorities';

  @override
  String get name => 'Caja de Prioridades';

  @override
  String get description => 'Estructura destacada para las 3 prioridades clave';

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.flag_outlined;

  @override
  Size get defaultSize => const Size(260, 180);

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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor, width: config.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: config.borderColor),
              const SizedBox(width: 6),
              Text(
                'PRIORIDADES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: config.borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                return Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: config.borderColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: config.borderColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: config.borderColor.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Definition for a notebook-ruled note block.
class PlannerNotesLinedDefinition extends AgendaWidgetDefinition {
  const PlannerNotesLinedDefinition();

  @override
  String get id => 'planner_notes_lined';

  @override
  String get name => 'Caja de Notas (Rayas)';

  @override
  String get description => 'Área de notas con renglones para escribir con precisión';

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
        border: Border.all(color: config.borderColor, width: config.borderWidth),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          8,
          (_) => Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}

/// Definition for a graph paper grid note block.
class PlannerNotesGridDefinition extends AgendaWidgetDefinition {
  const PlannerNotesGridDefinition();

  @override
  String get id => 'planner_notes_grid';

  @override
  String get name => 'Caja de Notas (Cuadrícula)';

  @override
  String get description => 'Área de notas con papel milimetrado o cuadrícula sutil';

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
        border: Border.all(color: config.borderColor, width: config.borderWidth),
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

// =============================================================================
// STICKERS (Stickers y Elementos Decorativos)
// =============================================================================

/// Definition for a heart sticker.
class StickerHeartDefinition extends AgendaWidgetDefinition {
  const StickerHeartDefinition();

  @override
  String get id => 'sticker_heart';

  @override
  String get name => 'Sticker Corazón';

  @override
  String get description => 'Icono decorativo de corazón';

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.favorite_border_rounded;

  @override
  Size get defaultSize => const Size(80, 80);

  @override
  String get initialConfigJson => const ElementConfig(
        colorHex: '#FFE4E6', // Rose 100
        borderColorHex: '#E11D48',
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
      child: Icon(
        Icons.favorite_rounded,
        size: math.min(100, 64),
        color: config.borderColor,
      ),
    );
  }
}

/// Definition for a star sticker.
class StickerStarDefinition extends AgendaWidgetDefinition {
  const StickerStarDefinition();

  @override
  String get id => 'sticker_star';

  @override
  String get name => 'Sticker Estrella';

  @override
  String get description => 'Icono decorativo de estrella brillante';

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.star_rounded;

  @override
  Size get defaultSize => const Size(80, 80);

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
    return Center(
      child: Icon(
        Icons.star_rounded,
        size: math.min(100, 64),
        color: config.borderColor,
      ),
    );
  }
}

/// Definition for a coffee mug sticker.
class StickerCoffeeDefinition extends AgendaWidgetDefinition {
  const StickerCoffeeDefinition();

  @override
  String get id => 'sticker_coffee';

  @override
  String get name => 'Sticker Café';

  @override
  String get description => 'Icono de descanso o café';

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.coffee_rounded;

  @override
  Size get defaultSize => const Size(80, 80);

  @override
  String get initialConfigJson => const ElementConfig(
        colorHex: '#FFEDD5',
        borderColorHex: '#9A3412',
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
      child: Icon(
        Icons.coffee_rounded,
        size: math.min(100, 64),
        color: config.borderColor,
      ),
    );
  }
}

/// Definition for a push-pin sticker.
class StickerPinDefinition extends AgendaWidgetDefinition {
  const StickerPinDefinition();

  @override
  String get id => 'sticker_pin';

  @override
  String get name => 'Sticker Chincheta';

  @override
  String get description => 'Chincheta decorativa para notas y tarjetas';

  @override
  ElementCategory get category => ElementCategory.stickers;

  @override
  IconData get icon => Icons.push_pin_outlined;

  @override
  Size get defaultSize => const Size(70, 70);

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
    return Center(
      child: Transform.rotate(
        angle: 0.3,
        child: Icon(
          Icons.push_pin_rounded,
          size: math.min(80, 56),
          color: config.borderColor,
        ),
      ),
    );
  }
}
