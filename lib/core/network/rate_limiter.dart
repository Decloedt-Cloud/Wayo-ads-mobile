/// Simple per-key spacing to avoid API spam (token bucket style: one call per interval).
final class RateLimiter {
  RateLimiter({required this.minInterval});

  final Duration minInterval;
  final Map<String, DateTime> _lastCall = {};

  bool canCall(String key) {
    final last = _lastCall[key];
    if (last == null) {
      return true;
    }
    return DateTime.now().difference(last) >= minInterval;
  }

  void mark(String key) => _lastCall[key] = DateTime.now();

  /// Clears spacing state (call after login / logout so a new session is never
  /// blocked by timestamps from the previous one).
  void reset() => _lastCall.clear();
}
