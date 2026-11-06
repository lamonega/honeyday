import 'package:flutter/foundation.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';

/// Immutable point-in-time copy of an agenda with all of its pages.
///
/// What: Agenda metadata plus every live page (ordered by `pageNumber`),
/// each with its live elements and optional ink (ordered by `createdAt` —
/// the same z-order the viewer renders).
/// Why: Batch operations over a whole agenda (PDF export, backup, sharing)
/// need one consistent read instead of N stream subscriptions.
@immutable
class AgendaSnapshot {
  /// Creates a snapshot of [agenda] and its [pages].
  const AgendaSnapshot({required this.agenda, required this.pages});

  /// Agenda metadata captured at read time.
  final Agenda agenda;

  /// Every live page of the agenda, ordered by `pageNumber` ascending.
  final List<AgendaPageSnapshot> pages;
}

/// One page, its elements and optional ink within an [AgendaSnapshot].
@immutable
class AgendaPageSnapshot {
  /// Creates a snapshot of [page] with its [elements] and optional [strokes].
  const AgendaPageSnapshot({
    required this.page,
    required this.elements,
    this.strokes = const [],
  });

  /// Page metadata captured at read time.
  final AgendaPage page;

  /// Live elements of [page], ordered by `createdAt` ascending (z-order).
  final List<CanvasWidgetData> elements;

  /// Live ink in creation order, captured at the same instant as the page.
  ///
  /// May be lazy: consume only while rendering this page so decoding points
  /// does not expand an entire agenda's handwriting in memory at once.
  /// Repeated iteration must return equivalent ink, not reread persistence.
  final Iterable<InkStroke> strokes;
}
