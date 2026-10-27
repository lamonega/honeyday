import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum SaveStatus { saved, saving, failed }

class _PendingWrite {
  _PendingWrite(this.operation);

  final Future<void> Function() operation;
  final Completer<void> completion = Completer<void>();
}

/// Ordered, retryable write queue for one open agenda viewer.
class SaveSession extends ChangeNotifier {
  final Queue<_PendingWrite> _writes = Queue<_PendingWrite>();
  final Set<VoidCallback> _flushers = {};
  bool _running = false;
  bool _disposed = false;
  Object? _error;
  StackTrace? _errorStack;
  Future<void>? _worker;

  Object? get error => _error;

  SaveStatus get status {
    if (_error != null) return SaveStatus.failed;
    if (_running || _writes.isNotEmpty) return SaveStatus.saving;
    return SaveStatus.saved;
  }

  void registerEditor(VoidCallback flush) => _flushers.add(flush);
  void unregisterEditor(VoidCallback flush) => _flushers.remove(flush);

  void flushEditors() {
    for (final flush in List<VoidCallback>.of(_flushers)) {
      flush();
    }
  }

  Future<void> enqueue(Future<void> Function() operation) {
    if (_disposed) throw StateError('SaveSession is disposed.');
    final write = _PendingWrite(operation);
    _writes.addLast(write);
    _startWorker();
    return write.completion.future;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _startWorker() {
    if (_running || _error != null || _writes.isEmpty) return;
    _running = true;
    _worker = _run();
    _notify();
  }

  Future<void> _run() async {
    try {
      while (_writes.isNotEmpty) {
        final write = _writes.first;
        try {
          await write.operation();
        } on Object catch (error, stack) {
          _error = error;
          _errorStack = stack;
          if (!write.completion.isCompleted) {
            write.completion.completeError(error, stack);
          }
          return;
        }
        _writes.removeFirst();
        if (!write.completion.isCompleted) write.completion.complete();
      }
    } finally {
      _running = false;
      _notify();
    }
  }

  Future<void> drain() async {
    while (true) {
      final error = _error;
      if (error != null) Error.throwWithStackTrace(error, _errorStack!);
      if (!_running && _writes.isEmpty) return;
      _startWorker();
      await _worker;
    }
  }

  Future<void> retry() async {
    _error = null;
    _errorStack = null;
    _startWorker();
    await drain();
  }

  @override
  void dispose() {
    _disposed = true;
    _flushers.clear();
    super.dispose();
  }
}
