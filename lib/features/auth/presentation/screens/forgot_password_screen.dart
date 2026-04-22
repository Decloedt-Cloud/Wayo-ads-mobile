import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/password_reset_top_bar.dart';
import '../widgets/rate_limit_cooldown_banner.dart';
import '../widgets/wayo_login_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forgotPasswordControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v, Translations t) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return t.validation.required;
    if (!_emailRegex.hasMatch(s)) return t.validation.invalid_email;
    return null;
  }

  Future<void> _submit(Translations t) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestOtp(_emailCtrl.text.trim());
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

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider, (
      prev,
      next,
    ) {
      if (next is FpOtpSent && prev is FpLoading) {
        context.push('/forgot-password/otp', extra: next.email);
      } else if (next is FpError && next.error is! RateLimitedException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAuthError(next.error, t))),
        );
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PasswordResetTopBar(),
                      const SizedBox(height: 8),
                      Text(
                            t.forgot_password.title,
                            style: AppTextStyles.displayLarge(
                              context,
                            ).copyWith(fontSize: 32, height: 1.1),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.12, curve: Curves.easeOutCubic),
                      const SizedBox(height: 12),
                      Text(
                        t.forgot_password.subtitle,
                        style: AppTextStyles.bodyLarge(context),
                      ).animate().fadeIn(delay: 120.ms, duration: 500.ms),
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          top: rate != null ? 16 : 0,
                          bottom: rate != null ? 16 : 0,
                        ),
                        child: rate == null
                            ? const SizedBox.shrink()
                            : RateLimitCooldownBanner(
                                key: ValueKey(rate.retryAfterSeconds),
                                initialSeconds: rate.retryAfterSeconds,
                                variant: RateLimitBannerVariant.passwordReset,
                                onComplete: () => ref
                                    .read(
                                      forgotPasswordControllerProvider.notifier,
                                    )
                                    .clearError(),
                              ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            validator: (v) => _validateEmail(v, t),
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(color: AppColors.textPrimaryOf(context)),
                            decoration: InputDecoration(
                              labelText: t.forgot_password.email_label,
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 220.ms, duration: 500.ms)
                          .slideY(begin: 0.08),
                      const SizedBox(height: 32),
                      IgnorePointer(
                            ignoring: rate != null,
                            child: Opacity(
                              opacity: rate != null ? 0.45 : 1,
                              child: WayoLoginButton(
                                isLoading: loading,
                                label: t.forgot_password.cta,
                                onPressed: () => _submit(t),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 320.ms, duration: 500.ms)
                          .slideY(begin: 0.12),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
