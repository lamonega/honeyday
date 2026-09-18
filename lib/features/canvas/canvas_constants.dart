/// Shared constants for the canvas feature.
///
/// Centralizes magic values used across canvas-related files
/// to ensure consistency and easy tuning. Grouped by domain,
/// values ordered ascending within each group.

// ---------------------------------------------------------------------------
// Spacing & Margins
// ---------------------------------------------------------------------------

/// Default page margin in points, used for snap anchors and fit-to-width.
const double kCanvasMargin = 24;

/// Minimum space between canvas elements when duplicating.
const double kDuplicateOffset = 24;

/// Default page grid/line spacing in points.
const double kPaperSpacing = 24;

// ---------------------------------------------------------------------------
// Element Transform (TransformableBox)
// ---------------------------------------------------------------------------

/// Horizontal padding around canvas elements for transform handles.
const double kTransformHMargin = 40;

/// Top padding above canvas elements for rotation/delete handles.
const double kTransformTopMargin = 48;

/// Bottom padding below canvas elements for the action bar.
const double kTransformBottomMargin = 76;

/// Radius of resize handle dots.
const double kResizeHandleRadius = 7;

/// Fraction of page height above which an element is considered "large".
const double kLargeElementThreshold = 0.75;

/// Pixels from page bottom below which the action bar repositions upward.
const double kNearBottomThreshold = 90;

/// Action bar offset from top margin for large elements.
const double kBarTopOffsetLarge = 12;

/// Action bar offset from top margin for elements near bottom.
const double kBarTopOffsetNearBottom = -44;

/// Action bar offset from top margin in the default (middle) position.
const double kBarTopOffsetDefault = 10;

// ---------------------------------------------------------------------------
// Selection & Handle UI
// ---------------------------------------------------------------------------

/// Connector stem height from element top to rotation handle.
const double kSelectionStemHeight = 20;

/// Vertical offset of the rotation handle above element top.
const double kRotationHandleTopOffset = 36;

/// Size of rotation and delete handle circles.
const double kHandleCircleSize = 24;

/// Icon size inside rotation and delete handles.
const double kHandleIconSize = 14;

/// Border radius of selected element outline.
const double kSelectionBorderRadius = 12;

/// Border radius of element content clip.
const double kContentClipRadius = 10;

// ---------------------------------------------------------------------------
// Action Bar (CanvasActionBar)
// ---------------------------------------------------------------------------

/// Border radius of the floating action bar.
const double kActionBarBorderRadius = 24;

/// Size of the color palette toggle button.
const double kPaletteButtonSize = 28;

/// Icon size inside the palette toggle button.
const double kPaletteToggleIconSize = 14;

/// Height of the divider between action bar buttons.
const double kActionBarDividerHeight = 16;

/// Icon size for action bar buttons (fit, center, duplicate, delete).
const double kActionBarIconSize = 18;

/// Border radius of the expanded palette row.
const double kPaletteRowBorderRadius = 20;

/// Diameter of individual color dots in the palette.
const double kPaletteDotSize = 22;

/// Check icon size inside a selected palette dot.
const double kPaletteCheckIconSize = 12;

// ---------------------------------------------------------------------------
// Floating Toolbar (CanvasFloatingToolbar)
// ---------------------------------------------------------------------------

/// Border radius of the floating ink toolbar.
const double kToolbarBorderRadius = 28;

/// Icon size for toolbar tool buttons.
const double kToolbarIconSize = 18;

/// Margin between color palette dots in the toolbar.
const double kToolbarPaletteDotMargin = 2;

/// Diameter of color palette dots in the toolbar.
const double kToolbarPaletteDotSize = 18;

/// Min button size constraint for toolbar buttons.
const double kToolbarButtonMinSize = 32;

/// Toolbar divider height.
const double kToolbarDividerHeight = 20;

/// Toolbar width slider width.
const double kToolbarSliderWidth = 60;

/// Toolbar width slider height.
const double kToolbarSliderHeight = 28;

/// Toolbar slider track height.
const double kToolbarSliderTrackHeight = 3;

/// Toolbar slider thumb diameter.
const double kToolbarSliderThumbSize = 14;

/// Toolbar slider thumb offset from track center.
const double kToolbarSliderThumbOffset = 7;

/// Min stroke width for pen tool.
const double kPenWidthMin = 1;

/// Max stroke width for pen tool.
const double kPenWidthMax = 12;

/// Min stroke width for highlighter tool.
const double kHighlighterWidthMin = 8;

/// Max stroke width for highlighter tool.
const double kHighlighterWidthMax = 40;

// ---------------------------------------------------------------------------
// Page Container (PageViewCanvas)
// ---------------------------------------------------------------------------

/// Default page width in points.
const double kDefaultPageWidth = 800;

/// Default page height in points.
const double kDefaultPageHeight = 1100;

/// Border radius of the page container shadow box.
const double kPageBorderRadius = 16;

/// Shadow opacity for the page container.
const double kPageShadowAlpha = 0.12;

/// Shadow blur radius for the page container.
const double kPageShadowBlur = 16;

/// Shadow offset for the page container.
const double kPageShadowOffsetY = 6;

/// Touch slop for gesture detection on the canvas.
const double kCanvasTouchSlop = 4;

/// Toolbar vertical position from top of canvas.
const double kToolbarTopPosition = 16;

// ---------------------------------------------------------------------------
// Canvas Snapping
// ---------------------------------------------------------------------------

/// Magnetic distance threshold in points for initial snap.
const double kSnapThreshold = 4;

/// Dead zone multiplier: once snapped, require this × threshold to unsnap.
const double kSnapDeadZoneMultiplier = 2;

/// Precision threshold for snap guide alignment detection.
const double kSnapGuidePrecision = 0.5;

// ---------------------------------------------------------------------------
// Default Element Position
// ---------------------------------------------------------------------------

/// Default X position for newly added catalog elements.
const double kNewElementDefaultX = 120;

/// Default Y position for newly added catalog elements.
const double kNewElementDefaultY = 100;

// ---------------------------------------------------------------------------
// Ink Defaults
// ---------------------------------------------------------------------------

/// Default pressure when device doesn't report pressure data.
const double kDefaultPressure = 0.5;

/// Freehand thinning parameter for pen strokes.
const double kPenThinning = 0.6;

/// Freehand smoothing parameter (shared by pen and highlighter).
const double kInkSmoothing = 0.5;

/// Freehand streamline parameter (shared by pen and highlighter).
const double kInkStreamline = 0.5;

/// Maximum number of undo states retained for both strokes and elements.
const int kMaxUndoSize = 50;
