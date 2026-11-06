import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveBackupFile(Uint8List bytes, String fileName) async {
  final file = XFile.fromData(
    bytes,
    mimeType: 'application/json',
    name: fileName,
  );
  if (Platform.isAndroid || Platform.isIOS) {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        subject: fileName,
        // iPad requires a non-empty popover anchor within the presenting view.
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Honeyday backup', extensions: ['honeyday']),
    ],
  );
  if (location == null) return false;
  await file.saveTo(location.path);
  return true;
}
