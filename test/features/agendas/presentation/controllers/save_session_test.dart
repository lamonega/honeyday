import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/presentation/controllers/save_session.dart';

void main() {
  late SaveSession session;

  setUp(() => session = SaveSession());
  tearDown(() => session.dispose());

  test('starts saved and draining an empty queue completes', () async {
    expect(session.status, SaveStatus.saved);
    expect(session.error, isNull);
    await session.drain();
  });

  test('serializes writes and drain waits for the entire queue', () async {
    final gate = Completer<void>();
    final events = <String>[];
    final first = session.enqueue(() async {
      events.add('first started');
      await gate.future;
      events.add('first finished');
    });
    final second = session.enqueue(() async => events.add('second'));
    var drained = false;
    final drain = session.drain().then((_) => drained = true);

    await Future<void>.delayed(Duration.zero);
    expect(events, ['first started']);
    expect(session.status, SaveStatus.saving);
    expect(drained, isFalse);

    gate.complete();
    await Future.wait([first, second, drain]);
    expect(events, ['first started', 'first finished', 'second']);
    expect(session.status, SaveStatus.saved);
  });

  test('notifies listeners when saving starts and finishes', () async {
    final statuses = <SaveStatus>[];
    session.addListener(() => statuses.add(session.status));

    await session.enqueue(() async {});
    await session.drain();

    expect(statuses, [SaveStatus.saving, SaveStatus.saved]);
  });

  test(
    'failure pauses the queue and drain reports the original error',
    () async {
      final error = StateError('disk full');
      var followingRan = false;
      final failed = session.enqueue(() async => throw error);
      final failure = expectLater(failed, throwsA(same(error)));
      final following = session.enqueue(() async => followingRan = true);

      await failure;
      await expectLater(session.drain(), throwsA(same(error)));
      expect(session.status, SaveStatus.failed);
      expect(session.error, same(error));
      expect(followingRan, isFalse);

      // A failed operation remains at the head until retry succeeds.
      unawaited(following);
    },
  );

  test('retry replays the failed write before later writes', () async {
    var attempts = 0;
    final events = <String>[];
    final failed = session.enqueue(() async {
      events.add('attempt ${++attempts}');
      if (attempts == 1) throw StateError('temporary failure');
    });
    final failure = expectLater(failed, throwsStateError);
    final second = session.enqueue(() async => events.add('second'));
    await failure;
    final third = session.enqueue(() async => events.add('third'));

    await session.retry();
    await Future.wait([second, third]);

    expect(events, ['attempt 1', 'attempt 2', 'second', 'third']);
    expect(session.status, SaveStatus.saved);
    expect(session.error, isNull);
  });

  test('repeated retry failures keep subsequent writes paused', () async {
    var attempts = 0;
    var followingRan = false;
    final failed = session.enqueue(() async {
      if (++attempts < 3) throw StateError('offline');
    });
    final failure = expectLater(failed, throwsStateError);
    final following = session.enqueue(() async => followingRan = true);
    await failure;

    await expectLater(session.retry(), throwsStateError);
    expect(attempts, 2);
    expect(followingRan, isFalse);
    expect(session.status, SaveStatus.failed);

    await session.retry();
    await following;
    expect(attempts, 3);
    expect(followingRan, isTrue);
  });

  test('synchronous exceptions are handled like async failures', () async {
    var fail = true;
    final failed = session.enqueue(() {
      if (fail) throw StateError('synchronous failure');
      return Future<void>.value();
    });
    await expectLater(failed, throwsStateError);
    expect(session.status, SaveStatus.failed);

    fail = false;
    await session.retry();
    expect(session.status, SaveStatus.saved);
  });

  test('flushes registered editors before draining their writes', () async {
    var saved = false;
    Future<void>? pending;
    void flush() {
      pending = session.enqueue(() async => saved = true);
    }

    session
      ..registerEditor(flush)
      ..flushEditors();
    await session.drain();
    await pending;
    expect(saved, isTrue);

    session.unregisterEditor(flush);
    saved = false;
    session.flushEditors();
    expect(saved, isFalse);
  });

  test('editors may unregister during a flush', () {
    final flushed = <String>[];
    void first() {
      flushed.add('first');
      session.unregisterEditor(first);
    }

    session
      ..registerEditor(first)
      ..registerEditor(() => flushed.add('second'))
      ..flushEditors()
      ..flushEditors();

    expect(flushed, ['first', 'second', 'second']);
  });

  test('concurrent drains wait for the same pending writes', () async {
    final gate = Completer<void>();
    final write = session.enqueue(() => gate.future);
    final drains = [session.drain(), session.drain()];
    gate.complete();
    await Future.wait([write, ...drains]);
    expect(session.status, SaveStatus.saved);
  });

  test('retry on a healthy session does not repeat completed writes', () async {
    var writes = 0;
    await session.enqueue(() async => writes++);
    await session.retry();
    expect(writes, 1);
  });

  test('dispose rejects new writes but lets accepted writes finish', () async {
    final detached = SaveSession();
    final gate = Completer<void>();
    var notifications = 0;
    var followingRan = false;
    detached.addListener(() => notifications++);
    final first = detached.enqueue(() => gate.future);
    final second = detached.enqueue(() async => followingRan = true);
    detached.dispose();
    final notificationsAtDispose = notifications;

    expect(() => detached.enqueue(() async {}), throwsStateError);
    gate.complete();
    await Future.wait([first, second, detached.drain()]);

    expect(followingRan, isTrue);
    expect(notifications, notificationsAtDispose);
  });
}
