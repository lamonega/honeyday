import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';
import 'package:honeyday/features/catalog/presentation/widgets/catalog_widget_mixin.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_config.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_mood_selector.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_notes_section.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_priority_list.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

export 'package:honeyday/features/catalog/presentation/widgets/journal/journal_config.dart'
    show JournalBlockConfig, JournalPriorityItem;

class JournalBlockDefinition extends AgendaWidgetDefinition {
  const JournalBlockDefinition();

  @override
  String get id => 'journal_block';

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).catalogJournalName;

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
  late CatalogConfigHelper<JournalBlockConfig> _configHelper;

  JournalBlockConfig get _config => _configHelper.config;

  @override
  void initState() {
    super.initState();
    _configHelper = CatalogConfigHelper<JournalBlockConfig>(
      parseConfig: JournalBlockConfig.fromJsonString,
      configToJson: (c) => c.toJsonString(),
      initialJson: widget.configJson,
    )..onConfigChanged = widget.onConfigChanged;
  }

  @override
  void didUpdateWidget(JournalBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configHelper.onConfigChanged = widget.onConfigChanged;
    if (oldWidget.configJson != widget.configJson) {
      _configHelper.updateFromJson(widget.configJson);
    }
  }

  void _updateConfig(JournalBlockConfig newConfig) {
    setState(() {
      _configHelper.updateConfig(newConfig);
    });
  }

  void _selectMood(String emoji) {
    if (!widget.isInteractive) return;
    _updateConfig(_config.copyWith(mood: emoji));
  }

  void _togglePriority(int index) {
    if (!widget.isInteractive) return;
    final item = _config.priorities[index];
    final updated = List<JournalPriorityItem>.from(_config.priorities);
    updated[index] = item.copyWith(isDone: !item.isDone);
    _updateConfig(_config.copyWith(priorities: updated));
  }

  void _editPriorityText(int index, String newText) {
    if (!widget.isInteractive) return;
    final item = _config.priorities[index];
    final updated = List<JournalPriorityItem>.from(_config.priorities);
    updated[index] = item.copyWith(text: newText);
    _updateConfig(_config.copyWith(priorities: updated));
  }

  void _updateDate(String newDate) {
    if (!widget.isInteractive) return;
    _updateConfig(_config.copyWith(date: newDate));
  }

  void _updateNotes(String newNotes) {
    if (!widget.isInteractive) return;
    _updateConfig(_config.copyWith(notes: newNotes));
  }

  String _localizedDate(String date, AppLocalizations l10n) {
    if (date.isEmpty || date == l10n.catalogJournalDefaultDate) {
      return l10n.catalogJournalDefaultDate;
    }
    if (date == l10n.catalogJournalToday) {
      return l10n.catalogJournalToday;
    }
    return date;
  }

  String _localizedPriorityText(String text, AppLocalizations l10n) {
    if (text.isEmpty || text == l10n.catalogJournalPriority1) {
      return l10n.catalogJournalPriority1;
    }
    if (text == l10n.catalogJournalPriority2) {
      return l10n.catalogJournalPriority2;
    }
    if (text == l10n.catalogJournalPriority3) {
      return l10n.catalogJournalPriority3;
    }
    return text;
  }

  String _localizedNotes(String notes, AppLocalizations l10n) {
    if (notes.isEmpty || notes == l10n.catalogJournalDefaultNotes) {
      return l10n.catalogJournalDefaultNotes;
    }
    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final displayDate = _localizedDate(_config.date, l10n);
    final displayNotes = _localizedNotes(_config.notes, l10n);

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
                child: widget.isInteractive
                    ? TextFormField(
                        initialValue: displayDate,
                        key: ValueKey('date_${widget.elementId}_$displayDate'),
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
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        onFieldSubmitted: _updateDate,
                      )
                    : Text(
                        displayDate,
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
              JournalMoodSelector(
                selectedMood: _config.mood,
                isInteractive: widget.isInteractive,
                onMoodSelected: _selectMood,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: 8),
          JournalPriorityList(
            priorities: _config.priorities,
            isInteractive: widget.isInteractive,
            onToggle: _togglePriority,
            onTextChanged: _editPriorityText,
            localizeText: (text) => _localizedPriorityText(text, l10n),
            headerText: l10n.catalogJournalPrioritiesHeader,
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outline),
          const SizedBox(height: 6),
          Expanded(
            child: JournalNotesSection(
              notes: displayNotes,
              elementId: widget.elementId,
              isInteractive: widget.isInteractive,
              onChanged: _updateNotes,
              headerText: l10n.catalogJournalNotesHeader,
              hintText: l10n.catalogJournalNotesHint,
              noNotesText: l10n.catalogJournalNoNotes,
            ),
          ),
        ],
      ),
    );
  }
}
