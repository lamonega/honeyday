import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// In-memory representation of a freehand vector stroke drawn on Layer 3.
///
/// What: Stores stroke geometry points with pressure, color, width, and brush type.
/// Why: Provides efficient Path caching and JSON serialization matching Drift's Strokes table.
class InkStroke {
  /// Constructs an [InkStroke].
  InkStroke({
    required this.id,
    required this.pageId,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.points,
    required this.createdAt,
  });

  /// Factory creating an [InkStroke] from deserialized database parameters.
  factory InkStroke.fromDb({
    required String id,
    required String pageId,
    required String brushType,
    required String colorHex,
    required double strokeWidth,
    required String pointsJson,
    required DateTime createdAt,
  }) {
    final tool = switch (brushType) {
      'highlighter' => InkToolType.highlighter,
      'eraser' => InkToolType.eraser,
      _ => InkToolType.pen,
    };

    return InkStroke(
      id: id,
      pageId: pageId,
      tool: tool,
      color: _colorFromHex(colorHex),
      strokeWidth: strokeWidth,
      points: _pointsFromJson(pointsJson),
      createdAt: createdAt,
    );
  }

  /// Unique identifier for this stroke.
  final String id;

  /// Foreign key referencing the parent page.
  final String pageId;

  /// Brush tool profile used when creating this stroke.
  final InkToolType tool;

  /// Color of the stroke.
  final Color color;

  /// Diameter of the stroke in virtual points.
  final double strokeWidth;

  /// Vector coordinate sequence with pressure values.
  final List<PointVector> points;

  /// Timestamp when the stroke was drawn.
  final DateTime createdAt;

  Path? _cachedPath;
  Rect? _cachedBounds;

  /// Returns the cached polygon [Path] calculated by `perfect_freehand`.
  Path get path => _cachedPath ??= _buildPath();

  /// Returns the cached bounding box of this stroke for rapid spatial queries.
  Rect get bounds => _cachedBounds ??= path.getBounds();

  /// Converts stroke vector points into a closed polygon [Path].
  Path _buildPath() {
    final options = StrokeOptions(
      size: strokeWidth,
      thinning: tool == InkToolType.pen ? 0.6 : 0,
      smoothing: 0.5,
      streamline: 0.5,
      simulatePressure: tool == InkToolType.pen,
      isComplete: true,
    );

    final outline = getStroke(points, options: options);
    final resultPath = Path();
    if (outline.isEmpty) return resultPath;

    resultPath.moveTo(outline.first.dx, outline.first.dy);
    for (var i = 1; i < outline.length; i++) {
      resultPath.lineTo(outline[i].dx, outline[i].dy);
    }
    resultPath.close();
    return resultPath;
  }

  /// Serializes vector points into a compact JSON string.
  String toJsonPoints() {
    final list = points
        .map(
          (p) => {
            'x': (p.dx * 10).round() / 10,
            'y': (p.dy * 10).round() / 10,
            if (p.pressure != null) 'p': (p.pressure! * 100).round() / 100,
          },
        )
        .toList();
    return jsonEncode(list);
  }

  /// Formats the stroke color into a hex string '#RRGGBB' or '#AARRGGBB'.
  String toHexColor() {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return const Color(0xFF1E293B);
  }

  static List<PointVector> _pointsFromJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        final x = (map['x'] as num).toDouble();
        final y = (map['y'] as num).toDouble();
        final p = (map['p'] as num?)?.toDouble();
        return PointVector(x, y, p);
      }).toList();
    } on Object {
      return [];
    }
  }
}
