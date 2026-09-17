import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Orientation of a magnetic alignment guide line.
///
/// What: Distinguishes between vertical (X-axis) and horizontal (Y-axis) snap lines.
/// Why: Guides are rendered with perpendicular spanning across the canvas surface.
enum SnapOrientation {
  /// Vertical alignment line representing an X-coordinate match.
  vertical,

  /// Horizontal alignment line representing a Y-coordinate match.
  horizontal,
}

/// Represents an active visual snapping guideline drawn during element transformation.
///
/// What: Defines start and end coordinates and orientation for an alignment line.
/// Why: Provides visual feedback when dragging modular widgets close to centers or sibling edges.
@immutable
class SnapGuideLine {
  /// Constructs a [SnapGuideLine].
  const SnapGuideLine({
    required this.start,
    required this.end,
    required this.orientation,
  });

  /// Starting point of the guideline.
  final Offset start;

  /// Ending point of the guideline.
  final Offset end;

  /// Direction of the guideline.
  final SnapOrientation orientation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SnapGuideLine &&
        other.start == start &&
        other.end == end &&
        other.orientation == orientation;
  }

  @override
  int get hashCode => Object.hash(start, end, orientation);
}

/// Result produced by a snapping calculation.
///
/// What: Encapsulates the snapped top-left position and all active guidelines.
/// Why: Allows the transform engine to reposition elements and update the guide overlay in a single pass.
@immutable
class SnappingResult {
  /// Constructs a [SnappingResult].
  const SnappingResult({required this.snappedPosition, required this.guides});

  /// Snapped top-left position for the element.
  final Offset snappedPosition;

  /// Active alignment lines to be rendered by the guide overlay.
  final List<SnapGuideLine> guides;
}

/// Mathematical helper for 2D alignment snapping on the Honeyday canvas.
///
/// What: Detects alignment with page centers, page margins, and sibling element bounds.
/// Why: Delivers a Canva-like magnetic snapping experience for modular agenda widgets.
abstract final class CanvasSnapping {
  /// Magnetic distance threshold in points for initial snap.
  static const double defaultThreshold = 4;

  /// Dead zone multiplier: once snapped, require this × threshold to unsnap.
  static const double deadZoneMultiplier = 2;

  /// Default margin distance from page edges in points.
  static const double defaultMargin = 24;

  /// Calculates magnetic alignment snapping for [candidateRect].
  ///
  /// When [isCurrentlySnapped] is true, uses an expanded threshold (dead zone)
  /// to prevent jittery snap/unsnap cycles.
  static SnappingResult calculateSnap({
    required Rect candidateRect,
    required Size pageSize,
    List<Rect> siblingRects = const [],
    double threshold = defaultThreshold,
    double margin = defaultMargin,
    bool isCurrentlySnapped = false,
  }) {
    final activeGuides = <SnapGuideLine>{};

    // Apply dead zone: once snapped, require more distance to unsnap
    final effectiveThreshold = isCurrentlySnapped
        ? threshold * deadZoneMultiplier
        : threshold;

    // --- Vertical Snapping (X-axis alignment) ---
    // Reduced anchors: only center and nearest edge per element (2 instead of 3)
    final candidateXAnchors = <double>[
      candidateRect.left,
      candidateRect.center.dx,
    ];

    final targetXAnchors = <double>{
      margin,
      pageSize.width / 2,
      pageSize.width - margin,
    };

    for (final sibling in siblingRects) {
      targetXAnchors
        ..add(sibling.left)
        ..add(sibling.center.dx)
        ..add(sibling.right);
    }

    double? bestDeltaX;
    for (final candidateX in candidateXAnchors) {
      for (final targetX in targetXAnchors) {
        final delta = targetX - candidateX;
        if (delta.abs() <= effectiveThreshold) {
          if (bestDeltaX == null || delta.abs() < bestDeltaX.abs()) {
            bestDeltaX = delta;
          }
        }
      }
    }

    final snappedLeft = bestDeltaX != null
        ? candidateRect.left + bestDeltaX
        : candidateRect.left;

    if (bestDeltaX != null) {
      final snappedXAnchors = [
        snappedLeft,
        snappedLeft + candidateRect.width / 2,
        snappedLeft + candidateRect.width,
      ];

      for (final targetX in targetXAnchors) {
        for (final snappedX in snappedXAnchors) {
          if ((targetX - snappedX).abs() < 0.5) {
            activeGuides.add(
              SnapGuideLine(
                start: Offset(targetX, 0),
                end: Offset(targetX, pageSize.height),
                orientation: SnapOrientation.vertical,
              ),
            );
          }
        }
      }
    }

    // --- Horizontal Snapping (Y-axis alignment) ---
    final candidateYAnchors = <double>[
      candidateRect.top,
      candidateRect.center.dy,
    ];

    final targetYAnchors = <double>{
      margin,
      pageSize.height / 2,
      pageSize.height - margin,
    };

    for (final sibling in siblingRects) {
      targetYAnchors
        ..add(sibling.top)
        ..add(sibling.center.dy)
        ..add(sibling.bottom);
    }

    double? bestDeltaY;
    for (final candidateY in candidateYAnchors) {
      for (final targetY in targetYAnchors) {
        final delta = targetY - candidateY;
        if (delta.abs() <= effectiveThreshold) {
          if (bestDeltaY == null || delta.abs() < bestDeltaY.abs()) {
            bestDeltaY = delta;
          }
        }
      }
    }

    final snappedTop = bestDeltaY != null
        ? candidateRect.top + bestDeltaY
        : candidateRect.top;

    if (bestDeltaY != null) {
      final snappedYAnchors = [
        snappedTop,
        snappedTop + candidateRect.height / 2,
        snappedTop + candidateRect.height,
      ];

      for (final targetY in targetYAnchors) {
        for (final snappedY in snappedYAnchors) {
          if ((targetY - snappedY).abs() < 0.5) {
            activeGuides.add(
              SnapGuideLine(
                start: Offset(0, targetY),
                end: Offset(pageSize.width, targetY),
                orientation: SnapOrientation.horizontal,
              ),
            );
          }
        }
      }
    }

    return SnappingResult(
      snappedPosition: Offset(snappedLeft, snappedTop),
      guides: activeGuides.toList(),
    );
  }
}
