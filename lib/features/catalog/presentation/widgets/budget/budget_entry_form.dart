import 'package:flutter/material.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// An inline "Add entry" button that appears at the bottom of the budget list.
///
/// Pressing the button invokes [onAdd]. The button is styled to be compact
/// and visually subordinate to the main content.
class BudgetEntryForm extends StatelessWidget {
  const BudgetEntryForm({
    required this.onAdd,
    super.key,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(
            l10n.catalogBudgetAddEntry,
            style: const TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
