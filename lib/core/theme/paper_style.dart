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
}
