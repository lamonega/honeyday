import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/canvas/presentation/widgets/erase_logic.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_painter.dart';
import 'package:uuid/uuid.dart';

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

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> implements InkCanvasHost {
  static const _uuid = Uuid();
  static const _maxUndoSize = 50;

  List<InkStroke> _strokes = [];
  final List<List<InkStroke>> _undoStack = [];
  final List<List<InkStroke>> _redoStack = [];

  List<StrokePoint>? _activePoints;
  bool _hasErasedDuringCurrentGesture = false;

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
    if (oldWidget.pageId != widget.pageId) {
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
    if (_undoStack.length > _maxUndoSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    widget.controller?.notifyHistoryChanged();
  }

  @override
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_strokes));
    _strokes = _undoStack.removeLast();
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  @override
  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_strokes));
    _strokes = _redoStack.removeLast();
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  @override
  void clear() {
    if (_strokes.isEmpty) return;
    _pushUndoState();
    _strokes = [];
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  void _handlePointerDown(PointerDownEvent event) {
    final pos = event.localPosition;
    final pressure = event.pressureMin == event.pressureMax
        ? 0.5
        : event.pressure;
    final point = StrokePoint(pos.dx, pos.dy, pressure);

    if (widget.activeTool == InkToolType.eraser) {
      _hasErasedDuringCurrentGesture = false;
      _activePoints = [point];
      _eraseIntersectingStrokes(pos);
    } else {
      _activePoints = [point];
    }
    setState(() {});
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePoints == null) return;
    final pos = event.localPosition;
    final pressure = event.pressureMin == event.pressureMax
        ? 0.5
        : event.pressure;
    final point = StrokePoint(pos.dx, pos.dy, pressure);

    _activePoints!.add(point);

    if (widget.activeTool == InkToolType.eraser) {
      _eraseIntersectingStrokes(pos);
    }
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePoints == null) return;

    if (widget.activeTool == InkToolType.eraser) {
      if (_hasErasedDuringCurrentGesture) {
        widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
      }
    } else if (_activePoints!.isNotEmpty) {
      _pushUndoState();
      final colorHex =
          '#${widget.activeColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
      final newStroke = InkStroke(
        id: _uuid.v4(),
        pageId: widget.pageId,
        tool: widget.activeTool,
        colorHex: colorHex,
        strokeWidth: widget.activeStrokeWidth,
        points: List.from(_activePoints!),
        createdAt: DateTime.now().toUtc(),
      );
      _strokes = [..._strokes, newStroke];
      widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    }

    _activePoints = null;
    _hasErasedDuringCurrentGesture = false;
    setState(() {});
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePoints = null;
    _hasErasedDuringCurrentGesture = false;
    setState(() {});
  }

  void _eraseIntersectingStrokes(Offset eraserPos) {
    final eraserRadius = widget.activeStrokeWidth / 2;
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
      if (!_hasErasedDuringCurrentGesture) {
        _pushUndoState();
        _hasErasedDuringCurrentGesture = true;
      }
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
                activeTool: widget.activeTool,
                activeColor: widget.activeColor,
                activeStrokeWidth: widget.activeStrokeWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
