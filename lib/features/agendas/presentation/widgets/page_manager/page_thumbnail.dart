import 'package:flutter/material.dart';
import 'package:honeyday/core/theme/paper_style.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';

/// Icon mapping for each paper style key.
const Map<String, IconData> kPaperIcons = <String, IconData>{
  'dotted': Icons.grain_rounded,
  'lined': Icons.view_headline_rounded,
  'grid': Icons.grid_4x4_rounded,
  'blank': Icons.crop_portrait_rounded,
};

/// Displays a single page as a tappable thumbnail card within the page manager.
///
/// Shows the paper style icon, 1-based page number, and localized style label.
/// Highlights the currently selected page with the primary color.
class PageThumbnail extends StatelessWidget {
  /// Creates a [PageThumbnail].
  const PageThumbnail({
    required this.page,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    super.key,
  });

  /// The agenda page model for this thumbnail.
  final AgendaPage page;

  /// Zero-based index of this page in the list.
  final int index;

  /// Whether this page is the currently active one.
  final bool isCurrent;

  /// Called when the thumbnail is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final styleKey = page.backgroundStyle;
    final icon = kPaperIcons[styleKey] ?? Icons.grain_rounded;
    final localizedLabels = PaperStyle.localizedLabels(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: isCurrent ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? colorScheme.primary : colorScheme.outline,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isCurrent
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 6),
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isCurrent ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              localizedLabels[styleKey] ?? styleKey,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
