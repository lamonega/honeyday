/// A 7-day weekly columns layout for planning Monday through Sunday.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A 7-day weekly layout spread with columns for each day (Lunes a Domingo).
///
/// Each column displays the day name as a header badge and provides ruled
/// writing lines below for daily planning. Weekend columns are visually
/// distinguished with a different header color.
final class PlannerWeeklyColumnsDefinition extends AgendaWidgetDefinition {
  const PlannerWeeklyColumnsDefinition();

  @override
  String get id => 'planner_weekly_columns';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogTemplateWeeklyView;

  @override
  String description(BuildContext context) =>
      AppLocalizations.of(context).catalogTemplateWeeklyViewDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.view_week_outlined;

  @override
  Size get defaultSize => const Size(720, 280);

  @override
  String get initialConfigJson => const ElementConfig(
    colorHex: '#FFFFFF',
    borderColorHex: '#CBD5E1',
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
    final days = [
      l10n.catalogDayMon,
      l10n.catalogDayTue,
      l10n.catalogDayWed,
      l10n.catalogDayThu,
      l10n.catalogDayFri,
      l10n.catalogDaySat,
      l10n.catalogDaySun,
    ];

    return Container(
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
      child: Row(
        children: List.generate(7, (index) {
          final isWeekend = index >= 5;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: index < 6
                    ? Border(
                        right: BorderSide(
                          color: config.borderColor.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
              child: Column(
                children: [
                  // Day header badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isWeekend
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(index == 0 ? 15 : 0),
                        topRight: Radius.circular(index == 6 ? 15 : 0),
                      ),
                    ),
                    child: Text(
                      days[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isWeekend
                            ? const Color(0xFFB45309)
                            : const Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Ruled writing lines
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (_) => Container(
                            height: 1,
                            color: config.borderColor.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
