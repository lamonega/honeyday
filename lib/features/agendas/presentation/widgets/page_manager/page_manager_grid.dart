import 'package:flutter/material.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager/page_thumbnail.dart';

/// A horizontal, reorderable grid of [PageThumbnail] cards.
///
/// Renders a [ReorderableListView] that lets users drag pages to reorder them.
/// Each thumbnail is tappable to select the corresponding page.
class PageManagerGrid extends StatelessWidget {
  /// Creates a [PageManagerGrid].
  const PageManagerGrid({
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onReorder,
    super.key,
  });

  /// The full list of agenda pages to display.
  final List<AgendaPage> pages;

  /// Zero-based index of the currently selected page.
  final int currentPageIndex;

  /// Called when a thumbnail is tapped with the page's index.
  final ValueChanged<int> onSelectPage;

  /// Called when a page is dragged to a new position.
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        onReorderItem: onReorder,
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
          final page = pages[index];
          return Container(
            key: ValueKey(page.id),
            margin: const EdgeInsets.only(right: 10),
            child: PageThumbnail(
              page: page,
              index: index,
              isCurrent: index == currentPageIndex,
              onTap: () => onSelectPage(index),
            ),
          );
        },
        itemCount: pages.length,
      ),
    );
  }
}
