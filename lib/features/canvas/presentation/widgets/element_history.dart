import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

/// Snapshot-based undo/redo history for element operations on a single page.
///
/// Stores full snapshots of the element list. Acceptable for planner pages
/// with a modest number of elements (typically < 20).
class ElementHistory {
  final List<List<CanvasWidgetData>> _undoStack = [];
  final List<List<CanvasWidgetData>> _redoStack = [];
  static const int _maxSize = 50;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Captures the current state before a mutation.
  void push(List<CanvasWidgetData> currentElements) {
    _undoStack.add(List.from(currentElements));
    if (_undoStack.length > _maxSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Restores the previous state. Returns null if nothing to undo.
  List<CanvasWidgetData>? undo(List<CanvasWidgetData> currentElements) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(List.from(currentElements));
    return _undoStack.removeLast();
  }

  /// Restores the next state. Returns null if nothing to redo.
  List<CanvasWidgetData>? redo(List<CanvasWidgetData> currentElements) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(List.from(currentElements));
    return _redoStack.removeLast();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
