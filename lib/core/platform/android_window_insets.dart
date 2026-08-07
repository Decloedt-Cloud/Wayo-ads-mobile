import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android window inset helpers.
///
/// Flutter [SystemUiMode] alone does **not** flip
/// `WindowCompat.setDecorFitsSystemWindows` — Stripe Payment Sheet / Link
/// fragments attached to [MainActivity] still draw under the nav bar while
/// that flag stays `false` (our edge-to-edge default).
final class AndroidWindowInsets {
  const AndroidWindowInsets._();

  static const _channel = MethodChannel('ma.wayo.wayoadsgo/window_insets');

  /// When [fits] is true, content is laid out above the system bars (safe for
  /// Stripe Link). When false, restores app edge-to-edge.
  static Future<void> setDecorFitsSystemWindows(bool fits) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setDecorFitsSystemWindows', fits);
    } catch (_) {
      // Best-effort — never block payments on channel failure.
    }
  }
}
