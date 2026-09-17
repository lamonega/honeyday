import 'package:flutter/material.dart';

/// Wraps a widget with semantic information for screen readers.
///
/// What: Provides accessibility labels and hints for interactive elements.
/// Why: WCAG 2.2 compliance and inclusive design.
class SemanticLabel extends StatelessWidget {
  /// Wraps [child] with a semantic [label] for screen readers.
  const SemanticLabel({required this.label, required this.child, super.key});

  /// The accessibility label read by screen readers.
  final String label;

  /// The widget to wrap.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(label: label, child: child);
  }
}

/// Wraps a button-like widget with semantic button role and label.
class SemanticButton extends StatelessWidget {
  /// Wraps [child] with semantic button role and [label].
  const SemanticButton({
    required this.label,
    required this.child,
    super.key,
    this.onTap,
  });

  /// The accessibility label read by screen readers.
  final String label;

  /// The widget to wrap.
  final Widget child;

  /// Optional tap handler — if provided, adds button semantics.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, label: label, onTap: onTap, child: child);
  }
}

/// Hides decorative elements from screen readers.
class SemanticHidden extends StatelessWidget {
  /// Hides [child] from screen readers.
  const SemanticHidden({required this.child, super.key});

  /// The decorative widget to hide.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: child);
  }
}

/// Groups child semantics into a single unit.
class SemanticGroup extends StatelessWidget {
  /// Groups child semantics into one.
  const SemanticGroup({required this.child, super.key});

  /// The child to group.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(child: child);
  }
}
