import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/widgets/bottom_details_bar.dart';
import 'package:honeyday/features/agendas/presentation/widgets/notebook_cover.dart';

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
                child: NotebookCover(
                  title: widget.agenda.title,
                  coverStyle: widget.agenda.coverStyle,
                  onDelete: widget.onDelete,
                ),
              ),
              BottomDetailsBar(
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
