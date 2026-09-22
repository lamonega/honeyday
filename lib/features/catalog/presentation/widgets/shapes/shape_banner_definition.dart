import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Definition for a decorative banner / ribbon header shape.
///
/// Used by [CatalogRegistry] to register in the catalog sidebar.
final class ShapeBannerDefinition extends AgendaWidgetDefinition {
  const ShapeBannerDefinition();

  @override
  String get id => 'shape_banner';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogShapePennant;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogShapePennantDesc;

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
