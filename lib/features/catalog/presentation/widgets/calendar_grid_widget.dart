import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

@immutable
class HabitRowItem {
  const HabitRowItem({
    required this.id,
    required this.title,
    required this.checks,
  });

  factory HabitRowItem.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'] as List<dynamic>? ?? const [];
    final checks = List<bool>.generate(7, (index) {
      if (index < rawChecks.length && rawChecks[index] is bool) {
        return rawChecks[index] as bool;
      }
      return false;
    });

    return HabitRowItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title']?.toString() ?? '',
      checks: checks,
    );
  }

  final String id;
  final String title;
  final List<bool> checks;

  HabitRowItem copyWith({String? id, String? title, List<bool>? checks}) {
    return HabitRowItem(
      id: id ?? this.id,
      title: title ?? this.title,
      checks: checks ?? List<bool>.from(this.checks),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'checks': checks};
  }
}

@immutable
class CalendarGridConfig {
  const CalendarGridConfig({required this.title, required this.habits});

  factory CalendarGridConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return CalendarGridConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final title = decoded['title']?.toString() ?? 'Hábitos Semanales';
        final rawList = decoded['habits'] as List<dynamic>? ?? const [];
        final habits = rawList
            .whereType<Map<String, dynamic>>()
            .map(HabitRowItem.fromJson)
            .toList();

        return CalendarGridConfig(
          title: title,
          habits: habits.isNotEmpty
              ? habits
              : CalendarGridConfig.defaultConfig().habits,
        );
      }
    } on Object catch (_) {}
    return CalendarGridConfig.defaultConfig();
  }

  factory CalendarGridConfig.defaultConfig() {
    return const CalendarGridConfig(
      title: 'Hábitos Semanales',
      habits: [
        HabitRowItem(
          id: '1',
          title: 'Beber 2L de agua',
          checks: [true, true, false, true, false, false, false],
        ),
        HabitRowItem(
          id: '2',
          title: 'Leer 20 minutos',
          checks: [false, true, true, true, true, false, false],
        ),
        HabitRowItem(
          id: '3',
          title: 'Ejercicio diario',
          checks: [true, false, true, false, true, false, false],
        ),
      ],
    );
  }

  final String title;
  final List<HabitRowItem> habits;

  CalendarGridConfig copyWith({String? title, List<HabitRowItem>? habits}) {
    return CalendarGridConfig(
      title: title ?? this.title,
      habits: habits ?? List<HabitRowItem>.from(this.habits),
    );
  }

  String toJsonString() {
    return jsonEncode({
      'title': title,
      'habits': habits.map((h) => h.toJson()).toList(),
    });
  }
}

class CalendarGridDefinition extends AgendaWidgetDefinition {
  const CalendarGridDefinition();

  @override
  String get id => 'calendar_grid';

  @override
  String get name => 'Cuadrícula con Días';

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
  static const List<String> _daysOfWeek = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  late CalendarGridConfig _config;

  @override
  void initState() {
    super.initState();
    _config = CalendarGridConfig.fromJsonString(widget.configJson);
  }

  @override
  void didUpdateWidget(CalendarGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configJson != widget.configJson) {
      _config = CalendarGridConfig.fromJsonString(widget.configJson);
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
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _addNewHabit() {
    if (!widget.isInteractive) return;

    final newHabit = HabitRowItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nuevo hábito',
      checks: List<bool>.filled(7, false),
    );

    final updatedHabits = [..._config.habits, newHabit];
    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _removeHabit(int index) {
    if (!widget.isInteractive) return;

    final updatedHabits = List<HabitRowItem>.from(_config.habits)
      ..removeAt(index);
    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _editHabitTitle(int index, String newTitle) {
    if (!widget.isInteractive) return;

    final updatedHabits = List<HabitRowItem>.from(_config.habits);
    updatedHabits[index] = updatedHabits[index].copyWith(title: newTitle);
    final newConfig = _config.copyWith(habits: updatedHabits);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
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
                  _config.title,
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
              Row(
                mainAxisSize: MainAxisSize.min,
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
                      _daysOfWeek[index],
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
              ),
              if (widget.isInteractive) const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _config.habits.length,
              itemBuilder: (context, habitIndex) {
                final habit = _config.habits[habitIndex];
                final allCompleted = habit.checks.every((checked) => checked);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: widget.isInteractive
                            ? TextFormField(
                                initialValue: habit.title,
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
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (val) =>
                                    _editHabitTitle(habitIndex, val),
                              )
                            : Text(
                                habit.title,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(7, (dayIndex) {
                          final isChecked = habit.checks[dayIndex];
                          return GestureDetector(
                            onTap: widget.isInteractive
                                ? () => _toggleCheck(habitIndex, dayIndex)
                                : null,
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
                                  color: isChecked
                                      ? colorScheme.primary
                                      : colorScheme.outline,
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
                      ),
                      if (widget.isInteractive)
                        InkWell(
                          onTap: () => _removeHabit(habitIndex),
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
              },
            ),
          ),
          if (widget.isInteractive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addNewHabit,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Añadir hábito',
                    style: TextStyle(fontSize: 12),
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
      ),
    );
  }
}
