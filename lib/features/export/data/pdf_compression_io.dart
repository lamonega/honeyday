import 'dart:io';
import 'dart:typed_data';

/// Deflate level used for exported page images.
///
/// Why 6 here and 1 on the web: on native platforms the compression runs on
/// worker isolates, so the CPU is both off the UI isolate and spread over
/// `min(4, cores - 1)` workers — measured at ~98 ms per A4 page, which the
/// pool hides behind the rasterizer. Level 6 is what the old pipeline used,
/// so the document keeps the same size (505 vs 504 KiB per page) while none of
/// that work happens on the thread that paints. The web has no isolates, so
/// it pays 3× more per page on the UI isolate and has to settle for level 1.
/// See `docs/export-pipeline.md` for the measurements.
const int kPdfDeflateLevel = 6;

/// Wraps [data] in a zlib stream (RFC 1950) for PDF's `/FlateDecode`.
///
/// What: [ZLibCodec] with the zlib container, i.e. header + deflate +
/// Adler-32. This is *not* `RawZLibCodec`, which emits RFC 1951 raw deflate
/// and produces unreadable PDFs.
/// Why: `dart:io` has a native (C) zlib, so this is the fast path.
Uint8List deflatePdfStream(Uint8List data, {int level = kPdfDeflateLevel}) {
  final encoded = ZLibCodec(level: level).encode(data);
  // `ZLibCodec.encode` is typed as `List<int>`; only pay for a copy when the
  // SDK really handed back an untyped list.
  return encoded is Uint8List ? encoded : Uint8List.fromList(encoded);
}
