import 'package:flutter/material.dart';

/// Stateless geometry wrapper for a non-interactive canvas element.
///
/// What: Places [child] at [position] (top-left origin in page coordinates)
/// with [size] and rotates it by [rotation] (radians, around the center).
/// Why: Shared by the interactive canvas (non-edit modes) and the static
/// page composition (export/thumbnails) so both render pixel-identically
/// from a single geometry implementation.
class StaticElementBox extends StatelessWidget {
  /// Creates a static geometry wrapper around [child].
  const StaticElementBox({
    required this.position,
    required this.size,
    required this.rotation,
    required this.child,
    super.key,
  });

  /// Top-left position in page coordinates (unscaled page points).
  final Offset position;

  /// Width and height of the element before rotation is applied.
  final Size size;

  /// Rotation angle around the element center, in radians.
  final double rotation;

  /// The element content painted inside the positioned box.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: size.width,
      height: size.height,
      child: Transform.rotate(angle: rotation, child: child),
    );
  }
}
