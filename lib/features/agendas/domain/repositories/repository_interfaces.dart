import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';

/// Repository for agenda CRUD operations.
abstract interface class AgendaRepository {
  Stream<List<Agenda>> watchAgendas();
  Future<Agenda?> getAgenda(String id);
  Future<Agenda> createAgenda({
    required String title,
    String coverStyle = 'honey',
  });
  Future<void> updateAgendaTitle(String id, String newTitle);
  Future<void> deleteAgenda(String id);
}

/// Repository for agenda page operations.
abstract interface class PageRepository {
  Stream<List<AgendaPage>> watchPages(String agendaId);
  Future<AgendaPage> createPage({
    required String agendaId,
    required int pageNumber,
    String? id,
    String backgroundStyle = 'dotted',
  });
  Future<void> updatePageBackground(String pageId, String backgroundStyle);
  Future<void> deletePage(String pageId);

  /// Copies a live page and all its live elements/ink immediately after it.
  /// A caller-supplied [id] makes a retry idempotent.
  Future<AgendaPage> duplicatePage(String pageId, {String? id});

  Future<void> reorderPages(List<String> pageIdsInOrder);
}

/// Repository for canvas element operations.
abstract interface class CanvasElementRepository {
  Stream<List<CanvasWidgetData>> watchCanvasElements(String pageId);
  Future<void> upsertCanvasElement(CanvasWidgetData element);
  Future<void> restoreCanvasElement(CanvasWidgetData element);

  /// Updates only [configJson] (and its timestamp) for [id], leaving
  /// geometry untouched. Returns whether a live row was updated.
  Future<bool> updateElementConfig(String id, String configJson);

  Future<void> deleteCanvasElement(String id);
}

/// Repository for ink stroke operations.
abstract interface class StrokeRepository {
  Stream<List<InkStroke>> watchStrokes(String pageId);
  Future<void> insertStroke(InkStroke stroke);
  Future<void> insertStrokesBatch(List<InkStroke> strokes);
  Future<void> deleteStroke(String id);
  Future<void> clearStrokes(String pageId);

  /// Atomically replaces every stroke on [pageId] with [strokes].
  Future<void> replaceStrokes(String pageId, List<InkStroke> strokes);
}

/// Combined repository interface for backward compatibility.
/// New code should prefer the focused interfaces above.
abstract interface class FullAgendaRepository
    implements
        AgendaRepository,
        PageRepository,
        CanvasElementRepository,
        StrokeRepository {
  /// One-shot consistent read of live pages, elements and optional ink.
  ///
  /// Ink geometry may be decoded lazily from captured data, never from a
  /// later database read. Set [includeInk] to false to skip ink entirely.
  /// Returns null when the agenda does not exist or is soft-deleted.
  Future<AgendaSnapshot?> getAgendaSnapshot(
    String agendaId, {
    bool includeInk = true,
  });
}
