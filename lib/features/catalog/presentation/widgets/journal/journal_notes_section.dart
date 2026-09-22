import 'package:flutter/material.dart';

/// The notes section of a journal block, containing a labeled header and a
/// multi-line text area.
///
/// In interactive mode a [TextFormField] allows the user to type notes. In
/// non-interactive mode the notes are displayed as plain text, or a "no notes"
/// placeholder when empty.
class JournalNotesSection extends StatefulWidget {
  /// Creates a [JournalNotesSection].
  const JournalNotesSection({
    required this.notes,
    required this.elementId,
    required this.isInteractive,
    required this.onChanged,
    required this.headerText,
    required this.hintText,
    required this.noNotesText,
    super.key,
  });

  /// The current notes text.
  final String notes;

  /// The element ID, used to generate a unique form field key.
  final String elementId;

  /// Whether the user can edit the notes.
  final bool isInteractive;

  /// Called when the notes text changes (interactive mode).
  final ValueChanged<String> onChanged;

  /// The header label displayed above the text area.
  final String headerText;

  /// Placeholder text shown in the text field when empty (interactive mode).
  final String hintText;

  /// Text shown when there are no notes (non-interactive mode).
  final String noNotesText;

  @override
  State<JournalNotesSection> createState() => _JournalNotesSectionState();
}

class _JournalNotesSectionState extends State<JournalNotesSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(JournalNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adopt external changes (undo/redo, config reload) without clobbering
    // in-flight typing.
    if (widget.notes != _controller.text) {
      _controller.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.headerText,
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
                  controller: _controller,
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
                    hintText: widget.hintText,
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
                  onChanged: widget.onChanged,
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    widget.notes.isEmpty ? widget.noNotesText : widget.notes,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: widget.notes.isEmpty
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
