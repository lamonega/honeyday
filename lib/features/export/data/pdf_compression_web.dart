import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Deflate level used for exported page images.
///
/// Why 1 here and 6 on native: the browser has no isolates, so this runs on
/// the UI isolate. Level 6 costs ~98 ms per A4 page against level 1's ~32 ms —
/// a 20-page agenda would freeze the tab for ~2 s. Level 1 keeps the export
/// responsive at the cost of a larger document, which is the right trade on
/// the one platform that cannot move the work off the main isolate.
/// See `docs/export-pipeline.md` for the measurements.
const int kPdfDeflateLevel = 1;

/// Wraps [data] in a zlib stream (RFC 1950) for PDF's `/FlateDecode`.
///
/// What: `archive`'s pure-Dart [ZLibEncoder], which writes the same
/// 2-byte header + deflate + Adler-32 container as `dart:io`'s `ZLibCodec`
/// (it is the encoder `package:pdf` itself used on web).
/// Why: `dart:io` does not exist on the web, and there are no isolates
/// there either, so the web build compresses on the main isolate. This is
/// the slowest platform by design — see `docs/export-pipeline.md`.
Uint8List deflatePdfStream(Uint8List data, {int level = kPdfDeflateLevel}) {
  return Uint8List.fromList(const ZLibEncoder().encode(data, level: level));
}
