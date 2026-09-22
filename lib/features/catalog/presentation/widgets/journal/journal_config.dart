import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A single priority item within a journal block.
///
/// Represents one checkbox entry with associated text and completion state.
@immutable
class JournalPriorityItem {
  const JournalPriorityItem({
    required this.id,
    required this.text,
    required this.isDone,
  });

  /// Creates a [JournalPriorityItem] from a JSON map.
  ///
  /// Falls back to a generated key and empty text for missing fields.
  factory JournalPriorityItem.fromJson(Map<String, dynamic> json) {
    return JournalPriorityItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      text: json['text']?.toString() ?? '',
      isDone: json['isDone'] == true,
    );
  }

  final String id;
  final String text;
  final bool isDone;

  JournalPriorityItem copyWith({String? id, String? text, bool? isDone}) {
    return JournalPriorityItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isDone': isDone};
  }
}

/// Configuration model for a journal block widget.
///
/// Holds the date, mood emoji, list of priorities, and free-form notes.
/// Supports JSON serialization for persistence and a sensible default config.
@immutable
class JournalBlockConfig {
  const JournalBlockConfig({
    required this.date,
    required this.mood,
    required this.priorities,
    required this.notes,
  });

  /// Parses a raw JSON string into a [JournalBlockConfig].
  ///
  /// Returns [JournalBlockConfig.defaultConfig] if the string is empty,
  /// malformed, or cannot be decoded.
  factory JournalBlockConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return JournalBlockConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final date = decoded['date']?.toString() ?? '';
        final mood = decoded['mood']?.toString() ?? '😊';
        final notes = decoded['notes']?.toString() ?? '';
        final rawPriorities =
            decoded['priorities'] as List<dynamic>? ?? const [];
        final priorities = rawPriorities
            .whereType<Map<String, dynamic>>()
            .map(JournalPriorityItem.fromJson)
            .toList();

        return JournalBlockConfig(
          date: date,
          mood: mood,
          priorities: priorities.isNotEmpty
              ? priorities
              : JournalBlockConfig.defaultConfig().priorities,
          notes: notes,
        );
      }
    } on Object catch (_) {}
    return JournalBlockConfig.defaultConfig();
  }

  /// Returns a default config with three empty priority slots.
  factory JournalBlockConfig.defaultConfig() {
    return const JournalBlockConfig(
      date: '',
      mood: '😊',
      priorities: [
        JournalPriorityItem(id: '1', text: '', isDone: false),
        JournalPriorityItem(id: '2', text: '', isDone: false),
        JournalPriorityItem(id: '3', text: '', isDone: false),
      ],
      notes: '',
    );
  }

  final String date;
  final String mood;
  final List<JournalPriorityItem> priorities;
  final String notes;

  JournalBlockConfig copyWith({
    String? date,
    String? mood,
    List<JournalPriorityItem>? priorities,
    String? notes,
  }) {
    return JournalBlockConfig(
      date: date ?? this.date,
      mood: mood ?? this.mood,
      priorities: priorities ?? List<JournalPriorityItem>.from(this.priorities),
      notes: notes ?? this.notes,
    );
  }

  /// Serializes this config to a JSON string.
  String toJsonString() {
    return jsonEncode({
      'date': date,
      'mood': mood,
      'priorities': priorities.map((p) => p.toJson()).toList(),
      'notes': notes,
    });
  }
}
