import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Triggers a browser download of [bytes] under [fileName].
///
/// What: Blob → object URL → anchor click → revoke. No navigator.share:
/// file sharing isn't uniformly supported by desktop browsers.
Future<void> savePdfImpl(Uint8List bytes, String fileName) async {
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
