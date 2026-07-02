import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_providers.dart';
import '../../core/connectivity/connectivity_status.dart';
import '../../core/platform/system_network_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../i18n/strings.g.dart';
import 'wayo_ads_brand_mark.dart';

/// Premium connectivity surface — mount once above the app router/content.
///
/// * `offline` → centered modal blocker (retry + system network settings).
/// * `reconnecting` → slim non-blocking banner at the top.
/// * `weak` → amber floating banner at the top.
/// * `online` (back from offline) → success toast at the bottom.
class ConnectivityOverlay extends ConsumerStatefulWidget {
  const ConnectivityOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityOverlay> createState() =>
      _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends ConsumerState<ConnectivityOverlay>
    with WidgetsBindingObserver {
  ConnectivityStatus _previous = ConnectivityStatus.unknown;
  bool _showSuccessToast = false;
  int _toastVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityServiceProvider).onAppForeground();
    }
  }

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
    final radioUp = ref.watch(connectivityRadioUpProvider);

    return Stack(
      children: [
        widget.child,
        if (status.isOffline)
          Positioned.fill(
            child: _BlockerLayer(
              radioUp: radioUp,
              onRetry: () => ref.read(connectivityServiceProvider).refresh(),
            ),
          ),
        if (status.isReconnecting)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: const _ReconnectingBanner(),
              ),
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
  const _BlockerLayer({required this.radioUp, required this.onRetry});

  final bool radioUp;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF4F4F5))
                  .withValues(alpha: 0.72),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: _OfflineCard(radioUp: radioUp, onRetry: onRetry),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 200.ms, curve: Curves.easeOutCubic);
  }
}

class _OfflineCard extends StatefulWidget {
  const _OfflineCard({required this.radioUp, required this.onRetry});

  final bool radioUp;
  final Future<void> Function() onRetry;

  @override
  State<_OfflineCard> createState() => _OfflineCardState();
}

class _OfflineCardState extends State<_OfflineCard> {
  bool _retrying = false;
  bool _openingSettings = false;

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

  Future<void> _onSettingsTap() async {
    if (_openingSettings) return;
    HapticFeedback.selectionClick();
    setState(() => _openingSettings = true);
    try {
      final opened = await openSystemNetworkSettings();
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.connectivity.settings_unavailable),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = _retrying || _openingSettings;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.borderOf(context).withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
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
                    const WayoAppIcon(size: 88),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceElevatedOf(context),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          widget.radioUp
                              ? Icons.cloud_off_rounded
                              : Icons.wifi_off_rounded,
                          size: 17,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.connectivity.offline_title,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context).copyWith(
                fontSize: 21,
                height: 1.2,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.radioUp
                  ? t.connectivity.offline_subtitle_radio_up
                  : t.connectivity.offline_subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: busy ? null : _onRetryTap,
              icon: _retrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                _retrying
                    ? t.connectivity.reconnecting_title
                    : t.connectivity.action_retry,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: busy ? null : _onSettingsTap,
                icon: _openingSettings
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      )
                    : Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: AppColors.textPrimaryOf(context),
                      ),
                label: Text(
                  t.connectivity.action_settings,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimaryOf(context),
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.borderOf(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms);
  }
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return _TopStatusBanner(
      icon: Icons.sync_rounded,
      iconColor: AppColors.primary,
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      backgroundTint: AppColors.primary.withValues(alpha: 0.1),
      title: t.connectivity.reconnecting_title,
      subtitle: t.connectivity.reconnecting_subtitle,
      trailing: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppColors.primary.withValues(alpha: 0.85),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -0.2,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms);
  }
}

class _WeakBanner extends StatelessWidget {
  const _WeakBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const amber = Color(0xFFF4A237);
    return _TopStatusBanner(
      icon: Icons.signal_cellular_alt_2_bar_rounded,
      iconColor: amber,
      borderColor: amber.withValues(alpha: 0.4),
      backgroundTint: amber.withValues(alpha: 0.12),
      title: t.connectivity.weak_title,
      subtitle: t.connectivity.weak_subtitle,
    )
        .animate()
        .slideY(
          begin: -0.2,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms);
  }
}

class _TopStatusBanner extends StatelessWidget {
  const _TopStatusBanner({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundTint,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundTint;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF151515) : Colors.white)
            .withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
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
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: green.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
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
        )
        .animate()
        .slideY(
          begin: 0.35,
          end: 0,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 180.ms)
        .then(delay: 2.seconds)
        .fadeOut(duration: 280.ms);
  }
}
