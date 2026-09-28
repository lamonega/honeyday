import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:honeyday/features/export/data/pdf_worker.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/domain/export_cancellation.dart';

/// Whether compression can run off the UI isolate.
///
/// Always true here: every `dart:io` platform has `Isolate.spawn`.
const bool pdfWorkerIsolatesSupported = true;

/// Workers to keep alive: `min(4, cores - 1)`.
///
/// Why: the frame pipeline lives on the UI isolate, so the last core is left
/// to it. Past four workers more stops helping — a page takes ~0.2 s to
/// compress while the rasterizer feeding the queue is the real bottleneck.
int get defaultPdfWorkerCount {
  final cores = Platform.numberOfProcessors;
  if (cores <= 2) return 1;
  return (cores - 1).clamp(1, 4);
}

/// Builds a worker backed by a fresh isolate.
PdfWorkerBuilder get defaultPdfWorkerBuilder => IsolatePdfWorker.spawn;

/// Spawns compression isolates for a [PdfWorkerPool].
///
/// What: one isolate per worker, each running [pdfWorkerEntryPoint] on a
/// shared command port, answering on a per-worker port.
/// Why: the pool stays a pure scheduler that knows nothing about ports, and
/// killing an isolate in `shutdown` makes cancellation instant even when a
/// page is mid-deflate.
class IsolatePdfWorker {
  IsolatePdfWorker._(
    this._isolate,
    this._commands,
    this._answers,
    this._errors,
    this._exits,
  );

  /// Spawns worker number [index] and waits until it is ready to take jobs.
  static Future<PdfCompressionWorker> spawn(int index) async {
    final answers = ReceivePort();
    final errors = ReceivePort();
    final exits = ReceivePort();
    final ready = Completer<SendPort>();
    _IsolateBackedWorker? worker;

    void failStartup(Object error, [StackTrace? stackTrace]) {
      if (!ready.isCompleted) ready.completeError(error, stackTrace);
    }

    answers.listen((message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
        return;
      }
      final currentWorker = worker;
      if (currentWorker != null) {
        currentWorker._onReply(message);
      } else {
        failStartup(StateError('Export worker sent data before becoming ready.'));
      }
    });
    errors.listen((message) {
      if (ready.isCompleted) return;
      final parts = message is List ? message : const <Object?>[];
      failStartup(
        StateError('Export worker failed during startup: $message'),
        parts.length > 1 && parts[1] is String
            ? StackTrace.fromString(parts[1]! as String)
            : null,
      );
    });
    exits.listen((_) {
      if (!ready.isCompleted) {
        failStartup(StateError('Export worker exited during startup.'));
      }
    });

    Isolate? isolate;
    try {
      isolate = await Isolate.spawn(
        pdfWorkerEntryPoint,
        answers.sendPort,
        onError: errors.sendPort,
        onExit: exits.sendPort,
        debugName: 'honeyday-export-$index',
      );
      final commands = await ready.future;
      worker = _IsolateBackedWorker(
        IsolatePdfWorker._(isolate, commands, answers, errors, exits),
      );
      return worker.handle;
    } on Object {
      answers.close();
      errors.close();
      exits.close();
      isolate?.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _answers;
  final ReceivePort _errors;
  final ReceivePort _exits;
}

/// The pool-facing half of one isolate-backed worker.
class _IsolateBackedWorker {
  _IsolateBackedWorker(this._worker);

  final IsolatePdfWorker _worker;

  int? _pageIndex;
  Completer<Uint8List>? _pending;
  bool _shutdown = false;

  PdfCompressionWorker get handle => PdfCompressionWorker(
    compress: _compress,
    shutdown: _shutdownWorker,
  );

  Future<Uint8List> _compress(PdfWorkerRequest request) {
    if (_shutdown) return Future<Uint8List>.error(const ExportCancelled());
    if (_pending != null) {
      return Future<Uint8List>.error(
        StateError('An export worker received overlapping jobs.'),
      );
    }

    final completer = Completer<Uint8List>();
    _pageIndex = request.pageIndex;
    _pending = completer;
    try {
      // TransferableTypedData hands the raster over without another Dart
      // heap copy. The isolate materializes it only for its own lifetime.
      _worker._commands.send(<Object?>[
        request.pageIndex,
        TransferableTypedData.fromList(<TypedData>[request.page.rgba]),
        request.page.width,
        request.page.height,
      ]);
    } on Object catch (error, stackTrace) {
      _pending = null;
      _pageIndex = null;
      completer.completeError(error, stackTrace);
    }
    return completer.future;
  }

  void _onReply(Object? reply) {
    final completer = _pending;
    if (completer == null || completer.isCompleted) return;
    if (reply is! List || reply.isEmpty || reply.first != _pageIndex) return;

    _pending = null;
    _pageIndex = null;
    final payload = reply.length > 1 ? reply[1] : null;
    if (payload is Uint8List) {
      completer.complete(payload);
    } else {
      final detail = reply.length > 2 ? reply[2] : null;
      completer.completeError(
        StateError('Export worker failed: $payload\n$detail'),
      );
    }
  }

  Future<void> _shutdownWorker() async {
    if (_shutdown) return;
    _shutdown = true;

    final pending = _pending;
    _pending = null;
    _pageIndex = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const ExportCancelled());
    }

    _worker._answers.close();
    _worker._errors.close();
    _worker._exits.close();
    _worker._isolate.kill(priority: Isolate.immediate);
  }
}
