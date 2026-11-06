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
    Object? earlyFailure;
    StackTrace? earlyFailureStack;

    void failWorker(Object error, StackTrace stackTrace) {
      final current = worker;
      if (current != null) {
        current._fail(error, stackTrace);
      } else if (!ready.isCompleted) {
        ready.completeError(error, stackTrace);
      } else {
        earlyFailure ??= error;
        earlyFailureStack ??= stackTrace;
      }
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
        failWorker(
          StateError('Export worker sent data before becoming ready.'),
          StackTrace.current,
        );
      }
    });
    errors.listen((message) {
      final parts = message is List ? message : const <Object?>[];
      failWorker(
        StateError('Export worker failed: $message'),
        parts.length > 1 && parts[1] is String
            ? StackTrace.fromString(parts[1]! as String)
            : StackTrace.current,
      );
    });
    exits.listen((_) {
      failWorker(
        StateError('Export worker exited unexpectedly.'),
        StackTrace.current,
      );
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
      final commands = await ready.future.timeout(const Duration(seconds: 10));
      worker = _IsolateBackedWorker(
        IsolatePdfWorker._(isolate, commands, answers, errors, exits),
      );
      final earlyError = earlyFailure;
      if (earlyError != null) {
        worker._fail(earlyError, earlyFailureStack ?? StackTrace.current);
      }
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
  Object? _failure;
  StackTrace? _failureStack;
  bool _shutdown = false;

  PdfCompressionWorker get handle =>
      PdfCompressionWorker(compress: _compress, shutdown: _shutdownWorker);

  Future<Uint8List> _compress(PdfWorkerRequest request) {
    if (_shutdown) return Future<Uint8List>.error(const ExportCancelled());
    final failure = _failure;
    if (failure != null) {
      return Future<Uint8List>.error(failure, _failureStack);
    }
    if (_pending != null) {
      return Future<Uint8List>.error(
        StateError('An export worker received overlapping jobs.'),
      );
    }

    final completer = Completer<Uint8List>();
    _pageIndex = request.pageIndex;
    _pending = completer;
    try {
      // Creating TransferableTypedData copies the bytes once on this isolate;
      // sending it is constant-time, and the worker materializes the transferred
      // payload only for the lifetime of its compression job.
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
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        final error = TimeoutException('PDF compression exceeded 60 seconds.');
        _fail(error, StackTrace.current);
        _worker._isolate.kill(priority: Isolate.immediate);
        throw error;
      },
    );
  }

  void _fail(Object error, StackTrace stackTrace) {
    if (_shutdown) return;
    _failure ??= error;
    _failureStack ??= stackTrace;

    final pending = _pending;
    _pending = null;
    _pageIndex = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(_failure!, _failureStack);
    }
  }

  void _onReply(Object? reply) {
    final completer = _pending;
    if (completer == null || completer.isCompleted) return;
    if (reply is! List || reply.isEmpty || reply.first != _pageIndex) {
      _fail(
        StateError('Export worker replied with an invalid page index.'),
        StackTrace.current,
      );
      return;
    }

    final payload = reply.length > 1 ? reply[1] : null;
    if (payload is Uint8List) {
      _pending = null;
      _pageIndex = null;
      completer.complete(payload);
    } else {
      final detail = reply.length > 2 ? reply[2] : null;
      _fail(
        StateError('Export worker failed: $payload\n$detail'),
        StackTrace.current,
      );
    }
  }

  Future<void> _shutdownWorker() async {
    if (_shutdown) return;
    _fail(const ExportCancelled(), StackTrace.current);
    _shutdown = true;

    _worker._answers.close();
    _worker._errors.close();
    _worker._exits.close();
    _worker._isolate.kill(priority: Isolate.immediate);
  }
}
