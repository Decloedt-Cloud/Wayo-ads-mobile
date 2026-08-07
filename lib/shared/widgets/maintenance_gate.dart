import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/maintenance/maintenance_providers.dart';
import '../../core/maintenance/maintenance_recovery_coordinator.dart';
import '../../core/maintenance/maintenance_recovery_hub.dart';
import '../../core/maintenance/maintenance_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/ui/wayo_toast.dart';
import '../../i18n/strings.g.dart';
import 'wayo_ads_brand_mark.dart';

/// Safety-net poll while the maintenance overlay is shown.
///
/// Real-time recovery is delivered by push (Reverb `maintenance.ended` /
/// `platform.available` in foreground, FCM data in background). This slow poll
/// + the immediate probe on resume only catch the rare case where both were
/// missed.
const _kMaintenanceActiveProbeInterval = Duration(seconds: 60);

/// Background poll when the app is healthy (catch deploy mid-session).
const _kMaintenanceIdleProbeInterval = Duration(seconds: 60);

/// Full-screen blocker when Wayo-ads (or Auth) is in maintenance.
class MaintenanceGate extends ConsumerStatefulWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends ConsumerState<MaintenanceGate>
    with WidgetsBindingObserver {
  Timer? _periodicProbe;
  bool _wasMaintenanceActive = false;
  bool _recoveryScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reverb / FCM maintenance-recovery control messages → immediate health probe.
    setMaintenanceRecoveryProbeHandler(() {
      if (!mounted) return;
      unawaited(_runProbe());
    });
    _wasMaintenanceActive = MaintenanceServiceHolder.instance.isActive;
    MaintenanceServiceHolder.instance.addListener(_onMaintenanceChanged);
    unawaited(_runProbe());
    _restartProbeTimer();
  }

  @override
  void dispose() {
    MaintenanceServiceHolder.instance.removeListener(_onMaintenanceChanged);
    clearMaintenanceRecoveryProbeHandler();
    _periodicProbe?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runProbe());
    }
  }

  void _onMaintenanceChanged() {
    final active = MaintenanceServiceHolder.instance.isActive;
    final leftMaintenance = _wasMaintenanceActive && !active;
    if (active != _wasMaintenanceActive) {
      _wasMaintenanceActive = active;
      _restartProbeTimer();
    }
    if (!leftMaintenance) return;
    _scheduleRecoveryAfterFrame();
  }

  /// Never invalidate Riverpod providers synchronously inside [notifyListeners]
  /// (ListenableBuilder may still be building).
  void _scheduleRecoveryAfterFrame() {
    if (_recoveryScheduled) return;
    _recoveryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoveryScheduled = false;
      if (!mounted) return;
      unawaited(ref.read(maintenanceRecoveryCoordinatorProvider).recoverNow());
    });
  }

  void _restartProbeTimer() {
    _periodicProbe?.cancel();
    final interval = MaintenanceServiceHolder.instance.isActive
        ? _kMaintenanceActiveProbeInterval
        : _kMaintenanceIdleProbeInterval;
    _periodicProbe = Timer.periodic(interval, (_) => unawaited(_runProbe()));
  }

  Future<void> _runProbe() async {
    final active = MaintenanceServiceHolder.instance.isActive;
    await MaintenanceServiceHolder.instance.probeOnLaunch(
      allowRecovery: active,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(maintenanceServiceProvider);

    return ListenableBuilder(
      listenable: MaintenanceServiceHolder.instance,
      builder: (context, _) {
        final active = MaintenanceServiceHolder.instance.isActive;
        if (!active) {
          return widget.child;
        }

        return PopScope(
          canPop: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: _MaintenanceScreen(
                    probing: MaintenanceServiceHolder.instance.isProbing,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaintenanceScreen extends ConsumerWidget {
  const _MaintenanceScreen({required this.probing});

  final bool probing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    const amber = Color(0xFFF47A1F);
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.center,
                child: _MaintenancePreferences(),
              ),
              const SizedBox(height: 32),
              const WayoAdsBrandMark(),
              const Spacer(),
              _PulseIcon(probing: probing),
              const SizedBox(height: 28),
              Text(
                t.maintenance.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium(
                  context,
                ).copyWith(color: onSurface, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                t.maintenance.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(color: muted, height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                t.maintenance.apology,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: muted.withValues(alpha: 0.9),
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: scheme.outlineVariant.withValues(
                        alpha: 0.35,
                      ),
                      color: amber,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 1400.ms,
                    color: amber.withValues(alpha: 0.35),
                  ),
              const Spacer(flex: 2),
              Text(
                t.maintenance.copyright,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: muted.withValues(alpha: 0.75), fontSize: 12),
              ),
              const SizedBox(height: 8),
              _SupportEmailLink(email: t.maintenance.support_email),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact theme toggle + language pill (matches maintenance web/mobile mock).
class _MaintenancePreferences extends StatelessWidget {
  const _MaintenancePreferences();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MaintenanceThemeToggle(),
        SizedBox(width: 12),
        _MaintenanceLanguagePill(),
      ],
    );
  }
}

class _MaintenanceThemeToggle extends ConsumerWidget {
  const _MaintenanceThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.55 : 0.45,
    );
    final fill = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
        : Colors.white;

    return Semantics(
      button: true,
      label: isDark
          ? context.t.app_settings.theme_light
          : context.t.app_settings.theme_dark,
      child: Material(
        color: fill,
        shape: CircleBorder(side: BorderSide(color: borderColor)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            ref
                .read(themeModeProvider.notifier)
                .set(isDark ? ThemeMode.light : ThemeMode.dark);
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 22,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceLanguagePill extends ConsumerWidget {
  const _MaintenanceLanguagePill();

  static const _options = <({AppLocale locale, String code})>[
    (locale: AppLocale.en, code: 'EN'),
    (locale: AppLocale.fr, code: 'FR'),
    (locale: AppLocale.ar, code: 'AR'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellFill = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.28)
        : Colors.white;
    final selectedFill = isDark
        ? const Color(0xFF5C5C5C)
        : const Color(0xFFEBEBEB);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: shellFill,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _MaintenanceLangSegment(
              code: _options[i].code,
              selected: locale == _options[i].locale,
              selectedFill: selectedFill,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(localeProvider.notifier).set(_options[i].locale);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceLangSegment extends StatelessWidget {
  const _MaintenanceLangSegment({
    required this.code,
    required this.selected,
    required this.selectedFill,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final Color selectedFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: selected
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportEmailLink extends StatelessWidget {
  const _SupportEmailLink({required this.email});

  final String email;

  Future<void> _openMail(BuildContext context) async {
    final uri = Uri.parse('mailto:$email');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      WayoToast.info(context, email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: email,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMail(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              email,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(
                color: const Color(0xFFF47A1F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFF47A1F),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatelessWidget {
  const _PulseIcon({required this.probing});

  final bool probing;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF47A1F);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoColor = isDark ? Colors.black : Colors.white;
    final icon = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF47A1F), Color(0xFFE85D04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: amber.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: WayoPlayWaveIcon(color: logoColor, size: 46),
    );

    if (probing) {
      return icon.animate(onPlay: (c) => c.repeat()).rotate(duration: 1200.ms);
    }
    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1.04, 1.04),
          duration: 1600.ms,
          curve: Curves.easeInOut,
        );
  }
}
