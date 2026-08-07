import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Schedules [action] after the current frame finishes building.
///
/// Use whenever a widget lifecycle (`build`, `initState`, `didUpdateWidget`,
/// `didChangeDependencies`, …) would otherwise write Riverpod state and trip:
/// `Tried to modify a provider while the widget tree was building.`
void deferAfterBuild(VoidCallback action) {
  final phase = SchedulerBinding.instance.schedulerPhase;
  final building = phase == SchedulerPhase.persistentCallbacks ||
      phase == SchedulerPhase.midFrameMicrotasks;
  if (!building) {
    action();
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) => action());
}
