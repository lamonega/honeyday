import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
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
    String backgroundStyle = 'dotted',
  });
  Future<void> updatePageBackground(String pageId, String backgroundStyle);
  Future<void> deletePage(String pageId);
  Future<void> reorderPages(List<String> pageIdsInOrder);
}

/// Repository for canvas element operations.
abstract interface class CanvasElementRepository {
  Stream<List<CanvasWidgetData>> watchCanvasElements(String pageId);
  Future<void> upsertCanvasElement(CanvasWidgetData element);
  Future<void> deleteCanvasElement(String id);
}

/// Repository for ink stroke operations.
abstract interface class StrokeRepository {
  Stream<List<InkStroke>> watchStrokes(String pageId);
  Future<void> insertStroke(InkStroke stroke);
  Future<void> insertStrokesBatch(List<InkStroke> strokes);
  Future<void> deleteStroke(String id);
  Future<void> clearStrokes(String pageId);
}

/// Combined repository interface for backward compatibility.
/// New code should prefer the focused interfaces above.
abstract interface class FullAgendaRepository
    implements
        AgendaRepository,
        PageRepository,
        CanvasElementRepository,
        StrokeRepository;
