import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_page_dialog.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/resource_catalog_sidebar.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

/// The central planner viewer and editor page for an active agenda.
///
/// Implements the View in the MVVM pattern recommended by the Flutter team:
/// Decoupled from direct database access and Drift companion models, delegating all state
/// and mutations to [AgendaViewerController] and reactive providers.
class AgendaViewerPage extends ConsumerStatefulWidget {
  /// Constructs an [AgendaViewerPage].
  const AgendaViewerPage({
    required this.agendaId,
    this.initialMode = 'writing',
    super.key,
  });

  /// The unique identifier of the agenda being edited/viewed.
  final String agendaId;

  /// Initial mode string: 'reading', 'writing', or 'edit'.
  final String initialMode;

  @override
  ConsumerState<AgendaViewerPage> createState() => _AgendaViewerPageState();
}

class _AgendaViewerPageState extends ConsumerState<AgendaViewerPage> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  bool get _isEditMode => widget.initialMode.toLowerCase() == 'edit';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Set initial canvas mode from route parameter
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
    }
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

  /// Builds the dedicated Modo Edición layout matching the top-right drawings in the SVG.
  Widget _buildEditModeScaffold(
    BuildContext context,
    AsyncValue<List<AgendaPage>> pagesAsync,
  ) {
    final pages = pagesAsync.value ?? [];
    final totalPages = pages.length;
    final controller = ref.read(agendaViewerControllerProvider);

    return Scaffold(
      backgroundColor: HoneydayTheme.paperLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a tus agendas',
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Herramientas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: HoneydayTheme.inkSlate,
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalPages > 0) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Página anterior',
                  onPressed: _currentPageIndex > 0
                      ? () => _goToPage(_currentPageIndex - 1, totalPages)
                      : null,
                ),
                Text(
                  'Pág. ${_currentPageIndex + 1} / $totalPages',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HoneydayTheme.inkSlate,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Página siguiente',
                  onPressed: _currentPageIndex < totalPages - 1
                      ? () => _goToPage(_currentPageIndex + 1, totalPages)
                      : null,
                ),
              ],
              IconButton(
                icon: const Icon(Icons.layers_rounded),
                tooltip: 'Gestionar páginas',
                onPressed: () => _showPageManagerSheet(context, pages),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: HoneydayTheme.honeyAmber,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Listo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => context.go('/'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: pagesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HoneydayTheme.honeyAmber),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error al cargar páginas: $error',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        data: (pagesList) {
          if (pagesList.isEmpty) {
            return const Center(
              child: Text(
                'No hay páginas disponibles.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

          return Row(
            children: [
              // Panel izquierdo: Catálogo de recursos
              ResourceCatalogSidebar(
                onSelectDefinition: (def) {
                  unawaited(
                    _addCatalogElement(pagesList[_currentPageIndex].id, def),
                  );
                },
              ),

              // Área central: Página en modo edición
              Expanded(
                child: PageView.builder(
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
                    );
                  },
                ),
              ),

              // Borde derecho: '+' para agregar una página
              Container(
                width: 48,
                decoration: const BoxDecoration(
                  color: HoneydayTheme.paperLight,
                  border: Border(
                    left: BorderSide(color: HoneydayTheme.paperBorder),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: HoneydayTheme.honeyAmber,
                      ),
                      tooltip: 'Nueva página',
                      onPressed: () async {
                        final chosenStyle = await showNewPageDesignDialog(
                          context,
                        );
                        if (chosenStyle == null || !mounted) return;
                        final newPageNumber = pagesList.length + 1;
                        await controller.addPage(
                          agendaId: widget.agendaId,
                          pageNumber: newPageNumber,
                          backgroundStyle: chosenStyle,
                        );
                        if (mounted) {
                          _goToPage(pagesList.length, pagesList.length + 1);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the Modo Lectura / Modo Escritura layout matching the bottom drawing in the SVG.
  Widget _buildReadWriteScaffold(
    BuildContext context,
    AsyncValue<List<AgendaPage>> pagesAsync,
    CanvasMode currentMode,
  ) {
    final pages = pagesAsync.value ?? [];
    final totalPages = pages.length;

    return Scaffold(
      backgroundColor: HoneydayTheme.paperLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a tus agendas',
          onPressed: () => context.go('/'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentMode == CanvasMode.writing
                  ? 'Modo Escritura'
                  : 'Modo Lectura',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HoneydayTheme.inkSlate,
              ),
            ),
            if (totalPages > 0) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Página anterior',
                onPressed: _currentPageIndex > 0
                    ? () => _goToPage(_currentPageIndex - 1, totalPages)
                    : null,
              ),
              Text(
                'Pág. ${_currentPageIndex + 1} / $totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HoneydayTheme.inkSlate,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Página siguiente',
                onPressed: _currentPageIndex < totalPages - 1
                    ? () => _goToPage(_currentPageIndex + 1, totalPages)
                    : null,
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_rounded),
            tooltip: 'Gestionar páginas',
            onPressed: () => _showPageManagerSheet(context, pages),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pagesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: HoneydayTheme.honeyAmber),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error al cargar páginas: $error',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        data: (pagesList) {
          if (pagesList.isEmpty) {
            return const Center(
              child: Text(
                'No hay páginas disponibles.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

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
                },
                itemBuilder: (context, index) {
                  final page = pagesList[index];

                  // 3D Page Turn Flip & Curl effect matching Google Play Books
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      var position = index.toDouble();
                      if (_pageController.position.haveDimensions &&
                          _pageController.page != null) {
                        position = index - _pageController.page!;
                      }

                      if (currentMode != CanvasMode.reading) {
                        return child!;
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
                    ),
                  );
                },
              ),

              // Botón de alternancia de lápiz en la esquina superior derecha
              Positioned(
                top: 24,
                right: 28,
                child: Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: currentMode == CanvasMode.writing
                      ? HoneydayTheme.honeyAmber
                      : Colors.white,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (currentMode == CanvasMode.writing) {
                        ref.read(canvasModeProvider.notifier).setReading();
                      } else {
                        ref.read(canvasModeProvider.notifier).setWriting();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        currentMode == CanvasMode.writing
                            ? Icons.menu_book_rounded
                            : Icons.edit_outlined,
                        color: currentMode == CanvasMode.writing
                            ? Colors.white
                            : HoneydayTheme.honeyAmber,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCatalogElement(
    String currentPageId,
    AgendaWidgetDefinition selectedDef,
  ) async {
    final controller = ref.read(agendaViewerControllerProvider);
    await controller.addCatalogElement(
      pageId: currentPageId,
      definition: selectedDef,
    );
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
          if (mounted && _currentPageIndex >= pages.length - 1) {
            _goToPage(pages.length - 2, pages.length - 1);
          }
        },
        onChangePaperStyle: (style) async {
          final currentPage = pages[_currentPageIndex];
          await controller.updatePageBackground(currentPage.id, style);
        },
        onReorderPages: (pageIds) async {
          final currentPageId = _currentPageIndex < pages.length
              ? pages[_currentPageIndex].id
              : null;
          await controller.reorderPages(pageIds);
          if (currentPageId != null && mounted) {
            final newIndex = pageIds.indexOf(currentPageId);
            if (newIndex != -1 && newIndex != _currentPageIndex) {
              setState(() => _currentPageIndex = newIndex);
              _pageController.jumpToPage(newIndex);
            }
          }
        },
      ),
    );
  }
}

/// Helper sub-widget displaying elements and strokes for a specific page.
///
/// Follows MVVM by observing dedicated providers and dispatching actions
/// to [AgendaViewerController], eliminating raw SQL/Drift logic from UI.
class _PageContentLoader extends ConsumerWidget {
  const _PageContentLoader({
    required this.page,
    required this.currentMode,
    super.key,
  });

  final AgendaPage page;
  final CanvasMode currentMode;

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
