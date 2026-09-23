import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/element_history.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

/// Manages the state and mutations of canvas elements on a page.
///
/// Handles element CRUD, transform operations, snapping cache,
/// and undo/redo coordination.
class CanvasElementManager {
  CanvasElementManager({
    required List<CanvasWidgetData> initialElements,
    required this.pageSize,
  })  : _elements = List.from(initialElements),
        _cachedSiblingRects =
            initialElements.map((e) => e.boundingBox).toList();

  final Size pageSize;
  List<CanvasWidgetData> _elements;
  List<Rect> _cachedSiblingRects;
  String? selectedElementId;
  final ElementHistory elementHistory = ElementHistory();

  List<CanvasWidgetData> get elements => _elements;
  List<Rect> get cachedSiblingRects => _cachedSiblingRects;

  /// Reset state for a new page.
  void reset(List<CanvasWidgetData> newElements) {
    _elements = List.from(newElements);
    _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
    selectedElementId = _elements.isNotEmpty ? _elements.first.id : null;
    elementHistory.clear();
  }

  /// Record the current element state for undo before a mutation.
  void recordStateForUndo() {
    elementHistory.push(_elements);
  }

  void _updateCache() {
    _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
  }

  /// Applies a widget-level config edit to the manager's copy of the element.
  ///
  /// The widget owns its config state, but the manager's snapshot feeds
  /// full-row persistence writes (drags, color changes): keeping it fresh
  /// prevents those writes from reverting the edit. No undo entry is
  /// recorded — config edits have never been part of element undo.
  void handleConfigChanged(String elementId, String configJson) {
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      _elements[index] = _elements[index].copyWith(configJson: configJson);
    }
  }

  void handleTransformChanged(
    String elementId,
    Offset newPosition,
    Size newSize,
    double newRotation,
  ) {
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      _elements[index] = _elements[index].copyWith(
        position: newPosition,
        size: newSize,
        rotation: newRotation,
      );
      _updateCache();
    }
  }

  void handleDeleteElement(String elementId) {
    recordStateForUndo();
    _elements.removeWhere((e) => e.id == elementId);
    _updateCache();
    if (selectedElementId == elementId) {
      selectedElementId = _elements.isNotEmpty ? _elements.first.id : null;
    }
  }

  void handleAdaptToPage(String elementId) {
    recordStateForUndo();
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      _elements[index] = _elements[index].copyWith(
        position: Offset.zero,
        size: pageSize,
        rotation: 0,
      );
      _updateCache();
    }
  }

  void handleFitWidth(String elementId) {
    recordStateForUndo();
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      const margin = kCanvasMargin;
      final current = _elements[index];
      _elements[index] = current.copyWith(
        position: Offset(margin, current.position.dy),
        size: Size(pageSize.width - (margin * 2), current.size.height),
      );
      _updateCache();
    }
  }

  void handleCenter(String elementId) {
    recordStateForUndo();
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      final current = _elements[index];
      _elements[index] = current.copyWith(
        position: Offset(
          (pageSize.width - current.size.width) / 2,
          (pageSize.height - current.size.height) / 2,
        ),
      );
      _updateCache();
    }
  }

  void handleColorChanged(
    String elementId,
    Color fillColor,
    Color borderColor,
  ) {
    recordStateForUndo();
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      final current = _elements[index];
      final newJson = ElementConfig.updateColorInJson(
        current.configJson,
        fillColor: fillColor,
        borderColor: borderColor,
      );
      _elements[index] = current.copyWith(configJson: newJson);
      _updateCache();
    }
  }

  void addElement(CanvasWidgetData element) {
    recordStateForUndo();
    _elements.add(element);
    _updateCache();
    selectedElementId = element.id;
  }

  List<CanvasWidgetData>? undoElements() {
    final restored = elementHistory.undo(_elements);
    if (restored != null) {
      _elements = restored;
      _updateCache();
      selectedElementId =
          _elements.isNotEmpty ? _elements.first.id : null;
    }
    return restored;
  }

  List<CanvasWidgetData>? redoElements() {
    final restored = elementHistory.redo(_elements);
    if (restored != null) {
      _elements = restored;
      _updateCache();
      selectedElementId =
          _elements.isNotEmpty ? _elements.first.id : null;
    }
    return restored;
  }
}
