/// Transform system — modular decomposition of `TransformableBox`.
///
/// This package breaks the monolithic `TransformableBox` widget into
/// focused, testable units:
///
/// * **`transform_constants.dart`** — shared constants and the
///   `OnTransformChanged` typedef.
/// * **`transform_state.dart`** — mutable state holder for the transform
///   lifecycle (drag position, snap results, palette visibility).
/// * **`transform_gestures.dart`** — mixin containing all gesture
///   handlers (body drag, rotation, and four-corner resize).
/// * **`transform_handles.dart`** — selection chrome widgets (outline,
///   rotation handle, delete handle, stem).
///
/// The main `TransformableBox` widget in the parent directory composes
/// these pieces together.
library;

export 'transform_constants.dart';
export 'transform_gestures.dart';
export 'transform_handles.dart';
export 'transform_state.dart';
