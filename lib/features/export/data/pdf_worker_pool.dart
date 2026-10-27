import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:honeyday/features/export/data/pdf_worker_factory.dart';
import 'package:honeyday/features/export/domain/export_cancellation.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

/// Resident bytes allowed for rasters waiting to be compressed.
///
/// Why: two A4 pages at 300 dpi (2 × 33.8 MB). A page takes 0.3-0.6 s to
/// rasterize against 0.15-0.35 s to compress, so two in flight is enough to
/// keep every worker fed while capping the export's memory at a small,
/// predictable number instead of one raster per page.
const int kDefaultInFlightByteBudget = 72 * 1024 * 1024;

/// One compression job: a page raster and its index in the document.
@immutable
class PdfWorkerRequest {
  /// Creates a request for the page at [pageIndex].
  const PdfWorkerRequest({required this.pageIndex, required this.page});

  /// Position of the page in the document (0-based, cover first).
  final int pageIndex;

  /// The raw raster to compress.
  final CapturedPage page;
}

/// Compresses one page raster into a PDF image stream.
typedef PdfWorkerCompress = Future<Uint8List> Function(PdfWorkerRequest request);

/// A single unit of compression capacity: an isolate on native platforms, a
/// direct call on web.
///
/// What: Runs one job at a time; the pool never hands a worker a second job
/// before the first settles, so a worker needs no queue of its own.
@immutable
class PdfCompressionWorker {
  /// Creates a worker able to run one job at a time.
  const PdfCompressionWorker({required this.compress, this.shutdown});

  /// Runs one job to completion.
  final PdfWorkerCompress compress;

  /// Releases the worker. Must tolerate being called while a job is running.
  final Future<void> Function()? shutdown;
}

/// Creates one worker of the pool.
///
/// Injected so the pool's scheduling, backpressure, ordering and cancellation
/// can be tested without spawning real isolates. Asynchronous because the
/// native implementation has to spawn one.
typedef PdfWorkerBuilder = Future<PdfCompressionWorker> Function(int index);

/// Callback invoked once a page's compressed stream is ready.
///
/// Called from whichever worker finished first, so two invocations can be in
/// flight at the same time. The consumer must therefore serialize its own
/// writes — `PdfWriter` does, with a single write queue.
typedef PdfStreamHandler = Future<void> Function(
  int pageIndex,
  Uint8List flateStream,
);

/// Schedules page rasters across a set of compression workers.
///
/// What: Bounds the work in flight by both worker count *and* total bytes, and
/// hands each finished stream to [onStream] in completion order, which is
/// generally not page order.
/// Why: the two bounds solve different problems. Worker count caps
/// parallelism; the byte budget caps residency, because every in-flight
/// raster is 34 MB at A4 300 dpi. Completion order is fine because a PDF's
/// cross-reference table maps object number to byte offset, so the writer can
/// emit objects in any order.
class PdfWorkerPool {
  /// Creates a pool.
  ///
  /// [maxWorkers] defaults to the platform's suggestion, which leaves a core
  /// for the frame pipeline.
  PdfWorkerPool({
    int? maxWorkers,
    this.inFlightByteBudget = kDefaultInFlightByteBudget,
    PdfWorkerBuilder? builder,
  }) : maxWorkers = maxWorkers ?? defaultPdfWorkerCount,
       _builder = builder ?? defaultPdfWorkerBuilder {
    if (this.maxWorkers <= 0) {
      throw ArgumentError.value(
        this.maxWorkers,
        'maxWorkers',
        'must be greater than zero',
      );
    }
    if (inFlightByteBudget <= 0) {
      throw ArgumentError.value(
        inFlightByteBudget,
        'inFlightByteBudget',
        'must be greater than zero',
      );
    }
  }

  /// Whether this platform can compress off the UI isolate at all.
  static bool get isSupported => pdfWorkerIsolatesSupported;

  /// Maximum number of jobs in flight.
  final int maxWorkers;

  /// Maximum total bytes of rasters in flight.
  final int inFlightByteBudget;

  final PdfWorkerBuilder _builder;

  final List<PdfCompressionWorker> _workers = [];
  final Queue<PdfCompressionWorker> _idle = Queue();
  final Queue<Completer<void>> _slotWaiters = Queue();

