import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/utils/color_utils.dart';

/// Tactile notebook-styled cover with spine stitch, page edges, ribbon bookmark,
/// Fraunces editorial title, and delete button.
class NotebookCover extends StatelessWidget {
  const NotebookCover({
    required this.title,
    required this.coverStyle,
    required this.onDelete,
    super.key,
  });

  final String title;
  final String coverStyle;
  final VoidCallback onDelete;

  static LinearGradient _getCoverGradient(String style) {
    // Try parsing as hex color first
    if (style.startsWith('#') || style.length == 6) {
      final hex = style.startsWith('#') ? style : '#$style';
      try {
        final color = hexToColor(hex);
        final dark = darken(color);
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, dark],
        );
      } on Object {
        // Fall through to presets
      }
    }

    switch (style.toLowerCase()) {
      case 'lavender':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        );
      case 'sage':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF047857)],
        );
      case 'rose':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
        );
      case 'slate':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF1E293B)],
        );
      case 'honey':
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: _getCoverGradient(coverStyle)),
      child: Stack(
        children: [
          const _CurvatureHighlight(),
          const _SpineShadow(),
          const _SpineStitches(),
          const _BookmarkRibbon(),
          const _PageEdges(),
          _CoverTitle(title: title),
          _DeleteButton(onDelete: onDelete),
        ],
      ),
    );
  }
}

class _CurvatureHighlight extends StatelessWidget {
  const _CurvatureHighlight();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.15),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpineShadow extends StatelessWidget {
  const _SpineShadow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 24,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.28), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _SpineStitches extends StatelessWidget {
  const _SpineStitches();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      top: 0,
      bottom: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
          (index) => Container(
            width: 5,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkRibbon extends StatelessWidget {
  const _BookmarkRibbon();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 44,
      child: Container(
        width: 12,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageEdges extends StatelessWidget {
  const _PageEdges();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      child: Container(
        width: 6,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF8EE),
          border: Border(
            left: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            8,
            (i) => Container(height: 1, color: const Color(0xFFE2D8C0)),
          ),
        ),
      ),
    );
  }
}

class _CoverTitle extends StatelessWidget {
  const _CoverTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 48, top: 18, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.fraunces(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      right: 10,
      child: IconButton(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white70,
          size: 19,
        ),
        tooltip: 'Eliminar agenda',
        visualDensity: VisualDensity.compact,
        onPressed: onDelete,
      ),
    );
  }
}
