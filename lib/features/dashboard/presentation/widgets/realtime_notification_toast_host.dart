import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/push/wayo_push_intent.dart';
import '../../../../core/push/wayo_push_service.dart';
import '../../../../core/realtime/realtime_signal.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../superadmin/presentation/providers/superadmin_providers.dart';
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

  void _onSignal(RealtimeSignal sig) async {
    if (!mounted) return;
    final payload = _signalPayloadMap(sig.raw);
    if (isAccountDeletionScheduledNotificationPayload(payload) &&
        await isAccountDeletionSelfInitiatedPushSuppressed()) {
      return;
    }
    if (!mounted) return;
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.creator &&
        isCreatorYoutubeConnectFcmPayload(_signalPayloadMap(sig.raw))) {
      return;
    }
    if ((role == WayoAdsAccountRole.creator ||
            role == WayoAdsAccountRole.advertiser) &&
        isSelfInitiatedWalletFcmPayload(_signalPayloadMap(sig.raw))) {
      return;
    }
    final isWithdrawalEvent = _isWithdrawalRealtimeEventName(sig.name);
    final isNotificationEvent = _isIncomingNotificationEvent(sig.name);
    final isSuperadminWithdrawal =
        role == WayoAdsAccountRole.superAdmin &&
        (isWithdrawalEvent || isWithdrawalNotificationPayload(sig.raw));
    if (!isNotificationEvent && !isSuperadminWithdrawal) {
      return;
    }
    final t = context.t;
    final parsed = _parsePayload(sig.raw);
    final title = parsed.$1;
    final body = parsed.$2;
    final headline = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : isSuperadminWithdrawal
        ? 'New withdrawal request'
        : t.dashboard.notification_incoming;
    final hasBody = body != null && body.trim().isNotEmpty;
    WayoToast.show(
      context,
      variant: WayoToastVariant.info,
      title: hasBody ? headline : null,
      message: hasBody ? body.trim() : headline,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: role == WayoAdsAccountRole.superAdmin && isSuperadminWithdrawal
            ? 'View payouts'
            : t.dashboard.notification_view,
        onPressed: () {
          if (role == WayoAdsAccountRole.superAdmin && isSuperadminWithdrawal) {
            invalidateSuperadminWithdrawalData(ref);
            ref.read(goRouterProvider).go(kSuperadminWithdrawalsRoute);
            return;
          }
          final r = switch (role) {
            WayoAdsAccountRole.creator => 'creator',
            WayoAdsAccountRole.advertiser => 'advertiser',
            WayoAdsAccountRole.superAdmin => 'superadmin',
            _ => 'app',
          };
          ref.read(goRouterProvider).push('/notifications?role=$r');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

bool _isWithdrawalRealtimeEventName(String name) {
  final lower = name.toLowerCase();
  if (!lower.contains('withdrawal')) return false;
  return lower.contains('creat') ||
      lower.contains('updat') ||
      lower.contains('approv') ||
      lower.contains('cancel') ||
      lower.contains('paid') ||
      lower.contains('valid') ||
      lower.contains('complet') ||
      lower.contains('request');
}

bool _isIncomingNotificationEvent(String name) {
  final n = name.toLowerCase();
  if (n == 'notification.created') return true;
  if (n == 'usernotificationcreated' || n.endsWith('.usernotificationcreated')) {
    return true;
  }
  if (n.contains('notification') && n.contains('created')) return true;
  if (n.contains('notification') && n.contains('new')) return true;
  return false;
}

Map<String, dynamic> _signalPayloadMap(Object? raw) {
  if (raw == null) return const {};
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) return const {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return const {};
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
