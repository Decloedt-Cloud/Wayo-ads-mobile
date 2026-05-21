import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/connectivity/connectivity_providers.dart';
import '../../core/connectivity/connectivity_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../i18n/strings.g.dart';

/// Premium connectivity surface — mount once above the app router/content.
///
/// * `offline` → centered modal-style blocker card (large illustration, retry).
/// * `reconnecting` → same card with a loading spinner instead of the illustration.
/// * `weak` → non-blocking floating banner at the top (amber).
/// * `online` (back from offline) → small success toast at the bottom that auto-dismisses.
///
/// The widget itself is transparent until there is something to show; it never
/// intercepts input in the `online` steady state.
class ConnectivityOverlay extends ConsumerStatefulWidget {
  const ConnectivityOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityOverlay> createState() =>
      _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends ConsumerState<ConnectivityOverlay> {
  ConnectivityStatus _previous = ConnectivityStatus.unknown;
  bool _showSuccessToast = false;
  int _toastVersion = 0;

  /// Re-fetch user-facing realtime surfaces as soon as the connection is back:
  /// chat conversations + messages, the Pusher/Reverb bindings and the main
  /// dashboard snapshot. Best-effort: exceptions are swallowed so the UI
  /// restoration toast always shows.
  void _reloadAfterReconnect() {
    try {
      ref.invalidate(chatConversationsProvider);
      scheduleInvalidateChatRealtimeBinding(
        () => ref.invalidate(chatRealtimeBindingProvider),
      );
      ref.invalidate(chatRealtimeServiceProvider);
      ref.invalidate(dashboardStreamProvider);
      ref.invalidate(notificationsListProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (
      _,
      next,
    ) {
      final status = next.valueOrNull ?? ConnectivityStatus.unknown;
      final cameBackOnline =
          _previous.isOffline &&
          status == ConnectivityStatus.online &&
          _previous != ConnectivityStatus.unknown;
      if (cameBackOnline) {
        setState(() {
          _showSuccessToast = true;
          _toastVersion += 1;
        });
        _reloadAfterReconnect();
      }
      _previous = status;
    });

    final async = ref.watch(connectivityStatusProvider);
    final status = async.valueOrNull ?? ConnectivityStatus.unknown;

    return Stack(
      children: [
        widget.child,
        if (status.isOffline || status.isReconnecting)
          Positioned.fill(
            child: _BlockerLayer(
              status: status,
              onRetry: () => ref.read(connectivityServiceProvider).refresh(),
            ),
          ),
        if (status.isWeak)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: const _WeakBanner(),
              ),
            ),
          ),
        if (_showSuccessToast)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _RestoredToast(
                key: ValueKey<int>(_toastVersion),
                onDismissed: () {
                  if (!mounted) return;
                  setState(() => _showSuccessToast = false);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _BlockerLayer extends StatelessWidget {
  const _BlockerLayer({required this.status, required this.onRetry});

  final ConnectivityStatus status;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(
                alpha: 0.55,
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _OfflineCard(status: status, onRetry: onRetry),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 220.ms, curve: Curves.easeOutCubic);
  }
}

class _OfflineCard extends StatefulWidget {
  const _OfflineCard({required this.status, required this.onRetry});

  final ConnectivityStatus status;
  final Future<void> Function() onRetry;

  @override
  State<_OfflineCard> createState() => _OfflineCardState();
}

class _OfflineCardState extends State<_OfflineCard> {
  bool _retrying = false;

  Future<void> _onRetryTap() async {
    if (_retrying) return;
    HapticFeedback.mediumImpact();
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final reconnecting =
        widget.status == ConnectivityStatus.reconnecting || _retrying;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedOf(
              context,
            ).withValues(alpha: isDark ? 0.92 : 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
                blurRadius: 42,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IllustrationHalo(reconnecting: reconnecting),
              const SizedBox(height: 20),
              Text(
                reconnecting
                    ? t.connectivity.reconnecting_title
                    : t.connectivity.offline_title,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle(context).copyWith(height: 1.25),
              ),
              const SizedBox(height: 8),
              Text(
                reconnecting
                    ? t.connectivity.reconnecting_subtitle
                    : t.connectivity.offline_subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await _openNetworkSettings();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.borderOf(context)),
                        foregroundColor: AppColors.textPrimaryOf(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t.connectivity.action_settings,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: reconnecting ? null : _onRetryTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: reconnecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              t.connectivity.action_retry,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return card
        .animate()
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 220.ms);
  }
}

class _IllustrationHalo extends StatelessWidget {
  const _IllustrationHalo({required this.reconnecting});

  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      width: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: reconnecting
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.wifi_off_rounded,
                    size: 30,
                    color: AppColors.primary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeakBanner extends StatelessWidget {
  const _WeakBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const amber = Color(0xFFF4A237);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: amber.withValues(alpha: 0.45),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: amber.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: amber.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.signal_cellular_alt_2_bar_rounded,
                      color: amber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.connectivity.weak_title,
                          style: TextStyle(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.connectivity.weak_subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .slideY(
          begin: -0.25,
          end: 0,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 220.ms);
  }
}

class _RestoredToast extends StatefulWidget {
  const _RestoredToast({super.key, required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  State<_RestoredToast> createState() => _RestoredToastState();
}

class _RestoredToastState extends State<_RestoredToast> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      widget.onDismissed();
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const green = AppColors.success;
    return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedOf(
                      context,
                    ).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: green.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t.connectivity.restored,
                        style: TextStyle(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .slideY(
          begin: 0.4,
          end: 0,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms)
        .then(delay: 2.seconds)
        .fadeOut(duration: 300.ms);
  }
}

/// Opens system network/Wi-Fi settings. Fails silently on platforms that do
/// not expose a user-accessible intent (desktop, restricted devices).
Future<void> _openNetworkSettings() async {
  final candidates = <Uri>[
    if (Platform.isIOS) Uri.parse('app-settings:'),
    if (Platform.isAndroid)
      Uri.parse('android.settings.WIRELESS_SETTINGS')
    else
      Uri.parse('app-settings:'),
  ];
  for (final uri in candidates) {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      continue;
    }
  }
}
