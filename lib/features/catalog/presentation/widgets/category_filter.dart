import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Reusable category filter chip row for catalog element pickers.
///
/// Displays localized filter tabs: All, Shapes, Templates, Decoration.
class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    required this.selectedCategory,
    required this.onCategoryChanged,
    super.key,
  });

  /// Currently selected category, or null for "All".
  final ElementCategory? selectedCategory;

  /// Callback when user selects a different category.
  final ValueChanged<ElementCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final tabs = [
      (l10n.catalogFilterAll, null as ElementCategory?),
      (l10n.catalogFilterShapes, ElementCategory.shapes),
      (l10n.catalogFilterTemplates, ElementCategory.planner),
      (l10n.catalogFilterDecoration, ElementCategory.stickers),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = selectedCategory == tab.$2;
          return ChoiceChip(
            label: Text(tab.$1),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            selected: isSelected,
            selectedColor: colorScheme.primaryContainer,
            side: BorderSide(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
            onSelected: (_) => onCategoryChanged(tab.$2),
          );
        },
      ),
    );
  }
}
