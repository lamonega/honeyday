import 'package:flutter/material.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// The notes section of a journal block, containing a labeled header and a
/// multi-line text area.
///
/// In interactive mode a [TextFormField] allows the user to type notes. In
/// non-interactive mode the notes are displayed as plain text, or a "no notes"
/// placeholder when empty.
class JournalNotesSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headerText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: isInteractive
              ? TextFormField(
                  initialValue: notes,
                  key: ValueKey('notes_${elementId}_$notes'),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
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
                  onChanged: onChanged,
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    notes.isEmpty ? noNotesText : notes,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: notes.isEmpty
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
