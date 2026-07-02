import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/apple_sign_in_facade.dart';
import '../../data/google_sign_in_facade.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/onboarding_gate.dart';
import '../../domain/register_field_check.dart';
import '../login/widgets/animated_digital_zellij_background.dart';
import '../login/widgets/login_field_styles.dart';
import '../login/widgets/premium_apple_sign_in_button.dart';
import '../login/widgets/premium_google_button.dart';
import '../models/signup_verify_payload.dart';
import '../widgets/login_footer.dart';
import '../widgets/noise_overlay.dart';
import '../widgets/password_requirements_panel.dart';
import '../widgets/rate_limit_cooldown_banner.dart';
import '../widgets/register_field_alert_banner.dart';
import '../widgets/wayo_logo.dart';
import '../widgets/wayo_login_button.dart';

class SignupRegisterScreen extends ConsumerStatefulWidget {
  const SignupRegisterScreen({super.key, required this.role});

  final String role;

  @override
  ConsumerState<SignupRegisterScreen> createState() =>
      _SignupRegisterScreenState();
}

class _SignupRegisterScreenState extends ConsumerState<SignupRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _googleSigningIn = false;
  bool _appleSigningIn = false;
  bool _submitInProgress = false;

  static const _checkDebounceMs = 450;
  Timer? _nameCheckTimer;
  Timer? _emailCheckTimer;
  RegisterFieldCheck _nameCheck = const RegisterFieldCheck();
  RegisterFieldCheck _emailCheck = const RegisterFieldCheck();
  String _lastCheckedName = '';
  String _lastCheckedEmail = '';

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
    _name.addListener(_scheduleNameCheck);
    _email.addListener(_scheduleEmailCheck);
  }

  @override
  void dispose() {
    _nameCheckTimer?.cancel();
    _emailCheckTimer?.cancel();
    _name.removeListener(_scheduleNameCheck);
    _email.removeListener(_scheduleEmailCheck);
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validateName(String? v, Translations t) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return t.signup.name_required;
    return null;
  }

  String? _validateEmail(String? v, Translations t) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return t.login.email_required;
    if (!_emailRegex.hasMatch(s)) return t.login.email_invalid;
    return null;
  }

  String? _validatePassword(String? v, Translations t) {
    return passwordRequirementsValidationError(v ?? '', t);
  }

  void _scheduleNameCheck() {
    _nameCheckTimer?.cancel();
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _nameCheck = const RegisterFieldCheck();
        _lastCheckedName = '';
      });
      return;
    }
    setState(() {
      _nameCheck = const RegisterFieldCheck();
      _lastCheckedName = '';
    });
    _nameCheckTimer = Timer(
      const Duration(milliseconds: _checkDebounceMs),
      () => unawaited(_runNameCheck(trimmed)),
    );
  }

  void _scheduleEmailCheck() {
    _emailCheckTimer?.cancel();
    final trimmed = _email.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _emailCheck = const RegisterFieldCheck();
        _lastCheckedEmail = '';
      });
      return;
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      setState(() {
        _emailCheck = const RegisterFieldCheck(
          state: RegisterFieldCheckState.invalid,
        );
        _lastCheckedEmail = '';
      });
      return;
    }
    setState(() {
      _emailCheck = const RegisterFieldCheck();
      _lastCheckedEmail = '';
    });
    _emailCheckTimer = Timer(
      const Duration(milliseconds: _checkDebounceMs),
      () => unawaited(_runEmailCheck(trimmed)),
    );
  }

  RegisterFieldCheck _mapAvailability(
    RegisterFieldAvailability data,
    Translations t, {
    required bool email,
  }) {
    if (data.available) {
      return const RegisterFieldCheck(state: RegisterFieldCheckState.ok);
    }
    if (data.reason == 'disposable') {
      return RegisterFieldCheck(
        state: RegisterFieldCheckState.disposable,
        message: data.message ?? t.signup.disposable_email,
      );
    }
    return RegisterFieldCheck(
      state: RegisterFieldCheckState.taken,
      message: data.message ??
          (email ? t.signup.email_taken : t.signup.name_taken),
    );
  }

  Future<bool> _runNameCheck(String name, {bool force = false}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _nameCheck = const RegisterFieldCheck(state: RegisterFieldCheckState.invalid);
      });
      return false;
    }
    if (!force &&
        trimmed == _lastCheckedName &&
        _nameCheck.state == RegisterFieldCheckState.ok) {
      return true;
    }
    setState(() {
      _nameCheck = const RegisterFieldCheck(
        state: RegisterFieldCheckState.checking,
      );
    });
    final t = context.t;
    final result =
        await ref.read(authRepositoryProvider).checkRegisterName(trimmed);
    if (!mounted) return false;
    switch (result) {
      case Success(:final data):
        final mapped = _mapAvailability(data, t, email: false);
        setState(() {
          _nameCheck = mapped;
          _lastCheckedName = trimmed;
        });
        return mapped.state == RegisterFieldCheckState.ok;
      case Failure(:final error):
        setState(() {
          _nameCheck = RegisterFieldCheck(
            state: RegisterFieldCheckState.error,
            message: localizeAuthError(error, t).isNotEmpty
                ? localizeAuthError(error, t)
                : t.signup.name_check_failed,
          );
        });
        return false;
    }
  }

  Future<bool> _runEmailCheck(String email, {bool force = false}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !_emailRegex.hasMatch(trimmed)) {
      setState(() {
        _emailCheck = RegisterFieldCheck(
          state: RegisterFieldCheckState.invalid,
        );
      });
      return false;
    }
    if (!force &&
        trimmed == _lastCheckedEmail &&
        _emailCheck.state == RegisterFieldCheckState.ok) {
      return true;
    }
    setState(() {
      _emailCheck = const RegisterFieldCheck(
        state: RegisterFieldCheckState.checking,
      );
    });
    final t = context.t;
    final result =
        await ref.read(authRepositoryProvider).checkRegisterEmail(trimmed);
    if (!mounted) return false;
    switch (result) {
      case Success(:final data):
        final mapped = _mapAvailability(data, t, email: true);
        setState(() {
          _emailCheck = mapped;
          _lastCheckedEmail = trimmed;
        });
        return mapped.state == RegisterFieldCheckState.ok;
      case Failure(:final error):
        setState(() {
          _emailCheck = RegisterFieldCheck(
            state: RegisterFieldCheckState.error,
            message: localizeAuthError(error, t).isNotEmpty
                ? localizeAuthError(error, t)
                : t.signup.email_check_failed,
          );
        });
        return false;
    }
  }

  bool get _availabilityBlocksSubmit =>
      _nameCheck.blocksSubmit || _emailCheck.blocksSubmit;

  bool get _nameFieldError =>
      _nameCheck.state == RegisterFieldCheckState.taken ||
      _nameCheck.state == RegisterFieldCheckState.error;

  bool get _emailFieldError =>
      _emailCheck.state == RegisterFieldCheckState.taken ||
      _emailCheck.state == RegisterFieldCheckState.disposable ||
      _emailCheck.state == RegisterFieldCheckState.error;

  Future<void> _submit(Translations t) async {
    if (_submitInProgress) return;
    _submitInProgress = true;
    try {
      FocusScope.of(context).unfocus();
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
      if (_password.text != _confirmPassword.text) {
        WayoToast.error(context, t.validation.mismatch);
        return;
      }
      final nameOk = await _runNameCheck(_name.text, force: true);
      final emailOk = await _runEmailCheck(_email.text, force: true);
      if (!nameOk || !emailOk) return;
      final outcome = await ref.read(authNotifierProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: widget.role,
          );
      if (!mounted) return;
      if (ref.read(authNotifierProvider).hasError) return;
      if (outcome == RegisterOutcome.needsEmailVerification) {
        context.go(
          '/signup/verify-otp',
          extra: SignupVerifyPayload(
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
        return;
      }
      _goAfterAuth(ref);
    } finally {
      if (mounted) _submitInProgress = false;
    }
  }

  Future<void> _signInWithGoogle(Translations t) async {
    if (_googleSigningIn) return;
    final googleCid = AuthRuntimeConfig.instance.googleServerClientId;
    if (googleCid.isEmpty) {
      WayoToast.error(context, t.login.google_not_configured);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _googleSigningIn = true);
    try {
      final idToken = await GoogleSignInFacade.signInForIdToken(googleCid);
      if (!mounted) return;
      if (idToken == null || idToken.isEmpty) {
        if (idToken != null) WayoToast.error(context, t.login.google_failed);
        return;
      }
      await ref
          .read(authNotifierProvider.notifier)
          .signupWithGoogle(idToken, widget.role);
      if (!context.mounted) return;
      if (ref.read(authNotifierProvider).hasError) return;
      _goAfterAuth(ref);
    } on PlatformException catch (e) {
      if (!mounted) return;
      WayoToast.error(context, _googleErrorMessage(e, t));
    } catch (e) {
      if (!mounted) return;
      WayoToast.error(context, t.login.google_failed);
    } finally {
      if (mounted) setState(() => _googleSigningIn = false);
    }
  }

  Future<void> _signInWithApple(Translations t) async {
    if (_appleSigningIn) return;
    if (kIsWeb || Theme.of(context).platform != TargetPlatform.iOS) return;
    FocusScope.of(context).unfocus();
    setState(() => _appleSigningIn = true);
    try {
      final cred = await AppleSignInFacade.signInOnIos();
      if (!mounted) return;
      if (cred == null) {
        WayoToast.error(context, t.login.apple_unavailable);
        return;
      }
      await ref.read(authNotifierProvider.notifier).signupWithApple(
            role: widget.role,
            identityToken: cred.identityToken,
            rawNonce: cred.rawNonce,
            authorizationCode: cred.authorizationCode,
            appleUserId: cred.userIdentifier,
          );
      if (!context.mounted) return;
      if (ref.read(authNotifierProvider).hasError) return;
      _goAfterAuth(ref);
    } on SignInWithAppleNotSupportedException {
      if (!mounted) return;
      WayoToast.error(context, t.login.apple_unavailable);
    } catch (e) {
      if (!mounted) return;
      if (AppleSignInFacade.isUserCanceled(e)) {
        WayoToast.info(context, t.login.apple_canceled);
        return;
      }
      WayoToast.error(context, t.login.apple_failed);
    } finally {
      if (mounted) setState(() => _appleSigningIn = false);
    }
  }

  String _googleErrorMessage(PlatformException e, Translations t) {
    if (GoogleSignInFacade.looksLikeStaleChannel(e)) {
      return t.login.google_channel_restart;
    }
    if (GoogleSignInFacade.isAndroidDeveloperConfigError(e)) {
      return t.login.google_android_oauth_misconfigured;
    }
    return e.message?.isNotEmpty == true ? e.message! : t.login.google_failed;
  }

  void _goAfterAuth(WidgetRef ref) {
    if (!mounted) return;
    final s = ref.read(authNotifierProvider).valueOrNull;
    if (s is! AuthAuthenticated) return;
    final next = onboardingRedirectPath(s.user);
    context.go(next ?? '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final auth = ref.watch(authNotifierProvider);
    final loading = auth.maybeWhen(
      data: (s) => s is AuthLoading,
      orElse: () => false,
    );
    final formLocked = loading || _googleSigningIn || _appleSigningIn;
    final showApple =
        !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS;
    final rateLimit = auth.maybeWhen(
      error: (e, _) => e is RateLimitedException ? e : null,
      orElse: () => null,
    );
    final apiError = rateLimit == null
        ? auth.maybeWhen(
            error: (e, _) => localizeAuthError(e, t),
            orElse: () => null,
          )
        : null;
    final canSubmit = !formLocked && !_availabilityBlocksSubmit;
    final roleLabel = widget.role == 'ADVERTISER'
        ? t.onboarding.role_advertiser_cta
        : t.onboarding.role_creator_cta;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final media = MediaQuery.of(context);

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
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: formLocked
                                ? null
                                : () => context.go('/signup'),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Row(
                        children: [
                          const WayoLogo(size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.signup.create_account,
                              style: AppTextStyles.headlineMedium(context)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.signup.register_subtitle(role: roleLabel),
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.textSecondaryOf(context),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_nameCheck.message != null) ...[
                        RegisterFieldAlertBanner(message: _nameCheck.message!),
                        const SizedBox(height: 10),
                      ],
                      if (_emailCheck.message != null) ...[
                        RegisterFieldAlertBanner(message: _emailCheck.message!),
                        const SizedBox(height: 10),
                      ],
                      if (rateLimit != null)
                        RateLimitCooldownBanner(
                          key: ValueKey(rateLimit.retryAfterSeconds),
                          initialSeconds: rateLimit.retryAfterSeconds,
                          onComplete: () => ref
                              .read(authNotifierProvider.notifier)
                              .clearLoginError(),
                        )
                      else if (apiError != null)
                        _errorBanner(context, apiError),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _name,
                        readOnly: formLocked,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => _validateName(v, t),
                        decoration: loginPremiumInputDecoration(
                          context,
                          labelText: t.signup.name_label,
                          showErrorBorder: _nameFieldError,
                        ),
                        onTapOutside: (_) =>
                            unawaited(_runNameCheck(_name.text)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        readOnly: formLocked,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => _validateEmail(v, t),
                        decoration: loginPremiumInputDecoration(
                          context,
                          labelText: t.login.email_label,
                          showErrorBorder: _emailFieldError,
                        ),
                        onTapOutside: (_) =>
                            unawaited(_runEmailCheck(_email.text)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        readOnly: formLocked,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => _validatePassword(v, t),
                        decoration: loginPremiumInputDecoration(
                          context,
                          labelText: t.login.password_label,
                          suffixIcon: IconButton(
                            onPressed: formLocked
                                ? null
                                : () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PasswordRequirementsPanel(password: _password.text),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPassword,
                        readOnly: formLocked,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) {
                          if ((v ?? '').isEmpty) return t.validation.required;
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!formLocked) unawaited(_submit(t));
                        },
                        decoration: loginPremiumInputDecoration(
                          context,
                          labelText: t.signup.confirm_password_label,
                          suffixIcon: IconButton(
                            onPressed: formLocked
                                ? null
                                : () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      WayoLoginButton(
                        isLoading: loading,
                        enabled: canSubmit,
                        onPressed: () => unawaited(_submit(t)),
                        label: t.signup.register_cta,
                      ),
                      if (showApple) ...[
                        const SizedBox(height: 14),
                        PremiumAppleSignInButton(
                          busy: _appleSigningIn,
                          enabled: !formLocked,
                          label: t.login.apple_cta,
                          onPressed: () => unawaited(_signInWithApple(t)),
                        ),
                      ],
                      const SizedBox(height: 14),
                      PremiumGoogleSignInButton(
                        busy: _googleSigningIn,
                        enabled: !formLocked,
                        label: t.login.google_cta,
                        onPressed: () => unawaited(_signInWithGoogle(t)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.signup.already_have_account,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                formLocked ? null : () => context.go('/login'),
                            child: Text(t.signup.sign_in_link),
                          ),
                        ],
                      ),
                      SizedBox(height: media.size.height * 0.02),
                      const LoginFooter(),
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

  Widget _errorBanner(BuildContext context, String message) {
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
