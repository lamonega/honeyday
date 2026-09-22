import 'dart:ui' show Offset;

import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_constants.dart';

/// Holds the mutable state for a `TransformableBox` during editing.
///
/// This class encapsulates the transient values that change while the user
/// drags, resizes, or rotates an element: the current drag position,
/// snap results, and whether the color palette is visible. It also provides
/// helper methods for computing derived layout values such as the action
/// bar's vertical offset.
class TransformState {
  /// The element's center in global coordinates, updated before rotation
  /// calculations.
  Offset? globalCenter;

  /// The in-progress position during a drag operation.
  Offset? dragPosition;

  /// Whether the color palette row in the action bar is expanded.
  bool showColorPalette = false;

  /// The most recent snap result, or `null` when snapping is inactive.
  SnappingResult? lastSnapResult;

  /// Whether snap guides are currently enabled (can be toggled via modifier
  /// keys during a drag).
  bool isSnapEnabled = true;

  /// Resets transient drag state when a gesture ends.
  void resetDrag() {
    dragPosition = null;
    lastSnapResult = null;
  }

  /// Computes the vertical offset for the floating action bar based on
  /// element size and page geometry.
  ///
  /// Large elements get a top-aligned bar; elements near the bottom of the
  /// page get an upward-shifted bar; all others get a default position
  /// below the element.
  double computeBarTop({
    required double elementHeight,
    required double pageHeight,
  }) {
    final isLarge = elementHeight > (pageHeight * kLargeElementThreshold);
    if (isLarge) {
      return kTransformTopMargin + kBarTopOffsetLarge;
    }
    return kTransformTopMargin + kBarTopOffsetDefault;
  }

  /// Computes the vertical offset for the action bar when the element is
  /// near the bottom of the page.
  double computeBarTopNearBottom({
    required double elementHeight,
    required double pageHeight,
    required double elementBottom,
  }) {
    final isNearBottom =
        elementBottom > (pageHeight - kNearBottomThreshold);
    if (isNearBottom) {
      return kTransformTopMargin + kBarTopOffsetNearBottom;
    }
    return kTransformTopMargin + elementHeight + kBarTopOffsetDefault;
  }
}
