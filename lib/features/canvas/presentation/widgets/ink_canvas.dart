import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:uuid/uuid.dart';

export 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';

/// Controller allowing external widgets (e.g., toolbars) to trigger undo/redo on an [InkCanvas].
///
/// What: Exposes methods to undo, redo, clear, and inspect history depth.
/// Why: Separates canvas presentation from user-triggered toolbar buttons.
class InkCanvasController extends ChangeNotifier {
  _InkCanvasState? _state;

  void _attach(_InkCanvasState state) {
    if (_state != state) {
      _state = state;
    }
  }

  void _detach() {
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

/// CustomPainter rendering freehand vector ink strokes using `perfect_freehand`.
///
/// What: Draws completed strokes and dynamically renders active in-progress strokes.
/// Why: Vector paths allow infinite resolution and physical fountain pen styling without raster degradation.
class InkPainter extends CustomPainter {
  /// Constructs an [InkPainter].
  InkPainter({
    required this.strokes,
    this.activePoints,
    this.activeTool = InkToolType.pen,
    this.activeColor = const Color(0xFF1E293B),
    this.activeStrokeWidth = 3,
  }) : _eraserPaint = Paint()
         ..color = const Color(0xFF64748B).withValues(alpha: 0.4)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.5;

  /// Completed strokes on this page.
  final List<InkStroke> strokes;

  /// Points collected for a stroke currently being drawn by the user.
  final List<PointVector>? activePoints;

  /// Active brush tool for the current stroke.
  final InkToolType activeTool;

  /// Active color for the current stroke.
  final Color activeColor;

  /// Active width for the current stroke.
  final double activeStrokeWidth;

  final Paint _eraserPaint;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      canvas.drawPath(stroke.path, _buildStrokePaint(stroke));
    }

    // 2. Draw stroke currently in progress
    if (activePoints != null && activePoints!.isNotEmpty) {
      if (activeTool == InkToolType.eraser) {
        final lastPoint = activePoints!.last;
        canvas.drawCircle(
          Offset(lastPoint.dx, lastPoint.dy),
          activeStrokeWidth / 2,
          _eraserPaint,
        );
      } else {
        final options = StrokeOptions(
          size: activeStrokeWidth,
          thinning: activeTool == InkToolType.pen ? 0.6 : 0,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: activeTool == InkToolType.pen,
          isComplete: false,
        );

        final outline = getStroke(activePoints!, options: options);
        if (outline.isNotEmpty) {
          final activePath = Path()..moveTo(outline.first.dx, outline.first.dy);
          for (var i = 1; i < outline.length; i++) {
            activePath.lineTo(outline[i].dx, outline[i].dy);
          }
          activePath.close();

          canvas.drawPath(activePath, _buildActivePaint());
        }
      }
    }
  }

  Paint _buildStrokePaint(InkStroke stroke) {
    final paint = Paint()..isAntiAlias = true;
    if (stroke.tool == InkToolType.highlighter) {
      paint
        ..color = stroke.color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;
    } else {
      paint
        ..color = stroke.color
        ..style = PaintingStyle.fill;
    }
    return paint;
  }

  Paint _buildActivePaint() {
    final paint = Paint()..isAntiAlias = true;
    if (activeTool == InkToolType.highlighter) {
      paint
        ..color = activeColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver;
    } else {
      paint
        ..color = activeColor
        ..style = PaintingStyle.fill;
    }
    return paint;
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) {
    if (activePoints != null || oldDelegate.activePoints != null) {
      return true;
    }
    return !listEquals(oldDelegate.strokes, strokes) ||
        oldDelegate.activeTool != activeTool ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth;
  }
}

/// Renders the transient stroke currently being drawn by the user or the eraser cursor.
///
/// What: Isolates active stroke rendering into a dedicated layer.
/// Why: Prevents repainting all completed historical strokes during continuous pointer movements (60/120fps).
class _ActiveStrokePainter extends CustomPainter {
  _ActiveStrokePainter({
    required this.activePoints,
    required this.activeTool,
    required this.activeColor,
    required this.activeStrokeWidth,
  }) : _eraserPaint = Paint()
         ..color = const Color(0xFF64748B).withValues(alpha: 0.4)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.5;

  final List<PointVector>? activePoints;
  final InkToolType activeTool;
  final Color activeColor;
  final double activeStrokeWidth;
  final Paint _eraserPaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (activePoints == null || activePoints!.isEmpty) return;

