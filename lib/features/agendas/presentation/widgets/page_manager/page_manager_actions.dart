import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Action buttons for the page manager sheet: paper style selector,
/// delete page, and add page.
///
/// Placed below the page thumbnail grid. The delete button is hidden
/// when there is only one page (since at least one page must exist).
class PageManagerActions extends StatelessWidget {
  /// Creates a [PageManagerActions].
  const PageManagerActions({
    required this.currentPage,
    required this.canDeletePage,
    required this.onChangePaperStyle,
    required this.onDeletePage,
    required this.onAddPage,
    super.key,
  });

  /// The currently selected page, or `null` if no page exists.
  final AgendaPage? currentPage;

  /// Whether the delete button should be shown.
  ///
  /// At least one page must exist, so deletion is only offered when
  /// there is more than one page.
  final bool canDeletePage;

  /// Called when the user picks a new paper style key.
  final ValueChanged<String> onChangePaperStyle;

  /// Called when the user confirms deletion of the current page.
  final VoidCallback onDeletePage;

  /// Called when the user taps the add-page button.
  final VoidCallback onAddPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final paperStyles = PaperStyle.localizedLabels(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentPage != null)
          Row(
            children: [
              DropdownButton<String>(
                value: currentPage!.backgroundStyle,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: paperStyles.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChangePaperStyle(val);
                },
              ),
              const Spacer(),
              if (canDeletePage)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDeletePage,
                ),
            ],
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddPage,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.agendaPageAdd),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
