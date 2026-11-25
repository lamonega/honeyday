import 'dart:convert';

import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

/// In-memory representation of a freehand vector stroke drawn on Layer 3.
///
/// What: Stores stroke geometry points with pressure, color, width, and brush type.
/// Why: Pure Dart domain entity with zero Flutter/external dependencies.
class InkStroke {
  /// Constructs an [InkStroke].
  InkStroke({
    required this.id,
    required this.pageId,
    required this.tool,
    required this.colorHex,
    required this.strokeWidth,
    required this.points,
    required this.createdAt,
    this.usesDevicePressure = false,
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

    final (points, usesDevicePressure) = _decodePoints(pointsJson);
    return InkStroke(
      id: id,
      pageId: pageId,
      tool: tool,
      colorHex: colorHex,
      strokeWidth: strokeWidth,
      points: points,
      createdAt: createdAt,
      usesDevicePressure: usesDevicePressure,
    );
  }

  /// Unique identifier for this stroke.
  final String id;

  /// Foreign key referencing the parent page.
  final String pageId;

  /// Brush tool profile used when creating this stroke.
  final InkToolType tool;

  /// Hex color string (e.g. '#FF1E293B').
  final String colorHex;

  /// Diameter of the stroke in virtual points.
  final double strokeWidth;

  /// Vector coordinate sequence with pressure values.
  final List<StrokePoint> points;

  /// Timestamp when the stroke was drawn.
  final DateTime createdAt;

  /// Whether to render measured pressure rather than simulate it.
  ///
  /// Older strokes may contain pressure samples, but were always drawn with
  /// simulated pressure.
  final bool usesDevicePressure;

  /// Serializes vector points into a compact JSON string.
  String toJsonPoints() {
    final list = [
      for (final (index, point) in points.indexed)
        {
          'x': (point.x * 10).round() / 10,
          'y': (point.y * 10).round() / 10,
          if (point.pressure != null)
            'p': (point.pressure! * 100).round() / 100,
          if (index == 0 && usesDevicePressure) 'dp': true,
        },
    ];
    return jsonEncode(list);
  }

  /// Returns the stored hex color string.
  String toHexColor() => colorHex;

  static (List<StrokePoint>, bool) _decodePoints(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      final points = decoded.map((item) {
        final map = item as Map<String, dynamic>;
        final x = (map['x'] as num).toDouble();
        final y = (map['y'] as num).toDouble();
        final p = (map['p'] as num?)?.toDouble();
        return StrokePoint(x, y, p);
      }).toList();
      final usesDevicePressure =
          decoded.isNotEmpty &&
          (decoded.first as Map<String, dynamic>)['dp'] == true;
      return (points, usesDevicePressure);
    } on Object {
      return ([], false);
    }
  }
}
