import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

/// Modal bottom sheet displaying the catalog of Canva-like agenda design elements.
class AddCatalogElementSheet extends StatefulWidget {
  const AddCatalogElementSheet({super.key});

  @override
  State<AddCatalogElementSheet> createState() => _AddCatalogElementSheetState();
}

class _AddCatalogElementSheetState extends State<AddCatalogElementSheet> {
  ElementCategory? _selectedCategory;

  static const _filterTabs = <(String, ElementCategory?)>[
    ('Todas', null),
    ('Formas', ElementCategory.shapes),
    ('Agenda', ElementCategory.planner),
    ('Stickers', ElementCategory.stickers),
  ];

  @override
  Widget build(BuildContext context) {
    final allDefs = CatalogRegistry.getAllDefinitions();
    final visibleDefs = _selectedCategory == null
        ? allDefs.where((d) => d.category != ElementCategory.legacy).toList()
        : allDefs.where((d) => d.category == _selectedCategory).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.interests_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Catálogo de Elementos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _selectedCategory == tab.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tab.$1),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = tab.$2);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: visibleDefs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final def = visibleDefs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(def.icon, color: colorScheme.primary),
                    ),
                    title: Text(
                      def.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    trailing: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => Navigator.of(context).pop(def),
                      child: const Text('Colocar'),
                    ),
                    onTap: () => Navigator.of(context).pop(def),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
