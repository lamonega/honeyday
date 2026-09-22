import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode_notifier.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas/canvas_gesture_layer.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas/canvas_grid_overlay.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas/canvas_page_shadow.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_element_manager.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_toolbar.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

export 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

// ──────────────────────────────────────────────
// Page view constants (used only here)
// ──────────────────────────────────────────────

/// Default page width in points.
const double kDefaultPageWidth = 800;

/// Touch slop for gesture detection.
const double kCanvasTouchSlop = 4;

/// Toolbar vertical position from top.
const double kToolbarTopPosition = 16;

/// The multi-layer interactive canvas page for Honeyday planners.
class PageViewCanvas extends ConsumerStatefulWidget {
  const PageViewCanvas({
    required this.pageId,
    super.key,
    this.paperStyle = PaperStyle.dotted,
    this.pageSize = const Size(kDefaultPageWidth, kDefaultPageHeight),
    this.initialElements = const [],
    this.initialStrokes = const [],
    this.elementBuilder,
    this.onElementUpdated,
    this.onElementDeleted,
    this.onElementDuplicated,
    this.onStrokesChanged,
    this.onDirty,
    this.onControllerCreated,
    this.showToolbar = true,
    this.strokesVisible = true,
  });

  final String pageId;
  final PaperStyle paperStyle;
  final Size pageSize;
  final List<CanvasWidgetData> initialElements;
  final List<InkStroke> initialStrokes;
  final Widget Function(BuildContext context, CanvasWidgetData element)?
  elementBuilder;
  final void Function(CanvasWidgetData updatedElement)? onElementUpdated;
  final void Function(String elementId)? onElementDeleted;
  final void Function(CanvasWidgetData sourceElement)? onElementDuplicated;
  final ValueChanged<List<InkStroke>>? onStrokesChanged;
  final VoidCallback? onDirty;
  final void Function(PageCanvasController controller)? onControllerCreated;
  final bool showToolbar;
  final bool strokesVisible;

  @override
  ConsumerState<PageViewCanvas> createState() => _PageViewCanvasState();
}

class _PageViewCanvasState extends ConsumerState<PageViewCanvas> {
  late final CanvasElementManager _elementManager;
  bool _transformActive = false;
  List<SnapGuideLine> _activeSnapGuides = const [];
  late final PageCanvasController _pageController;

