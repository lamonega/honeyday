import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

/// Share sheet on Android/iOS/macOS, native save dialog on Windows/Linux.
Future<void> savePdfImpl(Uint8List bytes, String fileName) async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
        ],
        // XFile.fromData loses its name on every platform except web.
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );
    return;
  }

  final location = await getSaveLocation(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: <String>['pdf']),
    ],
    suggestedName: fileName,
  );
  if (location == null) return; // user dismissed the dialog
  await File(location.path).writeAsBytes(bytes, flush: true);
}
