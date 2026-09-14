import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

/// Sidebar panel displaying the "Catálogo de Elementos" in Edit Mode.
class ResourceCatalogSidebar extends StatefulWidget {
  const ResourceCatalogSidebar({
    required this.onSelectDefinition,
    super.key,
    this.width = 260,
  });

  final ValueChanged<AgendaWidgetDefinition> onSelectDefinition;
  final double width;

  @override
  State<ResourceCatalogSidebar> createState() => _ResourceCatalogSidebarState();
}

class _ResourceCatalogSidebarState extends State<ResourceCatalogSidebar> {
  bool _isCollapsed = false;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 52 : widget.width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outline)),
      ),
      child: _isCollapsed
          ? _buildCollapsedRail(colorScheme)
          : _buildExpandedSidebar(visibleDefs, colorScheme),
    );
  }

  Widget _buildCollapsedRail(ColorScheme colorScheme) {
    return OverflowBox(
      minWidth: 52,
      maxWidth: 52,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Mostrar elementos',
              color: colorScheme.onSurface,
              onPressed: () => setState(() => _isCollapsed = false),
            ),
            const SizedBox(height: 8),
            Tooltip(
              message: 'Mostrar elementos',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _isCollapsed = false),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.interests_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSidebar(
    List<AgendaWidgetDefinition> visibleDefs,
    ColorScheme colorScheme,
  ) {
    return OverflowBox(
      minWidth: widget.width,
      maxWidth: widget.width,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.interests_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Elementos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Ocultar elementos',
                    color: colorScheme.onSurface,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _isCollapsed = true),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _selectedCategory == tab.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tab.$1),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor: colorScheme.surface,
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setState(() => _selectedCategory = tab.$2);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: colorScheme.outline),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                itemCount: visibleDefs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final def = visibleDefs[index];
                  return _CatalogItemCard(
                    definition: def,
                    onTap: () => widget.onSelectDefinition(def),
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

class _CatalogItemCard extends StatelessWidget {
  const _CatalogItemCard({
    required this.definition,
    required this.onTap,
  });

  final AgendaWidgetDefinition definition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  definition.icon,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  definition.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
