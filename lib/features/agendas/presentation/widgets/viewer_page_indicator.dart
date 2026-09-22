import 'package:flutter/material.dart';

/// Animated row of dots indicating the current page in the viewer.
///
/// Displays a horizontal row of pill-shaped dots, with the active dot
/// stretched wider and colored with the primary color. Inactive dots
/// are smaller and semi-transparent.
class ViewerPageIndicator extends StatelessWidget {
  const ViewerPageIndicator({
    required this.childCount,
    required this.currentPage,
    super.key,
  });

  /// Total number of pages.
  final int childCount;

  /// Index of the currently visible page (0-based).
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(childCount, (i) {
        final isActive = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
