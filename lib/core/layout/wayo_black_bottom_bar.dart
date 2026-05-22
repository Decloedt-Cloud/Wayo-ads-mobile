import 'package:flutter/material.dart';

import 'wayo_system_insets.dart';

/// Superadmin / full-screen edge-to-edge: solid black strip over the system
/// navigation area (replaces transparent overlap with OS nav buttons).
class WayoBlackBottomBar extends StatelessWidget {
  const WayoBlackBottomBar({super.key, this.contentHeight = 0});

  /// Extra height above the system inset (0 = inset fill only).
  final double contentHeight;

  static const Color barColor = Color(0xFF0D0D0D);

  /// Total height of [WayoBlackBottomBar] in this [context] (for scroll padding).
  static double totalHeight(BuildContext context, {double contentHeight = 0}) {
    return wayoSystemBottomInset(context) + contentHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: barColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: kWayoAndroidNavBarFallback),
        child: SizedBox(
          height: contentHeight,
          width: double.infinity,
        ),
      ),
    );
  }
}
