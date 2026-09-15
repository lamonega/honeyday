import 'package:flutter/material.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';

/// Bottom sheet allowing users to view page thumbnails, jump between pages,
/// reorder pages, delete pages, and change page texture.
class PageManagerSheet extends StatefulWidget {
  const PageManagerSheet({
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onDeletePage,
    required this.onChangePaperStyle,
    required this.onReorderPages,
    super.key,
  });

  final List<AgendaPage> pages;
  final int currentPageIndex;
  final ValueChanged<int> onSelectPage;
  final ValueChanged<String> onDeletePage;
  final ValueChanged<String> onChangePaperStyle;
  final ValueChanged<List<String>> onReorderPages;

  @override
  State<PageManagerSheet> createState() => _PageManagerSheetState();
}

class _PageManagerSheetState extends State<PageManagerSheet> {
  late List<AgendaPage> _pages;
  late int _currentPageIndex;

  static const _paperStyles = <String, String>{
    'dotted': 'Puntos',
    'lined': 'Rayas',
    'grid': 'Cuadrícula',
    'blank': 'Blanca',
  };

  @override
  void initState() {
    super.initState();
    _pages = List.of(widget.pages);
    _currentPageIndex = widget.currentPageIndex;
  }

  @override
  void didUpdateWidget(PageManagerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages) {
      _pages = List.of(widget.pages);
    }
    if (oldWidget.currentPageIndex != widget.currentPageIndex) {
      _currentPageIndex = widget.currentPageIndex;
    }
  }

  void _movePage(int fromIndex, int toIndex) {
    if (toIndex < 0 || toIndex >= _pages.length) return;
    setState(() {
      final item = _pages.removeAt(fromIndex);
      _pages.insert(toIndex, item);
      if (_currentPageIndex == fromIndex) {
        _currentPageIndex = toIndex;
      } else if (fromIndex < _currentPageIndex &&
          toIndex >= _currentPageIndex) {
        _currentPageIndex -= 1;
      } else if (fromIndex > _currentPageIndex &&
          toIndex <= _currentPageIndex) {
        _currentPageIndex += 1;
      }
    });
    widget.onReorderPages(_pages.map((p) => p.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _currentPageIndex < _pages.length
        ? _pages[_currentPageIndex]
        : null;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.layers_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Páginas (${_pages.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: _pages.length,
              onReorderItem: _movePage,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                final isCurrent = index == _currentPageIndex;

                return Container(
                  key: ValueKey(page.id),
                  width: 125,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: isCurrent ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        onTap: () {
                          widget.onSelectPage(index);
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                page.backgroundStyle == 'grid'
                                    ? Icons.grid_4x4_rounded
                                    : page.backgroundStyle == 'lined'
                                    ? Icons.view_headline_rounded
                                    : Icons.grain_rounded,
                                color: isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Página ${index + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isCurrent
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _paperStyles[page.backgroundStyle] ??
                                    page.backgroundStyle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              tooltip: 'Mover a la izquierda',
                              onPressed: index > 0
                                  ? () => _movePage(index, index - 1)
                                  : null,
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              tooltip: 'Mover a la derecha',
                              onPressed: index < _pages.length - 1
                                  ? () => _movePage(index, index + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (currentPage != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Fondo de la página actual:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: currentPage.backgroundStyle,
                  underline: const SizedBox.shrink(),
                  items: _paperStyles.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _pages[_currentPageIndex] = _pages[_currentPageIndex]
                            .copyWith(backgroundStyle: val);
                      });
                      widget.onChangePaperStyle(val);
                    }
                  },
                ),
                if (_pages.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Eliminar esta página',
                    onPressed: () {
                      widget.onDeletePage(currentPage.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
