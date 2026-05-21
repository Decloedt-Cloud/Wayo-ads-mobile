import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/push/push_permission_policy.dart';
import '../../../core/push/system_push_permission.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/realtime/realtime_signal.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/wayo_ads_account_role.dart';
import '../../chat/data/chat_realtime_service.dart';
import '../../chat/presentation/providers/chat_providers.dart';
import '../../dashboard/presentation/providers/dashboard_state_providers.dart';

/// Pending contextual/generic push opt-in (consumed by [PushPermissionPromptHost]).
final pushPermissionPromptContextProvider =
    StateProvider<PushPermissionContext?>((ref) => null);

Future<void> trySchedulePushPermissionPrompt({
  required AuthAuthenticated auth,
  required AppPrefs prefs,
  required void Function(PushPermissionContext? context) setPendingContext,
  required PushPermissionContext context,
}) async {
  final role = auth.user.wayoAdsRole;
  if (role != WayoAdsAccountRole.advertiser &&
      role != WayoAdsAccountRole.creator &&
      role != WayoAdsAccountRole.superAdmin) {
    return;
  }

  final granted = await areSystemPushNotificationsGranted();
  if (granted) {
    await PushPermissionPolicy(prefs).recordEnabled(auth.user.id);
    return;
  }

  final policy = PushPermissionPolicy(prefs);
  final show = await policy.shouldShowPrompt(
    userId: auth.user.id,
    context: context,
    systemNotificationsGranted: granted,
  );
  if (!show) {
    return;
  }
  setPendingContext(context);
}

/// Listens to chat + Wayo-ads realtime and schedules contextual re-prompts.
final pushPermissionContextListenerProvider = Provider<void>((ref) {
  final chatSub = ref.watch(chatRealtimeServiceProvider).events.listen((event) {
    if (event is! ChatMessageSentEvent) {
      return;
    }
    unawaited(_onChatMessageSent(ref, event));
  });

  final reverbSub = ref.watch(wayoReverbRealtimeProvider).signals.listen((sig) {
    unawaited(_onReverbSignal(ref, sig));
  });

  ref.onDispose(() {
    chatSub.cancel();
    reverbSub.cancel();
  });
});

Future<void> _onChatMessageSent(Ref ref, ChatMessageSentEvent event) async {
  try {
    final creds = await ref.read(chatBootstrapProvider.future);
    final repo = ref.read(chatRepositoryProvider);
    final m = repo.parseRemoteMessage(event.rawMessage);
    if (m.userId == creds.chatUserId) {
      return;
    }
  } catch (_) {
    return;
  }
  final auth = ref.read(authNotifierProvider).valueOrNull;
  if (auth is! AuthAuthenticated) return;
  await trySchedulePushPermissionPrompt(
    auth: auth,
    prefs: ref.read(appPrefsProvider),
    setPendingContext: (c) =>
        ref.read(pushPermissionPromptContextProvider.notifier).state = c,
    context: PushPermissionContext.chatMessage,
  );
}

Future<void> _onReverbSignal(Ref ref, RealtimeSignal sig) async {
  final lower = sig.name.toLowerCase();
  final campaignEvent =
      lower == 'campaign.updated' ||
      (lower.contains('campaign') &&
          (lower.contains('updat') ||
              lower.contains('creat') ||
              lower.contains('delet') ||
              lower.contains('paus') ||
              lower.contains('status')));

  if (campaignEvent) {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    await trySchedulePushPermissionPrompt(
      auth: auth,
      prefs: ref.read(appPrefsProvider),
      setPendingContext: (c) =>
          ref.read(pushPermissionPromptContextProvider.notifier).state = c,
      context: PushPermissionContext.campaignStatus,
    );
    return;
  }

  final balanceEvent =
      lower == 'balance.updated' ||
      (lower.contains('balance') && lower.contains('updat'));
  final payoutEvent =
      lower.contains('payout') &&
      (lower.contains('updat') || lower.contains('complet'));
  final invoiceNotif = _notificationTypeFromRaw(sig.raw)
      .toUpperCase()
      .contains('INVOICE');

  if (balanceEvent || payoutEvent || invoiceNotif) {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    await trySchedulePushPermissionPrompt(
      auth: auth,
      prefs: ref.read(appPrefsProvider),
      setPendingContext: (c) =>
          ref.read(pushPermissionPromptContextProvider.notifier).state = c,
      context: PushPermissionContext.invoice,
    );
  }
}

String _notificationTypeFromRaw(dynamic raw) {
  if (raw == null) {
    return '';
  }
  Map<String, dynamic>? map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is Map) {
    map = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) {
        map = d;
      } else if (d is Map) {
        map = Map<String, dynamic>.from(d);
      }
    } catch (_) {}
  }
  if (map == null) {
    return '';
  }
  return (map['notification_type'] ??
          map['notificationType'] ??
          map['type'] ??
          '')
      .toString();
}
