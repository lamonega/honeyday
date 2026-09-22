import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';

/// Floating action button that toggles between writing and reading canvas modes.
///
/// In writing mode the button shows a book icon (tap to switch to reading).
/// In reading mode the button shows a pencil icon (tap to switch to writing).
class ViewerCanvasModeToggle extends StatelessWidget {
  const ViewerCanvasModeToggle({
    required this.currentMode,
    required this.onToggle,
    super.key,
  });

  /// The active [CanvasMode] used to determine which icon to display.
  final CanvasMode currentMode;

  /// Called when the user taps the button. The parent should switch modes.
  final VoidCallback onToggle;

  bool get _isWriting => currentMode == CanvasMode.writing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: onToggle,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: Icon(
        _isWriting ? Icons.menu_book_outlined : Icons.edit_outlined,
      ),
    );
  }
}

/// Shows a haptic light feedback.
Future<void> hapticLight() =>
    Haptics.vibrate(HapticsType.light).onError((_, _) {});
