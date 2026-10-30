import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/core/utils/haptics.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/controllers/agenda_viewer_controller.dart';
import 'package:honeyday/features/agendas/presentation/controllers/save_session.dart';
import 'package:honeyday/features/agendas/presentation/widgets/viewer_app_bar.dart';
import 'package:honeyday/features/agendas/presentation/widgets/viewer_canvas_mode_toggle.dart';
import 'package:honeyday/features/agendas/presentation/widgets/viewer_catalog_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/viewer_page_navigator.dart';
import 'package:honeyday/features/agendas/presentation/widgets/save_session_scope.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode_notifier.dart';
import 'package:honeyday/features/canvas/domain/writing_input.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_canvas_controller.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';
import 'package:honeyday/features/export/presentation/export_actions.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Page for viewing and interacting with an agenda's pages.
///
/// Supports three [CanvasMode]s: reading (swipe to flip), writing (ink),
/// and edit (move/resize widgets). Mode is determined by [initialMode].
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
  bool _exitInProgress = false;
  bool _exportPreparing = false;
  final SaveSession _saveSession = SaveSession();
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
    for (final controller in _pageControllers.values) {
      controller.removeListener(_onPageHistoryChanged);
    }
    _pageControllers.clear();
    _pageController.dispose();
    _saveSession.dispose();
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
      unawaited(hapticLight());
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

  void _onPageHistoryChanged() {
    if (mounted) setState(() {});
  }

  void _registerPageController(String pageId, PageCanvasController controller) {
    if (!mounted) return;
    final previous = _pageControllers[pageId];
    if (identical(previous, controller)) return;
    previous?.removeListener(_onPageHistoryChanged);
    _pageControllers[pageId] = controller;
    controller.addListener(_onPageHistoryChanged);
    setState(() {});
  }

  bool get _canUndo => _currentPageController?.canUndo ?? false;
  bool get _canRedo => _currentPageController?.canRedo ?? false;

  /// App bar action that starts the PDF export flow for this agenda.
  ///
  /// Disabled while a run is in flight: the progress dialog is
  /// non-dismissible, so a second export would mount a second capture host
  /// underneath it and double the memory ceiling mid-run.
  Future<void> _startExport(int pagesCount) async {
    if (_exportPreparing || exportInProgress.value) return;
    setState(() => _exportPreparing = true);
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      _saveSession.flushEditors();
      await _saveSession.drain();
      if (!mounted) return;
      await runAgendaExport(
        context,
        ref,
        agendaId: widget.agendaId,
        pagesCount: pagesCount,
      );
    } on Object catch (error) {
      if (mounted) _reportPersistError(context, error);
    } finally {
      if (mounted) setState(() => _exportPreparing = false);
    }
  }

  Widget _buildSaveStatus() {
    return ListenableBuilder(
      listenable: _saveSession,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        return switch (_saveSession.status) {
          SaveStatus.saved => Tooltip(message: l10n.agendaSaved, child: const Icon(Icons.cloud_done_outlined)),
          SaveStatus.saving => Tooltip(message: l10n.agendaSaving, child: const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          SaveStatus.failed => IconButton(
              tooltip: l10n.agendaRetrySave,
              icon: const Icon(Icons.error_outline),
              onPressed: () async {
                try {
                  _saveSession.flushEditors();
                  await _saveSession.retry();
                } on Object catch (error) {
                  if (context.mounted) _reportPersistError(context, error);
                }
              },
            ),
        };
      },
    );
  }

  Widget _buildExportButton(int pagesCount) {
    return ValueListenableBuilder<bool>(
      valueListenable: exportInProgress,
      builder: (context, busy, _) => IconButton(
        icon: const Icon(Icons.picture_as_pdf_outlined),
        tooltip: AppLocalizations.of(context).exportPdfTooltip,
        onPressed: busy
            ? null
            : () => unawaited(_startExport(pagesCount)),
      ),
    );
  }

  Future<void> _requestExit() async {
    if (_exitInProgress || _exportPreparing || exportInProgress.value) return;
    setState(() => _exitInProgress = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      _saveSession.flushEditors();
      await _saveSession.drain();
      if (mounted) context.go('/');
    } on Object catch (error) {
      if (mounted) _reportPersistError(context, error);
    } finally {
      if (mounted) setState(() => _exitInProgress = false);
    }
  }

  void _toggleCanvasMode() {
    final currentMode = ref.read(canvasModeProvider);
    if (currentMode == CanvasMode.writing) {
      ref.read(canvasModeProvider.notifier).setReading();
    } else {
      ref.read(canvasModeProvider.notifier).setWriting();
    }
    unawaited(hapticLight());
  }

  Future<void> _showPageManager(List<AgendaPage> pages) async {
    final controller = ref.read(agendaViewerControllerProvider);

    // The sheet outlives the build that opened it: pages can be deleted,
    // added or reordered while it stays on screen, so callbacks must read
    // the provider instead of trusting the captured snapshot.
    List<AgendaPage> currentPages() =>
        ref.read(agendaPagesProvider(widget.agendaId)).value ?? pages;

    await ViewerCatalogSheet.showPageManager(
      context: context,
      pages: pages,
      currentPageIndex: _currentPageIndex,
      onSelectPage: (index) => _goToPage(index, currentPages().length),
      onDeletePage: (pageId) async {
        final before = currentPages();
        if (before.length <= 1) return;
        try {
          await _saveSession.enqueue(() => controller.deletePage(pageId));
        } on Object catch (error) {
          if (mounted) {
            _reportPersistError(context, error);
          }
          return;
        }
        if (mounted && _currentPageIndex >= before.length - 1) {
          _goToPage(before.length - 2, before.length - 1);
        }
      },
      onChangePaperStyle: (style) async {
        final current = currentPages();
        if (_currentPageIndex >= current.length) return;
        try {
          await _saveSession.enqueue(() => controller.updatePageBackground(
            current[_currentPageIndex].id,
            style,
          ));
        } on Object catch (error) {
          if (mounted) {
            _reportPersistError(context, error);
          }
          return;
        }
      },
      onReorderPages: (pageIds) async {
        final current = currentPages();
        final currentPageId = _currentPageIndex < current.length
            ? current[_currentPageIndex].id
            : null;
        try {
          await _saveSession.enqueue(() => controller.reorderPages(pageIds));
        } on Object catch (error) {
          if (mounted) {
            _reportPersistError(context, error);
          }
          return;
        }
        if (currentPageId != null && mounted) {
          final newIndex = pageIds.indexOf(currentPageId);
          if (newIndex != -1 && newIndex != _currentPageIndex) {
            setState(() => _currentPageIndex = newIndex);
            _pageController.jumpToPage(newIndex);
          }
        }
      },
      onAddPage: () async {
        final style = await ViewerCatalogSheet.showNewPageDesign(context);
        if (style == null || !mounted) return;
        final newIndex = currentPages().length;
        final pageId = _uuid.v4();
        try {
          await _saveSession.enqueue(() async {
            await controller.addPage(
              id: pageId,
              agendaId: widget.agendaId,
              pageNumber: newIndex + 1,
              backgroundStyle: style,
            );
          });
        } on Object catch (error) {
          if (mounted) {
            _reportPersistError(context, error);
          }
          return;
        }
        if (mounted) {
          ref.invalidate(agendaPagesProvider(widget.agendaId));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _goToPage(newIndex, newIndex + 1);
            }
          });
        }
      },
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

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(agendaPagesProvider(widget.agendaId));
    final currentMode = ref.watch(canvasModeProvider);

    final scaffold = _isEditMode
        ? _buildEditModeScaffold(context, pagesAsync)
        : _buildReadWriteScaffold(context, pagesAsync, currentMode);
    return SaveSessionScope(session: _saveSession, child: scaffold);
  }

  Widget _buildPagesAsyncBody({
    required AsyncValue<List<AgendaPage>> pagesAsync,
    required Widget Function(List<AgendaPage> pagesList) builder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return pagesAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      error: (error, _) => Center(
        child: Text(
          AppLocalizations.of(context).agendaPagesError(error.toString()),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      data: (pagesList) {
        if (pagesList.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context).agendaNoPages,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestExit());
      },
      child: AbsorbPointer(
        absorbing: _exitInProgress || _exportPreparing,
        child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: ViewerAppBar(
          onBack: () => unawaited(_requestExit()),
          actions: [_buildSaveStatus(), _buildExportButton(totalPages)],
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
              onPressed: () => _showPageManager(pages),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              child: const Icon(Icons.layers_outlined, size: 20),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              heroTag: 'add_element',
              onPressed: () async {
                final def = await ViewerCatalogSheet.showElementPicker(context);
                if (def == null || !mounted) return;
                // `_currentPagePageId` is null while pages are still loading
                // or when the index drifted past the end of the list.
                final pageId = _currentPagePageId;
                if (pageId == null) return;
                await _addCatalogElement(pageId, def);
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
                    canvasControllers: _pageControllers,
                    strokesVisible: _strokesVisible,
                    onControllerCreated: (c) => _registerPageController(page.id, c),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestExit());
      },
      child: AbsorbPointer(
        absorbing: _exitInProgress || _exportPreparing,
        child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: ViewerAppBar(
          onBack: () => unawaited(_requestExit()),
          actions: [_buildSaveStatus(), _buildExportButton(totalPages)],
        ),
        floatingActionButton: ViewerCanvasModeToggle(
          currentMode: currentMode,
          onToggle: _toggleCanvasMode,
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
                    unawaited(hapticLight());
                  },
                  itemBuilder: (context, index) {
                    final page = pagesList[index];
                    final isAdjacent = (index - _currentPageIndex).abs() <= 1;

                    if (!isAdjacent || currentMode != CanvasMode.reading) {
                      return _PageContentLoader(
                        key: ValueKey(page.id),
                        page: page,
                        currentMode: currentMode,
                        canvasControllers: _pageControllers,
                        strokesVisible: _strokesVisible,
                        // Register in every mode: writing-mode config
                        // edits need the controller to sync the manager.
                        onControllerCreated: (c) =>
                            _registerPageController(page.id, c),
                      );
                    }

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        // Swapping the canvas mode swaps the PageView physics,
                        // so Scrollable recreates its ScrollPosition and
                        // `haveDimensions` resets to false; this builder then
                        // runs during layout, before applyContentDimensions.
                        // The fallback must be page-relative so the active page
                        // stays at rest — using the absolute item index leaves
                        // the current page stuck mid-flip until the controller
                        // notifies again on the next page turn.
                        var position = (index - _currentPageIndex).toDouble();
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
                        canvasControllers: _pageControllers,
                        strokesVisible: _strokesVisible,
                        onControllerCreated: (c) =>
                            _registerPageController(page.id, c),
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
        ),
      ),
    );
  }
}

class _PageContentLoader extends ConsumerWidget {
  const _PageContentLoader({
    required this.page,
    required this.currentMode,
    required this.canvasControllers,
    this.onControllerCreated,
    this.strokesVisible = true,
    super.key,
  });

  final AgendaPage page;
  final CanvasMode currentMode;

  /// Page canvas controllers keyed by page id, used to sync config edits
  /// into each canvas's element manager.
  final Map<String, PageCanvasController> canvasControllers;
  final void Function(PageCanvasController controller)? onControllerCreated;
  final bool strokesVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elementsAsync = ref.watch(pageElementsProvider(page.id));
    final strokesAsync = ref.watch(pageStrokesProvider(page.id));
    final controller = ref.read(agendaViewerControllerProvider);
    final saveSession = SaveSessionScope.maybeOf(context);
    final colorScheme = Theme.of(context).colorScheme;

    // PageViewCanvas and InkCanvas only consume their initial lists on mount;
    // mounting while the streams are still loading would render the page
    // blank and, worse, let a first stroke wipe previously saved ink.
    if (elementsAsync.isLoading || strokesAsync.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    final elementsAsyncError = elementsAsync.hasError
        ? elementsAsync
        : strokesAsync;
    if (elementsAsyncError.hasError) {
      final error = elementsAsyncError.error;
      return Center(
        child: Text(
          AppLocalizations.of(context).agendaPagesError(error.toString()),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final elements = elementsAsync.value ?? [];
    final strokes = strokesAsync.value ?? [];
    final writingInput = ref.watch(writingInputProvider);

    void persist(Future<void> Function() write) {
      final session = saveSession;
      if (session == null) {
        unawaited(_guardPersist(context, write()));
        return;
      }
      unawaited(session.enqueue(write).catchError((Object error) {
        if (context.mounted) _reportPersistError(context, error);
      }));
    }

    return PageViewCanvas(
      key: ValueKey('${page.id}_canvas'),
      pageId: page.id,
      paperStyle: PaperStyle.fromString(page.backgroundStyle),
      initialElements: elements,
      initialStrokes: strokes,
      strokesVisible: strokesVisible,
      onControllerCreated: onControllerCreated,
      elementBuilder: (context, elementData) {
        final isInteractive = currentMode == CanvasMode.writing &&
            writingInput == WritingInput.content;

        return CatalogRegistry.buildWidget(
          context,
          widgetType: elementData.widgetType,
          elementId: elementData.id,
          configJson: elementData.configJson,
          isInteractive: isInteractive,
          onConfigChanged: (newJson) {
            // Keep the canvas manager's copy fresh so full-row transform
            // writes (drags, color changes) don't revert this edit.
            canvasControllers[page.id]?.syncElementConfig(
              elementData.id,
              newJson,
            );
            persist(() => controller.updateElementConfig(elementData, newJson));
          },
        );
      },
      onElementUpdated: (updatedData) =>
          persist(() => controller.updateElementTransform(updatedData)),
      onElementDeleted: (id) =>
          persist(() => controller.deleteElement(id)),
      onElementRestored: (element) =>
          persist(() => controller.restoreElement(element)),
      onStrokesChanged: (newStrokes) =>
          persist(() => controller.syncStrokes(page.id, newStrokes)),
    );
  }
}

/// Awaits a persistence write so a rejection surfaces to the user instead
/// of escaping as an unhandled async error.
Future<void> _guardPersist(BuildContext context, Future<void> write) async {
  try {
    await write;
  } on Object catch (error) {
    if (context.mounted) {
      _reportPersistError(context, error);
    }
  }
}

/// Logs [error] and tells the user that their change could not be saved.
void _reportPersistError(BuildContext context, Object error) {
  debugPrint('Honeyday: persistence failed: $error');
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).agendaSaveError)),
    );
}
