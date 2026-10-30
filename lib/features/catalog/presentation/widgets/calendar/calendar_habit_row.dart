import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_config.dart';

/// A single habit row displaying an editable title, seven daily checkboxes,
/// and an optional remove button.
///
/// When the row is not interactive the title is plain text
/// and taps on checkboxes / the remove button are disabled.
class CalendarHabitRow extends StatelessWidget {
  const CalendarHabitRow({
    required this.habit,
    required this.isInteractive,
    required this.displayTitle,
    required this.onToggleCheck,
    required this.onEditTitle,
    required this.onRemove,
    super.key,
  });

  final HabitRowItem habit;

  /// Whether the row supports editing (toggles, title input, remove button).
  final bool isInteractive;

  /// The resolved title to display (may differ from the habit title when it
  /// matches a default/empty value).
  final String displayTitle;

  /// Called when a day checkbox is tapped. The argument is the day index (0–6).
  final ValueChanged<int> onToggleCheck;

  /// Called when the user submits a new title via the text field.
  final ValueChanged<String> onEditTitle;

  /// Called when the remove button is tapped.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allCompleted = habit.checks.every((checked) => checked);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: isInteractive
                ? TextFormField(
                    initialValue: displayTitle,
                    key: ValueKey('habit_${habit.id}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: allCompleted
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: allCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                    onChanged: onEditTitle,
                  )
                : Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: allCompleted
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: allCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),
          _CheckboxRow(
            checks: habit.checks,
            isInteractive: isInteractive,
            onToggleCheck: onToggleCheck,
          ),
          if (isInteractive)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders seven animated checkbox squares in a horizontal row.
class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.checks,
    required this.isInteractive,
    required this.onToggleCheck,
  });

  final List<bool> checks;
  final bool isInteractive;
  final ValueChanged<int> onToggleCheck;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (dayIndex) {
        final isChecked = checks[dayIndex];
        return GestureDetector(
          onTap: isInteractive ? () => onToggleCheck(dayIndex) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isChecked
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isChecked ? colorScheme.primary : colorScheme.outline,
                width: 1.2,
              ),
            ),
            child: isChecked
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colorScheme.onPrimary,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
