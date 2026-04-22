import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_signal.dart';
import '../../../../core/ui/root_scaffold_messenger_key.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../providers/dashboard_state_providers.dart';

/// Shows a floating snackbar when Reverb fires `notification.created` (Wayo-ads + mobile).
class RealtimeNotificationToastHost extends ConsumerStatefulWidget {
  const RealtimeNotificationToastHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeNotificationToastHost> createState() =>
      _RealtimeNotificationToastHostState();
}

class _RealtimeNotificationToastHostState
    extends ConsumerState<RealtimeNotificationToastHost> {
  StreamSubscription<RealtimeSignal>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(wayoReverbRealtimeProvider).signals.listen(_onSignal);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onSignal(RealtimeSignal sig) {
    if (sig.name != 'notification.created') return;
    if (!mounted) return;
    final t = context.t;
    final parsed = _parsePayload(sig.raw);
    final title = parsed.$1;
    final body = parsed.$2;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final headline = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : t.dashboard.notification_incoming;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 88),
        duration: const Duration(seconds: 5),
        showCloseIcon: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            if (body != null && body.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                body.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
        action: SnackBarAction(
          label: t.dashboard.notification_view,
          onPressed: () {
            final role = ref.read(currentWayoAdsAccountRoleProvider);
            final r = switch (role) {
              WayoAdsAccountRole.creator => 'creator',
              WayoAdsAccountRole.advertiser => 'advertiser',
              _ => 'app',
            };
            ref.read(goRouterProvider).push('/notifications?role=$r');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Returns (title, message) if present in broadcast payload.
(String?, String?) _parsePayload(Object? raw) {
  if (raw == null) {
    return (null, null);
  }
  Map<String, dynamic>? map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) {
      return (null, null);
    }
    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) {
      map = decoded;
    } else {
      return (null, null);
    }
  }
  if (map == null) {
    return (null, null);
  }
  final n = map['notification'];
  if (n is Map<String, dynamic>) {
    return (
      n['title'] as String? ?? map['title'] as String?,
      n['message'] as String? ??
          n['body'] as String? ??
          map['message'] as String?,
    );
  }
  return (
    map['title'] as String?,
    map['message'] as String? ?? map['body'] as String?,
  );
}
