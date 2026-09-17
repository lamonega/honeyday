import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;

/// CustomPainter rendering freehand vector ink strokes using `perfect_freehand`.
///
/// What: Draws completed strokes and dynamically renders active in-progress strokes.
/// Why: Vector paths allow infinite resolution and physical fountain pen styling without raster degradation.
class InkPainter extends CustomPainter {
  /// Constructs an [InkPainter].
  InkPainter({
    required this.strokes,
    this.activePoints,
    this.activeTool = InkToolType.pen,
    this.activeColor = const Color(0xFF1E293B),
    this.activeStrokeWidth = 3,
  }) : _eraserPaint = Paint()
         ..color = const Color(0xFF64748B).withValues(alpha: 0.4)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.5;

  /// Completed strokes on this page.
  final List<InkStroke> strokes;

  /// Points collected for a stroke currently being drawn by the user.
  final List<StrokePoint>? activePoints;

  /// Active brush tool for the current stroke.
  final InkToolType activeTool;

  /// Active color for the current stroke.
  final Color activeColor;

  /// Active width for the current stroke.
  final double activeStrokeWidth;

  final Paint _eraserPaint;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final strokePath = buildPath(
        stroke.points,
        strokeWidth: stroke.strokeWidth,
        tool: stroke.tool,
      );
      canvas.drawPath(strokePath, _buildStrokePaint(stroke));
    }

    if (activePoints != null && activePoints!.isNotEmpty) {
      if (activeTool == InkToolType.eraser) {
        final lastPoint = activePoints!.last;
        canvas.drawCircle(
          Offset(lastPoint.x, lastPoint.y),
          activeStrokeWidth / 2,
          _eraserPaint,
        );
      } else {
        final activePath = buildPath(
          activePoints!,
          strokeWidth: activeStrokeWidth,
          tool: activeTool,
        );
        canvas.drawPath(activePath, _buildActivePaint());
      }
    }
  }

  Paint _buildStrokePaint(InkStroke stroke) {
    final paint = Paint()..isAntiAlias = true;
    final color = colorFromHex(stroke.colorHex);
    if (stroke.tool == InkToolType.highlighter) {
      paint
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;
    } else {
      paint
        ..color = color
        ..style = PaintingStyle.fill;
    }
    return paint;
  }

  Paint _buildActivePaint() {
    final paint = Paint()..isAntiAlias = true;
    if (activeTool == InkToolType.highlighter) {
      paint
        ..color = activeColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;
    } else {
      paint
        ..color = activeColor
        ..style = PaintingStyle.fill;
    }
    return paint;
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) {
    if (activePoints != null || oldDelegate.activePoints != null) {
      return true;
    }
    return !listEquals(oldDelegate.strokes, strokes) ||
        oldDelegate.activeTool != activeTool ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth;
  }
}

/// Renders the transient stroke currently being drawn by the user or the eraser cursor.
///
/// What: Isolates active stroke rendering into a dedicated layer.
/// Why: Prevents repainting all completed historical strokes during continuous pointer movements (60/120fps).
class ActiveStrokePainter extends CustomPainter {
  ActiveStrokePainter({
    required this.activePoints,
    required this.activeTool,
    required this.activeColor,
    required this.activeStrokeWidth,
  }) : _eraserPaint = Paint()
         ..color = const Color(0xFF64748B).withValues(alpha: 0.4)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.5;

  final List<StrokePoint>? activePoints;
  final InkToolType activeTool;
  final Color activeColor;
  final double activeStrokeWidth;
  final Paint _eraserPaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (activePoints == null || activePoints!.isEmpty) return;

    if (activeTool == InkToolType.eraser) {
      final lastPoint = activePoints!.last;
      canvas.drawCircle(
        Offset(lastPoint.x, lastPoint.y),
        activeStrokeWidth / 2,
        _eraserPaint,
      );
    } else {
      final activePath = buildPath(
        activePoints!,
        strokeWidth: activeStrokeWidth,
        tool: activeTool,
      );
      canvas.drawPath(activePath, _buildActivePaint());
    }
  }

  Paint _buildActivePaint() {
    final paint = Paint()..isAntiAlias = true;
    if (activeTool == InkToolType.highlighter) {
      paint
        ..color = activeColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;
    } else {
      paint
        ..color = activeColor
        ..style = PaintingStyle.fill;
    }
    return paint;
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) {
    return activePoints != null || oldDelegate.activePoints != null;
  }
}

/// Builds a polygon [Path] from [points] using `perfect_freehand`.
Path buildPath(
  List<StrokePoint> points, {
  required double strokeWidth,
  required InkToolType tool,
  bool isComplete = false,
}) {
  final options = StrokeOptions(
    size: strokeWidth,
    thinning: tool == InkToolType.pen ? 0.6 : 0,
    smoothing: 0.5,
    streamline: 0.5,
    simulatePressure: tool == InkToolType.pen,
    isComplete: isComplete,
  );

  final freehandPoints = points
      .map((p) => PointVector(p.x, p.y, p.pressure))
      .toList();
  final outline = getStroke(freehandPoints, options: options);
  final resultPath = Path();
  if (outline.isEmpty) return resultPath;

  resultPath.moveTo(outline.first.dx, outline.first.dy);
  for (var i = 1; i < outline.length; i++) {
    resultPath.lineTo(outline[i].dx, outline[i].dy);
  }
  resultPath.close();
  return resultPath;
}

/// Converts a hex color string (e.g. '#FF1E293B') to a Flutter [Color].
Color colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) {
    return Color(int.parse('FF$clean', radix: 16));
  } else if (clean.length == 8) {
    return Color(int.parse(clean, radix: 16));
  }
  return const Color(0xFF1E293B);
}
