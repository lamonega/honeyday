import 'dart:js_interop';
import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_sink.dart';
import 'package:honeyday/features/export/data/save_pdf_web.dart';
import 'package:web/web.dart';

/// Verifies the browser can read the PDF Blob after the click returns.
Future<void> verifyPdfDownload() async {
  const fileName = 'Agenda — Honeyday.pdf';
  final bytes = Uint8List.fromList([37, 80, 68, 70]);
  HTMLAnchorElement? download;
  final listener = ((Event event) {
    final anchor = event.target! as HTMLAnchorElement;
    if (anchor.download != fileName) return;
    event.preventDefault(); // Don't write to the browser profile.
    download = anchor;
  }).toJS;

  document.addEventListener('click', listener);
  try {
    await savePdfImpl(PdfArtifact.bytes(bytes), fileName);
    final anchor = download;
    if (anchor == null || anchor.isConnected) {
      throw StateError('PDF download did not click and remove the anchor.');
    }
    final response = await window.fetch(anchor.href.toJS).toDart;
    final buffer = await response.arrayBuffer().toDart;
    if (response.headers.get('content-type') != 'application/pdf' ||
        buffer.toDart.asUint8List().join(',') != bytes.join(',')) {
      throw StateError('PDF download returned an invalid MIME type or bytes.');
    }
  } finally {
    document.removeEventListener('click', listener);
  }
}
