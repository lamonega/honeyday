import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/data/pdf_worker_factory.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/domain/export_cancellation.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

void main() {
  test(
    'disposing a native worker completes its in-flight request',
    () async {
      final worker = await defaultPdfWorkerBuilder(0);
      final result = worker.compress(
        PdfWorkerRequest(
          pageIndex: 0,
          page: CapturedPage(
            rgba: Uint8List(800 * 1100 * 4),
            width: 800,
            height: 1100,
          ),
        ),
      );
      final cancelled = expectLater(
        result,
        throwsA(isA<ExportCancelled>()),
      );

      // The worker has received the request, but is terminated before the
      // isolate can answer. Its pending completer must not hang forever.
      await worker.shutdown!.call();
      await cancelled;
    },
    skip: !PdfWorkerPool.isSupported,
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
