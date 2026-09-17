import 'package:flutter/foundation.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/element_history.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';

/// Combined controller for a canvas page, wrapping stroke undo/redo
/// (via [InkCanvasController]) and element undo/redo (via [ElementHistory]).
class PageCanvasController extends ChangeNotifier {
  PageCanvasController({
    required this._inkController,
    required this._elementHistory,
  }) {
    _inkController.addListener(notifyListeners);
  }

  final InkCanvasController _inkController;
  final ElementHistory _elementHistory;

  /// Set by the canvas state to wire up element add/remove/undo/redo
  /// with the actual state.
  void Function(CanvasWidgetData element)? addElementCallback;
  VoidCallback? undoElementsCallback;
  VoidCallback? redoElementsCallback;

  InkCanvasController get ink => _inkController;
  ElementHistory get elementHistory => _elementHistory;

  // --- Stroke undo/redo (delegates to InkCanvasController) ---

  bool get canUndoStrokes => _inkController.canUndo;
  bool get canRedoStrokes => _inkController.canRedo;
  void undoStrokes() => _inkController.undo();
  void redoStrokes() => _inkController.redo();
  void clearStrokes() => _inkController.clear();

  // --- Element undo/redo ---

  bool get canUndoElements => _elementHistory.canUndo;
  bool get canRedoElements => _elementHistory.canRedo;

  void undoElements() => undoElementsCallback?.call();
  void redoElements() => redoElementsCallback?.call();

  /// Adds an element to the local canvas state (with undo history).
  void addElement(CanvasWidgetData element) => addElementCallback?.call(element);

  /// Captures the current element state before a mutation.
  void pushElementState(List<CanvasWidgetData> current) =>
      _elementHistory.push(current);

  // --- Combined ---

  bool get canUndo => canUndoStrokes || canUndoElements;
  bool get canRedo => canRedoStrokes || canRedoElements;

  @override
  void dispose() {
    _inkController
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
