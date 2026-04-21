import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_notifier.dart';
import 'providers/dashboard_state_providers.dart';

/// Global realtime invalidation + logout disconnect. Reverb subscribe is driven from [DashboardScreen].
class RealtimeDashboardWire extends ConsumerWidget {
  const RealtimeDashboardWire({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeInvalidationProvider);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenData((s) async {
        if (s is! AuthAuthenticated) {
          await ref.read(wayoReverbRealtimeProvider).disconnect();
        }
      });
    });

    return child;
  }
}
