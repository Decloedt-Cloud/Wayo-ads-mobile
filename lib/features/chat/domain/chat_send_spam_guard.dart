import 'dart:math' as math;

/// Client-side flood control for chat text sends (consecutive messages).
///
/// When the user exceeds [maxMessagesInWindow] within [windowDuration], the next
/// send attempt starts a cooldown; repeat violations lengthen the wait (capped).
class ChatSendSpamGuard {
  ChatSendSpamGuard({
    this.maxMessagesInWindow = 4,
    this.windowDuration = const Duration(seconds: 8),
    this.baseCooldown = const Duration(seconds: 8),
    this.maxCooldown = const Duration(seconds: 45),
  });

  final int maxMessagesInWindow;
  final Duration windowDuration;
  final Duration baseCooldown;
  final Duration maxCooldown;

  final List<DateTime> _sendTimes = [];
  DateTime? _cooldownUntil;
  Duration? _activeCooldownTotal;
  int _violationStreak = 0;

  /// Remaining wait time, or `null` when sends are allowed.
  Duration? get remainingCooldown {
    final until = _cooldownUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    if (!left.isNegative && left > Duration.zero) {
      return left;
    }
    _cooldownUntil = null;
    _activeCooldownTotal = null;
    return null;
  }

  Duration? get activeCooldownTotal => _activeCooldownTotal;

  bool get isCoolingDown => remainingCooldown != null;

  /// Returns remaining cooldown when blocked; `null` if the send may proceed.
  Duration? checkBeforeSend() {
    final active = remainingCooldown;
    if (active != null) return active;

    final now = DateTime.now();
    _pruneOld(now);
    if (_sendTimes.length >= maxMessagesInWindow) {
      return _startCooldown(now);
    }
    return null;
  }

  /// Call when a user message was actually queued/sent (optimistic or confirmed).
  void recordSend() {
    final now = DateTime.now();
    _pruneOld(now);
    _sendTimes.add(now);
  }

  Duration _startCooldown(DateTime now) {
    _violationStreak = math.min(_violationStreak + 1, 12);
    final extra = (_violationStreak - 1) * 5;
    final seconds = math.min(
      maxCooldown.inSeconds,
      baseCooldown.inSeconds + extra,
    );
    _activeCooldownTotal = Duration(seconds: seconds);
    _cooldownUntil = now.add(_activeCooldownTotal!);
    _sendTimes.clear();
    return _activeCooldownTotal!;
  }

  void _pruneOld(DateTime now) {
    _sendTimes.removeWhere((t) => now.difference(t) > windowDuration);
  }
}
