import 'package:flutter/material.dart';

/// Bottom-nav tab ids used by the shell coach-mark tour.
enum ShellTutorialTarget { dashboard, campaigns, wallet, invoices, chat }

/// Active tab during [ShellTutorialController] — nav paints it at full brightness.
final shellTutorialHighlightTab = ValueNotifier<ShellTutorialTarget?>(null);

/// Horizontal slide timing shared by the onboarding overlay and bottom nav.
const Duration shellTutorialSlideDuration = Duration(milliseconds: 420);
const Curve shellTutorialSlideCurve = Curves.easeOutCubic;

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

GlobalKey? shellTutorialTabKeyForTarget(
  ShellTutorialTarget target, {
  required GlobalKey? dashboardKey,
  required GlobalKey? campaignsKey,
  required GlobalKey? walletKey,
  required GlobalKey? invoicesKey,
  required GlobalKey? chatKey,
  required bool showInvoicesTab,
}) {
  switch (target) {
    case ShellTutorialTarget.dashboard:
      return dashboardKey;
    case ShellTutorialTarget.campaigns:
      return campaignsKey;
    case ShellTutorialTarget.wallet:
      return walletKey;
    case ShellTutorialTarget.invoices:
      return showInvoicesTab ? invoicesKey : null;
    case ShellTutorialTarget.chat:
      return chatKey;
  }
}
