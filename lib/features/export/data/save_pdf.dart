import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/save_pdf_io.dart'
    if (dart.library.js_interop) 'package:honeyday/features/export/data/save_pdf_web.dart';

/// Hands the generated PDF to the platform's save/share surface.
///
/// What: Share sheet (Android/iOS/macOS), native save dialog
/// (Windows/Linux), browser download (web) — see the platform implementations.
/// Why: One entry point keeps `export_actions` platform-free, and it owns the
/// temp file lifecycle: a file-backed artifact is deleted once the platform
/// has taken it, so nothing is left in the temp directory.
Future<void> savePdf(PdfArtifact artifact, String fileName) =>
    savePdfImpl(artifact, fileName);
