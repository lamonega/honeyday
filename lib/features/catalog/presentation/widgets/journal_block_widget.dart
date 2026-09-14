import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

@immutable
class JournalPriorityItem {
  const JournalPriorityItem({
    required this.id,
    required this.text,
    required this.isDone,
  });

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

@immutable
class JournalBlockConfig {
  const JournalBlockConfig({
    required this.date,
    required this.mood,
    required this.priorities,
    required this.notes,
  });

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
    } on Object catch (_) {}
    return JournalBlockConfig.defaultConfig();
  }

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

  String toJsonString() {
    return jsonEncode({
      'date': date,
      'mood': mood,
      'priorities': priorities.map((p) => p.toJson()).toList(),
      'notes': notes,
    });
  }
}

class JournalBlockDefinition extends AgendaWidgetDefinition {
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

class JournalBlockWidget extends StatefulWidget {
  const JournalBlockWidget({
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
    final colorScheme = Theme.of(context).colorScheme;

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
                child: widget.isInteractive
                    ? TextFormField(
                        initialValue: _config.date,
                        key: ValueKey('date_${widget.elementId}'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          border: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        onFieldSubmitted: _updateDate,
                      )
                    : Text(
                        _config.date,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
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
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
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
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary),
                  ),
                  child: Text(
                    _config.mood,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            'Prioridades del Día',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
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
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: priority.isDone
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 1.2,
                        ),
                      ),
                      child: priority.isDone
                          ? Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: colorScheme.onPrimary,
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
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                              decoration: priority.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              border: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
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
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
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
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: 6),
          Text(
            'Notas & Reflexión',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
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
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí tus pensamientos del día...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(6),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary),
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
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
