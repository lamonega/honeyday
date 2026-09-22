import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A segmented button for choosing the paper texture style of a new agenda.
///
/// Each entry in [styles] maps a style key to a human-readable label. Tapping
/// a segment provides haptic feedback and invokes [onPaperSelected] with the
/// chosen key.
class AgendaPaperStylePicker extends StatelessWidget {
  /// Constructs an [AgendaPaperStylePicker].
  const AgendaPaperStylePicker({
    required this.styles,
    required this.selectedPaper,
    required this.onPaperSelected,
    super.key,
  });

  /// Map of paper style keys to their display labels.
  final Map<String, String> styles;

  /// The key of the currently selected paper style.
  final String selectedPaper;

  /// Called with the style key when the user selects a new paper style.
  final ValueChanged<String> onPaperSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: styles.entries.map((entry) {
        return ButtonSegment(value: entry.key, label: Text(entry.value));
      }).toList(),
      selected: {selectedPaper},
      onSelectionChanged: (newSelection) {
        unawaited(HapticFeedback.selectionClick());
        onPaperSelected(newSelection.first);
      },
    );
  }
}
