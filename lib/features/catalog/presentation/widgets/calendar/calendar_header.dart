import 'package:flutter/material.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Displays the seven-day-of-week header labels (Mon–Sun) in a fixed-width row.
///
/// Each label sits in a 24×24 box; weekend labels (Sat, Sun) are rendered with
/// the primary color and a tinted background.
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({required this.days, super.key});

  /// The seven day abbreviations to display (in order Mon → Sun).
  final List<String> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(7, (index) {
        final isWeekend = index >= 5;
        return Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isWeekend
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            days[index],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isWeekend
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }),
    );
  }
}

/// Builds the localized list of day-of-week abbreviations (Mon → Sun).
List<String> buildDaysOfWeek(AppLocalizations l10n) {
  return [
    l10n.catalogHabitsDayMon,
    l10n.catalogHabitsDayTue,
    l10n.catalogHabitsDayWed,
    l10n.catalogHabitsDayThu,
    l10n.catalogHabitsDayFri,
    l10n.catalogHabitsDaySat,
    l10n.catalogHabitsDaySun,
  ];
}
