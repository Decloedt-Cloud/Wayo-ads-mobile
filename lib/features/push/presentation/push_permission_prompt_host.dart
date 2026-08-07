import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/wayo_ads_dio.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/riverpod/defer_after_build.dart';
import '../../../core/push/push_permission_policy.dart';
import '../../../core/push/push_registration_lifecycle.dart';
import '../../../core/push/system_push_permission.dart';
import '../../../core/push/user_push_notifications_preference.dart';
import '../../../core/push/wayo_push_intent.dart';
import '../../../core/push/wayo_push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/wayo_toast.dart';
import '../../../i18n/strings.g.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/wayo_ads_account_role.dart';
import '../../auth/presentation/providers/current_account_providers.dart';
import '../../chat/presentation/providers/chat_providers.dart';
import '../../dashboard/presentation/providers/dashboard_state_providers.dart';
import 'push_permission_prompt_trigger.dart';

/// Schedules the push opt-in sheet (14-day deferral, max 3 shows, contextual re-prompts).
class PushPermissionPromptHost extends ConsumerStatefulWidget {
  const PushPermissionPromptHost({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<PushPermissionPromptHost> createState() =>
      _PushPermissionPromptHostState();
}

class _PushPermissionPromptHostState
    extends ConsumerState<PushPermissionPromptHost> with WidgetsBindingObserver {
  bool _overlayVisible = false;
  PushPermissionContext _overlayContext = PushPermissionContext.generic;
  Timer? _debounce;
  Timer? _periodicPushHealTimer;
  RawReceivePort? _deferredPushPort;
  bool _deferredPushInFlight = false;
  DateTime? _lastResumePushSyncAt;

  Future<void> _consumeDeferredPushIntents() async {
    if (!mounted || _deferredPushInFlight) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    _deferredPushInFlight = true;
    try {
      await consumeDeferredChatQuickReply(
        onSend: (conversationId, text) async {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return;

          await recordInlineReplyEchoGuard(
            conversationId: '$conversationId',
            messageText: trimmed,
          );

          final repo = ref.read(chatRepositoryProvider);
          final rt = ref.read(chatRealtimeServiceProvider);
          Object? lastError;

          for (var attempt = 0; attempt < 5; attempt++) {
            try {
              if (attempt > 0) {
                await Future<void>.delayed(
                  Duration(milliseconds: 380 * attempt),
                );
              }
              final creds = await ref.read(chatBootstrapProvider.future);
              await repo.sendTextMessage(
                creds,
                conversationId,
                trimmed,
                socketId: () => rt.socketId,
              );
              ref.invalidate(chatConversationsProvider);
              return;
            } on DioException catch (e) {
              lastError = e;
              final code = e.response?.statusCode;
              final is401 = code == 401;
              if (is401 && attempt < 4) {
                ref.invalidate(chatBootstrapProvider);
              }
            } catch (e) {
              lastError = e;
            }
          }
          await clearInlineReplyEchoGuard();
          throw lastError ??
              Exception('Deferred notification reply failed after retries');
        },
      );

      if (!mounted) return;
      await consumeDeferredWayoPushIntents(
        context: context,
        isAuthenticated: true,
        role: ref.read(currentWayoAdsAccountRoleProvider),
        processDeferredMarkRead:
            ({required notificationId, conversationId}) async {
          if (conversationId != null && conversationId.isNotEmpty) {
            await dismissWayoChatNotification(conversationId);
          }
          try {
            await ref.read(notificationsRepositoryProvider).markRead(
                  notificationId,
                  conversationId: conversationId,
                );
          } catch (_) {}
          final convInt = int.tryParse(conversationId ?? '');
          if (convInt != null) {
            try {
              final creds = await ref.read(chatBootstrapProvider.future);
              final rt = ref.read(chatRealtimeServiceProvider);
              await ref.read(chatRepositoryProvider).markRead(
                    creds,
                    convInt,
                    socketId: () => rt.socketId,
                  );
            } catch (_) {}
          }
          ref.invalidate(notificationsListProvider);
          ref.invalidate(dashboardStreamProvider);
          ref.invalidate(chatConversationsProvider);
        },
      );
    } finally {
      _deferredPushInFlight = false;
    }
  }

  void _tryConsumeDeferredPush() {
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    unawaited(_consumeDeferredPushIntents());
  }

  bool _eligibleRole(WayoAdsAccountRole r) =>
      r == WayoAdsAccountRole.advertiser ||
      r == WayoAdsAccountRole.creator ||
      r == WayoAdsAccountRole.superAdmin;

  bool _allowedRoute(String loc) {
    if (loc == '/splash' || loc == '/login') return false;
    if (loc.startsWith('/onboarding')) return false;
    if (loc.startsWith('/forgot-password')) return false;
    return true;
  }

  String? _matchedLocation(BuildContext context) {
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return null;
    }
  }

  Future<void> _presentOverlay(PushPermissionContext context) async {
    if (!mounted || _overlayVisible) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    final granted = await areSystemPushNotificationsGranted();
    if (granted) {
      await PushPermissionPolicy(ref.read(appPrefsProvider))
          .recordEnabled(auth.user.id);
      ref.read(pushPermissionPromptContextProvider.notifier).state = null;
      return;
    }

    final policy = PushPermissionPolicy(ref.read(appPrefsProvider));
    final show = await policy.shouldShowPrompt(
      userId: auth.user.id,
      context: context,
      systemNotificationsGranted: granted,
    );
    if (!show) {
      ref.read(pushPermissionPromptContextProvider.notifier).state = null;
      return;
    }

    await policy.recordPromptShown(auth.user.id);
    if (!mounted) return;
    setState(() {
      _overlayContext = context;
      _overlayVisible = true;
    });
    ref.read(pushPermissionPromptContextProvider.notifier).state = null;
  }

  void _tryScheduleGenericPrompt() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _overlayVisible) return;
      final auth = ref.read(authNotifierProvider).valueOrNull;
      if (auth is! AuthAuthenticated) return;
      if (!_eligibleRole(auth.user.wayoAdsRole)) return;

