import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/agendas/data/repositories/agenda_repository_provider.dart';
import 'package:honeyday/features/agendas/domain/repositories/agenda_repository.dart';
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
      return repository.watchCanvasElements(pageId).map((rawList) {
        return rawList.map((e) {
          return CanvasWidgetData(
            id: e.id,
            pageId: e.pageId,
            widgetType: e.widgetType,
            position: Offset(e.posX, e.posY),
            size: Size(e.width, e.height),
            rotation: e.rotation,
            configJson: e.configJson,
          );
        }).toList();
      });
    });

/// Exposes the UI-ready vector ink strokes for a given page ID.
// ignore: specify_nonobvious_property_types
final pageStrokesProvider = StreamProvider.family<List<InkStroke>, String>((
  ref,
  pageId,
) {
  final repository = ref.watch(agendaRepositoryProvider);
  return repository.watchStrokes(pageId).map((rawList) {
    return rawList.map((s) {
      return InkStroke.fromDb(
        id: s.id,
        pageId: s.pageId,
        brushType: s.brushType,
        colorHex: s.colorHex,
        strokeWidth: s.strokeWidth,
        pointsJson: s.pointsJson,
        createdAt: s.createdAt,
      );
    }).toList();
  });
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
    final elementId = _uuid.v4();
    final companion = CanvasElementsCompanion.insert(
      id: elementId,
      pageId: pageId,
      widgetType: definition.id,
      posX: const drift.Value(120),
      posY: const drift.Value(100),
      width: drift.Value(definition.defaultSize.width),
      height: drift.Value(definition.defaultSize.height),
      rotation: const drift.Value(0),
      configJson: drift.Value(definition.initialConfigJson),
      createdAt: drift.Value(DateTime.now().toUtc()),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    );

    await _repository.upsertCanvasElement(companion);
  }

  /// Updates the 2D transform (position, size, rotation) of a canvas element.
  Future<void> updateElementTransform(CanvasWidgetData updatedData) {
    return _repository.upsertCanvasElement(
      CanvasElementsCompanion(
        id: drift.Value(updatedData.id),
        pageId: drift.Value(updatedData.pageId),
        widgetType: drift.Value(updatedData.widgetType),
        posX: drift.Value(updatedData.position.dx),
        posY: drift.Value(updatedData.position.dy),
        width: drift.Value(updatedData.size.width),
        height: drift.Value(updatedData.size.height),
        rotation: drift.Value(updatedData.rotation),
        configJson: drift.Value(updatedData.configJson),
        updatedAt: drift.Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Updates the JSON configuration payload of a canvas element.
  Future<void> updateElementConfig(CanvasWidgetData data, String newJson) {
    return _repository.upsertCanvasElement(
      CanvasElementsCompanion(
        id: drift.Value(data.id),
        pageId: drift.Value(data.pageId),
        widgetType: drift.Value(data.widgetType),
        configJson: drift.Value(newJson),
        updatedAt: drift.Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Deletes a canvas element by its [id].
  Future<void> deleteElement(String id) {
    return _repository.deleteCanvasElement(id);
  }

  /// Duplicates an existing canvas element on the page with a slight offset.
  Future<void> duplicateElement(CanvasWidgetData source) async {
    final newId = _uuid.v4();
    final companion = CanvasElementsCompanion.insert(
      id: newId,
      pageId: source.pageId,
      widgetType: source.widgetType,
      posX: drift.Value(source.position.dx + 24),
      posY: drift.Value(source.position.dy + 24),
      width: drift.Value(source.size.width),
      height: drift.Value(source.size.height),
      rotation: drift.Value(source.rotation),
      configJson: drift.Value(source.configJson),
      createdAt: drift.Value(DateTime.now().toUtc()),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    );
    await _repository.upsertCanvasElement(companion);
  }

  /// Synchronizes vector ink strokes for a page.
  Future<void> syncStrokes(String pageId, List<InkStroke> newStrokes) async {
    await _repository.clearStrokes(pageId);
    for (final stroke in newStrokes) {
      await _repository.insertStroke(
        StrokesCompanion.insert(
          id: stroke.id,
          pageId: pageId,
          brushType: drift.Value(stroke.tool.name),
          colorHex: drift.Value(stroke.toHexColor()),
          strokeWidth: drift.Value(stroke.strokeWidth),
          pointsJson: drift.Value(stroke.toJsonPoints()),
          createdAt: drift.Value(stroke.createdAt),
          updatedAt: drift.Value(DateTime.now().toUtc()),
        ),
      );
    }
  }
}
