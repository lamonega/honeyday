import 'package:flutter/material.dart';
import 'package:honeyday/features/catalog/presentation/widgets/journal/journal_config.dart';

/// A single priority row containing a checkbox, text field, and strike-through
/// styling when completed.
///
/// Used inside `JournalPriorityList` to render each individual priority entry.
class JournalPriorityItemWidget extends StatefulWidget {
  const JournalPriorityItemWidget({
    required this.priority,
    required this.isInteractive,
    required this.onToggle,
    required this.onTextChanged,
    required this.localizedText,
    super.key,
  });

  /// The priority data model to display.
  final JournalPriorityItem priority;

  /// Whether the user can interact with this item.
  final bool isInteractive;

  /// Called when the checkbox is tapped to toggle completion.
  final VoidCallback onToggle;

  /// Called when the text field is submitted with new text.
  final ValueChanged<String> onTextChanged;

  /// The display text, already localized by the parent.
  final String localizedText;

  @override
  State<JournalPriorityItemWidget> createState() =>
      _JournalPriorityItemWidgetState();
}

class _JournalPriorityItemWidgetState extends State<JournalPriorityItemWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.priority.text);
  }

  @override
  void didUpdateWidget(JournalPriorityItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.priority.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.priority.text,
        selection: TextSelection.collapsed(offset: widget.priority.text.length),
      );
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.isInteractive ? widget.onToggle : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.priority.isDone
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: widget.priority.isDone
                      ? colorScheme.primary
                      : colorScheme.outline,
                  width: 1.2,
                ),
              ),
              child: widget.priority.isDone
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
                    controller: _controller,
                    key: ValueKey('prio_${widget.priority.id}'),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.priority.isDone
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: widget.priority.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.localizedText,
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
                    onChanged: widget.onTextChanged,
                  )
                : Text(
                    widget.localizedText,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.priority.isDone
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration: widget.priority.isDone
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
  }
}
