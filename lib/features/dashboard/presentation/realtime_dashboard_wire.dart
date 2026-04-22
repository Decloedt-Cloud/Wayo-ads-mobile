import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_notifier.dart';
import 'providers/dashboard_state_providers.dart';

/// Global Reverb: connects as soon as the user is signed in (any tab), not only on [DashboardScreen].
class RealtimeDashboardWire extends ConsumerStatefulWidget {
  const RealtimeDashboardWire({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeDashboardWire> createState() => _RealtimeDashboardWireState();
}

class _RealtimeDashboardWireState extends ConsumerState<RealtimeDashboardWire> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(authNotifierProvider).valueOrNull;
      if (s is AuthAuthenticated) {
        unawaited(ref.read(wayoReverbRealtimeProvider).connectForUser(s.user.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeInvalidationProvider);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      next.whenData((s) async {
        if (s is AuthAuthenticated) {
          await ref.read(wayoReverbRealtimeProvider).connectForUser(s.user.id);
        } else {
          await ref.read(wayoReverbRealtimeProvider).disconnect();
        }
      });
    });

    return widget.child;
  }
}
