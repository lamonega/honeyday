import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

/// Single bullet item in the journal's priority section.
///
/// What: Stores the priority text and boolean completion state.
/// Why: Provides an immutable model for daily top-3 focus targets.
@immutable
class JournalPriorityItem {
  /// Constructs a [JournalPriorityItem].
  const JournalPriorityItem({
    required this.id,
    required this.text,
    required this.isDone,
  });

  /// Decodes priority item from a JSON map.
  factory JournalPriorityItem.fromJson(Map<String, dynamic> json) {
    return JournalPriorityItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      text: json['text']?.toString() ?? '',
      isDone: json['isDone'] == true,
    );
  }

  /// Unique identifier.
  final String id;

  /// Goal or priority description.
  final String text;

  /// Completion state.
  final bool isDone;

  /// Creates a copy with optionally updated fields.
  JournalPriorityItem copyWith({String? id, String? text, bool? isDone}) {
    return JournalPriorityItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isDone': isDone};
  }
}

/// Parsed configuration model for [JournalBlockWidget].
///
/// What: Holds date header, selected mood emoji, priority bullets, and lined note body.
/// Why: Delivers structured daily/weekly reflection data with robust JSON fallback.
@immutable
class JournalBlockConfig {
  /// Constructs a [JournalBlockConfig].
  const JournalBlockConfig({
    required this.date,
    required this.mood,
    required this.priorities,
    required this.notes,
  });

  /// Decodes JSON string into a [JournalBlockConfig].
  factory JournalBlockConfig.fromJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return JournalBlockConfig.defaultConfig();
    }
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final date = decoded['date']?.toString() ?? 'Hoy';
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
    } on Object catch (_) {
      // Fallback on JSON parse error
    }
    return JournalBlockConfig.defaultConfig();
  }

  /// Factory defaults for newly created journal blocks.
  factory JournalBlockConfig.defaultConfig() {
    return const JournalBlockConfig(
      date: 'Viernes, 11 de Septiembre',
      mood: '😊',
      priorities: [
        JournalPriorityItem(
          id: '1',
          text: 'Completar objetivos clave del día',
          isDone: false,
        ),
        JournalPriorityItem(
          id: '2',
          text: 'Momento de desconexión y lectura',
          isDone: false,
        ),
        JournalPriorityItem(
          id: '3',
          text: 'Planificar la semana próxima',
          isDone: false,
        ),
      ],
      notes: 'Reflexiones y aprendizajes de hoy...',
    );
  }

  /// Date string displayed in the header.
  final String date;

  /// Selected mood emoji.
  final String mood;

  /// Top 3 priority checklist items.
  final List<JournalPriorityItem> priorities;

  /// Freeform multiline journal text.
  final String notes;

  /// Creates a copy with optionally updated fields.
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

  /// Serializes to JSON string.
  String toJsonString() {
    return jsonEncode({
      'date': date,
      'mood': mood,
      'priorities': priorities.map((p) => p.toJson()).toList(),
      'notes': notes,
    });
  }
}

/// Catalog definition for [JournalBlockWidget].
///
/// What: Implements [AgendaWidgetDefinition] for daily/weekly journal blocks.
/// Why: Enables registration in the catalog registry for canvas element insertion.
class JournalBlockDefinition extends AgendaWidgetDefinition {
  /// Const constructor for definition registration.
  const JournalBlockDefinition();

  @override
  String get id => 'journal_block';

  @override
  String get name => 'Entrada Diaria / Semanal';

  @override
  IconData get icon => Icons.auto_stories_rounded;

  @override
  Size get defaultSize => const Size(320, 300);

  @override
  String get initialConfigJson =>
      JournalBlockConfig.defaultConfig().toJsonString();

  @override
  Widget build(
    BuildContext context, {
    required String elementId,
    required String configJson,
    required bool isInteractive,
    required ValueChanged<String> onConfigChanged,
  }) {
    return JournalBlockWidget(
      elementId: elementId,
      configJson: configJson,
      isInteractive: isInteractive,
      onConfigChanged: onConfigChanged,
    );
  }
}

/// Presentation widget rendering a daily/weekly journal block.
///
/// What: Combines a date header, mood emoji selector, 3 priority bullets, and a lined note section.
/// Why: Provides an authentic stationery journal block optimized for both active writing and aesthetic reading.
class JournalBlockWidget extends StatefulWidget {
  /// Constructs a [JournalBlockWidget].
  const JournalBlockWidget({
    required this.elementId,
    required this.configJson,
    required this.isInteractive,
    required this.onConfigChanged,
    super.key,
  });

  /// Unique canvas element UUID.
  final String elementId;

  /// JSON payload encoding journal data.
  final String configJson;

  /// Interactivity flag (true in writing mode, false in reading/edit mode).
  final bool isInteractive;

