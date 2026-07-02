import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/apple_email_policy.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/onboarding_gate.dart';
import '../login/widgets/animated_digital_zellij_background.dart';
import '../widgets/noise_overlay.dart';
import '../widgets/verify_email_otp_card.dart';

class EmailVerificationOtpOnboardingScreen extends ConsumerStatefulWidget {
  const EmailVerificationOtpOnboardingScreen({super.key});

  @override
  ConsumerState<EmailVerificationOtpOnboardingScreen> createState() =>
      _EmailVerificationOtpOnboardingScreenState();
}

class _EmailVerificationOtpOnboardingScreenState
    extends ConsumerState<EmailVerificationOtpOnboardingScreen> {
  static const _cooldownSeconds = 60;
  int _cooldown = _cooldownSeconds;
  Timer? _timer;
  int _otpKey = 0;
  bool _sending = true;
  bool _verifying = false;
  bool _codeSentBanner = false;
  String? _sendError;
  String _code = '';

  @override
  void initState() {
    super.initState();
    unawaited(_sendCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? _email() {
    return ref.read(authNotifierProvider).maybeWhen(
          data: (s) => s is AuthAuthenticated ? s.user.email : null,
          orElse: () => null,
        );
  }

  void _startCooldown([int seconds = _cooldownSeconds]) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _sendError = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final r = await repo.sendEmailVerificationOtp(email: _email());
    if (!mounted) return;
    switch (r) {
      case Success(:final data):
        _startCooldown(data.clamp(30, 600));
        setState(() => _codeSentBanner = true);
      case Failure(:final error):
        if (error is RateLimitedException) {
          final seconds = error.retryAfterSeconds.clamp(1, 600);
          _startCooldown(seconds);
          _sendError = context.t.login.rate_limit_remaining(seconds: seconds);
        } else {
          _sendError = localizeAuthError(error, context.t);
        }
    }
    setState(() => _sending = false);
  }

  Future<void> _submit() async {
    if (_verifying || _code.length != 6) return;
    setState(() => _verifying = true);
    final t = context.t;
    final repo = ref.read(authRepositoryProvider);
    final r = await repo.confirmEmailAddressOtp(_code, email: _email());
    if (!mounted) return;
    switch (r) {
      case Success(:final data):
        await ref.read(authNotifierProvider.notifier).applyOnboardingUser(data);
        if (!mounted) return;
        final next = onboardingRedirectPath(data);
        context.go(next ?? '/dashboard');
      case Failure(:final error):
        WayoToast.error(context, localizeAuthError(error, t));
        setState(() {
          _otpKey++;
          _code = '';
        });
    }
    if (mounted) setState(() => _verifying = false);
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Widget? _headerExtra(String email) {
    if (!isAppleHideMyEmailAddress(email)) return null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t.onboarding.email_code_hide_my_email_warning,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authNotifierProvider).maybeWhen(
          data: (s) => s is AuthAuthenticated ? s.user.email : '',
          orElse: () => '',
        );
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedDigitalZellijBackground(reduceMotion: reduce),
          ),
          Positioned.fill(
            child: NoiseOverlay(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.032
                  : 0.022,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: VerifyEmailOtpCard(
                otpKey: _otpKey,
                sending: _sending,
                verifying: _verifying,
                cooldown: _cooldown,
                showCodeSentBanner: _codeSentBanner && _sendError == null,
                sendError: _sendError,
                code: _code,
                headerExtra: _headerExtra(email),
                onCodeChanged: (v) => setState(() => _code = v),
                onVerify: _submit,
                onResend: () async {
                  setState(() {
                    _otpKey++;
                    _code = '';
                  });
                  await _sendCode();
                },
                onDifferentAccount: _signOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
