import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_priority_item.dart';

/// Displays the priorities section header and the list of priority items.
///
/// Renders each [JournalPriorityItem] via [JournalPriorityItemWidget] in a
/// vertical list. The section includes a labeled header above the items.
class JournalPriorityList extends StatelessWidget {
  const JournalPriorityList({
    required this.priorities,
    required this.isInteractive,
    required this.onToggle,
    required this.onTextChanged,
    required this.localizeText,
    required this.headerText,
    super.key,
  });

  /// The list of priority items to display.
  final List<JournalPriorityItem> priorities;

  /// Whether the user can interact with the items.
  final bool isInteractive;

  /// Called when a priority checkbox is toggled. Receives the item index.
  final ValueChanged<int> onToggle;

  /// Called when a priority text is edited. Receives the item index and new text.
  final void Function(int index, String text) onTextChanged;

  /// Returns the localized display text for a priority's identity and text.
  final String Function(JournalPriorityItem priority) localizeText;

  /// The header label displayed above the priority items.
  final String headerText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headerText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(priorities.length, (index) {
          final priority = priorities[index];
          return JournalPriorityItemWidget(
            priority: priority,
            isInteractive: isInteractive,
            onToggle: () => onToggle(index),
            onTextChanged: (val) => onTextChanged(index, val),
            localizedText: localizeText(priority),
          );
        }),
      ],
    );
  }
}
