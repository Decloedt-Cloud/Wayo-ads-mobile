import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/noise_overlay.dart';
import '../widgets/otp_input_field.dart';
import '../widgets/password_reset_top_bar.dart';
import '../widgets/rate_limit_cooldown_banner.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const _cooldownSeconds = 60;
  int _cooldown = _cooldownSeconds;
  Timer? _timer;
  int _otpRebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _cooldown = _cooldownSeconds;
    _timer?.cancel();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  RateLimitedException? _rateLimit(ForgotPasswordState s) {
    if (s is! FpError) return null;
    final e = s.error;
    return e is RateLimitedException ? e : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.watch(localeProvider);

    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider, (prev, next) {
      if (next is FpOtpVerified && prev is FpLoading) {
        context.pushReplacement('/forgot-password/new-password', extra: next.resetToken);
      } else if (next is FpError && next.error is! RateLimitedException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAuthError(next.error, t))),
        );
        setState(() => _otpRebuildKey++);
      }
    });

    final state = ref.watch(forgotPasswordControllerProvider);
    final loading = state is FpLoading;
    final rate = _rateLimit(state);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedMeshBackground()),
          const Positioned.fill(child: NoiseOverlay()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PasswordResetTopBar(),
                    const SizedBox(height: 8),
                    Text(
                      t.otp.title,
                      style: AppTextStyles.displayLarge(context).copyWith(fontSize: 32, height: 1.1),
                    ).animate().fadeIn(duration: 450.ms),
                    const SizedBox(height: 12),
                    Text(
                      t.otp.subtitle(email: widget.email),
                      style: AppTextStyles.bodyLarge(context),
                    ),
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(top: rate != null ? 16 : 0, bottom: rate != null ? 16 : 0),
                      child: rate == null
                          ? const SizedBox.shrink()
                          : RateLimitCooldownBanner(
                              key: ValueKey(rate.retryAfterSeconds),
                              initialSeconds: rate.retryAfterSeconds,
                              variant: RateLimitBannerVariant.passwordReset,
                              onComplete: () =>
                                  ref.read(forgotPasswordControllerProvider.notifier).clearError(),
                            ),
                    ),
                    const SizedBox(height: 28),
                    IgnorePointer(
                      ignoring: loading || rate != null,
                      child: Opacity(
                        opacity: (loading || rate != null) ? 0.45 : 1,
                        child: OtpInputField(
                          key: ValueKey(_otpRebuildKey),
                          onCompleted: (code) {
                            ref.read(forgotPasswordControllerProvider.notifier).verifyOtp(widget.email, code);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: IgnorePointer(
                        ignoring: loading || rate != null || _cooldown > 0,
                        child: Opacity(
                          opacity: (loading || rate != null || _cooldown > 0) ? 0.45 : 1,
                          child: _cooldown > 0
                              ? Text(
                                  t.otp.resend_in(seconds: _cooldown),
                                  style: AppTextStyles.caption(context),
                                )
                              : TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(forgotPasswordControllerProvider.notifier)
                                        .requestOtp(widget.email);
                                    if (context.mounted) {
                                      setState(() => _otpRebuildKey++);
                                      _startCooldown();
                                    }
                                  },
                                  child: Text(
                                    t.otp.resend,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
