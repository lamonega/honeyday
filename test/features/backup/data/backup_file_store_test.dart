// The file_selector test seam lives in its transitive platform interface.
// ignore: depend_on_referenced_packages
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/backup/data/backup_file_store.dart';

void main() {
  final originalSelector = FileSelectorPlatform.instance;
  late _RecordingSelector selector;
  const store = PlatformBackupFileStore();

  setUp(() {
    selector = _RecordingSelector();
    FileSelectorPlatform.instance = selector;
  });

  tearDown(() {
    FileSelectorPlatform.instance = originalSelector;
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android can open a backup reported as text/plain', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final bytes = Uint8List.fromList([1, 2, 3]);
    selector.file = XFile.fromData(bytes, mimeType: 'text/plain');

    expect(await store.pickBackup(), bytes);
    expect(selector.groups, isEmpty);
  });

  test('iOS keeps UTI filters, and picker cancellation returns null', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(await store.pickBackup(), isNull);
    expect(selector.groups!.single.extensions, ['honeyday', 'json']);
    expect(
      selector.groups!.single.uniformTypeIdentifiers,
      contains('public.data'),
    );
  });
}

class _RecordingSelector extends FileSelectorPlatform {
  List<XTypeGroup>? groups;
  XFile? file;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    groups = acceptedTypeGroups;
    return file;
  }
}