  Completer<void>? _drained;
  int _inFlightBytes = 0;
  int _inFlightCount = 0;
  Object? _failure;
  StackTrace? _failureStack;
  bool _started = false;
  bool _closeRequested = false;
  bool _cancelled = false;
  bool _disposed = false;

  /// Invoked for every finished stream, in completion order.
  PdfStreamHandler? onStream;

  /// Number of jobs submitted but not yet finished.
  @visibleForTesting
  int get inFlight => _inFlightCount;

  /// Bytes of raster currently waiting to be, or being, compressed.
  @visibleForTesting
  int get inFlightBytes => _inFlightBytes;

  /// Whether [start] has run and [dispose] has not.
  bool get isRunning => _workers.isNotEmpty;

  /// Creates the workers and arms [close]'s drain.
  Future<void> start() async {
    if (_disposed) {
      throw StateError('PdfWorkerPool.start() ran after dispose().');
    }
    if (_started) return;
    if (_closeRequested) {
      throw StateError('PdfWorkerPool.start() ran after close().');
    }

    _started = true;
    try {
      for (var index = 0; index < maxWorkers; index++) {
        final worker = await _builder(index);
        _workers.add(worker);
        _idle.add(worker);
      }
      // Do not complete this here. An empty pool is not drained until close()
      // explicitly asks for it; otherwise close() could race the first submit
      // and return while a worker was still compressing a page.
      _drained = Completer<void>();
    } on Object {
      for (final worker in _workers) {
        try {
          await worker.shutdown?.call();
        } on Object {
          // Preserve the startup error; cleanup is best effort.
        }
      }
      _workers.clear();
      _idle.clear();
      _started = false;
      rethrow;
    }
  }

  /// Hands the raster of page [pageIndex] to the next free worker, waiting
  /// for capacity when the pool is saturated.
  ///
  /// Throws [ExportCancelled] once the pool was cancelled. Worker failures do
  /// not surface here: they are sticky and re-raised by [close] so the caller
  /// sees the real error instead of a hang.
  Future<void> submit(
    int pageIndex,
    CapturedPage page, {
    bool Function()? isCancelled,
  }) async {
    if (_cancelled) throw const ExportCancelled();
    if (_disposed || _closeRequested) {
      throw StateError('PdfWorkerPool.submit() ran after close/dispose.');
    }
    if (_workers.isEmpty) {
      throw StateError('PdfWorkerPool.submit() ran before start().');
    }

    final bytes = page.byteLength;
    await _acquire(bytes, isCancelled);
    if (_cancelled || (isCancelled?.call() ?? false)) {
      _release(bytes, null);
      throw const ExportCancelled();
    }
    if (_disposed || _closeRequested) {
      _release(bytes, null);
      throw StateError('PdfWorkerPool.submit() ran after close/dispose.');
    }
    // `_acquire` guarantees a free worker: every finished job returns its
    // worker to `_idle`, so `_idle.length == maxWorkers - _inFlightCount`.
    final worker = _idle.removeFirst();
    unawaited(_run(worker, pageIndex, page, bytes));
  }

  /// Waits until every submitted page has been handed to [onStream].
  ///
  /// [isCancelled], when supplied, is checked periodically while workers drain
  /// so a user cancellation does not have to wait for a slow final page.
  Future<void> close({bool Function()? isCancelled}) async {
    if (_cancelled) throw const ExportCancelled();
    if (!_started || _disposed) {
      throw StateError('PdfWorkerPool.close() ran before start().');
    }

    _closeRequested = true;
    _maybeDrain();
    final drained = _drained!;
    while (!drained.isCompleted) {
      if (isCancelled?.call() ?? false) throw const ExportCancelled();
      if (isCancelled == null) {
        await drained.future;
        break;
      }
      await _waitForDrainOrPoll(drained);
    }
    if (isCancelled?.call() ?? false) throw const ExportCancelled();
    final failure = _failure;
    if (failure != null) {
      Error.throwWithStackTrace(failure, _failureStack ?? StackTrace.current);
    }
  }

