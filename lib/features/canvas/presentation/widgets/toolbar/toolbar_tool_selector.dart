import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';

/// Icon size for toolbar tool buttons.
const double kToolbarIconSize = 18;

/// Min button size for toolbar buttons.
const double kToolbarButtonMinSize = 32;

/// Divider height in toolbar.
const double kToolbarDividerHeight = 20;

/// A row of tool-selector buttons (pen, highlighter, eraser).
///
/// Highlights the currently active [selectedTool] and calls [onToolSelected]
/// when the user taps a different tool.
class ToolbarToolSelector extends StatelessWidget {
  const ToolbarToolSelector({
    required this.selectedTool,
    required this.onToolSelected,
    super.key,
  });

  /// The currently active ink tool.
  final InkToolType selectedTool;

  /// Callback when a tool button is tapped.
  final ValueChanged<InkToolType> onToolSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarToolBtn(
          icon: Icons.edit_outlined,
          isSelected: selectedTool == InkToolType.pen,
          onTap: () => onToolSelected(InkToolType.pen),
        ),
        ToolbarToolBtn(
          icon: Icons.brush_outlined,
          isSelected: selectedTool == InkToolType.highlighter,
          onTap: () => onToolSelected(InkToolType.highlighter),
        ),
        ToolbarToolBtn(
          icon: Icons.auto_fix_normal_outlined,
          isSelected: selectedTool == InkToolType.eraser,
          onTap: () => onToolSelected(InkToolType.eraser),
        ),
      ],
    );
  }
}

/// A compact icon button used inside the floating toolbar.
///
/// When [isSelected] is true the button renders with a highlighted background.
/// Set [isEnabled] to false to grey out the button (e.g. for disabled undo).
class ToolbarToolBtn extends StatelessWidget {
  const ToolbarToolBtn({
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isEnabled = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: kToolbarIconSize),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: kToolbarButtonMinSize,
        minHeight: kToolbarButtonMinSize,
      ),
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer)
          : null,
      color: !isEnabled
          ? colorScheme.onSurface.withValues(alpha: 0.2)
          : isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.6),
      onPressed: onTap,
    );
  }
}

/// A thin vertical divider used to separate toolbar sections.
class ToolbarDivider extends StatelessWidget {
  const ToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: kToolbarDividerHeight,
        width: 1,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
      ),
    );
  }
}
