import 'package:flutter/material.dart';

/// Available mood emojis for the journal block.
const List<String> kJournalMoodEmojis = ['😊', '😌', '🤔', '😴', '⚡'];

/// A horizontal row of mood emoji selectors.
///
/// In interactive mode the user can tap an emoji to select it. The selected
/// emoji is highlighted with a circular border and container color. In
/// non-interactive mode the current mood is displayed in a pill-shaped badge.
class JournalMoodSelector extends StatelessWidget {
  const JournalMoodSelector({
    required this.selectedMood,
    required this.isInteractive,
    required this.onMoodSelected,
    super.key,
  });

  /// The currently selected mood emoji.
  final String selectedMood;

  /// Whether the user can tap to change the mood.
  final bool isInteractive;

  /// Called when the user taps a new mood emoji.
  final ValueChanged<String> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isInteractive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary),
        ),
        child: Text(
          selectedMood,
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: kJournalMoodEmojis.map((emoji) {
        final isSelected = emoji == selectedMood;
        return GestureDetector(
          onTap: () => onMoodSelected(emoji),
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
                color: isSelected ? colorScheme.primary : Colors.transparent,
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
    );
  }
}
