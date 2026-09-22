import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_grid.dart';
import 'package:honeyday/features/catalog/presentation/widgets/calendar/calendar_header.dart';
import 'package:honeyday/features/catalog/presentation/widgets/catalog_widget_mixin.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Registers the calendar habit grid widget with the catalog system.
class CalendarGridDefinition extends AgendaWidgetDefinition {
  const CalendarGridDefinition();

  @override
  String get id => 'calendar_grid';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogHabitsName;

  @override
  IconData get icon => Icons.calendar_view_week_rounded;

  @override
  Size get defaultSize => const Size(320, 240);

  @override
  String get initialConfigJson =>
      CalendarGridConfig.defaultConfig().toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    return CalendarGridWidget(
      elementId: elementId,
      configJson: configJson,
      isInteractive: isInteractive,
      onConfigChanged: onConfigChanged,
    );
  }
}

/// Main orchestration widget for the calendar habit grid.
///
/// Composes [CalendarHeader] and [CalendarGrid] inside a styled container,
/// managing state via [CatalogConfigHelper].
class CalendarGridWidget extends StatefulWidget {
  const CalendarGridWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  final String elementId;
  final String configJson;
  final bool isInteractive;
  final ValueChanged<String> onConfigChanged;

  @override
  State<CalendarGridWidget> createState() => _CalendarGridWidgetState();
}

class _CalendarGridWidgetState extends State<CalendarGridWidget> {
  late CatalogConfigHelper<CalendarGridConfig> _configHelper;

  CalendarGridConfig get _config => _configHelper.config;

  @override
  void initState() {
    super.initState();
    _configHelper = CatalogConfigHelper<CalendarGridConfig>(
      parseConfig: CalendarGridConfig.fromJsonString,
      configToJson: (c) => c.toJsonString(),
      onConfigChanged: widget.onConfigChanged,
      initialJson: widget.configJson,
    );
  }

  @override
  void didUpdateWidget(CalendarGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configJson != widget.configJson) {
      _configHelper.updateFromJson(widget.configJson);
    }
  }

  void _toggleCheck(int habitIndex, int dayIndex) {
    if (!widget.isInteractive) return;

    final habit = _config.habits[habitIndex];
    final updatedChecks = List<bool>.from(habit.checks);
    updatedChecks[dayIndex] = !updatedChecks[dayIndex];

    final updatedHabits = List<HabitRowItem>.from(_config.habits);
    updatedHabits[habitIndex] = habit.copyWith(checks: updatedChecks);

    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  void _addNewHabit() {
    if (!widget.isInteractive) return;

    final l10n = AppLocalizations.of(context);
    final newHabit = HabitRowItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: l10n.catalogHabitsNew,
      checks: List<bool>.filled(7, false),
    );

    final updatedHabits = [..._config.habits, newHabit];
    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  void _removeHabit(int index) {
    if (!widget.isInteractive) return;

    final updatedHabits = List<HabitRowItem>.from(_config.habits)
      ..removeAt(index);
    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  void _editHabitTitle(int index, String newTitle) {
    if (!widget.isInteractive) return;

    final updatedHabits = List<HabitRowItem>.from(_config.habits);
    updatedHabits[index] = updatedHabits[index].copyWith(title: newTitle);
    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final days = buildDaysOfWeek(l10n);
    final isDefaultTitle =
        _config.title.isEmpty || _config.title == l10n.catalogHabitsTitle;
    final displayTitle =
        isDefaultTitle ? l10n.catalogHabitsTitle : _config.title;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              CalendarHeader(days: days),
              if (widget.isInteractive) const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CalendarGrid(
              habits: _config.habits,
              isInteractive: widget.isInteractive,
              onToggleCheck: _toggleCheck,
              onEditTitle: _editHabitTitle,
              onRemoveHabit: _removeHabit,
              onAddHabit: _addNewHabit,
            ),
          ),
        ],
      ),
    );
  }
}
