import 'dart:io';

// The file_selector test seam lives in its transitive platform interface.
// ignore: depend_on_referenced_packages
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/backup/data/save_backup_io.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final originalSelector = FileSelectorPlatform.instance;
  const name = 'honeyday-2026-11-25.honeyday';
  final bytes = Uint8List.fromList([123, 34, 118, 34, 58, 49, 125]);
  late Directory temp;
  late _RecordingSelector selector;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('honeyday_save_backup_test_');
    debugBackupShareTempDirectory = () => temp;
    debugBackupShareClock = DateTime.now;
    selector = _RecordingSelector();
    FileSelectorPlatform.instance = selector;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(shareChannel, null);
    FileSelectorPlatform.instance = originalSelector;
    debugDefaultTargetPlatformOverride = null;
    debugBackupShareTempDirectory = () => Directory.systemTemp;
    debugBackupShareClock = DateTime.now;
    await temp.delete(recursive: true);
  });

  test(
    'Android stages backup file, shares by path, and cleans up immediately',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        expect(call.method, 'share');
        final args = call.arguments as Map<Object?, Object?>;
        final path = (args['paths']! as List<Object?>).single! as String;
        final staged = File(path);
        expect(staged.uri.pathSegments.last, name);
        expect(await staged.readAsBytes(), bytes);
        expect(args['mimeTypes'], ['application/json']);
        expect(args['originWidth'], isNull);
        expect(args['originHeight'], isNull);
        return 'com.android.intentresolver';
      });

      final shared = await saveBackupFile(bytes, name);

      expect(shared, isTrue);
      expect(await temp.list().toList(), isEmpty);
    },
  );

  test('iOS keeps staged backup on completed share and sweeps stale folders lazily', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    late String firstPath;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      firstPath = (args['paths']! as List<Object?>).single! as String;
      return 'com.apple.UIKit.activity.AirDrop';
    });

    final firstShared = await saveBackupFile(bytes, name);
    expect(firstShared, isTrue);
    final firstFolder = File(firstPath).parent;
    expect(File(firstPath).existsSync(), isTrue);

    debugBackupShareClock = () =>
        DateTime.now().add(const Duration(minutes: 15));
    late String secondPath;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      secondPath = (args['paths']! as List<Object?>).single! as String;
      return 'com.apple.UIKit.activity.AirDrop';
    });

    final secondShared = await saveBackupFile(bytes, name);
    expect(secondShared, isTrue);
    expect(firstFolder.existsSync(), isFalse);
    expect(File(secondPath).existsSync(), isTrue);
  });

  test('iOS cleans up staged backup immediately when dismissed', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(shareChannel, (_) async => '');

    final shared = await saveBackupFile(bytes, name);

    expect(shared, isFalse);
    expect(await temp.list().toList(), isEmpty);
  });

  test('iOS cleans up staged backup immediately if share throws', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(shareChannel, (_) async {
      throw PlatformException(code: 'share_failed');
    });

    await expectLater(
      saveBackupFile(bytes, name),
      throwsA(isA<PlatformException>()),
    );
    expect(await temp.list().toList(), isEmpty);
  });

  test(
    'desktop saves backup through file_selector and handles cancellation',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(await saveBackupFile(bytes, name), isFalse);

      final destination = File.fromUri(temp.uri.resolve('saved.honeyday'));
      selector.location = FileSaveLocation(destination.path);
      expect(await saveBackupFile(bytes, name), isTrue);
      expect(selector.suggestedName, name);
      expect(selector.groups!.single.extensions, ['honeyday']);
      expect(await destination.readAsBytes(), bytes);
    },
  );
}

class _RecordingSelector extends FileSelectorPlatform {
  List<XTypeGroup>? groups;
  String? suggestedName;
  FileSaveLocation? location;

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    groups = acceptedTypeGroups;
    suggestedName = options.suggestedName;
    return location;
  }
}
