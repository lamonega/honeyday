import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/widgets/agenda_card.dart';

/// Delay between each card's staggered entrance animation, in milliseconds.
const int _kStaggerMs = 60;

/// Duration of each card's entrance animation, in milliseconds.
const int _kAnimDurationMs = 400;

/// Vertical slide offset used as the begin value for the entrance transition.
const double _kSlideBegin = 0.92;

/// Wraps [AgendaCard] in a grid-friendly card with animated entrance effects.
///
/// Each card fades in and slides upward with a staggered delay based on its
/// [index] in the grid, creating a cascading reveal effect on first render.
class AgendaGridCard extends StatelessWidget {
  /// Constructs an [AgendaGridCard].
  const AgendaGridCard({
    required this.agenda,
    required this.index,
    required this.onOpenWriting,
    required this.onOpenReading,
    required this.onOpenEdit,
    required this.onDelete,
    super.key,
  });

  /// The agenda to display.
  final Agenda agenda;

  /// Position index in the grid, used to stagger the entrance animation.
  final int index;

  /// Triggered when opening the card in writing mode.
  final VoidCallback onOpenWriting;

  /// Triggered when opening the card in reading mode.
  final VoidCallback onOpenReading;

  /// Triggered when opening the card in edit mode.
  final VoidCallback onOpenEdit;

  /// Triggered when the user requests deletion.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final staggerDelay = Duration(milliseconds: _kStaggerMs * index);
    const animDuration = Duration(milliseconds: _kAnimDurationMs);

    return AgendaCard(
      agenda: agenda,
      onOpenWriting: onOpenWriting,
      onOpenReading: onOpenReading,
      onOpenEdit: onOpenEdit,
      onDelete: onDelete,
    )
        .animate()
        .fadeIn(duration: animDuration, delay: staggerDelay)
        .slideY(
          begin: _kSlideBegin,
          end: 0,
          duration: animDuration,
          delay: staggerDelay,
          curve: Curves.easeOutCubic,
        );
  }
}
