import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/add_catalog_element_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_page_dialog.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/viewer_app_bar.dart';
import 'package:honeyday/features/agendas/presentation/widgets/viewer_page_navigator.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_canvas_controller.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';
import 'package:uuid/uuid.dart';

class AgendaViewerPage extends ConsumerStatefulWidget {
  const AgendaViewerPage({
    required this.agendaId,
    this.initialMode = 'writing',
    super.key,
  });

  final String agendaId;
  final String initialMode;

  @override
  ConsumerState<AgendaViewerPage> createState() => _AgendaViewerPageState();
}

class _AgendaViewerPageState extends ConsumerState<AgendaViewerPage> {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  bool _hasUnsavedChanges = false;
  bool _strokesVisible = true;
  final Map<String, PageCanvasController> _pageControllers = {};

  bool get _isEditMode => widget.initialMode.toLowerCase() == 'edit';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditMode) {
        ref.read(canvasModeProvider.notifier).setEdit();
      } else {
        final mode = switch (widget.initialMode.toLowerCase()) {
          'writing' => CanvasMode.writing,
          _ => CanvasMode.reading,
        };
        ref.read(canvasModeProvider.notifier).setMode(mode);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index, int totalPages) {
    if (index >= 0 && index < totalPages) {
      setState(() => _currentPageIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      _hapticLight();
    }
  }

  void _hapticLight() {
    unawaited(Haptics.vibrate(HapticsType.light).onError((_, _) {}));
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _undo() {
    final controller = _currentPageController;
    if (controller == null) return;
    if (controller.canUndoElements) {
      controller.undoElements();
    } else if (controller.canUndoStrokes) {
      controller.undoStrokes();
    }
    setState(() {});
  }

  void _redo() {
    final controller = _currentPageController;
    if (controller == null) return;
    if (controller.canRedoElements) {
      controller.redoElements();
    } else if (controller.canRedoStrokes) {
      controller.redoStrokes();
    }
    setState(() {});
  }

  void _toggleStrokes() {
    setState(() => _strokesVisible = !_strokesVisible);
  }

  PageCanvasController? get _currentPageController {
    final pageId = _currentPagePageId;
    if (pageId == null) return null;
    return _pageControllers[pageId];
  }

  String? get _currentPagePageId {
    final pagesAsync = ref.read(agendaPagesProvider(widget.agendaId));
    final pages = pagesAsync.value;
    if (pages == null || _currentPageIndex >= pages.length) return null;
    return pages[_currentPageIndex].id;
  }

  bool get _canUndo => _currentPageController?.canUndo ?? false;
  bool get _canRedo => _currentPageController?.canRedo ?? false;

  Future<bool> _showExitDialog() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Tenés cambios sin guardar. ¿Qué querés hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    return result != 'cancel';
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(agendaPagesProvider(widget.agendaId));
    final currentMode = ref.watch(canvasModeProvider);

    if (_isEditMode) {
      return _buildEditModeScaffold(context, pagesAsync);
    }

    return _buildReadWriteScaffold(context, pagesAsync, currentMode);
  }

  Widget _buildPagesAsyncBody({
    required AsyncValue<List<AgendaPage>> pagesAsync,
    required Widget Function(List<AgendaPage> pagesList) builder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return pagesAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error al cargar páginas: $error',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      data: (pagesList) {
        if (pagesList.isEmpty) {
          return Center(
            child: Text(
              'No hay páginas disponibles.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }
        return builder(pagesList);
      },
    );
  }

  Widget _buildEditModeScaffold(
    BuildContext context,
    AsyncValue<List<AgendaPage>> pagesAsync,
  ) {
    final pages = pagesAsync.value ?? [];
    final totalPages = pages.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: ViewerAppBar(
        onBack: () async {
          final shouldPop = await _showExitDialog();
          if (shouldPop && context.mounted) context.go('/');
        },
        actions: const [],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_canUndo)
            FloatingActionButton.small(
              heroTag: 'undo',
              onPressed: _undo,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              child: const Icon(Icons.undo_rounded, size: 20),
            ),
          if (_canUndo) const SizedBox(width: 8),
          if (_canRedo)
            FloatingActionButton.small(
              heroTag: 'redo',
              onPressed: _redo,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              child: const Icon(Icons.redo_rounded, size: 20),
            ),
          if (_canRedo) const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'toggle_strokes',
            onPressed: _toggleStrokes,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            child: Icon(
              _strokesVisible ? Icons.draw_outlined : Icons.draw,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'page_manager',
            onPressed: () => _showPageManagerSheet(context, pages),
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            child: const Icon(Icons.layers_outlined, size: 20),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: 'add_element',
            onPressed: () async {
              final def = await AddCatalogElementSheet.show(context);
              if (def == null || !mounted) return;
              await _addCatalogElement(
                pages[_currentPageIndex].id,
                def,
              );
            },
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _buildPagesAsyncBody(
        pagesAsync: pagesAsync,
        builder: (pagesList) => Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagesList.length,
              onPageChanged: (index) {
                setState(() => _currentPageIndex = index);
              },
              itemBuilder: (context, index) {
                final page = pagesList[index];
                return _PageContentLoader(
                  key: ValueKey(page.id),
                  page: page,
                  currentMode: CanvasMode.edit,
                  strokesVisible: _strokesVisible,
                  onDirty: _markDirty,
                  onControllerCreated: (c) => _pageControllers[page.id] = c,
                );
              },
            ),
            if (totalPages > 1)
              ViewerPageNavigator(
                childCount: totalPages,
                currentPage: _currentPageIndex,
                onGoToPage: (index) => _goToPage(index, totalPages),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadWriteScaffold(
    BuildContext context,
    AsyncValue<List<AgendaPage>> pagesAsync,
    CanvasMode currentMode,
  ) {
    final pages = pagesAsync.value ?? [];
    final totalPages = pages.length;
    final isWriting = currentMode == CanvasMode.writing;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: ViewerAppBar(
        onBack: () async {
          final shouldPop = await _showExitDialog();
          if (shouldPop && context.mounted) context.go('/');
        },
        actions: const [],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isWriting) {
            ref.read(canvasModeProvider.notifier).setReading();
          } else {
            ref.read(canvasModeProvider.notifier).setWriting();
          }
          _hapticLight();
        },
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Icon(
          isWriting ? Icons.menu_book_outlined : Icons.edit_outlined,
        ),
      ),
      body: _buildPagesAsyncBody(
        pagesAsync: pagesAsync,
        builder: (pagesList) {
          final scrollPhysics = currentMode == CanvasMode.reading
              ? const PageScrollPhysics()
              : const NeverScrollableScrollPhysics();

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: scrollPhysics,
                itemCount: pagesList.length,
                onPageChanged: (index) {
                  setState(() => _currentPageIndex = index);
                  _hapticLight();
                },
                itemBuilder: (context, index) {
                  final page = pagesList[index];
                  final isAdjacent =
                      (index - _currentPageIndex).abs() <= 1;

                  if (!isAdjacent || currentMode != CanvasMode.reading) {
                    return _PageContentLoader(
                      key: ValueKey(page.id),
                      page: page,
                      currentMode: currentMode,
                      strokesVisible: _strokesVisible,
                      onDirty: _isEditMode ? _markDirty : null,
                      onControllerCreated: _isEditMode
                          ? (c) => _pageControllers[page.id] = c
                          : null,
                    );
                  }

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      var position = index.toDouble();
                      if (_pageController.position.haveDimensions &&
                          _pageController.page != null) {
                        position = index - _pageController.page!;
                      }

                      final clamped = position.clamp(-1.0, 1.0);
                      final isTurning = clamped.abs() > 0.001;
                      final isLeft = clamped < 0;
                      final rotationY = clamped * (math.pi / 3.5);
                      final shadowOpacity = (clamped.abs() * 0.4).clamp(
                        0.0,
                        0.45,
                      );

                      return Transform(
                        alignment: isLeft
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0008)
                          ..rotateY(rotationY),
                        child: Stack(
                          children: [
                            child!,
                            if (isTurning)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: isLeft
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        end: isLeft
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        colors: [
                                          Colors.black.withValues(
                                            alpha: shadowOpacity,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    child: _PageContentLoader(
                      key: ValueKey(page.id),
                      page: page,
                      currentMode: currentMode,
                      strokesVisible: _strokesVisible,
                      onDirty: _isEditMode ? _markDirty : null,
                      onControllerCreated: _isEditMode
                          ? (c) => _pageControllers[page.id] = c
                          : null,
                    ),
                  );
                },
              ),
              if (totalPages > 1)
                ViewerPageNavigator(
                  childCount: totalPages,
                  currentPage: _currentPageIndex,
                  onGoToPage: (index) => _goToPage(index, totalPages),
                ),
            ],
          );
        },
      ),
    );
  }

  static const _uuid = Uuid();

  Future<void> _addCatalogElement(
    String currentPageId,
    AgendaWidgetDefinition selectedDef,
  ) async {
    final pageController = _pageControllers[currentPageId];
    if (pageController == null) return;

    final element = CanvasWidgetData(
      id: _uuid.v4(),
      pageId: currentPageId,
      widgetType: selectedDef.id,
      position: const Offset(120, 100),
      size: selectedDef.defaultSize,
      configJson: selectedDef.initialConfigJson,
    );

    pageController.addElement(element);
  }

  Future<void> _showPageManagerSheet(
    BuildContext context,
    List<AgendaPage> pages,
  ) async {
    final controller = ref.read(agendaViewerControllerProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PageManagerSheet(
        pages: pages,
        currentPageIndex: _currentPageIndex,
        onSelectPage: (index) => _goToPage(index, pages.length),
        onDeletePage: (pageId) async {
          if (pages.length <= 1) return;
          await controller.deletePage(pageId);
          _markDirty();
          if (mounted && _currentPageIndex >= pages.length - 1) {
            _goToPage(pages.length - 2, pages.length - 1);
          }
        },
        onChangePaperStyle: (style) async {
          final currentPage = pages[_currentPageIndex];
          await controller.updatePageBackground(currentPage.id, style);
          _markDirty();
        },
        onReorderPages: (pageIds) async {
          final currentPageId = _currentPageIndex < pages.length
              ? pages[_currentPageIndex].id
              : null;
          await controller.reorderPages(pageIds);
          _markDirty();
          if (currentPageId != null && mounted) {
            final newIndex = pageIds.indexOf(currentPageId);
            if (newIndex != -1 && newIndex != _currentPageIndex) {
              setState(() => _currentPageIndex = newIndex);
              _pageController.jumpToPage(newIndex);
            }
          }
        },
        onAddPage: () async {
          final style = await showNewPageDesignDialog(context);
          if (style != null && mounted) {
            await controller.addPage(
              agendaId: widget.agendaId,
              pageNumber: pages.length + 1,
              backgroundStyle: style,
            );
            _markDirty();
            if (mounted) {
              final newIndex = pages.length;
              ref.invalidate(agendaPagesProvider(widget.agendaId));
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _goToPage(newIndex, newIndex + 1);
                }
              });
            }
          }
        },
      ),
    );
  }
}

