import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/presentation/canvas/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_painter.dart';
import 'package:honeyday/features/canvas/presentation/widgets/canvas_toolbar.dart';
import 'package:honeyday/features/canvas/presentation/widgets/element_history.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_canvas_controller.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

export 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

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
  late List<CanvasWidgetData> _elements;
  late List<Rect> _cachedSiblingRects;
  String? _selectedElementId;
  bool _transformActive = false;
  List<SnapGuideLine> _activeSnapGuides = const [];
  late final PageCanvasController _pageController;

  @override
  void initState() {
    super.initState();
    _elements = List.from(widget.initialElements);
    _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
    if (_elements.isNotEmpty) {
      _selectedElementId = _elements.first.id;
    }
    _pageController = PageCanvasController(
      inkController: InkCanvasController(),
      elementHistory: ElementHistory(),
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
      _elements = List.from(widget.initialElements);
      _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
      _selectedElementId = _elements.isNotEmpty ? _elements.first.id : null;
      _activeSnapGuides = const [];
      _pageController.elementHistory.clear();
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
      _pageController.pushElementState(_elements);
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
      final index = _elements.indexWhere((e) => e.id == elementId);
      if (index != -1) {
        final updated = _elements[index].copyWith(
          position: newPosition,
          size: newSize,
          rotation: newRotation,
        );
        _elements[index] = updated;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        widget.onElementUpdated?.call(updated);
        widget.onDirty?.call();
      }
    });
  }

  void _handleDeleteElement(String elementId) {
    _pageController.pushElementState(_elements);
    setState(() {
      _elements.removeWhere((e) => e.id == elementId);
      _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
      if (_selectedElementId == elementId) {
        _selectedElementId = _elements.isNotEmpty ? _elements.first.id : null;
      }
    });
    widget.onElementDeleted?.call(elementId);
    widget.onDirty?.call();
  }

  void _handleAdaptToPage(String elementId) {
    _pageController.pushElementState(_elements);
    setState(() {
      final index = _elements.indexWhere((e) => e.id == elementId);
      if (index != -1) {
        final updated = _elements[index].copyWith(
          position: Offset.zero,
          size: widget.pageSize,
          rotation: 0,
        );
        _elements[index] = updated;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        widget.onElementUpdated?.call(updated);
        widget.onDirty?.call();
      }
    });
  }

  void _handleFitWidth(String elementId) {
    _pageController.pushElementState(_elements);
    setState(() {
      final index = _elements.indexWhere((e) => e.id == elementId);
      if (index != -1) {
        const margin = kCanvasMargin;
        final current = _elements[index];
        final updated = current.copyWith(
          position: Offset(margin, current.position.dy),
          size: Size(widget.pageSize.width - (margin * 2), current.size.height),
        );
        _elements[index] = updated;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        widget.onElementUpdated?.call(updated);
        widget.onDirty?.call();
      }
    });
  }

  void _handleCenter(String elementId) {
    _pageController.pushElementState(_elements);
    setState(() {
      final index = _elements.indexWhere((e) => e.id == elementId);
      if (index != -1) {
        final current = _elements[index];
        final updated = current.copyWith(
          position: Offset(
            (widget.pageSize.width - current.size.width) / 2,
            (widget.pageSize.height - current.size.height) / 2,
          ),
        );
        _elements[index] = updated;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        widget.onElementUpdated?.call(updated);
        widget.onDirty?.call();
      }
    });
  }

  void _handleColorChanged(
    String elementId,
    Color fillColor,
    Color borderColor,
  ) {
    _pageController.pushElementState(_elements);
    setState(() {
      final index = _elements.indexWhere((e) => e.id == elementId);
      if (index != -1) {
        final current = _elements[index];
        final newJson = ElementConfig.updateColorInJson(
          current.configJson,
          fillColor: fillColor,
          borderColor: borderColor,
        );
        final updated = current.copyWith(configJson: newJson);
        _elements[index] = updated;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        widget.onElementUpdated?.call(updated);
        widget.onDirty?.call();
      }
    });
  }

  void _addElement(CanvasWidgetData element) {
    _pageController.pushElementState(_elements);
    setState(() {
      _elements.add(element);
      _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
      _selectedElementId = element.id;
    });
    widget.onElementUpdated?.call(element);
    widget.onDirty?.call();
  }

  void undoElements() {
    final previous = _elements;
    final restored = _pageController.elementHistory.undo(_elements);
    if (restored != null) {
      final restoredIds = restored.map((e) => e.id).toSet();
      for (final removed
          in previous.where((e) => !restoredIds.contains(e.id))) {
        widget.onElementDeleted?.call(removed.id);
      }
      setState(() {
        _elements = restored;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        _selectedElementId =
            _elements.isNotEmpty ? _elements.first.id : null;
      });
      final onUpdated = widget.onElementUpdated;
      if (onUpdated != null) {
        _elements.forEach(onUpdated);
      }
      widget.onDirty?.call();
    }
  }

  void redoElements() {
    final previous = _elements;
    final restored = _pageController.elementHistory.redo(_elements);
    if (restored != null) {
      final previousIds = previous.map((e) => e.id).toSet();
      final onUpdated = widget.onElementUpdated;
      if (onUpdated != null) {
        restored
            .where((e) => !previousIds.contains(e.id))
            .forEach(onUpdated);
      }
      setState(() {
        _elements = restored;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        _selectedElementId =
            _elements.isNotEmpty ? _elements.first.id : null;
      });
      if (onUpdated != null) {
        _elements.forEach(onUpdated);
      }
      widget.onDirty?.call();
    }
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
                    child: FittedBox(
                      child: Container(
                        width: widget.pageSize.width,
                        height: widget.pageSize.height,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(kPageBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: kPageShadowAlpha),
                            blurRadius: kPageShadowBlur,
                            offset: const Offset(0, kPageShadowOffsetY),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(kPageBorderRadius),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: PageSurface(paperStyle: widget.paperStyle),
                            ),
                            ..._elements.map((element) {
                              final isSelected =
                                  _selectedElementId == element.id;
                              final siblingRects = _cachedSiblingRects
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
                                    _selectedElementId = element.id;
                                  });
                                },
                                onTransformChanged: (pos, size, rot) {
                                  _handleTransformChanged(
                                    element.id,
                                    pos,
                                    size,
                                    rot,
                                  );
                                },
                                onTransformStarted: () =>
                                    _handleTransformStarted(element.id),
                                onTransformEnded: _handleTransformEnded,
                                onSnapGuidesChanged: (guides) {
                                  setState(() {
                                    _activeSnapGuides = guides;
                                  });
                                },
                                onDelete: () =>
                                    _handleDeleteElement(element.id),
                                onAdaptToPage: () =>
                                    _handleAdaptToPage(element.id),
                                onFitWidth: () => _handleFitWidth(element.id),
                                onCenter: () => _handleCenter(element.id),
                                onDuplicate: widget.onElementDuplicated != null
                                    ? () => widget.onElementDuplicated!(element)
                                    : null,
                                onColorChanged: (fill, border) =>
                                    _handleColorChanged(
                                      element.id,
                                      fill,
                                      border,
                                    ),
                                currentColor: ElementConfig.fromJsonString(
                                  element.configJson,
                                ).fillColor,
                                child:
                                    widget.elementBuilder?.call(
                                      context,
                                      element,
                                    ) ??
                                    _buildDefaultElementCard(
                                      element,
                                      colorScheme,
                                    ),
                              );
                            }),
                            if (mode == CanvasMode.edit &&
                                _activeSnapGuides.isNotEmpty)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: SnapGuideOverlayPainter(
                                      guides: _activeSnapGuides,
                                      guideColor: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: mode != CanvasMode.writing ||
                                    !widget.strokesVisible,
                                child: Visibility(
                                  visible: widget.strokesVisible,
                                  child: InkCanvas(
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
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  'Modular Widget Container',
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
