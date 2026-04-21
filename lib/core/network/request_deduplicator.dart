import 'dart:async';

/// Coalesces identical in-flight async work into a single network call.
///
/// Callers always await the same outward [Future] (backed by a [Completer]), so
/// cleanup runs once and errors are not double-reported across listeners.
final class RequestDeduplicator {
  final Map<String, Future<dynamic>> _inflight = {};

  Future<T> run<T>(String key, Future<T> Function() task) {
    final existing = _inflight[key];
    if (existing != null) {
      return existing as Future<T>;
    }

    final completer = Completer<T>();
    _inflight[key] = completer.future;

    Future<T> inner;
    try {
      inner = task();
    } catch (e, st) {
      _inflight.remove(key);
      completer.completeError(e, st);
      return completer.future;
    }

    inner.then<void>(
      (value) {
        _inflight.remove(key);
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      },
      onError: (Object e, StackTrace st) {
        _inflight.remove(key);
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      },
    );

    return completer.future;
  }
}