    if (activeTool == InkToolType.eraser) {
      final lastPoint = activePoints!.last;
      canvas.drawCircle(
        Offset(lastPoint.dx, lastPoint.dy),
        activeStrokeWidth / 2,
        _eraserPaint,
      );
    } else {
      final options = StrokeOptions(
        size: activeStrokeWidth,
        thinning: activeTool == InkToolType.pen ? 0.6 : 0,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: activeTool == InkToolType.pen,
        isComplete: false,
      );

      final outline = getStroke(activePoints!, options: options);
      if (outline.isNotEmpty) {
        final activePath = Path()..moveTo(outline.first.dx, outline.first.dy);
        for (var i = 1; i < outline.length; i++) {
          activePath.lineTo(outline[i].dx, outline[i].dy);
        }
        activePath.close();

        final paint = Paint()..isAntiAlias = true;
        if (activeTool == InkToolType.highlighter) {
          paint
            ..color = activeColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.srcOver;
        } else {
          paint
            ..color = activeColor
            ..style = PaintingStyle.fill;
        }
        canvas.drawPath(activePath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveStrokePainter oldDelegate) {
    return activePoints != null || oldDelegate.activePoints != null;
  }
}

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

class _InkCanvasState extends State<InkCanvas> {
  static const _uuid = Uuid();
  static const _maxUndoSize = 50;

  List<InkStroke> _strokes = [];
  final List<List<InkStroke>> _undoStack = [];
  final List<List<InkStroke>> _redoStack = [];

  List<PointVector>? _activePoints;
  bool _hasErasedDuringCurrentGesture = false;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialStrokes);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant InkCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
    if (oldWidget.pageId != widget.pageId) {
      _strokes = List.from(widget.initialStrokes);
      _undoStack.clear();
      _redoStack.clear();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
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

  /// Reverts the last stroke or eraser action.
  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.from(_strokes));
    _strokes = _undoStack.removeLast();
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  /// Restores the previously undone action.
  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.from(_strokes));
    _strokes = _redoStack.removeLast();
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
    setState(() {});
  }

  /// Clears all strokes on the canvas.
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
    final point = PointVector(pos.dx, pos.dy, pressure);

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
    final point = PointVector(pos.dx, pos.dy, pressure);

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
      final newStroke = InkStroke(
        id: _uuid.v4(),
        pageId: widget.pageId,
        tool: widget.activeTool,
        color: widget.activeColor,
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

  /// Detects and deletes any stroke intersecting the eraser tool at [eraserPos].
  void _eraseIntersectingStrokes(Offset eraserPos) {
    final eraserRadius = widget.activeStrokeWidth / 2;
    final surviving = <InkStroke>[];
    var erasedAny = false;

    for (final stroke in _strokes) {
      if (_strokeIntersectsPoint(stroke, eraserPos, eraserRadius)) {
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

  /// Spatial calculation determining if [stroke] intersects with an eraser circle at [point].
  bool _strokeIntersectsPoint(
    InkStroke stroke,
    Offset point,
    double eraserRadius,
  ) {
    final totalRadius = (stroke.strokeWidth / 2) + eraserRadius;
    // Bounding box spatial pruning
    if (!stroke.bounds.inflate(totalRadius).contains(point)) {
      return false;
    }

    final r2 = totalRadius * totalRadius;

    // Check distance against each line segment of the stroke
    for (var i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      if (_distanceSquaredToSegment(point, p1, p2) <= r2) {
        return true;
      }
    }

    if (stroke.points.length == 1) {
      final single = stroke.points.first;
      final dx = point.dx - single.dx;
      final dy = point.dy - single.dy;
      return (dx * dx + dy * dy) <= r2;
    }

    return false;
  }

  double _distanceSquaredToSegment(Offset p, PointVector a, PointVector b) {
    final l2 = (b.dx - a.dx) * (b.dx - a.dx) + (b.dy - a.dy) * (b.dy - a.dy);
    if (l2 == 0) {
      final dx = p.dx - a.dx;
      final dy = p.dy - a.dy;
      return dx * dx + dy * dy;
    }
    var t =
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    final projX = a.dx + t * (b.dx - a.dx);
    final projY = a.dy + t * (b.dy - a.dy);
    final dx = p.dx - projX;
    final dy = p.dy - projY;
    return dx * dx + dy * dy;
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
              painter: _ActiveStrokePainter(
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
