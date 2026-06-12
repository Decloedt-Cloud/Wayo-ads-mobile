import 'package:flutter/foundation.dart';

/// Bottom-nav tab ids used by the shell coach-mark tour.
enum ShellTutorialTarget { dashboard, campaigns, wallet, invoices, chat }

/// Active tab during [ShellTutorialController] — nav paints it at full brightness.
final shellTutorialHighlightTab = ValueNotifier<ShellTutorialTarget?>(null);

void clearShellTutorialHighlight() {
  shellTutorialHighlightTab.value = null;
}

ShellTutorialTarget? shellTutorialTargetFromIdentify(dynamic identify) {
  if (identify is! String) return null;
  for (final t in ShellTutorialTarget.values) {
    if (t.name == identify) return t;
  }
  return null;
}
