import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/data/pdf_worker_pool.dart';
import 'package:honeyday/features/export/domain/export_cancellation.dart';
import 'package:honeyday/features/export/domain/export_capture.dart';

/// A page whose [CapturedPage.byteLength] is exactly [bytes].
///
/// Why it matters: the pool throttles on `byteLength`, so a fake page that
/// quietly had a different size would make the capacity tests meaningless.
CapturedPage pageOfBytes(int bytes) {
  final width = bytes ~/ 4;
  final page = CapturedPage(
    rgba: Uint8List(width * 4),
    width: width,
    height: 1,
  );
  assert(page.byteLength == bytes, 'fake page must be exactly $bytes bytes');
  return page;
}

/// A job handed to a fake worker, still waiting for the test to finish it.
class _Job {
  _Job(this.request, this.workerIndex);

  final PdfWorkerRequest request;
  final int workerIndex;
  final Completer<Uint8List> completer = Completer<Uint8List>();
}

/// A worker whose jobs the test completes by hand.
///
/// Why not real isolates: the pool's contract is about scheduling, capacity
/// and cancellation, and those are far easier to pin down when the test owns
/// the moment each job finishes. Real isolates are exercised by the
/// responsiveness test and the benchmark.
class _FakeWorker {
  _FakeWorker(this.index, this.jobs);

  final int index;
  final List<_Job> jobs;
  bool shutDown = false;
  _Job? current;

  /// The pool-facing view of this worker.
  PdfCompressionWorker get handle => PdfCompressionWorker(
    compress: (request) {
      final job = _Job(request, index);
      jobs.add(job);
      current = job;
      return job.completer.future;
    },
    shutdown: () async => shutDown = true,
  );
}

/// A pool of fake workers plus the bookkeeping the assertions need.
class _Harness {
  _Harness({this.maxWorkers = 2, this.inFlightByteBudget = 1 << 20});

  final int maxWorkers;
  final int inFlightByteBudget;
  final List<_Job> jobs = [];
  final List<_FakeWorker> workers = [];
  final List<int> delivered = [];

  late final PdfWorkerPool pool;

  /// How many jobs have reached a worker.
  int get started => jobs.length;

  /// How many jobs are still running.
  int get busy => workers.where((w) => w.current != null).length;

  PdfWorkerPool build({int workerCount = 2}) {
    workers
      ..clear()
      ..addAll([for (var i = 0; i < workerCount; i++) _FakeWorker(i, jobs)]);
    pool = PdfWorkerPool(
      maxWorkers: maxWorkers,
      inFlightByteBudget: inFlightByteBudget,
      builder: (index) async => workers[index].handle,
    );
    pool.onStream = (index, stream) async => delivered.add(index);
    return pool;
  }

  /// Completes the oldest unfinished job.
  void completeNext() {
    final job = jobs.firstWhere((j) => !j.completer.isCompleted);
    workers[job.workerIndex].current = null;
    job.completer.complete(Uint8List.fromList([job.request.pageIndex]));
  }

  /// Fails the oldest unfinished job.
  void failNext(Object error) {
    final job = jobs.firstWhere((j) => !j.completer.isCompleted);
    workers[job.workerIndex].current = null;
    job.completer.completeError(error);
  }

  /// Completes every job that has *already* reached a worker, one microtask
  /// apart so the pool can re-arm its slots between them.
  Future<void> completeStarted() async {
    while (jobs.any((j) => !j.completer.isCompleted)) {
      completeNext();
      await Future<void>.delayed(Duration.zero);
    }
  }
}

