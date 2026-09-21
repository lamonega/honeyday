import 'package:flutter/widgets.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// Paper texture style variants supported by the canvas background.
///
/// What: Discriminator for background paper patterns.
/// Why: Users can choose between standard bullet journal dot grid, lined notebook,
/// graph paper grid, or clean blank paper.
enum PaperStyle {
  /// Bullet journal style dot grid pattern.
  dotted,

  /// Horizontal ruled notebook lines.
  lined,

  /// Graph paper square grid pattern.
  grid,

  /// Solid cream paper without any guidelines.
  blank;

  /// Parses a string representation into a [PaperStyle], defaulting to [PaperStyle.dotted].
  static PaperStyle fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'lined':
        return PaperStyle.lined;
      case 'grid':
        return PaperStyle.grid;
      case 'blank':
        return PaperStyle.blank;
      case 'dotted':
      default:
        return PaperStyle.dotted;
    }
  }

  /// Localized labels map for each paper style key.
  static Map<String, String> localizedLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return <String, String>{
      'dotted': l10n.paperStyleDots,
      'lined': l10n.paperStyleLines,
      'grid': l10n.paperStyleGrid,
      'blank': l10n.paperStyleBlank,
    };
  }

  /// Localized label for this paper style variant.
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case PaperStyle.dotted:
        return l10n.paperStyleDots;
      case PaperStyle.lined:
        return l10n.paperStyleLines;
      case PaperStyle.grid:
        return l10n.paperStyleGrid;
      case PaperStyle.blank:
        return l10n.paperStyleBlank;
    }
  }

}
