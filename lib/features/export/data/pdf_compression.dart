/// Deflate codec used for every image stream in the exported PDF.
///
/// Why: `/FlateDecode` in a PDF expects a *zlib* stream (RFC 1950: 2-byte
/// header + raw deflate + Adler-32), not the bare deflate of RFC 1951.
/// Getting this wrong produces a structurally valid PDF that no viewer opens,
/// so the distinction is isolated in one tiny platform file.
library;
export 'pdf_compression_io.dart'
    if (dart.library.js_interop) 'pdf_compression_web.dart';
