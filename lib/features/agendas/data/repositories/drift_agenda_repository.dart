import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/agenda_dao.dart';
import 'package:honeyday/features/agendas/data/repositories/canvas_element_dao.dart';
import 'package:honeyday/features/agendas/data/repositories/page_dao.dart';
import 'package:honeyday/features/agendas/data/repositories/stroke_dao.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';

/// Drift SQLite implementation of [FullAgendaRepository].
///
/// Delegates all operations to the corresponding DAO classes,
/// each of which encapsulates the relational queries and transactions
/// for a specific domain concept.
class DriftAgendaRepository implements FullAgendaRepository {
  /// Constructs a [DriftAgendaRepository] using the provided [AppDatabase].
  DriftAgendaRepository(AppDatabase db)
    : _db = db,
      _agendaDao = AgendaDao(db),
      _pageDao = PageDao(db),
      _canvasElementDao = CanvasElementDao(db),
      _strokeDao = StrokeDao(db);

  final AppDatabase _db;
  final AgendaDao _agendaDao;
  final PageDao _pageDao;
  final CanvasElementDao _canvasElementDao;
  final StrokeDao _strokeDao;

  @override
  Stream<List<Agenda>> watchAgendas() => _agendaDao.watchAgendas();

  @override
  Stream<List<Agenda>> watchTrashedAgendas() =>
      _agendaDao.watchTrashedAgendas();

  @override
  Future<void> restoreAgenda(String id) => _agendaDao.restoreAgenda(id);

  @override
  Future<void> deleteAgendaPermanently(String id) =>
      _agendaDao.deleteAgendaPermanently(id);

  @override
  Future<Agenda?> getAgenda(String id) => _agendaDao.getAgenda(id);

  @override
  Future<Agenda> createAgenda({
    required String title,
    String coverStyle = 'honey',
  }) => _agendaDao.createAgenda(title: title, coverStyle: coverStyle);

  @override
  Future<void> updateAgendaTitle(String id, String newTitle) =>
      _agendaDao.updateAgendaTitle(id, newTitle);

  @override
  Future<void> deleteAgenda(String id) => _agendaDao.deleteAgenda(id);

  @override
  Stream<List<AgendaPage>> watchPages(String agendaId) =>
      _pageDao.watchPages(agendaId);

  @override
  Future<AgendaPage> createPage({
    required String agendaId,
    required int pageNumber,
    String? id,
    String backgroundStyle = 'dotted',
  }) => _pageDao.createPage(
    id: id,
    agendaId: agendaId,
    pageNumber: pageNumber,
    backgroundStyle: backgroundStyle,
  );

  @override
  Future<void> updatePageBackground(String pageId, String backgroundStyle) =>
      _pageDao.updatePageBackground(pageId, backgroundStyle);

  @override
  Future<void> deletePage(String pageId) => _pageDao.deletePage(pageId);

  @override
  Future<AgendaPage> duplicatePage(String pageId, {String? id}) =>
      _pageDao.duplicatePage(pageId, id: id);

  @override
  Future<void> reorderPages(List<String> pageIdsInOrder) =>
      _pageDao.reorderPages(pageIdsInOrder);

  @override
  Stream<List<CanvasWidgetData>> watchCanvasElements(String pageId) =>
      _canvasElementDao.watchCanvasElements(pageId);

  @override
  Future<void> upsertCanvasElement(CanvasWidgetData element) =>
      _canvasElementDao.upsertCanvasElement(element);

  @override
  Future<void> restoreCanvasElement(CanvasWidgetData element) =>
      _canvasElementDao.restoreCanvasElement(element);

  @override
  Future<bool> updateElementConfig(String id, String configJson) =>
      _canvasElementDao.updateElementConfig(id, configJson);

  @override
  Future<void> deleteCanvasElement(String id) =>
      _canvasElementDao.deleteCanvasElement(id);

  @override
  Stream<List<InkStroke>> watchStrokes(String pageId) =>
      _strokeDao.watchStrokes(pageId);

  @override
  Future<void> insertStroke(InkStroke stroke) =>
      _strokeDao.insertStroke(stroke);

  @override
  Future<void> insertStrokesBatch(List<InkStroke> strokes) =>
      _strokeDao.insertStrokesBatch(strokes);

  @override
  Future<void> deleteStroke(String id) => _strokeDao.deleteStroke(id);

  @override
  Future<void> clearStrokes(String pageId) => _strokeDao.clearStrokes(pageId);

  @override
  Future<void> replaceStrokes(String pageId, List<InkStroke> strokes) =>
      _strokeDao.replaceStrokes(pageId, strokes);

  @override
  Future<AgendaSnapshot?> getAgendaSnapshot(
    String agendaId, {
    bool includeInk = true,
  }) {
    // One SQLite transaction ⇒ consistent view (SQLite gives a consistent
    // read inside a transaction; safe even while the viewer keeps writing
    // during an export).
    return _db.transaction(() async {
      final agenda = await _agendaDao.getAgenda(agendaId);
      if (agenda == null) return null;

      final pages = await _pageDao.getPages(agendaId);
      final elements = await _canvasElementDao.getCanvasElementsForAgenda(
        agendaId,
      );

      final strokesByPage = includeInk
          ? await _strokeDao.getStrokesForAgenda(agendaId)
          : const <String, Iterable<InkStroke>>{};

      // Group the single flat, already-ordered read by page without
      // reordering, then attach each group to its page.
      final elementsByPage = <String, List<CanvasWidgetData>>{};
      for (final element in elements) {
        elementsByPage.putIfAbsent(element.pageId, () => []).add(element);
      }

      return AgendaSnapshot(
        agenda: agenda,
        pages: [
          for (final page in pages)
            AgendaPageSnapshot(
              page: page,
              elements: elementsByPage[page.id] ?? const [],
              strokes: strokesByPage[page.id] ?? const [],
            ),
        ],
      );
    });
  }
}
