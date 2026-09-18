import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';

/// CustomPainter rendering magnetic alignment guidelines during widget drag.
class SnapGuideOverlayPainter extends CustomPainter {
  const SnapGuideOverlayPainter({
    required this.guides,
    this.guideColor = const AppColors.honeyAmber,
  });

  final List<SnapGuideLine> guides;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (guides.isEmpty) return;

    final paint = Paint()
      ..color = guideColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      canvas.drawLine(guide.start, guide.end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SnapGuideOverlayPainter oldDelegate) {
    return !listEquals(oldDelegate.guides, guides) ||
        oldDelegate.guideColor != guideColor;
  }
}
