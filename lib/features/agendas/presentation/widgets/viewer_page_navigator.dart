import 'package:flutter/material.dart';

class ViewerPageNavigator extends StatelessWidget {
  const ViewerPageNavigator({
    required this.childCount,
    required this.currentPage,
    required this.onGoToPage,
    super.key,
  });

  final int childCount;
  final int currentPage;
  final void Function(int index) onGoToPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: currentPage > 0
                    ? () => onGoToPage(currentPage - 1)
                    : null,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: currentPage > 0
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              ...List.generate(childCount, (i) {
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
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              Text(
                '${currentPage + 1}/$childCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: currentPage < childCount - 1
                    ? () => onGoToPage(currentPage + 1)
                    : null,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: currentPage < childCount - 1
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
