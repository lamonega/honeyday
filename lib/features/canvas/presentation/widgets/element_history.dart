import 'dart:convert';

import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

/// Snapshot-based undo/redo history for element operations on a single page.
///
/// Stores full snapshots of the element list. Acceptable for planner pages
/// with a modest number of elements (typically < 20).
class ElementHistory {
  final List<List<CanvasWidgetData>> _undoStack = [];
  final List<List<CanvasWidgetData>> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Captures the current state before a mutation.
  void push(List<CanvasWidgetData> currentElements) {
    _undoStack.add(List.from(currentElements));
    if (_undoStack.length > kMaxUndoSize) {
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

  /// Keeps non-undoable content edits in existing design snapshots.
  void rebaseConfig({
    required String elementId,
    required String beforeJson,
    required String afterJson,
  }) {
    final before = jsonDecode(beforeJson) as Map<String, dynamic>;
    final after = jsonDecode(afterJson) as Map<String, dynamic>;
    final changedKeys = <String>{...before.keys, ...after.keys}
        .where(
          (key) =>
              jsonEncode(before[key]) != jsonEncode(after[key]) ||
              before.containsKey(key) != after.containsKey(key),
        )
        .toList();

    void rebaseStack(List<List<CanvasWidgetData>> stack) {
      for (final snapshot in stack) {
        for (var i = 0; i < snapshot.length; i++) {
          final element = snapshot[i];
          if (element.id != elementId) continue;
          final config = jsonDecode(element.configJson) as Map<String, dynamic>;
          for (final key in changedKeys) {
            if (after.containsKey(key)) {
              config[key] = after[key];
            } else {
              config.remove(key);
            }
          }
          snapshot[i] = element.copyWith(configJson: jsonEncode(config));
        }
      }
    }

    rebaseStack(_undoStack);
    rebaseStack(_redoStack);
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
