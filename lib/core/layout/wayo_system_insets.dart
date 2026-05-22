import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Typical 3-button navigation bar height when [MediaQuery] insets are zero
/// under [SystemUiMode.edgeToEdge] on some Android builds.
const double kWayoAndroidNavBarFallback = 48;

/// Bottom inset for system gesture / navigation bar.
///
/// Uses the max of [MediaQuery.viewPadding] and [MediaQuery.padding], with an
/// Android fallback when both are 0 (common with edge-to-edge).
double wayoSystemBottomInset(BuildContext context) {
  final mq = MediaQuery.of(context);
  var inset = math.max(mq.viewPadding.bottom, mq.padding.bottom);
  if (inset <= 0 &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    inset = kWayoAndroidNavBarFallback;
  }
  return inset;
}

/// Scroll padding so the last row clears system nav + a [FloatingActionButton].
///
/// [kFloatingActionButtonSize] (56) + scaffold margin (16) + [gap] above the FAB.
double wayoScrollBottomReserveForFab(BuildContext context, {double gap = 28}) {
  return wayoSystemBottomInset(context) + 56 + 16 + gap;
}

/// Scroll padding when there is no FAB (system nav only).
double wayoScrollBottomReserve(BuildContext context, {double gap = 16}) {
  return wayoSystemBottomInset(context) + gap;
}
