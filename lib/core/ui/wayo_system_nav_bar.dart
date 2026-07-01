import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Opaque system navigation bar color — black (dark) / white (light).
Color wayoSystemNavBarColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.black
      : Colors.white;
}

SystemUiOverlayStyle wayoSystemNavBarOverlay(
  BuildContext context, {
  Color? statusBarColor,
  Brightness? statusBarIconBrightness,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = wayoSystemNavBarColor(context);
  return SystemUiOverlayStyle(
    statusBarColor: statusBarColor ?? Colors.transparent,
    statusBarIconBrightness:
        statusBarIconBrightness ?? (isDark ? Brightness.light : Brightness.dark),
    systemNavigationBarColor: bg,
    systemNavigationBarDividerColor: bg,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
  );
}

/// Paints the Android/iOS home-indicator inset with [wayoSystemNavBarColor].
///
/// Use as [Scaffold.bottomNavigationBar] on full-screen routes (profile, etc.).
class WayoSystemNavBarFill extends StatelessWidget {
  const WayoSystemNavBarFill({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = wayoSystemNavBarColor(context);
    return Material(
      color: bg,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ColoredBox(
        color: bg,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: const SizedBox(width: double.infinity, height: 0),
        ),
      ),
    );
  }
}
