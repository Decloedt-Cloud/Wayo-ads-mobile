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
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/noise_overlay.dart';
import '../widgets/password_reset_top_bar.dart';
import '../widgets/password_requirements_panel.dart';
import '../widgets/rate_limit_cooldown_banner.dart';
import '../widgets/wayo_login_button.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void initState() {
    super.initState();
    _pwdCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v, Translations t) {
    return passwordRequirementsValidationError(v ?? '', t);
  }

  Future<void> _submit(Translations t) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pwdCtrl.text != _confirmCtrl.text) {
      WayoToast.error(context, t.validation.mismatch);
      return;
    }
    HapticFeedback.mediumImpact();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .resetPassword(resetToken: widget.resetToken, password: _pwdCtrl.text);
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

    if (widget.resetToken.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider, (
      prev,
      next,
    ) {
      if (next is FpSuccess && prev is FpLoading) {
        ref.read(forgotPasswordControllerProvider.notifier).reset();
        WayoToast.success(context, t.reset_password.password_updated);
        context.go('/login');
      } else if (next is FpError && next.error is! RateLimitedException) {
        WayoToast.error(context, localizeAuthError(next.error, t));
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
                        t.reset_password.title,
                        style: AppTextStyles.displayLarge(
                          context,
                        ).copyWith(fontSize: 32, height: 1.1),
                      ).animate().fadeIn(duration: 450.ms),
                      const SizedBox(height: 12),
                      Text(
                        t.reset_password.subtitle,
                        style: AppTextStyles.bodyLarge(context),
                      ),
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
                      IgnorePointer(
                        ignoring: rate != null,
                        child: Opacity(
                          opacity: rate != null ? 0.45 : 1,
                          child: TextFormField(
                            controller: _pwdCtrl,
                            obscureText: _obscure1,
                            validator: (v) => _validatePassword(v, t),
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(color: AppColors.textPrimaryOf(context)),
                            decoration: InputDecoration(
                              labelText: t.reset_password.new_password,
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PasswordRequirementsPanel(password: _pwdCtrl.text),
                      const SizedBox(height: 16),
                      IgnorePointer(
                        ignoring: rate != null,
                        child: Opacity(
                          opacity: rate != null ? 0.45 : 1,
                          child: TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure2,
                            validator: (v) => _validatePassword(v, t),
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(color: AppColors.textPrimaryOf(context)),
                            decoration: InputDecoration(
                              labelText: t.reset_password.confirm_password,
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      IgnorePointer(
                        ignoring: rate != null,
                        child: Opacity(
                          opacity: rate != null ? 0.45 : 1,
                          child: WayoLoginButton(
                            isLoading: loading,
                            label: t.reset_password.cta,
                            onPressed: () => _submit(t),
                          ),
                        ),
                      ),
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
