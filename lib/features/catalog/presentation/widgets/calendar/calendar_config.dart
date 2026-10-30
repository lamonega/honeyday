import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Represents a single habit with a title and seven daily check states.
@immutable
class HabitRowItem {
  const HabitRowItem({
    required this.id,
    required this.title,
    required this.checks,
  });

  /// Creates a [HabitRowItem] from a JSON map.
  ///
  /// Falls back to defaults for missing or malformed fields.
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

/// Configuration model for the calendar habit grid.
///
/// Contains a title and a list of [HabitRowItem] entries.
/// Supports serialization to/from JSON strings.
@immutable
class CalendarGridConfig {
  const CalendarGridConfig({required this.title, required this.habits});

  /// Parses a raw JSON string into a [CalendarGridConfig].
  ///
  /// Returns [CalendarGridConfig.defaultConfig] if the string is empty or
  /// cannot be decoded.
  factory CalendarGridConfig.fromJsonString(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return CalendarGridConfig.defaultConfig();
      }
      final rawHabits = decoded['habits'];
      if (rawHabits != null && rawHabits is! List) {
        return CalendarGridConfig.defaultConfig();
      }
      return CalendarGridConfig(
        title: decoded['title']?.toString() ?? '',
        habits: rawHabits == null
            ? CalendarGridConfig.defaultConfig().habits
            : (rawHabits as List)
                  .whereType<Map<String, dynamic>>()
                  .map(HabitRowItem.fromJson)
                  .toList(),
      );
    } on Object {
      return CalendarGridConfig.defaultConfig();
    }
  }

  /// The default configuration with three sample habits.
  ///
  /// Titles are left empty; the UI resolves them via localized strings.
  factory CalendarGridConfig.defaultConfig() {
    return const CalendarGridConfig(
      title: '',
      habits: [
        HabitRowItem(
          id: '1',
          title: '',
          checks: [true, true, false, true, false, false, false],
        ),
        HabitRowItem(
          id: '2',
          title: '',
          checks: [false, true, true, true, true, false, false],
        ),
        HabitRowItem(
          id: '3',
          title: '',
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
