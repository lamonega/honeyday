import 'dart:isolate';

import 'package:honeyday/features/export/data/pdf_image_stream.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

/// Entry point of a compression isolate.
///
/// What: Announces its command port, then answers each job by compressing
/// the transferred raster into a PDF image stream and sending the bytes back,
/// tagged with the job's page index.
/// Why: All of the export's CPU — stripping 34 MB of alpha, applying the
/// predictor and deflating ~25 MB — used to run on the isolate that also owns
/// the frame pipeline, which is exactly why the app froze. Running it here
/// makes the cost parallel *and* invisible to the UI.
///
/// Protocol (see `pdf_worker_pool_io.dart`):
/// * pool → worker: `[pageIndex, TransferableTypedData, width, height]`
/// * worker → pool: `[pageIndex, Uint8List]` for a stream,
///   `[pageIndex, message, stackTrace]` for a failure.
void pdfWorkerEntryPoint(SendPort pool) {
  final commands = ReceivePort();
  pool.send(commands.sendPort);

  commands.listen((message) {
    final job = message! as List<Object?>;
    final pageIndex = job[0]! as int;
    final data = job[1]! as TransferableTypedData;
    final width = job[2]! as int;
    final height = job[3]! as int;

    try {
      // Zero-copy: materializing transferred data maps the buffer the pool
      // handed over instead of copying 34 MB across isolates.
      final rgba = data.materialize().asUint8List();
      final stream = encodePageImage(
        CapturedPage(rgba: rgba, width: width, height: height),
        backgroundArgb: kExportCreamArgb,
      );
      pool.send(<Object?>[pageIndex, stream]);
    } on Object catch (error, stackTrace) {
      pool.send(<Object?>[pageIndex, '$error', '$stackTrace']);
    }
  });
}