  /// Stops the pool. With [cancel] the queue is dropped and nothing further is
  /// delivered, which is what makes cancelling a running export immediate
  /// instead of "at the next page boundary".
  Future<void> dispose({bool cancel = false}) async {
    if (_disposed) return;
    _disposed = true;
    if (cancel) _cancelled = true;
    _closeRequested = true;
    _wakeAll();

    final workers = List<PdfCompressionWorker>.of(_workers);
    _workers.clear();
    _idle.clear();
    // Running jobs are deliberately abandoned after their workers are killed.
    // Their finally blocks observe _disposed and do not decrement these
    // counters a second time.
    _inFlightBytes = 0;
    _inFlightCount = 0;
    final drained = _drained;
    if (drained != null && !drained.isCompleted) drained.complete();

    Object? firstError;
    StackTrace? firstStack;
    for (final worker in workers) {
      try {
        await worker.shutdown?.call();
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStack ??= stackTrace;
      }
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack ?? StackTrace.current);
    }
  }

  Future<void> _waitForDrainOrPoll(Completer<void> target) async {
    final poll = Completer<void>();
    final timer = Timer(const Duration(milliseconds: 25), poll.complete);
    try {
      await Future.any<void>([target.future, poll.future]);
    } finally {
      timer.cancel();
    }
  }

  void _throwIfFailed() {
    final failure = _failure;
    if (failure != null) {
      Error.throwWithStackTrace(
        failure,
        _failureStack ?? StackTrace.current,
      );
    }
  }

  /// Waits for all submitted work, including stream writing, to finish.
  /// The pool remains open for another submission afterward.
  Future<void> waitUntilIdle({bool Function()? isCancelled}) async {
    while (true) {
      if (_cancelled || (isCancelled?.call() ?? false)) {
        throw const ExportCancelled();
      }
      if (!_started || _disposed || _closeRequested) {
        throw StateError('Cannot wait on an inactive PDF pool.');
      }
      _throwIfFailed();
      if (_inFlightCount == 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> _acquire(int bytes, bool Function()? isCancelled) async {
    final oversized = bytes > inFlightByteBudget;
    while (true) {
      _throwIfFailed();
      if (_cancelled || (isCancelled?.call() ?? false)) {
        throw const ExportCancelled();
      }
      if (_disposed || _closeRequested) {
        throw StateError('PdfWorkerPool.submit() ran after close/dispose.');
      }
      final hasRoom = _inFlightCount < maxWorkers &&
          (oversized
              ? _inFlightCount == 0
              : _inFlightBytes + bytes <= inFlightByteBudget);
      if (hasRoom) {
        _inFlightBytes += bytes;
        _inFlightCount++;
        return;
      }
      // A page larger than the whole budget is admitted alone rather than
      // deadlocking; anything else waits for a slot to free up. Poll the
      // caller's cancellation signal while parked so a full pool cannot turn
      // Cancel into another long wait.
      final waiter = Completer<void>();
      _slotWaiters.add(waiter);
      try {
        while (!waiter.isCompleted) {
          if (isCancelled?.call() ?? false) {
            _slotWaiters.remove(waiter);
            throw const ExportCancelled();
          }
          await _waitForDrainOrPoll(waiter);
        }
      } finally {
        if (_slotWaiters.contains(waiter)) _slotWaiters.remove(waiter);
      }
    }
  }

  Future<void> _run(
    PdfCompressionWorker worker,
    int pageIndex,
    CapturedPage page,
    int bytes,
  ) async {
    try {
      final stream = await worker.compress(
        PdfWorkerRequest(pageIndex: pageIndex, page: page),
      );
      if (!_cancelled && !_disposed) await onStream?.call(pageIndex, stream);
    } on Object catch (error, stackTrace) {
      if (!_disposed) {
        _failure ??= error;
        _failureStack ??= stackTrace;
      }
    } finally {
      // dispose() kills workers and resets the counters. Do not let a late
      // completion from a killed isolate make them negative or return a dead
      // worker to the idle queue.
      if (!_disposed) {
        _release(bytes, _cancelled ? null : worker);
        _maybeDrain();
      }
    }
  }

  void _release(int bytes, PdfCompressionWorker? worker) {
    if (_disposed) return;
    _inFlightBytes -= bytes;
    _inFlightCount--;
    if (worker != null) _idle.add(worker);
    if (_slotWaiters.isNotEmpty) {
      _slotWaiters.removeFirst().complete();
    }
  }

  void _wakeAll() {
    while (_slotWaiters.isNotEmpty) {
      _slotWaiters.removeFirst().complete();
    }
  }

  void _maybeDrain() {
    final drained = _drained;
    if (drained == null || drained.isCompleted || !_closeRequested) return;
    if (_inFlightCount > 0) return;
    drained.complete();
  }
}