  @override
  void initState() {
    super.initState();
    _elementManager = CanvasElementManager(
      initialElements: widget.initialElements,
      pageSize: widget.pageSize,
    );
    _pageController = PageCanvasController(
      inkController: InkCanvasController(),
      elementHistory: _elementManager.elementHistory,
    );
    _pageController.undoElementsCallback = undoElements;
    _pageController.redoElementsCallback = redoElements;
    _pageController.addElementCallback = _addElement;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerCreated?.call(_pageController);
    });
  }

  @override
  void didUpdateWidget(covariant PageViewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId) {
      _elementManager.reset(widget.initialElements);
      _activeSnapGuides = const [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTransformStarted(String elementId) {
    if (!_transformActive) {
      _transformActive = true;
      _pageController.pushElementState(_elementManager.elements);
    }
  }

  void _handleTransformEnded() {
    _transformActive = false;
  }

  void _handleTransformChanged(
    String elementId,
    Offset newPosition,
    Size newSize,
    double newRotation,
  ) {
    setState(() {
      _elementManager.handleTransformChanged(
        elementId,
        newPosition,
        newSize,
        newRotation,
      );
      widget.onElementUpdated?.call(
        _elementManager.elements.firstWhere((e) => e.id == elementId),
      );
      widget.onDirty?.call();
    });
  }

  void _handleDeleteElement(String elementId) {
    setState(() {
      _elementManager.handleDeleteElement(elementId);
    });
    widget.onElementDeleted?.call(elementId);
    widget.onDirty?.call();
  }

  void _handleAdaptToPage(String elementId) {
    setState(() {
      _elementManager.handleAdaptToPage(elementId);
      widget.onElementUpdated?.call(
        _elementManager.elements.firstWhere((e) => e.id == elementId),
      );
      widget.onDirty?.call();
    });
  }

  void _handleFitWidth(String elementId) {
    setState(() {
      _elementManager.handleFitWidth(elementId);
      widget.onElementUpdated?.call(
        _elementManager.elements.firstWhere((e) => e.id == elementId),
      );
      widget.onDirty?.call();
    });
  }

  void _handleCenter(String elementId) {
    setState(() {
      _elementManager.handleCenter(elementId);
      widget.onElementUpdated?.call(
        _elementManager.elements.firstWhere((e) => e.id == elementId),
      );
      widget.onDirty?.call();
    });
  }

  void _handleColorChanged(
    String elementId,
    Color fillColor,
    Color borderColor,
  ) {
    setState(() {
      _elementManager.handleColorChanged(elementId, fillColor, borderColor);
      widget.onElementUpdated?.call(
        _elementManager.elements.firstWhere((e) => e.id == elementId),
      );
      widget.onDirty?.call();
    });
  }

  void _addElement(CanvasWidgetData element) {
    setState(() {
      _elementManager.addElement(element);
    });
    widget.onElementUpdated?.call(element);
    widget.onDirty?.call();
  }

  void undoElements() {
    final previous = _elementManager.elements;
    final restored = _elementManager.undoElements();
    if (restored != null) {
      final restoredIds = restored.map((e) => e.id).toSet();
      for (final removed
          in previous.where((e) => !restoredIds.contains(e.id))) {
        widget.onElementDeleted?.call(removed.id);
      }
      setState(() {});
      final onUpdated = widget.onElementUpdated;
      if (onUpdated != null) {
        _elementManager.elements.forEach(onUpdated);
      }
      widget.onDirty?.call();
    }
  }

  void redoElements() {
    final previous = _elementManager.elements;
    final restored = _elementManager.redoElements();
    if (restored != null) {
      final previousIds = previous.map((e) => e.id).toSet();
      final onUpdated = widget.onElementUpdated;
      if (onUpdated != null) {
        restored
            .where((e) => !previousIds.contains(e.id))
            .forEach(onUpdated);
      }
      setState(() {});
      if (onUpdated != null) {
        _elementManager.elements.forEach(onUpdated);
      }
      widget.onDirty?.call();
    }
  }

  List<Widget> _buildElementLayers(CanvasMode mode) {
    return _elementManager.elements.map((element) {
      final isSelected = _elementManager.selectedElementId == element.id;
      final siblingRects = _elementManager.cachedSiblingRects
          .where((r) => r != element.boundingBox)
          .toList();

      return TransformableBox(
        key: ValueKey(element.id),
        position: element.position,
        size: element.size,
        rotation: element.rotation,
        canvasMode: mode,
        isSelected: isSelected,
        pageSize: widget.pageSize,
        siblingRects: siblingRects,
        onTap: () {
          setState(() {
            _elementManager.selectedElementId = element.id;
          });
        },
        onTransformChanged: (pos, size, rot) {
          _handleTransformChanged(element.id, pos, size, rot);
        },
        onTransformStarted: () => _handleTransformStarted(element.id),
        onTransformEnded: _handleTransformEnded,
        onSnapGuidesChanged: (guides) {
          setState(() {
            _activeSnapGuides = guides;
          });
        },
        onDelete: () => _handleDeleteElement(element.id),
        onAdaptToPage: () => _handleAdaptToPage(element.id),
        onFitWidth: () => _handleFitWidth(element.id),
        onCenter: () => _handleCenter(element.id),
        onDuplicate: widget.onElementDuplicated != null
            ? () => widget.onElementDuplicated!(element)
            : null,
        onColorChanged: (fill, border) =>
            _handleColorChanged(element.id, fill, border),
        currentColor:
            ElementConfig.fromJsonString(element.configJson).fillColor,
        child: widget.elementBuilder?.call(context, element) ??
            _buildDefaultElementCard(
              element,
              Theme.of(context).colorScheme,
            ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(canvasModeProvider);
    final inkToolState = ref.watch(inkToolProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Center(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      gestureSettings:
                          const DeviceGestureSettings(touchSlop: kCanvasTouchSlop),
                    ),
                    child: CanvasPageShadow(
                      pageSize: widget.pageSize,
                      colorScheme: colorScheme,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: PageSurface(paperStyle: widget.paperStyle),
                          ),
                          ..._buildElementLayers(mode),
                          CanvasGridOverlay(
                            guides: _activeSnapGuides,
                            guideColor: colorScheme.primary,
                          ),
                          CanvasGestureLayer(
                            pageId: widget.pageId,
                            activeTool: inkToolState.tool,
                            activeColor: inkToolState.color,
                            activeStrokeWidth: inkToolState.strokeWidth,
                            initialStrokes: widget.initialStrokes,
                            controller: _pageController.ink,
                            onStrokesChanged: (strokes) {
                              widget.onStrokesChanged?.call(strokes);
                              widget.onDirty?.call();
                            },
                            canvasMode: mode,
                            strokesVisible: widget.strokesVisible,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.showToolbar && mode == CanvasMode.writing)
                  Positioned(
                    top: kToolbarTopPosition,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CanvasFloatingToolbar(
                        inkController: _pageController.ink,
                        onCloseWriting: () {
                          ref.read(canvasModeProvider.notifier).setReading();
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultElementCard(
    CanvasWidgetData element,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: colorScheme.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.widgets_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    element.widgetType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            Expanded(
              child: Center(
                child: Text(
                  AppLocalizations.of(context).canvasModularWidgetContainer,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
