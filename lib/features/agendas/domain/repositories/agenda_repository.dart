import 'package:honeyday/core/database/app_database.dart';

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
  Future<void> updatePageBackground(
    String pageId,
    String backgroundStyle,
  );

  /// Soft-deletes a page by its [pageId].
  Future<void> deletePage(String pageId);

  /// Watches all modular canvas widgets for a given [pageId].
  Stream<List<CanvasElement>> watchCanvasElements(String pageId);

  /// Inserts or updates a canvas element.
  Future<void> upsertCanvasElement(CanvasElementsCompanion element);

  /// Soft-deletes a canvas element.
  Future<void> deleteCanvasElement(String id);

  /// Watches all vector ink strokes for a given [pageId].
  Stream<List<Stroke>> watchStrokes(String pageId);

  /// Inserts a newly drawn freehand stroke.
  Future<void> insertStroke(StrokesCompanion stroke);

  /// Removes a single stroke by its [id].
  Future<void> deleteStroke(String id);

  /// Clears all strokes on a given page.
  Future<void> clearStrokes(String pageId);
}
