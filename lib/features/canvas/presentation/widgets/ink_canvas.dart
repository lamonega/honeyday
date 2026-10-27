import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/canvas/presentation/widgets/erase_logic.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_painter.dart';
import 'package:uuid/uuid.dart';

// ──────────────────────────────────────────────
// Ink canvas constants (used only here)
// ──────────────────────────────────────────────

/// Default pressure when device doesn't report pressure data.
const double kDefaultPressure = 0.5;

/// Interactive vector ink drawing canvas (Layer 3).
///
/// What: Captures stylus and touch pointer events, calculates smooth polygon outlines
/// using `perfect_freehand`, supports Pen, Highlighter, and Eraser, and manages undo/redo history.
/// Why: Provides an authentic handwriting experience on agendas with zero input lag.
class InkCanvas extends StatefulWidget {
  /// Constructs an [InkCanvas].
  const InkCanvas({
    required this.pageId,
    required this.activeTool,
    required this.activeColor,
    required this.activeStrokeWidth,
    super.key,
    this.initialStrokes = const [],
    this.controller,
    this.onStrokesChanged,
    this.inputEnabled = true,
  });

  /// Page ID associated with these strokes.
  final String pageId;

  /// Active brush tool.
  final InkToolType activeTool;

  /// Active color.
  final Color activeColor;

  /// Active stroke width.
  final double activeStrokeWidth;

  /// Initial strokes loaded from database.
  final List<InkStroke> initialStrokes;

  /// Optional controller to trigger undo/redo from parent toolbars.
  final InkCanvasController? controller;

  /// Emits updated stroke list for debounced persistence.
  final ValueChanged<List<InkStroke>>? onStrokesChanged;

  /// Whether this canvas currently accepts new pointer gestures.
  final bool inputEnabled;

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> implements InkCanvasHost {
  static const _uuid = Uuid();

  List<InkStroke> _strokes = [];
  final List<List<InkStroke>> _undoStack = [];
  final List<List<InkStroke>> _redoStack = [];

  List<StrokePoint>? _activePoints;
  bool _hasErasedDuringCurrentGesture = false;
  int? _activePointerId;
  InkToolType? _gestureTool;
  Color? _gestureColor;
  double? _gestureWidth;
  List<InkStroke>? _strokesBeforeGesture;

  @override
  bool get canUndo => _undoStack.isNotEmpty;

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialStrokes);
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(covariant InkCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
    widget.controller?.attach(this);
    }
    if (oldWidget.inputEnabled && !widget.inputEnabled) {
      _cancelGesture();
    }
    if (oldWidget.pageId != widget.pageId) {
      _cancelGesture();
      _strokes = List.from(widget.initialStrokes);
      _undoStack.clear();
      _redoStack.clear();
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  void _pushUndoState() {
    _undoStack.add(List.from(_strokes));
    if (_undoStack.length > kMaxUndoSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    widget.controller?.notifyHistoryChanged();
  }

  @override
  void undo() {
    if (_activePointerId != null) _cancelGesture();
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_strokes));
    _strokes = _undoStack.removeLast();
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  @override
  void redo() {
    if (_activePointerId != null) _cancelGesture();
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_strokes));
    _strokes = _redoStack.removeLast();
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  @override
  void clear() {
    if (_activePointerId != null) _cancelGesture();
    if (_strokes.isEmpty) return;
    _pushUndoState();
    _strokes = [];
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.inputEnabled || _activePointerId != null) return;
    _activePointerId = event.pointer;
    _gestureTool = widget.activeTool;
    _gestureColor = widget.activeColor;
    _gestureWidth = widget.activeStrokeWidth;
    _strokesBeforeGesture = List<InkStroke>.of(_strokes);
    final pos = event.localPosition;
    final pressure = event.pressureMin == event.pressureMax
        ? kDefaultPressure
        : event.pressure;
    final point = StrokePoint(pos.dx, pos.dy, pressure);

    if (_gestureTool == InkToolType.eraser) {
      _hasErasedDuringCurrentGesture = false;
      _activePoints = [point];
      _eraseIntersectingStrokes(pos);
    } else {
      _activePoints = [point];
    }
    setState(() {});
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointerId != event.pointer || _activePoints == null) return;
    final pos = event.localPosition;
    final pressure = event.pressureMin == event.pressureMax
        ? kDefaultPressure
        : event.pressure;
    final point = StrokePoint(pos.dx, pos.dy, pressure);

    _activePoints!.add(point);

    if (_gestureTool == InkToolType.eraser) {
      _eraseIntersectingStrokes(pos);
    }
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointerId != event.pointer || _activePoints == null) return;
    final before = _strokesBeforeGesture!;
    var changed = false;

    if (_gestureTool == InkToolType.eraser) {
      changed = _hasErasedDuringCurrentGesture;
    } else if (_activePoints!.isNotEmpty) {
      final colorHex =
          '#${_gestureColor!.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
      final newStroke = InkStroke(
        id: _uuid.v4(),
        pageId: widget.pageId,
        tool: _gestureTool!,
        colorHex: colorHex,
        strokeWidth: _gestureWidth!,
        points: List.from(_activePoints!),
        createdAt: DateTime.now().toUtc(),
      );
      _strokes = [..._strokes, newStroke];
      changed = true;
    }

    if (changed) _recordUndo(before);
    _resetGesture();
    setState(() {});
    if (changed) {
      widget.controller?.notifyHistoryChanged();
      widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointerId != event.pointer) return;
    _cancelGesture();
    setState(() {});
  }

  void _recordUndo(List<InkStroke> snapshot) {
    _undoStack.add(List<InkStroke>.of(snapshot));
    if (_undoStack.length > kMaxUndoSize) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _cancelGesture() {
    final before = _strokesBeforeGesture;
    if (before != null) _strokes = before;
    _resetGesture();
  }

  void _resetGesture() {
    _activePointerId = null;
    _activePoints = null;
    _gestureTool = null;
    _gestureColor = null;
    _gestureWidth = null;
    _strokesBeforeGesture = null;
    _hasErasedDuringCurrentGesture = false;
  }

  void _eraseIntersectingStrokes(Offset eraserPos) {
    final eraserRadius = (_gestureWidth ?? widget.activeStrokeWidth) / 2;
    final surviving = <InkStroke>[];
    var erasedAny = false;

    for (final stroke in _strokes) {
      if (strokeIntersectsPoint(stroke, eraserPos, eraserRadius)) {
        erasedAny = true;
      } else {
        surviving.add(stroke);
      }
    }

    if (erasedAny) {
      _hasErasedDuringCurrentGesture = true;
      _strokes = surviving;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              isComplex: true,
              painter: InkPainter(strokes: _strokes),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: ActiveStrokePainter(
                activePoints: _activePoints,
                activeTool: _gestureTool ?? widget.activeTool,
                activeColor: _gestureColor ?? widget.activeColor,
                activeStrokeWidth: _gestureWidth ?? widget.activeStrokeWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
