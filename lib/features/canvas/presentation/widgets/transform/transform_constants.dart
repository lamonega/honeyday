import 'dart:ui' show Offset, Size;

/// Constants and typedefs used throughout the transform system.
///
/// These values control spacing, sizing, and positioning of transform
/// handles, the selection outline, and the floating action bar relative
/// to the element being transformed.

/// Horizontal padding around elements for transform handles.
const double kTransformHMargin = 40;

/// Top padding above elements for rotation/delete handles.
const double kTransformTopMargin = 48;

/// Bottom padding below elements for the action bar.
const double kTransformBottomMargin = 76;

/// Radius of resize handle dots.
const double kResizeHandleRadius = 7;

/// Fraction of page height above which element is "large".
const double kLargeElementThreshold = 0.75;

/// Pixels from page bottom below which action bar repositions.
const double kNearBottomThreshold = 90;

/// Action bar offset from top for large elements.
const double kBarTopOffsetLarge = 12;

/// Action bar offset from top for elements near bottom.
const double kBarTopOffsetNearBottom = -44;

/// Action bar default offset from top.
const double kBarTopOffsetDefault = 10;

/// Connector stem height from element top to rotation handle.
const double kSelectionStemHeight = 20;

/// Vertical offset of rotation handle above element top.
const double kRotationHandleTopOffset = 36;

/// Size of rotation and delete handle circles.
const double kHandleCircleSize = 24;

/// Icon size inside rotation and delete handles.
const double kHandleIconSize = 14;

/// Border radius of selected element outline.
const double kSelectionBorderRadius = 12;

/// Border radius of element content clip.
const double kContentClipRadius = 10;

/// Callback signature for when a transform (move, resize, rotate) occurs.
typedef OnTransformChanged = void Function(
  Offset position,
  Size size,
  double rotation,
);
