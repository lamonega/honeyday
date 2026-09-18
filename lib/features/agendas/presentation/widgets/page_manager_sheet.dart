import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';

/// Bottom sheet for managing agenda pages: view thumbnails, navigate,
/// reorder via drag, change paper style, add and delete pages.
class PageManagerSheet extends StatefulWidget {
  const PageManagerSheet({
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onDeletePage,
    required this.onChangePaperStyle,
    required this.onReorderPages,
    required this.onAddPage,
    super.key,
  });

  final List<AgendaPage> pages;
  final int currentPageIndex;
  final ValueChanged<int> onSelectPage;
  final ValueChanged<String> onDeletePage;
  final ValueChanged<String> onChangePaperStyle;
  final ValueChanged<List<String>> onReorderPages;
  final VoidCallback onAddPage;

  @override
  State<PageManagerSheet> createState() => _PageManagerSheetState();
}

class _PageManagerSheetState extends State<PageManagerSheet> {
  late List<AgendaPage> _pages;
  late int _currentPageIndex;

  static const _paperStyles = PaperStyle.labels;

  static const _paperIcons = <String, IconData>{
    'dotted': Icons.grain_rounded,
    'lined': Icons.view_headline_rounded,
    'grid': Icons.grid_4x4_rounded,
    'blank': Icons.crop_portrait_rounded,
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
      if (_currentPageIndex == oldIndex) {
        _currentPageIndex = newIndex;
      } else if (oldIndex < _currentPageIndex &&
          newIndex >= _currentPageIndex) {
        _currentPageIndex -= 1;
      } else if (oldIndex > _currentPageIndex &&
          newIndex <= _currentPageIndex) {
        _currentPageIndex += 1;
      }
    });
    widget.onReorderPages(_pages.map((p) => p.id).toList());
  }

  Future<void> _confirmDelete() async {
    final currentPage = _currentPageIndex < _pages.length
        ? _pages[_currentPageIndex]
        : null;
    if (currentPage == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar página?'),
        content: Text(
          'Se eliminará la página ${_currentPageIndex + 1}. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDeletePage(currentPage.id);
      Navigator.of(context).pop();
    }
  }

  Widget _buildPageCard(AgendaPage page, int index, ColorScheme colorScheme) {
    final isCurrent = index == _currentPageIndex;
    final styleKey = page.backgroundStyle;
    final icon = _paperIcons[styleKey] ?? Icons.grain_rounded;

    return GestureDetector(
      onTap: () {
        widget.onSelectPage(index);
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? colorScheme.primary : colorScheme.outline,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isCurrent
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 6),
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _paperStyles[styleKey] ?? styleKey,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentPage =
        _currentPageIndex < _pages.length ? _pages[_currentPageIndex] : null;

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
          Text(
            'Páginas (${_pages.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              onReorderItem: _onReorder,
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
                return Container(
                  key: ValueKey(page.id),
                  margin: const EdgeInsets.only(right: 10),
                  child: _buildPageCard(page, index, colorScheme),
                );
              },
              itemCount: _pages.length,
            ),
          ),
          const SizedBox(height: 12),
          if (currentPage != null)
            Row(
              children: [
                DropdownButton<String>(
                  value: currentPage.backgroundStyle,
                  underline: const SizedBox.shrink(),
                  isDense: true,
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
                const Spacer(),
                if (_pages.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAddPage();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Añadir página'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