      final loc = _matchedLocation(context) ?? '';
      if (!_allowedRoute(loc)) return;

      unawaited(
        trySchedulePushPermissionPrompt(
          auth: auth,
          prefs: ref.read(appPrefsProvider),
          setPendingContext: (c) => ref
              .read(pushPermissionPromptContextProvider.notifier)
              .state = c,
          context: PushPermissionContext.generic,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deferredPushPort = RawReceivePort((_) {
      if (!mounted) return;
      unawaited(_consumeDeferredPushIntents());
    });
    IsolateNameServer.registerPortWithName(
      _deferredPushPort!.sendPort,
      kWayoDeferredPushPortName,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryConsumeDeferredPush();
      unawaited(_syncPushRegistrationOnResume(force: true));
      _startPeriodicPushHeal();
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(kWayoDeferredPushPortName);
    _deferredPushPort?.close();
    _deferredPushPort = null;
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _periodicPushHealTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryConsumeDeferredPush();
      _tryScheduleGenericPrompt();
      unawaited(_syncPushRegistrationOnResume());
      _startPeriodicPushHeal();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _periodicPushHealTimer?.cancel();
      _periodicPushHealTimer = null;
    }
  }

  /// Periodic foreground heal — same effect as toggle off/on, without UI.
  Future<void> _syncPushRegistrationOnResume({bool force = false}) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final now = DateTime.now();
    final last = _lastResumePushSyncAt;
    if (!force &&
        last != null &&
        now.difference(last) < const Duration(seconds: 20)) {
      return;
    }
    _lastResumePushSyncAt = now;
    await ref
        .read(authNotifierProvider.notifier)
        .syncPushRegistrationOnResume();
  }

  /// Keep the server token + local delivery flag healthy while the app stays open.
  void _startPeriodicPushHeal() {
    _periodicPushHealTimer?.cancel();
    _periodicPushHealTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      unawaited(_syncPushRegistrationOnResume(force: true));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    deferAfterBuild(() {
      if (mounted) _tryScheduleGenericPrompt();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushPermissionContextListenerProvider);

    ref.listen<PushPermissionContext?>(pushPermissionPromptContextProvider, (
      _,
      next,
    ) {
      if (next == null) return;
      unawaited(_presentOverlay(next));
    });

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, _) {
      _tryScheduleGenericPrompt();
      _tryConsumeDeferredPush();
    });

    final child = widget.child ?? const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (_overlayVisible)
          _PushPermissionOverlay(
            contextKind: _overlayContext,
            onLater: () async {
              final auth = ref.read(authNotifierProvider).valueOrNull;
              if (auth is AuthAuthenticated) {
                await PushPermissionPolicy(ref.read(appPrefsProvider))
                    .recordDismissed(auth.user.id);
              }
              if (mounted) setState(() => _overlayVisible = false);
            },
            onEnable: () async {
              final prefs = ref.read(appPrefsProvider);
              final auth = ref.read(authNotifierProvider).valueOrNull;
              if (auth is! AuthAuthenticated) return;

              final ok = await enableUserPushNotifications(
                wayoAdsDio: ref.read(wayoAdsDioProvider),
                prefs: prefs,
                reason: PushRegisterReason.permissionPrompt,
              );
              if (ok) {
                await PushPermissionPolicy(prefs).recordEnabled(auth.user.id);
              }
              if (!mounted) return;
              setState(() => _overlayVisible = false);

              if (!context.mounted) return;
              if (ok) {
                WayoToast.success(
                  context,
                  context.t.push.onboarding_success,
                  duration: const Duration(seconds: 4),
                );
              } else {
                WayoToast.warning(
                  context,
                  context.t.push.onboarding_denied_hint,
                  duration: const Duration(seconds: 6),
                );
              }
            },
          ),
      ],
    );
  }
}

class _PushPermissionOverlay extends StatelessWidget {
  const _PushPermissionOverlay({
    required this.contextKind,
    required this.onLater,
    required this.onEnable,
  });

  final PushPermissionContext contextKind;
  final Future<void> Function() onLater;
  final Future<void> Function() onEnable;

  String _contextSubtitle(Translations t) {
    return switch (contextKind) {
      PushPermissionContext.chatMessage => t.push.onboarding_context_chat,
      PushPermissionContext.campaignStatus => t.push.onboarding_context_campaign,
      PushPermissionContext.invoice => t.push.onboarding_context_invoice,
      PushPermissionContext.generic => t.push.onboarding_subtitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF312E81)]
                      : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFFFBEB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1, 1),
                          duration: 550.ms,
                          curve: Curves.easeOutBack,
                        )
                        .shimmer(
                          duration: 1400.ms,
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                    const SizedBox(height: 18),
                    Text(
                      t.push.onboarding_title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      _contextSubtitle(t),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ).animate().fadeIn(delay: 80.ms, duration: 420.ms),
                    const SizedBox(height: 18),
                    _Bullet(text: t.push.onboarding_bullet_campaigns, delayMs: 120),
                    _Bullet(text: t.push.onboarding_bullet_messages, delayMs: 200),
                    _Bullet(text: t.push.onboarding_bullet_system, delayMs: 280),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () => onEnable(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        t.push.onboarding_enable,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 400.ms),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => onLater(),
                      child: Text(
                        t.push.onboarding_later,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 320.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 420.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.delayMs});

  final String text;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delayMs.ms, duration: 360.ms).slideX(begin: -0.04, end: 0);
  }
}
