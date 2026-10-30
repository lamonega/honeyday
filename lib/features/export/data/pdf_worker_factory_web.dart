import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/domain/export_cancellation.dart';
import 'package:web/web.dart' as web;

@JS()
extension type _TransferableBytes(JSUint8Array _) implements JSUint8Array {
  external JSArrayBuffer get buffer;
}

@JS()
extension type _WorkerRequest._(JSObject _) implements JSObject {
  external factory _WorkerRequest({
    required int pageIndex,
    required int width,
    required int height,
    required JSUint8Array rgba,
  });
}

@JS()
extension type _WorkerReply(JSObject _) implements JSObject {
  external int get pageIndex;
  external JSUint8Array? get bytes;
  external String? get error;
}

/// Browser Web Workers are real background threads, but not Dart isolates.
const bool pdfWorkerIsolatesSupported = false;

int get defaultPdfWorkerCount => 1;

PdfWorkerBuilder get defaultPdfWorkerBuilder =>
    (index) async => _BrowserPdfWorker().handle;

class _BrowserPdfWorker {
  _BrowserPdfWorker()
    : _worker = web.Worker(
        Uri.parse(web.document.baseURI)
            .resolve('pdf_export_worker.js')
            .toString()
            .toJS,
      ) {
    _worker.onmessage = ((web.MessageEvent event) {
      final pending = _pending;
      if (pending == null || pending.isCompleted) return;

      final JSObject data;
      try {
        data = event.data as JSObject;
      } on Object catch (error) {
        _fail(error);
        return;
      }
      try {
        final reply = _WorkerReply(data);
        if (reply.pageIndex != _pageIndex) {
          _fail(StateError('PDF Web Worker replied for the wrong page.'));
          return;
        }

        final error = reply.error;
        final bytes = reply.bytes;
        final output = bytes?.toDart;
        _pending = null;
        _pageIndex = null;

        if (error != null) {
          pending.completeError(StateError(error));
        } else if (output == null) {
          pending.completeError(
            StateError('PDF Web Worker returned no compressed bytes.'),
          );
        } else {
          pending.complete(output);
        }
      } on Object catch (error) {
        _fail(error);
      }
    }).toJS;

    _worker.onerror = ((web.Event event) {
      _fail(StateError('PDF Web Worker failed to load or execute.'));
    }).toJS;

    _worker.onmessageerror = ((web.MessageEvent event) {
      _fail(StateError('Invalid message from PDF Web Worker.'));
    }).toJS;
  }

  final web.Worker _worker;
  Completer<Uint8List>? _pending;
  int? _pageIndex;
  Object? _failure;
  bool _closed = false;

  PdfCompressionWorker get handle =>
      PdfCompressionWorker(compress: _compress, shutdown: _shutdown);

  Future<Uint8List> _compress(PdfWorkerRequest request) async {
    if (_closed) throw const ExportCancelled();
    final failure = _failure;
    if (failure != null) throw failure;
    if (_pending != null) {
      throw StateError('Overlapping browser PDF compression jobs.');
    }

    final pending = Completer<Uint8List>();
    _pending = pending;
    _pageIndex = request.pageIndex;

    try {
      // `toJS` creates an owned JS typed array; transfer its backing buffer so
      // browser-to-worker delivery does not clone another full page raster.
      final rgba = _TransferableBytes(request.page.rgba.toJS);
      _worker.postMessage(
        _WorkerRequest(
          pageIndex: request.pageIndex,
          width: request.page.width,
          height: request.page.height,
          rgba: rgba,
        ),
        <JSAny?>[rgba.buffer].toJS,
      );
    } on Object catch (error) {
      _fail(error);
    }

    return pending.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        final error = TimeoutException('PDF Web Worker timed out.');
        _fail(error);
        _worker.terminate();
        throw error;
      },
    );
  }

  void _fail(Object error) {
    _failure ??= error;
    final pending = _pending;
    _pending = null;
    _pageIndex = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(_failure!);
    }
  }

  Future<void> _shutdown() async {
    if (_closed) return;
    _fail(const ExportCancelled());
    _closed = true;
    _worker
      ..onmessage = null
      ..onerror = null
      ..onmessageerror = null
      ..terminate();
  }
}
