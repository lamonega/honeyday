import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/database/app_database.dart';

/// Bottom sheet allowing users to view page thumbnails, jump between pages,
/// reorder pages, delete pages, and change page texture.
///
/// What: Orchestrates multi-page management for an agenda.
/// Why: Fulfills the master plan requirement for page navigation, reordering,
/// texture toggles, and deletion.
class PageManagerSheet extends StatefulWidget {
  /// Constructs a [PageManagerSheet].
  const PageManagerSheet({
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onDeletePage,
    required this.onChangePaperStyle,
    required this.onReorderPages,
    super.key,
  });

  /// All non-deleted pages in this agenda.
  final List<AgendaPage> pages;

  /// 0-indexed position of the currently visible page.
  final int currentPageIndex;

  /// Triggered when the user taps a page to jump to it.
  final ValueChanged<int> onSelectPage;

  /// Triggered when deleting a page.
  final ValueChanged<String> onDeletePage;

  /// Triggered when the user changes paper style for the active page.
  final ValueChanged<String> onChangePaperStyle;

  /// Triggered when pages are reordered.
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: HoneydayTheme.paperBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: HoneydayTheme.honeyAmber),
              const SizedBox(width: 8),
              Text(
                'Páginas (${_pages.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HoneydayTheme.inkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal list of page thumbnails with reordering support
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
                    color: HoneydayTheme.paperLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? HoneydayTheme.honeyAmber
                          : HoneydayTheme.paperBorder,
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
                                    ? HoneydayTheme.honeyAmber
                                    : const Color(0xFF94A3B8),
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
                                      ? HoneydayTheme.honeyAmber
                                      : HoneydayTheme.inkSlate,
                                ),
                              ),
                              Text(
                                _paperStyles[page.backgroundStyle] ??
                                    page.backgroundStyle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 36,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: HoneydayTheme.paperBorder,
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
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 16,
                                  color: Color(0xFF94A3B8),
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
                const Text(
                  'Fondo de la página actual:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
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
