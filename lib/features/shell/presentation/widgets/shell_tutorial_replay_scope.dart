import 'package:flutter/material.dart';

/// Exposes [replay] so descendant routes (e.g. dashboard) can relaunch the
/// bottom-navigation coach-mark tour tied to `AppShell`.
class ShellTutorialReplayScope extends InheritedWidget {
  const ShellTutorialReplayScope({
    super.key,
    required this.replay,
    required super.child,
  });

  /// Resets prefs and shows the shell onboarding tour for the signed-in role.
  final Future<void> Function()? replay;

  static ShellTutorialReplayScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellTutorialReplayScope>();

  @override
  bool updateShouldNotify(covariant ShellTutorialReplayScope oldWidget) =>
      !identical(oldWidget.replay, replay);
}
