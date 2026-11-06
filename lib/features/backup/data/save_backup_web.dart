import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<bool> saveBackupFile(Uint8List bytes, String fileName) async {
  final blob = Blob(
    <JSAny>[bytes.toJS].toJS,
    BlobPropertyBag(type: 'application/json'),
  );
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  document.body?.appendChild(anchor);
  anchor
    ..click()
    ..remove();
  // Let the browser consume the download before releasing its backing URL.
  Timer(const Duration(seconds: 1), () => URL.revokeObjectURL(url));
  return true;
}
