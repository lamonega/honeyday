import 'dart:js_interop';

import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:web/web.dart';

/// Triggers a browser download of the document under [fileName].
///
/// What: Blob → object URL → anchor click → revoke. No navigator.share: file
/// sharing isn't uniformly supported by desktop browsers.
/// Why: the web output is always byte-backed — a browser has no filesystem to
/// stream into.
Future<void> savePdfImpl(PdfArtifact artifact, String fileName) async {
  final bytes = artifact.bytes;
  if (bytes == null) {
    throw StateError('The exported PDF artifact is empty.');
  }
  final blob = Blob(
    <JSAny>[bytes.toJS].toJS,
    BlobPropertyBag(type: 'application/pdf'),
  );
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  document.body?.appendChild(anchor);
  anchor
    ..click()
    ..remove();
  URL.revokeObjectURL(url);
}
