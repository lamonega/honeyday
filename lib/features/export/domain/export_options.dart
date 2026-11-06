import 'package:flutter/foundation.dart';

/// Paper formats supported by the PDF export.
///
/// What: The user-facing size choices offered at export time.
/// Why: Kept as data (not widgets) so domain code and tests can reason about
/// the format table without touching the UI.
enum PdfExportFormat {
  /// ISO 216 A4 (210 × 297 mm).
  a4,

  /// ANSI/US Letter (8.5 × 11 in).
  letter;

  /// Locale-independent short name used in filenames and fallback labels.
  String get fileLabel => switch (this) {
    PdfExportFormat.a4 => 'A4',
    PdfExportFormat.letter => 'Letter',
  };
}

/// User-selected options for one PDF export run.
@immutable
class ExportOptions {
  /// Creates an options snapshot; defaults match the dialog defaults.
  const ExportOptions({
    this.format = PdfExportFormat.a4,
    this.includeTypedContent = true,
    this.includeInk = true,
  });

  /// Target paper size; content is contained and centered on it.
  final PdfExportFormat format;

  /// When `false`, every element is rendered with its definition's default
  /// config (blank template: no typed text, default colors).
  final bool includeTypedContent;

  /// Includes saved handwriting. Turn this and [includeTypedContent] off
  /// for a reusable template without personal writing.
  final bool includeInk;
}
