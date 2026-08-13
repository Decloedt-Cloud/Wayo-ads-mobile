import 'package:flutter/material.dart';

import 'app_update_gate.dart';

/// Legacy name for [AppUpdateGate] (forced + optional updates).
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppUpdateGate(child: child);
}
