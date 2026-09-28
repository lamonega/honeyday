import 'package:honeyday/features/export/data/pdf_image_stream.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';

/// Whether compression can run off the UI isolate.
///
/// Always false: the web has no isolates, so page compression runs inline on
/// the UI isolate and web stays the slowest export target. See
/// `docs/export-pipeline.md`.
const bool pdfWorkerIsolatesSupported = false;

/// One worker: the browser has nothing to offload to.
int get defaultPdfWorkerCount => 1;

/// Builds the single inline worker.
PdfWorkerBuilder get defaultPdfWorkerBuilder => (index) async {
  return PdfCompressionWorker(
    compress: (request) async => encodePageImage(
      request.page,
      backgroundArgb: kExportCreamArgb,
    ),
  );
};
