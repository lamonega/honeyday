import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/paper_style.dart';

export 'package:honeyday/core/theme/paper_style.dart';

/// CustomPainter rendering Layer 0 paper texture backgrounds.
///
/// What: Draws a creamy paper surface (#FFFDF7) and subtle grid/dot/line guidelines (#CBD5E1 / #E2E8F0).
/// Why: Provides an authentic physical agenda tactile feel while maintaining low CPU/GPU overhead.
class PaperSurfacePainter extends CustomPainter {
  /// Constructs a [PaperSurfacePainter].
  PaperSurfacePainter({
    required this.paperStyle,
    this.backgroundColor = const Color(0xFFFFFDF7),
    this.guidelineColor = const Color(0xFFCBD5E1),
    this.marginColor = const Color(0xFFE2E8F0),
    this.spacing = 24,
    this.margin = 24,
  }) : _backgroundPaint = Paint()
         ..color = backgroundColor
         ..style = PaintingStyle.fill,
       _dotPaint = Paint()
         ..color = guidelineColor
         ..style = PaintingStyle.fill,
       _linePaint = Paint()
         ..color = guidelineColor
         ..strokeWidth = 1
         ..style = PaintingStyle.stroke,
       _marginLinePaint = Paint()
         ..color = marginColor
         ..strokeWidth = 1.2
         ..style = PaintingStyle.stroke,
       _gridPaint = Paint()
         ..color = guidelineColor
         ..strokeWidth = 0.8
         ..style = PaintingStyle.stroke;

  /// Paper texture pattern.
  final PaperStyle paperStyle;

  /// Cream paper background fill color.
  final Color backgroundColor;

  /// Primary color for dots, lines, or grid intersections.
  final Color guidelineColor;

  /// Margin line boundary color.
  final Color marginColor;

  /// Grid cell distance in points.
  final double spacing;

  /// Page margin offset from edges in points.
  final double margin;

  final Paint _backgroundPaint;
  final Paint _dotPaint;
  final Paint _linePaint;
  final Paint _marginLinePaint;
  final Paint _gridPaint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    switch (paperStyle) {
      case PaperStyle.dotted:
        _drawDots(canvas, size);
      case PaperStyle.lined:
        _drawLined(canvas, size);
      case PaperStyle.grid:
        _drawGrid(canvas, size);
      case PaperStyle.blank:
        break;
    }
  }

  /// Draws a bullet journal dot grid.
  void _drawDots(Canvas canvas, Size size) {
    for (var y = margin; y <= size.height - margin; y += spacing) {
      for (var x = margin; x <= size.width - margin; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, _dotPaint);
      }
    }
  }

  /// Draws horizontal notebook lines.
  void _drawLined(Canvas canvas, Size size) {
    // Draw left vertical notebook margin line
    canvas.drawLine(
      Offset(margin * 1.5, margin),
      Offset(margin * 1.5, size.height - margin),
      _marginLinePaint,
    );

    // Draw horizontal ruled lines
    for (var y = margin + spacing; y <= size.height - margin; y += spacing) {
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        _linePaint,
      );
    }
  }

  /// Draws a graph paper grid.
  void _drawGrid(Canvas canvas, Size size) {
    // Horizontal lines
    for (var y = margin; y <= size.height - margin; y += spacing) {
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        _gridPaint,
      );
    }

    // Vertical lines
    for (var x = margin; x <= size.width - margin; x += spacing) {
      canvas.drawLine(
        Offset(x, margin),
        Offset(x, size.height - margin),
        _gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PaperSurfacePainter oldDelegate) {
    return oldDelegate.paperStyle != paperStyle ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.guidelineColor != guidelineColor ||
        oldDelegate.marginColor != marginColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.margin != margin;
  }
}

/// Widget presenting the Layer 0 paper background for an agenda page.
///
/// What: Encapsulates [PaperSurfacePainter] inside a [RepaintBoundary].
/// Why: Isolates paper background rasterization from frequent ink and widget updates.
class PageSurface extends StatelessWidget {
  /// Constructs a [PageSurface].
  const PageSurface({
    required this.paperStyle,
    super.key,
    this.backgroundColor = const Color(0xFFFFFDF7),
    this.guidelineColor = const Color(0xFFCBD5E1),
    this.marginColor = const Color(0xFFE2E8F0),
    this.spacing = 24,
    this.margin = 24,
    this.child,
  });

  /// Paper texture pattern.
  final PaperStyle paperStyle;

  /// Background color.
  final Color backgroundColor;

  /// Color for guidelines and dots.
  final Color guidelineColor;

  /// Margin line color.
  final Color marginColor;

  /// Grid cell spacing.
  final double spacing;

  /// Page margin offset.
  final double margin;

  /// Optional child layered directly above the surface.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: PaperSurfacePainter(
          paperStyle: paperStyle,
          backgroundColor: backgroundColor,
          guidelineColor: guidelineColor,
          marginColor: marginColor,
          spacing: spacing,
          margin: margin,
        ),
        child: child,
      ),
    );
  }
}
