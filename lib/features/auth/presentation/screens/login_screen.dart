import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../data/apple_sign_in_facade.dart';
import '../../data/google_sign_in_facade.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/onboarding_gate.dart';
import '../login/widgets/animated_digital_zellij_background.dart';
import '../login/widgets/login_field_styles.dart';
import '../login/widgets/login_hero_premium.dart';
import '../login/widgets/premium_apple_sign_in_button.dart';
import '../login/widgets/premium_google_button.dart';
import '../widgets/login_footer.dart';
import '../widgets/rate_limit_cooldown_banner.dart';
import '../widgets/noise_overlay.dart';
import '../widgets/wayo_logo.dart';
import '../widgets/wayo_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _googleSigningIn = false;
  bool _appleSigningIn = false;
  bool _sessionExpiredSnackScheduled = false;

  /// Blocks duplicate POSTs when both "Done" on keyboard and the CTA fire together.
  bool _submitInProgress = false;

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionExpiredSnackScheduled) return;
    final q = GoRouterState.of(context).uri.queryParameters;
    if (q['sessionExpired'] != '1') return;
    _sessionExpiredSnackScheduled = true;
    final t = context.t;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WayoToast.error(context, t.login.session_expired_snack);
      if (context.mounted) context.go('/login');
    });
  }

  String? _validateEmail(String? v, Translations t) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return t.login.email_required;
    if (!_emailRegex.hasMatch(s)) return t.login.email_invalid;
    return null;
  }

  String? _validatePassword(String? v, Translations t) {
    final s = v ?? '';
    if (s.isEmpty) return t.login.password_required;
    if (s.length < 6) return t.login.password_min;
    return null;
  }

  Future<void> _submit(Translations t) async {
    if (_submitInProgress) {
      return;
    }
    _submitInProgress = true;
    try {
      FocusScope.of(context).unfocus();
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) {
        return;
      }
      await ref
          .read(authNotifierProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (!context.mounted) {
        return;
      }
      if (ref.read(authNotifierProvider).hasError) {
        return;
      }
      _goAfterLogin(ref);
    } finally {
      if (mounted) {
        _submitInProgress = false;
      }
    }
  }

  Future<void> _signInWithGoogle(Translations t) async {
    if (_googleSigningIn) return;
    final googleCid = AuthRuntimeConfig.instance.googleServerClientId;
    if (googleCid.isEmpty) {
      if (!mounted) return;
      WayoToast.error(context, t.login.google_not_configured);
      return;
    }
    if (!AuthRuntimeConfig.looksLikeGoogleWebClientId(googleCid)) {
      if (!mounted) return;
      WayoToast.error(context, t.login.google_wrong_client_id);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _googleSigningIn = true);
    try {
      final idToken = await GoogleSignInFacade.signInForIdToken(googleCid);
      if (!mounted) return;
      if (idToken == null) {
        return;
      }
      if (idToken.isEmpty) {
        WayoToast.error(context, t.login.google_failed);
        return;
      }
      await ref.read(authNotifierProvider.notifier).loginWithGoogle(idToken);
      if (!context.mounted) return;
      if (ref.read(authNotifierProvider).hasError) return;
      _goAfterLogin(ref);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final msg = GoogleSignInFacade.looksLikeStaleChannel(e)
          ? t.login.google_channel_restart
          : GoogleSignInFacade.isAndroidDeveloperConfigError(e)
          ? t.login.google_android_oauth_misconfigured
          : (e.message?.isNotEmpty == true
                ? e.message!
                : t.login.google_failed);
      WayoToast.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      final msg = GoogleSignInFacade.looksLikeStaleChannel(e)
          ? t.login.google_channel_restart
          : GoogleSignInFacade.isAndroidDeveloperConfigError(e)
          ? t.login.google_android_oauth_misconfigured
          : t.login.google_failed;
      WayoToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _googleSigningIn = false);
    }
  }

  Future<void> _signInWithApple(Translations t) async {
    if (_appleSigningIn) return;
    if (kIsWeb || Theme.of(context).platform != TargetPlatform.iOS) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _appleSigningIn = true);
    try {
      final cred = await AppleSignInFacade.signInOnIos();
      if (!mounted) return;
      if (cred == null) {
        WayoToast.error(context, t.login.apple_unavailable);
        return;
      }
      await ref.read(authNotifierProvider.notifier).loginWithApple(
            identityToken: cred.identityToken,
            rawNonce: cred.rawNonce,
            authorizationCode: cred.authorizationCode,
            appleUserId: cred.userIdentifier,
          );
      if (!context.mounted) return;
      if (ref.read(authNotifierProvider).hasError) return;
      _goAfterLogin(ref);
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

  void _goAfterLogin(WidgetRef ref) {
    if (!mounted) return;
    final s = ref.read(authNotifierProvider).valueOrNull;
    if (s is! AuthAuthenticated) return;
    final next = onboardingRedirectPath(s.user);
    context.go(next ?? '/dashboard');
  }

  SystemUiOverlayStyle _overlayFor(Brightness b) {
    if (b == Brightness.dark) {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFAFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    );
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
    final showAppleLogin =
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
    final media = MediaQuery.of(context);
    final brightness = Theme.of(context).brightness;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayFor(brightness),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedDigitalZellijBackground(reduceMotion: reduce),
            ),
            Positioned.fill(
              child: NoiseOverlay(
                opacity: brightness == Brightness.dark ? 0.032 : 0.022,
              ),
            ),
            SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.deferToChild,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    media.size.height * 0.04,
                    24,
                    24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LoginTopBar(reduce: reduce, brand: t.login.brand),
                          SizedBox(height: media.size.height * 0.038),
                          _wrapEntrance(
                            reduce,
                            LoginHeroPremium(reduceMotion: reduce),
                            baseDelay: 240.ms,
                          ),
                          const SizedBox(height: 18),
                          _wrapEntrance(
                            reduce,
                            Text(
                              t.login.subtitle,
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                color: AppColors.textSecondaryOf(context),
                                height: 1.45,
                                fontSize: 15,
                              ),
                            ),
                            baseDelay: 380.ms,
                          ),
                          const SizedBox(height: 28),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.only(
                              bottom: (rateLimit == null && apiError == null)
                                  ? 0
                                  : 16,
                            ),
                            child: rateLimit != null
                                ? RateLimitCooldownBanner(
                                    key: ValueKey(rateLimit.retryAfterSeconds),
                                    initialSeconds: rateLimit.retryAfterSeconds,
                                    onComplete: () => ref
                                        .read(authNotifierProvider.notifier)
                                        .clearLoginError(),
                                  )
                                : apiError == null
                                ? const SizedBox.shrink()
                                : Material(
                                    color: AppColors.surfaceElevatedOf(context),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              apiError,
                                              style:
                                                  AppTextStyles.bodyLarge(
                                                    context,
                                                  ).copyWith(
                                                    color: AppColors.error,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          _wrapEntrance(
                            reduce,
                            TextFormField(
                              controller: _email,
                              readOnly: formLocked,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) => _validateEmail(v, t),
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: loginPremiumInputDecoration(
                                context,
                                labelText: t.login.email_label,
                              ),
                            ),
                            baseDelay: 480.ms,
                          ),
                          const SizedBox(height: 14),
                          _wrapEntrance(
                            reduce,
                            TextFormField(
                              controller: _password,
                              readOnly: formLocked,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              validator: (v) => _validatePassword(v, t),
                              onFieldSubmitted: (_) {
                                if (!formLocked) unawaited(_submit(t));
                              },
                              style: AppTextStyles.bodyLarge(context).copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: loginPremiumInputDecoration(
                                context,
                                labelText: t.login.password_label,
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? t.login.show_password
                                      : t.login.hide_password,
                                  onPressed: formLocked
                                      ? null
                                      : () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ),
                            ),
                            baseDelay: 540.ms,
                          ),
                          const SizedBox(height: 26),
                          _wrapEntrance(
                            reduce,
                            WayoLoginButton(
                              isLoading: loading,
                              enabled: !loading && !_googleSigningIn && !_appleSigningIn,
                              onPressed: () => unawaited(_submit(t)),
                              label: t.login.cta,
                            ),
                            baseDelay: 620.ms,
                            slideFrom: 0.2,
                          ),
                          if (showAppleLogin) ...[
                            const SizedBox(height: 14),
                            _wrapEntrance(
                              reduce,
                              PremiumAppleSignInButton(
                                busy: _appleSigningIn,
                                enabled: !formLocked,
                                label: t.login.apple_cta,
                                onPressed: () => unawaited(_signInWithApple(t)),
                              ),
                              baseDelay: 660.ms,
                              slideFrom: 0.18,
                            ),
                            const SizedBox(height: 8),
                            _wrapEntrance(
                              reduce,
                              Text(
                                t.login.apple_hide_my_email_hint,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyLarge(context).copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryOf(context),
                                  height: 1.35,
                                ),
                              ),
                              baseDelay: 680.ms,
                              slideFrom: 0.16,
                            ),
                          ],
                          const SizedBox(height: 14),
                          _wrapEntrance(
                            reduce,
                            PremiumGoogleSignInButton(
                              busy: _googleSigningIn,
                              enabled: !formLocked,
                              label: t.login.google_cta,
                              onPressed: () => unawaited(_signInWithGoogle(t)),
                            ),
                            baseDelay: showAppleLogin ? 720.ms : 680.ms,
                            slideFrom: 0.16,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: formLocked
                                  ? null
                                  : () => context.push('/forgot-password'),
                              child: Text(
                                t.login.forgot_password_link,
                                style: AppTextStyles.labelLarge(context)
                                    .copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _wrapEntrance(
                            reduce,
                            const LoginFooter(),
                            baseDelay: 780.ms,
                            slideFrom: 0.08,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _wrapEntrance(
  bool reduce,
  Widget child, {
  required Duration baseDelay,
  double slideFrom = 0.12,
}) {
  if (reduce) {
    return child;
  }
  return child
      .animate()
      .fadeIn(delay: baseDelay, duration: 720.ms, curve: Curves.easeOutCubic)
      .slideY(begin: slideFrom, duration: 720.ms, curve: Curves.easeOutCubic);
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar({required this.reduce, required this.brand});

  final bool reduce;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final row = Row(
      children: [
        WayoLogo(size: 50, enableMotion: !reduce),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            brand,
            style: AppTextStyles.headlineMedium(context).copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThemeToggleButton(),
              SizedBox(width: 4),
              LanguageSwitcher(),
            ],
          ),
        ),
      ],
    );
    if (reduce) {
      return row;
    }
    return row
        .animate()
        .fadeIn(duration: 560.ms, curve: Curves.easeOutCubic)
        .slideX(begin: -0.12, duration: 560.ms, curve: Curves.easeOutCubic);
  }
}
