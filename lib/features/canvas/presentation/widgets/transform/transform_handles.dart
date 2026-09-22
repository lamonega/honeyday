/// Selection chrome widgets that appear around a transformable element.
///
/// This file provides:
/// * [SelectionOutline] — the bordered rectangle drawn around the selected
///   element content.
/// * [RotationHandle] — the circular drag handle above the element that
///   controls rotation.
/// * [DeleteHandle] — the circular close button that triggers deletion.
///
/// These widgets are purely presentational; all interaction logic lives in
/// `TransformGestureMixin` (see `transform_gestures.dart`).
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transform/transform_constants.dart';

/// Draws the selection border and clipped child content area.
///
/// The border uses the theme's primary color and is drawn at a fixed
/// radius defined by [kSelectionBorderRadius]. The child is clipped to
/// a slightly smaller radius ([kContentClipRadius]) for visual polish.
class SelectionOutline extends StatelessWidget {
  const SelectionOutline({
    required this.child,
    required this.isSelected,
    super.key,
  });

  /// The element content to render inside the clipped area.
  final Widget child;

  /// Whether the element is currently selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(kSelectionBorderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kContentClipRadius),
        child: child,
      ),
    );
  }
}

/// Circular drag handle that controls element rotation.
///
/// Positioned at the top of the selection chrome, connected by a thin
/// vertical stem. Dragging this handle fires [onPanStart], [onPanUpdate],
/// and [onPanEnd] callbacks that the parent uses to compute the new
/// rotation angle.
class RotationHandle extends StatelessWidget {
  const RotationHandle({
    required this.onPanStart,
    required this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    super.key,
  });

  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: Container(
        width: kHandleCircleSize,
        height: kHandleCircleSize,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: kHandleIconSize,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

/// Circular delete button that triggers element removal.
///
/// Positioned at the top-right corner of the selection chrome. Tapping
/// this handle invokes [onTap].
class DeleteHandle extends StatelessWidget {
  const DeleteHandle({
    required this.onTap,
    super.key,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: kHandleCircleSize,
        height: kHandleCircleSize,
        decoration: BoxDecoration(
          color: colorScheme.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: kHandleIconSize,
          color: colorScheme.onError,
        ),
      ),
    );
  }
}

/// Vertical stem connecting the element's top edge to the rotation handle.
///
/// This is a simple 2px-wide colored bar rendered in the theme's primary
/// color.
class SelectionStem extends StatelessWidget {
  const SelectionStem({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 2,
      height: kSelectionStemHeight,
      color: colorScheme.primary,
    );
  }
}
