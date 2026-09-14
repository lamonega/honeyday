import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

/// Sidebar panel displaying the "Catálogo de Elementos" in Edit Mode.
///
/// What: Presents Canva-like geometric shapes, static planner layout templates,
/// stickers, and accessories organized by categories.
/// Why: Fulfills Requirement 1: elements are static layout and design building blocks
/// that can be placed, resized, recolored, and adapted to the whole page.
class ResourceCatalogSidebar extends StatefulWidget {
  /// Constructs a [ResourceCatalogSidebar].
  const ResourceCatalogSidebar({
    required this.onSelectDefinition,
    super.key,
    this.width = 260,
  });

  /// Callback invoked when a user taps an element definition to add it to the page.
  final ValueChanged<AgendaWidgetDefinition> onSelectDefinition;

  /// Width of the sidebar container.
  final double width;

  @override
  State<ResourceCatalogSidebar> createState() => _ResourceCatalogSidebarState();
}

class _ResourceCatalogSidebarState extends State<ResourceCatalogSidebar> {
  bool _isCollapsed = false;
  ElementCategory? _selectedCategory; // null = Todas

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 52 : widget.width,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: HoneydayTheme.paperLight,
        border: Border(
          right: BorderSide(color: HoneydayTheme.paperBorder),
        ),
      ),
      child: _isCollapsed
          ? _buildCollapsedRail()
          : _buildExpandedSidebar(visibleDefs),
    );
  }

  Widget _buildCollapsedRail() {
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
            color: HoneydayTheme.inkSlate,
            onPressed: () {
              setState(() {
                _isCollapsed = false;
              });
            },
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: 'Mostrar elementos',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _isCollapsed = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HoneydayTheme.honeyContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.interests_rounded,
                  color: HoneydayTheme.honeyAmber,
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

  Widget _buildExpandedSidebar(List<AgendaWidgetDefinition> visibleDefs) {
    return OverflowBox(
      minWidth: widget.width,
      maxWidth: widget.width,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: widget.width,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HoneydayTheme.honeyContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.interests_rounded,
                    color: HoneydayTheme.honeyAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Elementos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: HoneydayTheme.inkSlate,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Ocultar elementos',
                  color: HoneydayTheme.inkSlate,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _isCollapsed = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // Category Filter Chips
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
                          ? HoneydayTheme.honeyDark
                          : HoneydayTheme.inkSecondary,
                    ),
                    selected: isSelected,
                    selectedColor: HoneydayTheme.honeyContainer,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? HoneydayTheme.honeyAmber
                          : HoneydayTheme.paperBorder,
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
          const Divider(height: 1, color: HoneydayTheme.paperBorder),

          // Elements List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              itemCount: visibleDefs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HoneydayTheme.paperBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HoneydayTheme.honeyContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  definition.icon,
                  color: HoneydayTheme.honeyAmber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  definition.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HoneydayTheme.inkPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: HoneydayTheme.honeyAmber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
