import 'dart:typed_data';

import 'package:honeyday/features/export/data/save_pdf_io.dart'
    if (dart.library.html) 'package:honeyday/features/export/data/save_pdf_web.dart';

/// Hands the generated PDF to the platform's save/share surface.
///
/// What: Share sheet (Android/iOS/macOS), native save dialog (Windows/Linux),
/// browser download (web) — see the platform implementations.
/// Why: One entry point keeps `export_actions` platform-free.
Future<void> savePdf(Uint8List bytes, String fileName) =>
    savePdfImpl(bytes, fileName);
