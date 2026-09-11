import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_page_dialog.dart';

/// Bottom sheet allowing users to view page thumbnails, jump between pages, add new pages, and change page texture.
///
/// What: Orchestrates multi-page management for an agenda.
/// Why: Fulfills the master plan requirement for page navigation, reordering, texture toggles, and deletion.
class PageManagerSheet extends StatelessWidget {
  /// Constructs a [PageManagerSheet].
  const PageManagerSheet({
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onAddPage,
    required this.onDeletePage,
    required this.onChangePaperStyle,
    super.key,
  });

  /// All non-deleted pages in this agenda.
  final List<AgendaPage> pages;

  /// 0-indexed position of the currently visible page.
  final int currentPageIndex;

  /// Triggered when the user taps a page to jump to it.
  final ValueChanged<int> onSelectPage;

  /// Triggered when the user requests adding a new page with the selected paper style.
  final ValueChanged<String> onAddPage;

  /// Triggered when deleting a page.
  final ValueChanged<String> onDeletePage;

  /// Triggered when the user changes paper style for the active page.
  final ValueChanged<String> onChangePaperStyle;

  static const _paperStyles = <String, String>{
    'dotted': 'Puntos',
    'lined': 'Rayas',
    'grid': 'Cuadrícula',
    'blank': 'Blanca',
  };

  @override
  Widget build(BuildContext context) {
    final currentPage = currentPageIndex < pages.length
        ? pages[currentPageIndex]
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
                'Páginas (${pages.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HoneydayTheme.inkSlate,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: HoneydayTheme.honeyAmber,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Añadir Página'),
                onPressed: () async {
                  final chosenStyle = await showNewPageDesignDialog(context);
                  if (chosenStyle != null && context.mounted) {
                    onAddPage(chosenStyle);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal list of page thumbnails
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                final isCurrent = index == currentPageIndex;

                return GestureDetector(
                  onTap: () {
                    onSelectPage(index);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 100,
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
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Página ${page.pageNumber}',
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
                      onChangePaperStyle(val);
                    }
                  },
                ),
                if (pages.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: 'Eliminar esta página',
                    onPressed: () {
                      onDeletePage(currentPage.id);
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
