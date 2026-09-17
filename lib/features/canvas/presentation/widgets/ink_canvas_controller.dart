import 'package:flutter/foundation.dart';

/// Abstract interface for the ink canvas state, breaking the circular dependency
/// between the controller and the state class.
abstract class InkCanvasHost {
  bool get canUndo;
  bool get canRedo;
  void undo();
  void redo();
  void clear();
}

/// Controller allowing external widgets (e.g., toolbars) to trigger undo/redo.
///
/// What: Exposes methods to undo, redo, clear, and inspect history depth.
/// Why: Separates canvas presentation from user-triggered toolbar buttons.
class InkCanvasController extends ChangeNotifier {
  InkCanvasHost? _state;

  /// Attaches the controller to a canvas host state.
  ///
  /// Should be called by the canvas widget in initState and didUpdateWidget.
  void attach(InkCanvasHost state) {
    if (_state != state) {
      _state = state;
    }
  }

  /// Detaches the controller from its current canvas host state.
  ///
  /// Should be called by the canvas widget in dispose and didUpdateWidget.
  void detach() {
    if (_state != null) {
      _state = null;
    }
  }

  /// Notifies listeners that the undo/redo stack state has changed.
  void notifyHistoryChanged() {
    notifyListeners();
  }

  /// Returns true if an action can be undone.
  bool get canUndo => _state?.canUndo ?? false;

  /// Returns true if an action can be redone.
  bool get canRedo => _state?.canRedo ?? false;

  /// Triggers an undo operation.
  void undo() {
    _state?.undo();
    notifyListeners();
  }

  /// Triggers a redo operation.
  void redo() {
    _state?.redo();
    notifyListeners();
  }

  /// Clears all strokes on the active canvas.
  void clear() {
    _state?.clear();
    notifyListeners();
  }
}
