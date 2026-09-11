import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/snapping.dart';
import 'package:honeyday/features/canvas/presentation/widgets/ink_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/transformable_box.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';

export 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';

/// CustomPainter rendering magnetic alignment guidelines during widget drag.
///
/// What: Draws dashed/solid lines at snapped page centers, margins, or sibling edges.
/// Why: Gives immediate visual confirmation of magnetic locks in [CanvasMode.edit].
class SnapGuideOverlayPainter extends CustomPainter {
  /// Constructs a [SnapGuideOverlayPainter].
  const SnapGuideOverlayPainter({
    required this.guides,
    this.guideColor = HoneydayTheme.honeyAmber,
  });

  /// Active alignment lines to paint.
  final List<SnapGuideLine> guides;

  /// Line color.
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
    return oldDelegate.guides != guides || oldDelegate.guideColor != guideColor;
  }
}

/// The multi-layer interactive canvas page for Honeyday planners.
///
/// What: Combines Layer 0 (PageSurface), Layer 1 (Modular Widgets in TransformableBoxes),
/// Layer 1.5 (Snapping Guide Overlay), and Layer 3 (Vector InkCanvas).
/// Why: Orchestrates mode-specific interactions (Reading, Writing, Edit) within a shared coordinate system.
class PageViewCanvas extends ConsumerStatefulWidget {
  /// Constructs a [PageViewCanvas].
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

  /// Parent page identifier.
  final String pageId;

  /// Background paper texture.
  final PaperStyle paperStyle;

  /// Base virtual dimensions of the page coordinate system.
  final Size pageSize;

  /// Modular catalog elements initially on the page.
  final List<CanvasWidgetData> initialElements;

  /// Freehand ink strokes initially on the page.
  final List<InkStroke> initialStrokes;

  /// Optional factory producing the UI widget for a given [CanvasWidgetData].
  final Widget Function(BuildContext context, CanvasWidgetData element)?
  elementBuilder;

  /// Emits updated transform attributes for an element.
  final void Function(CanvasWidgetData updatedElement)? onElementUpdated;

  /// Emits when an element is deleted via its handle in edit mode.
  final void Function(String elementId)? onElementDeleted;

  /// Emits when an element is duplicated via the quick action bar.
  final void Function(CanvasWidgetData sourceElement)? onElementDuplicated;

  /// Emits when vector strokes are created, erased, or undone/redone.
  final ValueChanged<List<InkStroke>>? onStrokesChanged;

  /// Whether to show the floating mode and ink toolbar overlay.
  final bool showToolbar;

  @override
  ConsumerState<PageViewCanvas> createState() => _PageViewCanvasState();
}

class _PageViewCanvasState extends ConsumerState<PageViewCanvas> {
  late List<CanvasWidgetData> _elements;
  String? _selectedElementId;
  List<SnapGuideLine> _activeSnapGuides = const [];
  final InkCanvasController _inkController = InkCanvasController();

