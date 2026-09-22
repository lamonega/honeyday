/// A top priorities block with numbered priority levels.
///
/// Used to register the element in the catalog sidebar and provide
/// default configuration.
library;

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/domain/element_config.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// A top priorities block with a star icon header and 3 numbered priority
/// rows, each with a ruled writing line.
///
/// Used to highlight the most important tasks or goals for a given period.
final class PlannerPrioritiesDefinition extends AgendaWidgetDefinition {
  const PlannerPrioritiesDefinition();

  @override
  String get id => 'planner_priorities';

  @override
  String name(BuildContext context) => AppLocalizations.of(context).catalogTemplatePriorities;

  @override
  String description(BuildContext context) => AppLocalizations.of(context).catalogTemplatePrioritiesDesc;

  @override
  ElementCategory get category => ElementCategory.planner;

  @override
  IconData get icon => Icons.flag_outlined;

  @override
  Size get defaultSize => const Size(260, 180);

  @override
  String get initialConfigJson => const ElementConfig().toJsonString();

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
            color: Colors.black.withValues(alpha: 0.03),
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
              Icon(Icons.star_rounded, size: 16, color: config.borderColor),
              const SizedBox(width: 6),
              Text(
                l10n.catalogPrioritiesHeader,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: config.borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                return Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: config.borderColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: config.borderColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: config.borderColor.withValues(alpha: 0.25),
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
