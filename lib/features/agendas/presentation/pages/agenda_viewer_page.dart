import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_page_dialog.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/resource_catalog_sidebar.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

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
    unawaited(
      Haptics.vibrate(HapticsType.light).onError((_, _) {}),
    );
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

  Widget _buildEditModeScaffold(
    BuildContext context,
    AsyncValue<List<AgendaPage>> pagesAsync,
  ) {
    final pages = pagesAsync.value ?? [];
    final totalPages = pages.length;
    final controller = ref.read(agendaViewerControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a tus agendas',
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Herramientas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
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
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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

          return Row(
            children: [
              ResourceCatalogSidebar(
                onSelectDefinition: (def) {
                  unawaited(
                    _addCatalogElement(pagesList[_currentPageIndex].id, def),
                  );
                },
              ),
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
              Container(
                width: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    left: BorderSide(color: colorScheme.outline),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: colorScheme.primary,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a tus agendas',
          onPressed: () => context.go('/'),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            isWriting ? 'Modo Escritura' : 'Modo Lectura',
            key: ValueKey(currentMode),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          if (totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPageIndex + 1}/$totalPages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.layers_rounded),
            tooltip: 'Gestionar páginas',
            onPressed: () => _showPageManagerSheet(context, pages),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.check_circle_rounded),
              tooltip: 'Finalizar',
              color: colorScheme.primary,
              onPressed: () => context.go('/'),
            ),
          ),
        ],
      ),
      body: pagesAsync.when(
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

              if (totalPages > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Material(
                    elevation: 2,
                    color: colorScheme.surface.withValues(alpha: 0.92),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _currentPageIndex > 0
                                  ? () => _goToPage(
                                      _currentPageIndex - 1,
                                      totalPages,
                                    )
                                  : null,
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 28,
                              ),
                              color: colorScheme.onSurface,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(totalPages, (i) {
                                final isActive = i == _currentPageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: isActive ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.primary
                                            .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                            IconButton(
                              onPressed: _currentPageIndex < totalPages - 1
                                  ? () => _goToPage(
                                      _currentPageIndex + 1,
                                      totalPages,
                                    )
                                  : null,
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 28,
                              ),
                              color: colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                bottom: totalPages > 1 ? 72 : 16,
                child: Center(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(28),
                    color: colorScheme.surface,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModePillButton(
                            icon: Icons.menu_book_rounded,
                            label: 'Lectura',
                            isActive: !isWriting,
                            onTap: () {
                              ref.read(canvasModeProvider.notifier).setReading();
                              _hapticLight();
                            },
                          ),
                          _ModePillButton(
                            icon: Icons.edit_rounded,
                            label: 'Escritura',
                            isActive: isWriting,
                            onTap: () {
                              ref.read(canvasModeProvider.notifier).setWriting();
                              _hapticLight();
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 350.ms).slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
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

class _ModePillButton extends StatelessWidget {
  const _ModePillButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

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