  @override
  void initState() {
    super.initState();
    _elements = List.from(widget.initialElements);
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
        widget.onElementUpdated?.call(updated);
      }
    });
  }

  void _handleDeleteElement(String elementId) {
    setState(() {
      _elements.removeWhere((e) => e.id == elementId);
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
        widget.onElementUpdated?.call(updated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(canvasModeProvider);
    final inkToolState = ref.watch(inkToolProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF1F5F9,
      ), // Subtle canvas workbench backdrop
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Pre-compute sibling bounding rects once for all elements
            final allSiblingRects = _elements
                .map((e) => e.boundingBox)
                .toList();

            return Stack(
              children: [
                // Center canvas sheet with physical paper shadow
                Center(
                  child: FittedBox(
                    child: Container(
                      width: widget.pageSize.width,
                      height: widget.pageSize.height,
                      decoration: BoxDecoration(
                        color: HoneydayTheme.paperLight,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // --- LAYER 0: Paper Surface Texture ---
                            Positioned.fill(
                              child: PageSurface(paperStyle: widget.paperStyle),
                            ),

                            // --- LAYER 1: Modular Catalog Widgets ---
                            ..._elements.map((element) {
                              final isSelected =
                                  _selectedElementId == element.id;
                              // Sibling rects exclude the current element
                              final siblingRects = allSiblingRects
                                  .where((r) =>
                                      r !=
                                      element.boundingBox)
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
                                    ? () =>
                                        widget.onElementDuplicated!(element)
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
                                child: widget.elementBuilder?.call(
                                      context,
                                      element,
                                    ) ??
                                    _buildDefaultElementCard(element),
                              );
                            }),

                            // --- LAYER 1.5: Magnetic Snapping Guidelines ---
                            if (mode == CanvasMode.edit &&
                                _activeSnapGuides.isNotEmpty)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: SnapGuideOverlayPainter(
                                      guides: _activeSnapGuides,
                                    ),
                                  ),
                                ),
                              ),

                            // --- LAYER 3: Vector Ink Drawing Layer ---
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

                // Top Floating Canvas Toolbar (only in writing mode, showing inking tools)
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

  Widget _buildDefaultElementCard(CanvasWidgetData element) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HoneydayTheme.paperBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.widgets_outlined,
                  size: 16,
                  color: HoneydayTheme.honeyAmber,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    element.widgetType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: HoneydayTheme.inkSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            const Expanded(
              child: Center(
                child: Text(
                  'Modular Widget Container',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
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
///
/// What: Lets users switch modes (Reading, Writing, Edit), pick brush tools (Pen,
/// Highlighter, Eraser), select palette colors, and trigger Undo/Redo.
/// Why: Offers an integrated toolbar adhering to Material 3 and Honeyday design aesthetics.
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

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: HoneydayTheme.paperBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pen Tool
            _buildToolButton(
              icon: Icons.edit_outlined,
              tooltip: 'Lápiz / Pluma',
              isSelected: inkState.tool == InkToolType.pen,
              onTap: () => ref
                  .read(inkToolProvider.notifier)
                  .selectTool(InkToolType.pen),
            ),
            const SizedBox(width: 4),

            // Highlighter Tool
            _buildToolButton(
              icon: Icons.brush_outlined,
              tooltip: 'Resaltador',
              isSelected: inkState.tool == InkToolType.highlighter,
              onTap: () => ref
                  .read(inkToolProvider.notifier)
                  .selectTool(InkToolType.highlighter),
            ),
            const SizedBox(width: 4),

            // Eraser Tool
            _buildToolButton(
              icon: Icons.auto_fix_normal_outlined,
              tooltip: 'Borrador',
              isSelected: inkState.tool == InkToolType.eraser,
              onTap: () => ref
                  .read(inkToolProvider.notifier)
                  .selectTool(InkToolType.eraser),
            ),

            if (inkState.tool != InkToolType.eraser) ...[
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 1,
                color: HoneydayTheme.paperBorder,
              ),
              const SizedBox(width: 8),

              // Palette Colors
              ...InkToolState.defaultPalette.map((color) {
                final isColorSelected = inkState.color == color;
                return GestureDetector(
                  onTap: () =>
                      ref.read(inkToolProvider.notifier).setColor(color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isColorSelected
                          ? Border.all(
                              color: HoneydayTheme.honeyAmber,
                              width: 2.5,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(width: 8),
            Container(height: 24, width: 1, color: HoneydayTheme.paperBorder),
            const SizedBox(width: 4),

            // Undo Button
            IconButton(
              icon: const Icon(Icons.undo_rounded, size: 18),
              tooltip: 'Deshacer',
              visualDensity: VisualDensity.compact,
              onPressed: inkController.undo,
            ),

            // Redo Button
            IconButton(
              icon: const Icon(Icons.redo_rounded, size: 18),
              tooltip: 'Rehacer',
              visualDensity: VisualDensity.compact,
              onPressed: inkController.redo,
            ),

            if (onCloseWriting != null) ...[
              const SizedBox(width: 4),
              Container(height: 24, width: 1, color: HoneydayTheme.paperBorder),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: HoneydayTheme.honeyContainer,
                  foregroundColor: HoneydayTheme.honeyAmber,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 18,
        color: isSelected
            ? HoneydayTheme.honeyAmber
            : const Color(0xFF64748B),
      ),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: HoneydayTheme.honeyContainer)
          : null,
      onPressed: onTap,
    );
  }
}
