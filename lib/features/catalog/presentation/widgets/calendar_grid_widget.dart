import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

/// Representation of a single habit row in the calendar grid.
///
/// What: Holds habit title and 7-day boolean completion states.
/// Why: Provides an immutable model for daily/weekly habit tracking spread across L-M-M-J-V-S-D.
@immutable
class HabitRowItem {
  /// Constructs a [HabitRowItem].
  const HabitRowItem({
    required this.id,
    required this.title,
    required this.checks,
  });

  /// Creates a [HabitRowItem] from a decoded JSON map.
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

  /// Unique identifier for this habit item.
  final String id;

  /// Human-readable name or description of the habit (e.g. 'Tomar 2L de agua').
  final String title;

  /// 7-day boolean checklist corresponding to [L, M, M, J, V, S, D].
  final List<bool> checks;

  /// Creates a copy with optionally updated fields.
  HabitRowItem copyWith({String? id, String? title, List<bool>? checks}) {
    return HabitRowItem(
      id: id ?? this.id,
      title: title ?? this.title,
      checks: checks ?? List<bool>.from(this.checks),
    );
  }

  /// Serializes this habit row to JSON.
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'checks': checks};
  }
}

/// Parsed configuration model for the [CalendarGridWidget].
///
/// What: Holds grid title and list of habit tracker rows.
/// Why: Centralizes serialization and guarantees fallback defaults on empty or corrupt JSON payloads.
@immutable
class CalendarGridConfig {
  /// Constructs a [CalendarGridConfig].
  const CalendarGridConfig({required this.title, required this.habits});

  /// Parses JSON payload, returning a valid config with defaults if JSON is missing or corrupt.
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
    } on Object catch (_) {
      // Fallback on JSON parse error
    }
    return CalendarGridConfig.defaultConfig();
  }

  /// Provides factory defaults for newly placed widgets.
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

  /// Header title for the grid.
  final String title;

  /// Ordered collection of habit rows.
  final List<HabitRowItem> habits;

  /// Creates a copy with optionally updated fields.
  CalendarGridConfig copyWith({String? title, List<HabitRowItem>? habits}) {
    return CalendarGridConfig(
      title: title ?? this.title,
      habits: habits ?? List<HabitRowItem>.from(this.habits),
    );
  }

  /// Serializes to JSON string.
  String toJsonString() {
    return jsonEncode({
      'title': title,
      'habits': habits.map((h) => h.toJson()).toList(),
    });
  }
}

/// Catalog definition for [CalendarGridWidget].
///
/// What: Implements [AgendaWidgetDefinition] for the 7-day habit and calendar spread.
/// Why: Allows dynamic registration in the catalog registry with defaults and build factory.
class CalendarGridDefinition extends AgendaWidgetDefinition {
  /// Const constructor for definition registration.
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

/// Presentation widget displaying an interactive 7-day calendar and habit tracker spread.
///
/// What: Renders day headers (L, M, M, J, V, S, D), habit rows with checkboxes, and live strike-throughs.
/// Why: Delivers an authentic bullet-journal habit tracker styled with Material 3 and warm honey amber tones.
class CalendarGridWidget extends StatefulWidget {
  /// Constructs a [CalendarGridWidget].
  const CalendarGridWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  /// Unique element UUID.
  final String elementId;

  /// JSON payload encoding habit items and checks.
  final String configJson;

  /// Interaction mode flag (true in writing mode, false in reading/edit mode).
  final bool isInteractive;

  /// Callback to persist updated JSON state.
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HoneydayTheme.paperBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title and day columns
          Row(
            children: [
              Expanded(
                child: Text(
                  _config.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HoneydayTheme.inkSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Day headers: L M M J V S D
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
                          ? HoneydayTheme.honeyContainer.withValues(alpha: 0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _daysOfWeek[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isWeekend
                            ? HoneydayTheme.honeyAmber
                            : HoneydayTheme.inkSlate.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }),
              ),
              if (widget.isInteractive) const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: HoneydayTheme.paperBorder),
          const SizedBox(height: 6),
          // Habit Rows
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
                      // Habit Title
                      Expanded(
                        child: widget.isInteractive
                            ? TextFormField(
                                initialValue: habit.title,
                                key: ValueKey('habit_${habit.id}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: allCompleted
                                      ? HoneydayTheme.inkSlate.withValues(
                                          alpha: 0.4,
                                        )
                                      : HoneydayTheme.inkSlate,
                                  decoration: allCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: HoneydayTheme.honeyAmber,
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
                                      ? HoneydayTheme.inkSlate.withValues(
                                          alpha: 0.4,
                                        )
                                      : HoneydayTheme.inkSlate,
                                  decoration: allCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const SizedBox(width: 8),
                      // 7 Day Checkboxes
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
                                    ? HoneydayTheme.honeyAmber
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isChecked
                                      ? HoneydayTheme.honeyAmber
                                      : HoneydayTheme.paperBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                      // Delete button in interactive mode
                      if (widget.isInteractive)
                        InkWell(
                          onTap: () => _removeHabit(habitIndex),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Interactive Action: Add Habit
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
                    foregroundColor: HoneydayTheme.honeyAmber,
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
