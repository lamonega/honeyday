import 'package:flutter/material.dart';
import 'package:honeyday/core/constants/app_constants.dart';

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
          margin: const EdgeInsets.only(bottom: kViewerNavBottomMargin),
          padding: const EdgeInsets.symmetric(
            horizontal: kViewerNavHorizontalPadding,
            vertical: kViewerNavVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(kViewerNavBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: kViewerNavShadowBlur,
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
                  size: kViewerNavChevronIconSize,
                  color: currentPage > 0
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              ...List.generate(childCount, (i) {
                final isActive = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: kViewerNavDotMargin),
                  width: isActive ? 16 : 5,
                  height: kViewerNavInactiveDotSize,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              Container(
                width: kViewerNavDividerWidth,
                height: kViewerNavDividerHeight,
                margin: const EdgeInsets.symmetric(horizontal: kViewerNavDividerMargin),
                color: colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              Text(
                '${currentPage + 1}/$childCount',
                style: TextStyle(
                  fontSize: kViewerNavTextFontSize,
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
                  size: kViewerNavChevronIconSize,
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
