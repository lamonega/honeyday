/// A habit tracker grid template for weekly habit monitoring.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A habit tracker grid template with a header, day columns, and rows for
/// individual habits with circular tracking bubbles.
///
/// Displays 4 habit rows and 7 day columns, allowing users to visually
/// track daily habits throughout the week.
final class PlannerHabitTrackerDefinition extends AgendaWidgetDefinition {
  const PlannerHabitTrackerDefinition();

  @override
  String get id => 'planner_habit_tracker';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogTemplateHabits;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogTemplateHabitsDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.calendar_view_month_rounded;

  @override
  Size get defaultSize => const Size(320, 200);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#FFFFFF',
    borderColorHex: '#E2E8F0',
    borderWidth: 1,
  ).toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    final config = ElementConfig.fromJsonString(configJson);
    final l10n = AppLocalizations.of(context);
    final dayHeaders = [
      l10n.catalogHabitsDayMon,
      l10n.catalogHabitsDayTue,
      l10n.catalogHabitsDayWed,
      l10n.catalogHabitsDayThu,
      l10n.catalogHabitsDayFri,
      l10n.catalogHabitsDaySat,
      l10n.catalogHabitsDaySun,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.borderColor,
          width: config.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_outline_rounded,
                size: 14,
                color: Color(0xFFE11D48),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.catalogHabitsHeader,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              ...dayHeaders.map(
                (d) => SizedBox(
                  width: 22,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (row) {
                return Row(
                  children: [
                    // Line for habit title
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 7 day bubbles
                    ...List.generate(
                      7,
                      (_) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
