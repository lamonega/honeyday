/// Platform factory for the PDF destination.
///
/// Why: Native platforms stream into a temp file (a path is what
/// `share_plus` and `file_selector` want, and it keeps the document out of
/// the heap); the web has no filesystem, so it accumulates a `Blob`.
library;
export 'pdf_output_io.dart'
    if (dart.library.js_interop) 'pdf_output_web.dart';
