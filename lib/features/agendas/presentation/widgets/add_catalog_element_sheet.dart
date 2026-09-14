import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

/// Modal bottom sheet displaying the catalog of Canva-like agenda design elements.
///
/// What: Presents registered shapes, planner layout templates, and stickers.
/// Why: Allows users to select and place static visual building blocks onto the agenda page.
class AddCatalogElementSheet extends StatefulWidget {
  /// Constructs an [AddCatalogElementSheet].
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

    return Material(
      color: Colors.white,
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
                  color: HoneydayTheme.paperBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.interests_rounded,
                  color: HoneydayTheme.honeyAmber,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Catálogo de Elementos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HoneydayTheme.inkSlate,
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

            // Category Chips
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
                            ? const Color(0xFF78350F)
                            : const Color(0xFF475569),
                      ),
                      selected: isSelected,
                      selectedColor: HoneydayTheme.honeyContainer,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isSelected
                            ? HoneydayTheme.honeyAmber
                            : HoneydayTheme.paperBorder,
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

            // List of items
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
                        color: HoneydayTheme.honeyContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(def.icon, color: HoneydayTheme.honeyAmber),
                    ),
                    title: Text(
                      def.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: HoneydayTheme.inkSlate,
                      ),
                    ),
                    trailing: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: HoneydayTheme.honeyContainer,
                        foregroundColor: const Color(0xFF78350F),
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
