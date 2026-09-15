import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';

/// Interactive card previewing a saved agenda notebook on the home dashboard.
///
/// What: Renders a tactile notebook-styled cover with spine stitch, page edges,
/// ribbon bookmark, Fraunces editorial title, and quick mode shortcuts.
/// Why: Directly reflects the physical agenda aesthetic of Honeyday, providing clear
/// entry points for reading/writing and edit mode.
class AgendaCard extends StatefulWidget {
  /// Constructs an [AgendaCard].
  const AgendaCard({
    required this.agenda,
    required this.onOpenWriting,
    required this.onOpenReading,
    required this.onOpenEdit,
    required this.onDelete,
    super.key,
  });

  /// The agenda database entity.
  final Agenda agenda;

  /// Triggered when tapping the card or writing button to open note-taking mode.
  final VoidCallback onOpenWriting;

  /// Triggered when tapping the book icon to enter horizontal reading mode.
  final VoidCallback onOpenReading;

  /// Triggered when tapping the pencil icon to enter layout edit mode.
  final VoidCallback onOpenEdit;

  /// Triggered when requesting deletion of this agenda.
  final VoidCallback onDelete;

  @override
  State<AgendaCard> createState() => _AgendaCardState();
}

class _AgendaCardState extends State<AgendaCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        unawaited(HapticFeedback.lightImpact());
        widget.onOpenWriting();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _isPressed ? 1 : 4,
          shadowColor: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: _NotebookCover(
                  title: widget.agenda.title,
                  coverStyle: widget.agenda.coverStyle,
                  onDelete: widget.onDelete,
                ),
              ),
              _BottomDetailsBar(
                pageCount: widget.agenda.pageCount,
                onOpenReading: widget.onOpenReading,
                onOpenEdit: widget.onOpenEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookCover extends StatelessWidget {
  const _NotebookCover({
    required this.title,
    required this.coverStyle,
    required this.onDelete,
  });

  final String title;
  final String coverStyle;
  final VoidCallback onDelete;

  static LinearGradient _getCoverGradient(String style) {
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
        onPressed: () {
          unawaited(HapticFeedback.mediumImpact());
          onDelete();
        },
      ),
    );
  }
}

class _BottomDetailsBar extends StatelessWidget {
  const _BottomDetailsBar({
    required this.pageCount,
    required this.onOpenReading,
    required this.onOpenEdit,
  });

  final int pageCount;
  final VoidCallback onOpenReading;
  final VoidCallback onOpenEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        children: [
          _PageCountBadge(pageCount: pageCount),
          const Spacer(),
          _ActionButton(
            icon: Icons.visibility_outlined,
            tooltip: 'Modo lectura',
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            onTap: onOpenReading,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.edit_outlined,
            tooltip: 'Modo edición',
            color: colorScheme.primary,
            onTap: onOpenEdit,
          ),
        ],
      ),
    );
  }
}

class _PageCountBadge extends StatelessWidget {
  const _PageCountBadge({required this.pageCount});

  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$pageCount ${pageCount == 1 ? 'pág' : 'págs'}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
    );
  }
}
