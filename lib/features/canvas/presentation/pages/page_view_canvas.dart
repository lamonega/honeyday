import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

export 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

/// CustomPainter rendering magnetic alignment guidelines during widget drag.
class SnapGuideOverlayPainter extends CustomPainter {
  const SnapGuideOverlayPainter({
    required this.guides,
    this.guideColor = const Color(0xFFD97706),
  });

  final List<SnapGuideLine> guides;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (guides.isEmpty) return;

    final paint = Paint()
      ..color = guideColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final guide in guides) {
      canvas.drawLine(guide.start, guide.end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SnapGuideOverlayPainter oldDelegate) {
    return !listEquals(oldDelegate.guides, guides) ||
        oldDelegate.guideColor != guideColor;
  }
}

/// The multi-layer interactive canvas page for Honeyday planners.
class PageViewCanvas extends ConsumerStatefulWidget {
  const PageViewCanvas({
    required this.pageId,
    super.key,
    this.paperStyle = PaperStyle.dotted,
    this.pageSize = const Size(800, 1100),
    this.initialElements = const [],
    this.initialStrokes = const [],
    this.elementBuilder,
    this.onElementUpdated,
    this.onElementDeleted,
    this.onElementDuplicated,
    this.onStrokesChanged,
    this.showToolbar = true,
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
  final bool showToolbar;

  @override
  ConsumerState<PageViewCanvas> createState() => _PageViewCanvasState();
}

class _PageViewCanvasState extends ConsumerState<PageViewCanvas> {
  late List<CanvasWidgetData> _elements;
  late List<Rect> _cachedSiblingRects;
  String? _selectedElementId;
  List<SnapGuideLine> _activeSnapGuides = const [];
  final InkCanvasController _inkController = InkCanvasController();

  @override
  void initState() {
    super.initState();
    _elements = List.from(widget.initialElements);
    _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
    if (_elements.isNotEmpty) {
      _selectedElementId = _elements.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant PageViewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId ||
        oldWidget.initialElements.length != widget.initialElements.length ||
        oldWidget.initialElements != widget.initialElements) {
      _elements = List.from(widget.initialElements);
      _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
      _selectedElementId = _elements.isNotEmpty ? _elements.first.id : null;
      _activeSnapGuides = const [];
    }
  }

  @override
  void dispose() {
    _inkController.dispose();
    super.dispose();
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
      }
    });
  }

  void _handleDeleteElement(String elementId) {
    setState(() {
      _elements.removeWhere((e) => e.id == elementId);
      _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
      if (_selectedElementId == elementId) {
        _selectedElementId = _elements.isNotEmpty ? _elements.first.id : null;
      }
    });
    widget.onElementDeleted?.call(elementId);
  }

  void _handleAdaptToPage(String elementId) {
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
      }
    });
  }

  void _handleFitWidth(String elementId) {
    setState(() {
      final index = _elements.indexWhere((e) => e.id == elementId);
      if (index != -1) {
        const margin = 24.0;
        final current = _elements[index];
        final updated = current.copyWith(
          position: Offset(margin, current.position.dy),
          size: Size(widget.pageSize.width - (margin * 2), current.size.height),
        );
        _elements[index] = updated;
        _cachedSiblingRects = _elements.map((e) => e.boundingBox).toList();
        widget.onElementUpdated?.call(updated);
      }
    });
  }

  void _handleCenter(String elementId) {
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
      }
    });
  }

  void _handleColorChanged(
    String elementId,
    Color fillColor,
    Color borderColor,
  ) {
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
      }
    });
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
                  child: FittedBox(
                    child: Container(
                      width: widget.pageSize.width,
                      height: widget.pageSize.height,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                                ignoring: mode != CanvasMode.writing,
                                child: InkCanvas(
                                  pageId: widget.pageId,
                                  activeTool: inkToolState.tool,
                                  activeColor: inkToolState.color,
                                  activeStrokeWidth: inkToolState.strokeWidth,
                                  initialStrokes: widget.initialStrokes,
                                  controller: _inkController,
                                  onStrokesChanged: widget.onStrokesChanged,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showToolbar && mode == CanvasMode.writing)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _CanvasFloatingToolbar(
                        inkController: _inkController,
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

/// Floating pill toolbar providing controls for CanvasMode and Ink tools.
class _CanvasFloatingToolbar extends ConsumerWidget {
  const _CanvasFloatingToolbar({
    required this.inkController,
    this.onCloseWriting,
  });

  final InkCanvasController inkController;
  final VoidCallback? onCloseWriting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inkState = ref.watch(inkToolProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(32),
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolButton(
              context: context,
              icon: Icons.edit_outlined,
              tooltip: 'Lápiz / Pluma',
              isSelected: inkState.tool == InkToolType.pen,
              onTap: () => ref
                  .read(inkToolProvider.notifier)
                  .selectTool(InkToolType.pen),
            ),
            const SizedBox(width: 4),
            _buildToolButton(
              context: context,
              icon: Icons.brush_outlined,
              tooltip: 'Resaltador',
              isSelected: inkState.tool == InkToolType.highlighter,
              onTap: () => ref
                  .read(inkToolProvider.notifier)
                  .selectTool(InkToolType.highlighter),
            ),
            const SizedBox(width: 4),
            _buildToolButton(
              context: context,
              icon: Icons.auto_fix_normal_outlined,
              tooltip: 'Borrador',
              isSelected: inkState.tool == InkToolType.eraser,
              onTap: () => ref
                  .read(inkToolProvider.notifier)
                  .selectTool(InkToolType.eraser),
            ),

            if (inkState.tool != InkToolType.eraser) ...[
              const SizedBox(width: 8),
              Container(height: 24, width: 1, color: colorScheme.outline),
              const SizedBox(width: 8),
              ..._getStrokeWidthsForTool(inkState.tool).map((width) {
                final isWidthSelected =
                    (inkState.strokeWidth - width).abs() < 0.5;
                return Tooltip(
                  message: 'Grosor ${width.toInt()}px',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => ref
                        .read(inkToolProvider.notifier)
                        .setStrokeWidth(width),
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isWidthSelected
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isWidthSelected
                            ? Border.all(color: colorScheme.primary, width: 1.5)
                            : null,
                      ),
                      child: Container(
                        width: (width * 1.4).clamp(3.0, 10.0),
                        height: (width * 1.4).clamp(3.0, 10.0),
                        decoration: BoxDecoration(
                          color: isWidthSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Container(height: 24, width: 1, color: colorScheme.outline),
              const SizedBox(width: 8),
              ...InkToolState.defaultPalette.map((color) {
                final isColorSelected = inkState.color == color;
                return GestureDetector(
                  onTap: () =>
                      ref.read(inkToolProvider.notifier).setColor(color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isColorSelected
                          ? Border.all(color: colorScheme.primary, width: 2.5)
                          : Border.all(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.15,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(width: 8),
            Container(height: 24, width: 1, color: colorScheme.outline),
            const SizedBox(width: 4),

            ListenableBuilder(
              listenable: inkController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 19),
                      tooltip: 'Deshacer',
                      visualDensity: VisualDensity.compact,
                      color: inkController.canUndo
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                      onPressed: inkController.canUndo
                          ? inkController.undo
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, size: 19),
                      tooltip: 'Rehacer',
                      visualDensity: VisualDensity.compact,
                      color: inkController.canRedo
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                      onPressed: inkController.canRedo
                          ? inkController.redo
                          : null,
                    ),
                  ],
                );
              },
            ),

            if (onCloseWriting != null) ...[
              const SizedBox(width: 4),
              Container(height: 24, width: 1, color: colorScheme.outline),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text(
                  'Listo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: onCloseWriting,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<double> _getStrokeWidthsForTool(InkToolType tool) {
    switch (tool) {
      case InkToolType.pen:
        return const [2.0, 4.0, 7.0];
      case InkToolType.highlighter:
        return const [12.0, 24.0];
      case InkToolType.eraser:
        return const [16.0];
    }
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: isSelected
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer)
          : null,
      onPressed: onTap,
    );
  }
}
