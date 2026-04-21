import 'package:flutter/animation.dart';

/// Shared timeline for the "Signal Ignition" splash (master controller 0→1).
abstract final class SplashSequence {
  static const totalDuration = Duration(milliseconds: 2500);

  static const secondLaunchDuration = Duration(milliseconds: 1000);

  static const reducedMotionDuration = Duration(milliseconds: 400);

  /// Intervals 0→1 on [totalDuration] (same curve mapping for [secondLaunchDuration]).
  static const dot = Interval(0.00, 0.12, curve: Curves.easeOutCubic);
  static const scan = Interval(0.12, 0.28, curve: Curves.easeInOut);
  static const burst = Interval(0.28, 0.44, curve: Curves.easeOutQuad);
  static const assembly = Interval(0.44, 0.64, curve: Curves.easeOutCubic);
  static const snap = Interval(0.64, 0.72, curve: Curves.elasticOut);
  static const flash = Interval(0.68, 0.72, curve: Curves.easeOut);
  static const wordmark = Interval(0.72, 0.88, curve: Curves.easeOutCubic);
  static const shockwave = Interval(0.88, 1.00, curve: Curves.easeOutCubic);

  /// Fractions of master 0→1 (same for any total wall duration).
  static const hapticBeats = <double>[0.12, 0.44, 0.68, 0.88];
}

/// [AppPrefs] string keys (values `'1'` when enabled / completed).
abstract final class SplashPrefKeys {
  static const completedOnce = 'splash.v1.completed_once';
}
