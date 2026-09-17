import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

/// Draggable bottom sheet displaying the catalog of design elements.
class AddCatalogElementSheet extends StatefulWidget {
  const AddCatalogElementSheet({super.key});

  @override
  State<AddCatalogElementSheet> createState() =>
      _AddCatalogElementSheetState();

  /// Shows the catalog sheet and returns the selected definition, or null.
  static Future<AgendaWidgetDefinition?> show(BuildContext context) {
    return showModalBottomSheet<AgendaWidgetDefinition>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCatalogElementSheet(),
    );
  }
}

class _AddCatalogElementSheetState extends State<AddCatalogElementSheet> {
  ElementCategory? _selectedCategory;

  static const _filterTabs = <(String, ElementCategory?)>[
    ('Todas', null),
    ('Formas', ElementCategory.shapes),
    ('Plantillas', ElementCategory.planner),
    ('Decoración', ElementCategory.stickers),
  ];

  @override
  Widget build(BuildContext context) {
    final allDefs = CatalogRegistry.getAllDefinitions();
    final visibleDefs = _selectedCategory == null
        ? allDefs.where((d) => d.category != ElementCategory.legacy).toList()
        : allDefs.where((d) => d.category == _selectedCategory).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: colorScheme.outline),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Elementos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterTabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final tab = _filterTabs[index];
                    final isSelected = _selectedCategory == tab.$2;
                    return ChoiceChip(
                      label: Text(tab.$1),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primaryContainer,
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = tab.$2);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: visibleDefs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final def = visibleDefs[index];
                    return Material(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(def),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                def.icon,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      def.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (def.description.isNotEmpty)
                                      Text(
                                        def.description,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
