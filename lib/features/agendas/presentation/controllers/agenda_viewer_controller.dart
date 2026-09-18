import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:uuid/uuid.dart';

/// Exposes the reactive list of pages for a given agenda ID.
// ignore: specify_nonobvious_property_types
final agendaPagesProvider = StreamProvider.family<List<AgendaPage>, String>((
  ref,
  agendaId,
) {
  final repository = ref.watch(agendaRepositoryProvider);
  return repository.watchPages(agendaId);
});

/// Exposes the UI-ready canvas widget elements for a given page ID.
// ignore: specify_nonobvious_property_types
final pageElementsProvider =
    StreamProvider.family<List<CanvasWidgetData>, String>((ref, pageId) {
      final repository = ref.watch(agendaRepositoryProvider);
      return repository.watchCanvasElements(pageId);
    });

/// Exposes the UI-ready vector ink strokes for a given page ID.
// ignore: specify_nonobvious_property_types
final pageStrokesProvider = StreamProvider.family<List<InkStroke>, String>((
  ref,
  pageId,
) {
  final repository = ref.watch(agendaRepositoryProvider);
  return repository.watchStrokes(pageId);
});

/// Provider for [AgendaViewerController].
final Provider<AgendaViewerController> agendaViewerControllerProvider =
    Provider<AgendaViewerController>((ref) {
      final repository = ref.watch(agendaRepositoryProvider);
      return AgendaViewerController(repository);
    });

/// ViewModel/Controller managing state mutations and business logic for the agenda viewer.
///
/// Encapsulates page management, element lifecycle, and vector stroke synchronization.
class AgendaViewerController {
  /// Constructs an [AgendaViewerController] using the provided [AgendaRepository].
  const AgendaViewerController(this._repository);

  final AgendaRepository _repository;
  static const _uuid = Uuid();

  /// Adds a new page to the given [agendaId].
  Future<AgendaPage> addPage({
    required String agendaId,
    required int pageNumber,
    String backgroundStyle = 'dotted',
  }) {
    return _repository.createPage(
      agendaId: agendaId,
      pageNumber: pageNumber,
      backgroundStyle: backgroundStyle,
    );
  }

  /// Soft-deletes a page by its [pageId].
  Future<void> deletePage(String pageId) {
    return _repository.deletePage(pageId);
  }

  /// Reorders pages according to the provided list of [pageIdsInOrder].
  Future<void> reorderPages(List<String> pageIdsInOrder) =>
      _repository.reorderPages(pageIdsInOrder);

  /// Updates the paper background pattern of a page.
  Future<void> updatePageBackground(String pageId, String backgroundStyle) {
    return _repository.updatePageBackground(pageId, backgroundStyle);
  }

  /// Adds a modular catalog element to a page.
  Future<void> addCatalogElement({
    required String pageId,
    required AgendaWidgetDefinition definition,
  }) async {
    final element = CanvasWidgetData(
      id: _uuid.v4(),
      pageId: pageId,
      widgetType: definition.id,
      position: const Offset(kNewElementDefaultX, kNewElementDefaultY),
      size: definition.defaultSize,
      configJson: definition.initialConfigJson,
    );

    await _repository.upsertCanvasElement(element);
  }

  /// Updates the 2D transform (position, size, rotation) of a canvas element.
  Future<void> updateElementTransform(CanvasWidgetData updatedData) {
    return _repository.upsertCanvasElement(updatedData);
  }

  /// Updates the JSON configuration payload of a canvas element.
  Future<void> updateElementConfig(CanvasWidgetData data, String newJson) {
    return _repository.upsertCanvasElement(data.copyWith(configJson: newJson));
  }

  /// Deletes a canvas element by its [id].
  Future<void> deleteElement(String id) {
    return _repository.deleteCanvasElement(id);
  }

  /// Duplicates an existing canvas element on the page with a slight offset.
  Future<void> duplicateElement(CanvasWidgetData source) async {
    final duplicate = CanvasWidgetData(
      id: _uuid.v4(),
      pageId: source.pageId,
      widgetType: source.widgetType,
      position: Offset(source.position.dx + kDuplicateOffset, source.position.dy + kDuplicateOffset),
      size: source.size,
      rotation: source.rotation,
      configJson: source.configJson,
    );
    await _repository.upsertCanvasElement(duplicate);
  }

  /// Synchronizes vector ink strokes for a page.
  Future<void> syncStrokes(String pageId, List<InkStroke> newStrokes) async {
    await _repository.clearStrokes(pageId);
    if (newStrokes.isEmpty) return;
    await _repository.insertStrokesBatch(newStrokes);
  }
}
