import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/result.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/onboarding_gate.dart';
import '../widgets/otp_input_field.dart';

class EmailVerificationOtpOnboardingScreen extends ConsumerStatefulWidget {
  const EmailVerificationOtpOnboardingScreen({super.key});

  @override
  ConsumerState<EmailVerificationOtpOnboardingScreen> createState() =>
      _EmailVerificationOtpOnboardingScreenState();
}

class _EmailVerificationOtpOnboardingScreenState
    extends ConsumerState<EmailVerificationOtpOnboardingScreen>
    with TickerProviderStateMixin {
  static const _cooldownSeconds = 60;
  int _cooldown = _cooldownSeconds;
  Timer? _timer;
  int _otpKey = 0;
  bool _sending = true;
  bool _verifying = false;
  String? _sendError;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _orange = Color(0xFFF97316);
  static const _orangeLight = Color(0xFFFFEDD5);
  static const _dark = Color(0xFF18181B);
  static const _darkCard = Color(0xFF27272A);
  static const _darkBorder = Color(0xFF3F3F46);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    unawaited(_sendCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
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
    final email = ref
        .read(authNotifierProvider)
        .maybeWhen(
          data: (s) => s is AuthAuthenticated ? s.user.email : null,
          orElse: () => null,
        );
    final r = await repo.sendEmailVerificationOtp(email: email);
    if (!mounted) return;
    switch (r) {
      case Success(:final data):
        _startCooldown(data.clamp(30, 600));
      case Failure(:final error):
        _sendError = localizeAuthError(error, context.t);
    }
    setState(() => _sending = false);
  }

  Future<void> _submit(String code) async {
    if (_verifying) return;
    setState(() => _verifying = true);
    final t = context.t;
    final repo = ref.read(authRepositoryProvider);
    final email = ref
        .read(authNotifierProvider)
        .maybeWhen(
          data: (s) => s is AuthAuthenticated ? s.user.email : null,
          orElse: () => null,
        );
    final r = await repo.confirmEmailAddressOtp(code, email: email);
    if (!mounted) return;
    switch (r) {
      case Success(:final data):
        await ref.read(authNotifierProvider.notifier).applyOnboardingUser(data);
        if (!mounted) return;
        final next = onboardingRedirectPath(data);
        context.go(next ?? '/dashboard');
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeAuthError(error, t)),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() => _otpKey++);
    }
    if (mounted) setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = ref
        .watch(authNotifierProvider)
        .maybeWhen(
          data: (s) => s is AuthAuthenticated ? s.user.email : '',
          orElse: () => '',
        );

    return Scaffold(
      backgroundColor: isDark ? _dark : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(isDark, t, email),
                const SizedBox(height: 48),
                _buildOtpSection(isDark, t),
                const SizedBox(height: 32),
                _buildResendSection(isDark, t),
                const SizedBox(height: 48),
                _buildSignOutButton(isDark, t),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Translations t, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_orange, Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _orange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t.onboarding.email_code_title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : _dark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: t.onboarding
                    .email_code_subtitle(email: '')
                    .split(email)
                    .first,
              ),
              TextSpan(
                text: email,
                style: TextStyle(color: _orange, fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: t.onboarding
                    .email_code_subtitle(email: '')
                    .split(email)
                    .last,
              ),
            ],
          ),
        ),
        if (_sendError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[400],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _sendError!,
                    style: TextStyle(fontSize: 14, color: Colors.red[400]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOtpSection(bool isDark, Translations t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? _darkCard : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? _darkBorder : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Enter verification code',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          if (_sending)
            Column(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _orange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sending code...',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            )
          else if (_verifying)
            Column(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _orange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verifying...',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            )
          else
            OtpInputField(key: ValueKey(_otpKey), onCompleted: _submit),
        ],
      ),
    );
  }

  Widget _buildResendSection(bool isDark, Translations t) {
    return Center(
      child: _cooldown > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? _darkCard : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.otp.resend_in(seconds: _cooldown),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : TextButton.icon(
              onPressed: _sending || _verifying
                  ? null
                  : () async {
                      await _sendCode();
                      if (mounted) setState(() => _otpKey++);
                    },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(t.otp.resend),
              style: TextButton.styleFrom(
                foregroundColor: _orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildSignOutButton(bool isDark, Translations t) {
    return Center(
      child: TextButton.icon(
        onPressed: () =>
            unawaited(ref.read(authNotifierProvider.notifier).logout()),
        icon: Icon(
          Icons.logout_rounded,
          size: 18,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        label: Text(
          t.verify_email.sign_out,
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
