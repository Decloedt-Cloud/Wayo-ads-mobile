import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notifications_status_provider.dart';

/// Orange « ! » on the preferences button when push is off or not permitted.
class PushDisabledSettingsBadge extends ConsumerStatefulWidget {
  const PushDisabledSettingsBadge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushDisabledSettingsBadge> createState() =>
      _PushDisabledSettingsBadgeState();
}

class _PushDisabledSettingsBadgeState
    extends ConsumerState<PushDisabledSettingsBadge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(pushNotificationsActiveProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(pushNotificationsActiveProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(pushNotificationsActiveProvider);
    if (active) {
      return widget.child;
    }

    final borderColor = Theme.of(context).colorScheme.surface;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFF4A237),
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
