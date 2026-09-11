import 'package:flutter/material.dart';

/// Data representation of a modular widget placed on Layer 1 of the canvas.
///
/// What: Holds 2D coordinates, size, rotation, type, and JSON payload for an element.
/// Why: Decouples rendering from SQLite schema and allows seamless in-memory transformation.
@immutable
class CanvasWidgetData {
  /// Constructs a [CanvasWidgetData].
  const CanvasWidgetData({
    required this.id,
    required this.pageId,
    required this.widgetType,
    required this.position,
    required this.size,
    this.rotation = 0,
    this.configJson = '{}',
  });

  /// Unique identifier of this canvas element.
  final String id;

  /// Parent page identifier.
  final String pageId;

  /// Type discriminator (e.g. 'calendar_grid', 'budget_calculator', 'journal_block', 'text_box').
  final String widgetType;

  /// Top-left position on the unscaled page surface.
  final Offset position;

  /// Dimensions of the container.
  final Size size;

  /// Rotation angle around center in radians.
  final double rotation;

  /// Serialized configuration payload for the modular widget.
  final String configJson;

  /// Creates a copy with specified fields replaced.
  CanvasWidgetData copyWith({
    String? id,
    String? pageId,
    String? widgetType,
    Offset? position,
    Size? size,
    double? rotation,
    String? configJson,
  }) {
    return CanvasWidgetData(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      widgetType: widgetType ?? this.widgetType,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      configJson: configJson ?? this.configJson,
    );
  }

  /// Computes the [Rect] bounding box for alignment snapping.
  Rect get boundingBox =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}