void main() {
  test('reports support and picks a sane default worker count', () {
    expect(PdfWorkerPool.isSupported, isA<bool>());
    // The default leaves a core for the frame pipeline and never exceeds 4.
    expect(PdfWorkerPool().maxWorkers, inInclusiveRange(1, 4));
  });

  test('delivers every submitted stream exactly once', () async {
    final harness = _Harness();
    final pool = harness.build();
    await pool.start();

    for (var index = 0; index < 4; index++) {
      await pool.submit(index, pageOfBytes(4));
      await harness.completeStarted();
    }
    await pool.close();

    expect(harness.delivered, [0, 1, 2, 3]);
    expect(_workersShutDown(harness), isFalse);

    await pool.dispose();
    expect(_workersShutDown(harness), isTrue);
  });

  test('starts no more jobs than there are workers', () async {
    final harness = _Harness();
    final pool = harness.build();
    await pool.start();

    await pool.submit(0, pageOfBytes(4));
    await pool.submit(1, pageOfBytes(4));
    expect(harness.started, 2, reason: 'both workers are busy');

    // The third submit must park: both workers are still running.
    var thirdDone = false;
    final third = pool.submit(2, pageOfBytes(4)).then((_) => thirdDone = true);
    await Future<void>.delayed(Duration.zero);
    expect(harness.started, 2, reason: 'the third page waits for a free slot');
    expect(thirdDone, isFalse);

    await harness.completeStarted();
    await third;
    await pool.close();
    expect(harness.started, 3);
    await pool.dispose();
  });

  test('caps resident bytes as well as worker count', () async {
    // Four workers, room for exactly one 4000-byte page.
    final harness = _Harness(maxWorkers: 4, inFlightByteBudget: 4000);
    final pool = harness.build(workerCount: 4);
    await pool.start();

    await pool.submit(0, pageOfBytes(4000));
    // A second page of the same size would double the resident bytes, so it
    // must wait even though three workers are idle.
    var admitted = false;
    final second = pool.submit(1, pageOfBytes(4000)).then((_) => admitted = true);
    await Future<void>.delayed(Duration.zero);
    expect(admitted, isFalse, reason: 'the byte budget must throttle admission');
    expect(harness.started, 1);

    await harness.completeStarted();
    await second;
    await pool.close();
    expect(harness.started, 2);
    await pool.dispose();
  });

  test('admits an oversized page alone instead of deadlocking', () async {
    final harness = _Harness(inFlightByteBudget: 16);
    final pool = harness.build();
    await pool.start();

    // 4000 bytes into a 16-byte budget: it can only ever run by itself.
    await pool.submit(0, pageOfBytes(4000));
    await harness.completeStarted();
    await pool.close();
    expect(harness.started, 1);
    await pool.dispose();
  });

  test('delivers streams in completion order, not page order', () async {
    final harness = _Harness();
    final pool = harness.build();
    await pool.start();

    await pool.submit(0, pageOfBytes(4));
    await pool.submit(1, pageOfBytes(4));
    expect(harness.started, 2);

    // The second job finishes first, so page 1 must be delivered before 0.
    final second = harness.jobs[1];
    harness.workers[second.workerIndex].current = null;
    second.completer.complete(Uint8List.fromList([1]));
    await Future<void>.delayed(Duration.zero);
    harness.completeNext();
    await Future<void>.delayed(Duration.zero);
    await pool.close();

    expect(harness.delivered, [1, 0]);
    await pool.dispose();
  });

  test('may deliver two streams at once, so the consumer must serialize', () async {
    // Documents the contract rather than defending against it: the pool is a
    // scheduler and knows nothing about the byte stream. Two workers finishing
    // together means two overlapping `onStream` calls, which is why
    // `PdfWriter` keeps a single write queue.
    final harness = _Harness();
    final pool = harness.build();
    await pool.start();

    var inside = 0;
    var maxInside = 0;
    pool.onStream = (index, stream) async {
      inside++;
      maxInside = maxInside > inside ? maxInside : inside;
      await Future<void>.delayed(Duration.zero);
      inside--;
    };

    await pool.submit(0, pageOfBytes(4));
    await pool.submit(1, pageOfBytes(4));
    await harness.completeStarted();
    await pool.close();

    expect(harness.jobs, hasLength(2));
    await pool.dispose();
    // No assertion on `maxInside`: it documents that overlap is permitted,
    // and pinning it to 1 or 2 would make the test machine-dependent.
    expect(maxInside, inInclusiveRange(1, 2));
  });

  test('propagates a worker failure out of close', () async {
    final harness = _Harness(maxWorkers: 1);
    final pool = harness.build(workerCount: 1);
    await pool.start();

    await pool.submit(0, pageOfBytes(4));
    harness.failNext(StateError('boom'));
    await expectLater(pool.close(), throwsStateError);
    await pool.dispose();
  });

  test('cancellation drops the queue and delivers nothing more', () async {
    final harness = _Harness(maxWorkers: 1);
    final pool = harness.build(workerCount: 1);
    await pool.start();

    await pool.submit(0, pageOfBytes(4));
    final parked = pool.submit(1, pageOfBytes(4));
    // Attach the expectation *before* cancelling: otherwise the rejection
    // lands before anyone is listening and the zone reports it as unhandled.
    final parkedFails = expectLater(parked, throwsA(isA<ExportCancelled>()));

    await pool.dispose(cancel: true);
    await parkedFails;

    // The job that was already running resolves into the void.
    harness.completeNext();
    await Future<void>.delayed(Duration.zero);
    expect(
      harness.delivered,
      isEmpty,
      reason: 'nothing is delivered after cancelling',
    );
    await expectLater(pool.close(), throwsA(isA<ExportCancelled>()));
  });

  test('rejects submissions before start', () async {
    final harness = _Harness();
    final pool = harness.build(workerCount: 1);

    await expectLater(pool.submit(0, pageOfBytes(4)), throwsStateError);
  });

  test('rejects submissions after cancelling', () async {
    final harness = _Harness(maxWorkers: 1);
    final pool = harness.build(workerCount: 1);
    await pool.start();
    await pool.dispose(cancel: true);

    await expectLater(
      pool.submit(0, pageOfBytes(4)),
      throwsA(isA<ExportCancelled>()),
    );
  });

  test('dispose is idempotent', () async {
    final harness = _Harness(maxWorkers: 1);
    final pool = harness.build(workerCount: 1);
    await pool.start();

    await pool.dispose();
    await pool.dispose();

    expect(_workersShutDown(harness), isTrue);
    expect(pool.isRunning, isFalse);
  });

  test('start is idempotent', () async {
    final harness = _Harness();
    final pool = harness.build();

    await pool.start();
    await pool.start();

    expect(harness.workers, hasLength(2));
    await pool.dispose();
  });
}

bool _workersShutDown(_Harness harness) =>
    harness.workers.every((w) => w.shutDown);
