import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';

/// Abstract contract defining persistence and query operations for agendas.
///
/// Implements the official Flutter team recommendation to use abstract repository
/// classes to allow easy testing with fakes and clean architectural separation.
abstract interface class AgendaRepository {
  /// Watches all non-deleted agendas ordered by update timestamp descending.
  Stream<List<Agenda>> watchAgendas();

  /// Retrieves a single agenda by its unique [id].
  Future<Agenda?> getAgenda(String id);

  /// Creates a new agenda and automatically initializes its first page.
  Future<Agenda> createAgenda({
    required String title,
    String coverStyle = 'honey',
  });

  /// Updates the title and audit timestamp of an agenda.
  Future<void> updateAgendaTitle(String id, String newTitle);

  /// Soft-deletes an agenda by marking `isDeleted = true`.
  Future<void> deleteAgenda(String id);

  /// Watches all pages belonging to [agendaId] ordered sequentially.
  Stream<List<AgendaPage>> watchPages(String agendaId);

  /// Adds a new page to an existing agenda and increments the agenda's page count.
  Future<AgendaPage> createPage({
    required String agendaId,
    required int pageNumber,
    String backgroundStyle = 'dotted',
  });

  /// Updates the paper background style of a page (e.g., 'dotted', 'lined', 'grid', 'blank').
  Future<void> updatePageBackground(String pageId, String backgroundStyle);

  /// Soft-deletes a page by its [pageId].
  Future<void> deletePage(String pageId);

  /// Reorders pages according to the given sequential [pageIdsInOrder].
  Future<void> reorderPages(List<String> pageIdsInOrder);

  /// Watches all modular canvas widgets for a given [pageId].
  Stream<List<CanvasWidgetData>> watchCanvasElements(String pageId);

  /// Inserts or updates a canvas element.
  Future<void> upsertCanvasElement(CanvasWidgetData element);

  /// Soft-deletes a canvas element.
  Future<void> deleteCanvasElement(String id);

  /// Watches all vector ink strokes for a given [pageId].
  Stream<List<InkStroke>> watchStrokes(String pageId);

  /// Inserts a newly drawn freehand stroke.
  Future<void> insertStroke(InkStroke stroke);

  /// Inserts multiple strokes in a single batch operation.
  Future<void> insertStrokesBatch(List<InkStroke> strokes);

  /// Removes a single stroke by its [id].
  Future<void> deleteStroke(String id);

  /// Clears all strokes on a given page.
  Future<void> clearStrokes(String pageId);
}
