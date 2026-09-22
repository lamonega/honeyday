import 'package:flutter/material.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager/page_manager_actions.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager/page_manager_grid.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

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

  void _onChangePaperStyle(String style) {
    setState(() {
      _pages[_currentPageIndex] = _pages[_currentPageIndex]
          .copyWith(backgroundStyle: style);
    });
    widget.onChangePaperStyle(style);
  }

  void _onAddPage() {
    Navigator.of(context).pop();
    widget.onAddPage();
  }

  Future<void> _confirmDelete() async {
    // At least one page must exist.
    if (_pages.length <= 1) return;

    final currentPage = _currentPageIndex < _pages.length
        ? _pages[_currentPageIndex]
        : null;
    if (currentPage == null) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.agendaPageDeleteTitle),
        content: Text(
          l10n.agendaPageDeleteContent(_currentPageIndex + 1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDeletePage(currentPage.id);
      Navigator.of(context).pop();
    }
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
            AppLocalizations.of(context).agendaPageCount(_pages.length),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          PageManagerGrid(
            pages: _pages,
            currentPageIndex: _currentPageIndex,
            onSelectPage: (index) {
              widget.onSelectPage(index);
              Navigator.of(context).pop();
            },
            onReorder: _onReorder,
          ),
          const SizedBox(height: 12),
          PageManagerActions(
            currentPage: currentPage,
            canDeletePage: _pages.length > 1,
            onChangePaperStyle: _onChangePaperStyle,
            onDeletePage: _confirmDelete,
            onAddPage: _onAddPage,
          ),
        ],
      ),
    );
  }
}
