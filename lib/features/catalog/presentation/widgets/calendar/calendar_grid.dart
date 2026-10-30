import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_habit_row.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A scrollable list of habit rows representing the habit grid.
///
/// Each row displays a habit title alongside seven day-of-week checkboxes.
/// The list can optionally include an interactive "add habit" button at the
/// bottom when [isInteractive] is true.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    required this.habits,
    required this.isInteractive,
    required this.onToggleCheck,
    required this.onEditTitle,
    required this.onRemoveHabit,
    required this.onAddHabit,
    super.key,
  });

  /// The current list of habit items to display.
  final List<HabitRowItem> habits;

  /// Whether taps on checkboxes and the remove/add buttons are enabled.
  final bool isInteractive;

  /// Called when a checkbox is toggled. Arguments are (habitIndex, dayIndex).
  final void Function(int habitIndex, int dayIndex) onToggleCheck;

  /// Called when a habit's title is edited. Arguments are (habitIndex, newTitle).
  final void Function(int habitIndex, String newTitle) onEditTitle;

  /// Called when a habit should be removed at the given index.
  final ValueChanged<int> onRemoveHabit;

  /// Called when the user taps the "add habit" button.
  final VoidCallback onAddHabit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: colorScheme.outline),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: habits.length,
            itemBuilder: (context, habitIndex) {
              final habit = habits[habitIndex];
              final displayHabitTitle = _localizedHabitTitle(habit, l10n);

              return CalendarHabitRow(
                habit: habit,
                isInteractive: isInteractive,
                displayTitle: displayHabitTitle,
                onToggleCheck: (dayIndex) =>
                    onToggleCheck(habitIndex, dayIndex),
                onEditTitle: (newTitle) => onEditTitle(habitIndex, newTitle),
                onRemove: () => onRemoveHabit(habitIndex),
              );
            },
          ),
        ),
        if (isInteractive)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddHabit,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  l10n.catalogHabitsAdd,
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Resolves a habit title against known localized defaults.
  String _localizedHabitTitle(HabitRowItem habit, AppLocalizations l10n) {
    if (habit.title.isNotEmpty) return habit.title;
    return switch (habit.id) {
      '1' => l10n.catalogHabitsDefault1,
      '2' => l10n.catalogHabitsDefault2,
      '3' => l10n.catalogHabitsDefault3,
      _ => '',
    };
  }
}
