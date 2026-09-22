import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_config.dart';

/// A single priority row containing a checkbox, text field, and strike-through
/// styling when completed.
///
/// Used inside [JournalPriorityList] to render each individual priority entry.
class JournalPriorityItemWidget extends StatelessWidget {
  const JournalPriorityItemWidget({
    required this.priority,
    required this.isInteractive,
    required this.onToggle,
    required this.onTextChanged,
    required this.localizedText,
    super.key,
  });

  /// The priority data model to display.
  final JournalPriorityItem priority;

  /// Whether the user can interact with this item.
  final bool isInteractive;

  /// Called when the checkbox is tapped to toggle completion.
  final VoidCallback onToggle;

  /// Called when the text field is submitted with new text.
  final ValueChanged<String> onTextChanged;

  /// The display text, already localized by the parent.
  final String localizedText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: isInteractive ? onToggle : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: priority.isDone
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: priority.isDone
                      ? colorScheme.primary
                      : colorScheme.outline,
                  width: 1.2,
                ),
              ),
              child: priority.isDone
                  ? Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: isInteractive
                ? TextFormField(
                    initialValue: localizedText,
                    key: ValueKey('prio_${priority.id}_$localizedText'),
                    style: TextStyle(
                      fontSize: 11,
                      color: priority.isDone
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: priority.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                    onFieldSubmitted: onTextChanged,
                  )
                : Text(
                    localizedText,
                    style: TextStyle(
                      fontSize: 11,
                      color: priority.isDone
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: priority.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
