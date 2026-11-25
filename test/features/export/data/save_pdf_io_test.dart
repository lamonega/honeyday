import 'dart:io';

// The file_selector test seam lives in its transitive platform interface.
// ignore: depend_on_referenced_packages
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/save_pdf.dart';
import 'package:honeyday/features/export/data/save_pdf_io.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final originalSelector = FileSelectorPlatform.instance;
  const name = 'Agenda — Honeyday.pdf';
  const bytes = [37, 80, 68, 70];
  late Directory temp;
  late _RecordingSelector selector;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('honeyday_save_pdf_test_');
    selector = _RecordingSelector();
    FileSelectorPlatform.instance = selector;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(shareChannel, null);
    FileSelectorPlatform.instance = originalSelector;
    debugDefaultTargetPlatformOverride = null;
    debugPdfShareClock = DateTime.now;
    await temp.delete(recursive: true);
  });

  test(
    'iOS shares by path without hardcoded origin and cleans up on dismiss',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final source = await File.fromUri(temp.uri.resolve('unnamed.pdf'))
          .writeAsBytes(bytes);
      var calls = 0;
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        calls++;
        expect(call.method, 'share');
        final args = call.arguments as Map<Object?, Object?>;
        final path = (args['paths']! as List<Object?>).single! as String;
        final shared = File(path);
        expect(shared.uri.pathSegments.last, name);
        expect(await shared.readAsBytes(), bytes);
        expect(args['mimeTypes'], ['application/pdf']);
        expect(args['originWidth'], isNull);
        expect(args['originHeight'], isNull);
        return '';
      });

      await savePdf(PdfArtifact.file(source.path), name);

      expect(calls, 1);
      expect(await temp.list().toList(), isEmpty);
    },
  );

  test('iOS keeps staged PDF after completed share and sweeps stale folders later', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final first = await File.fromUri(temp.uri.resolve('first.pdf'))
        .writeAsBytes(bytes);
    late String firstSharedPath;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      firstSharedPath = (args['paths']! as List<Object?>).single! as String;
      return 'com.apple.UIKit.activity.AirDrop';
    });

    await savePdf(PdfArtifact.file(first.path), name);

    final firstFolder = File(firstSharedPath).parent;
    expect(File(firstSharedPath).existsSync(), isTrue);
    expect(firstFolder.existsSync(), isTrue);

    // Advance the share clock past the 10-minute stale window and share again.
    debugPdfShareClock = () => DateTime.now().add(const Duration(minutes: 15));
    final second = await File.fromUri(temp.uri.resolve('second.pdf'))
        .writeAsBytes(bytes);
    late String secondSharedPath;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      secondSharedPath = (args['paths']! as List<Object?>).single! as String;
      return 'com.apple.UIKit.activity.AirDrop';
    });

    await savePdf(PdfArtifact.file(second.path), name);

    expect(firstFolder.existsSync(), isFalse);
    expect(File(secondSharedPath).existsSync(), isTrue);
  });

  test('deletes the staged PDF if iOS share throws', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final source = await File.fromUri(temp.uri.resolve('unnamed.pdf'))
        .writeAsBytes(bytes);
    messenger.setMockMethodCallHandler(shareChannel, (_) async {
      throw PlatformException(code: 'share_failed');
    });

    await expectLater(
      savePdf(PdfArtifact.file(source.path), name),
      throwsA(isA<PlatformException>()),
    );
    expect(await temp.list().toList(), isEmpty);
  });

  test('deletes the staged PDF if Android share throws', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final source = await File.fromUri(temp.uri.resolve('unnamed.pdf'))
        .writeAsBytes(bytes);
    messenger.setMockMethodCallHandler(shareChannel, (_) async {
      throw PlatformException(code: 'share_failed');
    });

    await expectLater(
      savePdf(PdfArtifact.file(source.path), name),
      throwsA(isA<PlatformException>()),
    );
    expect(await temp.list().toList(), isEmpty);
  });

  test('macOS saves a byte-backed PDF through the document dialog', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final destination = File.fromUri(temp.uri.resolve('saved.pdf'));
    selector.location = FileSaveLocation(destination.path);

    await savePdf(PdfArtifact.bytes(Uint8List.fromList(bytes)), name);

    expect(selector.suggestedName, name);
    expect(selector.groups!.single.extensions, ['pdf']);
    expect(await destination.readAsBytes(), bytes);
  });

  test(
    'cancelling the desktop dialog deletes only the temporary PDF',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final source = await File.fromUri(temp.uri.resolve('unnamed.pdf'))
          .writeAsBytes(bytes);

      await savePdf(PdfArtifact.file(source.path), name);

      expect(selector.suggestedName, name);
      expect(await temp.list().toList(), isEmpty);
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