  /// Persistence callback.
  final ValueChanged<String> onConfigChanged;

  @override
  State<JournalBlockWidget> createState() => _JournalBlockWidgetState();
}

class _JournalBlockWidgetState extends State<JournalBlockWidget> {
  static const List<String> _moodEmojis = ['😊', '😌', '🤔', '😴', '⚡'];

  late JournalBlockConfig _config;

  @override
  void initState() {
    super.initState();
    _config = JournalBlockConfig.fromJsonString(widget.configJson);
  }

  @override
  void didUpdateWidget(JournalBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configJson != widget.configJson) {
      _config = JournalBlockConfig.fromJsonString(widget.configJson);
    }
  }

  void _selectMood(String emoji) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(mood: emoji);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _togglePriority(int index) {
    if (!widget.isInteractive) return;

    final item = _config.priorities[index];
    final updated = List<JournalPriorityItem>.from(_config.priorities);
    updated[index] = item.copyWith(isDone: !item.isDone);

    final newConfig = _config.copyWith(priorities: updated);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _editPriorityText(int index, String newText) {
    if (!widget.isInteractive) return;

    final item = _config.priorities[index];
    final updated = List<JournalPriorityItem>.from(_config.priorities);
    updated[index] = item.copyWith(text: newText);

    final newConfig = _config.copyWith(priorities: updated);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _updateDate(String newDate) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(date: newDate);
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig.toJsonString());
  }

  void _updateNotes(String newNotes) {
    if (!widget.isInteractive) return;

    final newConfig = _config.copyWith(notes: newNotes);
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
          // Header: Date & Mood Selector
          Row(
            children: [
              Expanded(
                child: widget.isInteractive
                    ? TextFormField(
                        initialValue: _config.date,
                        key: ValueKey('date_${widget.elementId}'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HoneydayTheme.inkSlate,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          border: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: HoneydayTheme.honeyAmber,
                            ),
                          ),
                        ),
                        onFieldSubmitted: _updateDate,
                      )
                    : Text(
                        _config.date,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HoneydayTheme.inkSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
              // Mood Selector
              if (widget.isInteractive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _moodEmojis.map((emoji) {
                    final isSelected = emoji == _config.mood;
                    return GestureDetector(
                      onTap: () => _selectMood(emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(3),
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? HoneydayTheme.honeyContainer
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? HoneydayTheme.honeyAmber
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: HoneydayTheme.honeyContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HoneydayTheme.honeyAmber),
                  ),
                  child: Text(
                    _config.mood,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: HoneydayTheme.paperBorder),
          const SizedBox(height: 8),

          // Priority Section (3 bullets)
          const Text(
            'Prioridades del Día',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HoneydayTheme.honeyAmber,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(_config.priorities.length, (index) {
            final priority = _config.priorities[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.isInteractive
                        ? () => _togglePriority(index)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: priority.isDone
                            ? HoneydayTheme.honeyAmber
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: priority.isDone
                              ? HoneydayTheme.honeyAmber
                              : HoneydayTheme.paperBorder,
                          width: 1.2,
                        ),
                      ),
                      child: priority.isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: widget.isInteractive
                        ? TextFormField(
                            initialValue: priority.text,
                            key: ValueKey('prio_${priority.id}'),
                            style: TextStyle(
                              fontSize: 11,
                              color: priority.isDone
                                  ? HoneydayTheme.inkSlate.withValues(
                                      alpha: 0.4,
                                    )
                                  : HoneydayTheme.inkSlate,
                              decoration: priority.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              border: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: HoneydayTheme.honeyAmber,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (val) =>
                                _editPriorityText(index, val),
                          )
                        : Text(
                            priority.text,
                            style: TextStyle(
                              fontSize: 11,
                              color: priority.isDone
                                  ? HoneydayTheme.inkSlate.withValues(
                                      alpha: 0.4,
                                    )
                                  : HoneydayTheme.inkSlate,
                              decoration: priority.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(height: 1, color: HoneydayTheme.paperBorder),
          const SizedBox(height: 6),

          // Lined Notes Section
          const Text(
            'Notas & Reflexión',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HoneydayTheme.inkSlate,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: widget.isInteractive
                ? TextFormField(
                    initialValue: _config.notes,
                    key: ValueKey('notes_${widget.elementId}'),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: HoneydayTheme.inkSlate,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Escribe aquí tus pensamientos del día...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.all(6),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: HoneydayTheme.honeyAmber),
                      ),
                    ),
                    onChanged: _updateNotes,
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      _config.notes.isEmpty
                          ? 'Sin notas para este día.'
                          : _config.notes,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: _config.notes.isEmpty
                            ? const Color(0xFF94A3B8)
                            : HoneydayTheme.inkSlate,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