class _PageContentLoader extends ConsumerWidget {
  const _PageContentLoader({
    required this.page,
    required this.currentMode,
    this.onDirty,
    this.onControllerCreated,
    this.strokesVisible = true,
    super.key,
  });

  final AgendaPage page;
  final CanvasMode currentMode;
  final VoidCallback? onDirty;
  final void Function(PageCanvasController controller)? onControllerCreated;
  final bool strokesVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elementsAsync = ref.watch(pageElementsProvider(page.id));
    final strokesAsync = ref.watch(pageStrokesProvider(page.id));
    final controller = ref.read(agendaViewerControllerProvider);

    final elements = elementsAsync.value ?? [];
    final strokes = strokesAsync.value ?? [];

    return PageViewCanvas(
      key: ValueKey('${page.id}_canvas'),
      pageId: page.id,
      paperStyle: PaperStyle.fromString(page.backgroundStyle),
      initialElements: elements,
      initialStrokes: strokes,
      strokesVisible: strokesVisible,
      onDirty: onDirty,
      onControllerCreated: onControllerCreated,
      elementBuilder: (context, elementData) {
        final isInteractive = currentMode == CanvasMode.writing;

        return CatalogRegistry.buildWidget(
          context,
          widgetType: elementData.widgetType,
          elementId: elementData.id,
          configJson: elementData.configJson,
          isInteractive: isInteractive,
          onConfigChanged: (newJson) {
            unawaited(controller.updateElementConfig(elementData, newJson));
          },
        );
      },
      onElementUpdated: (updatedData) {
        unawaited(controller.updateElementTransform(updatedData));
      },
      onElementDeleted: controller.deleteElement,
      onElementDuplicated: (source) async {
        await controller.duplicateElement(source);
      },
      onStrokesChanged: (newStrokes) async {
        await controller.syncStrokes(page.id, newStrokes);
      },
    );
  }
}
