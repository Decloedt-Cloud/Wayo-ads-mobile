import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/result.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/onboarding_gate.dart';
import '../login/widgets/animated_digital_zellij_background.dart';
import '../models/pending_signup_verify_store.dart';
import '../models/signup_verify_payload.dart';
import '../widgets/noise_overlay.dart';
import '../widgets/verify_email_otp_card.dart';

class SignupEmailVerificationScreen extends ConsumerStatefulWidget {
  const SignupEmailVerificationScreen({super.key, required this.payload});

  final SignupVerifyPayload payload;

  @override
  ConsumerState<SignupEmailVerificationScreen> createState() =>
      _SignupEmailVerificationScreenState();
}

class _SignupEmailVerificationScreenState
    extends ConsumerState<SignupEmailVerificationScreen> {
  int _cooldown = 0;
  Timer? _timer;
  int _otpKey = 0;
  bool _sending = false;
  bool _verifying = false;
  bool _codeSentBanner = false;
  String? _sendError;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _applyInitialDispatchState(widget.payload);
  }

  void _applyInitialDispatchState(SignupVerifyPayload payload) {
    if (payload.initialCodeSent) {
      _codeSentBanner = true;
      _startCooldown(payload.initialCooldownSeconds);
      return;
    }
    if (payload.initialSendError != null) {
      _sendError = payload.initialSendError;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
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
    final r = await repo.sendEmailVerificationOtp(email: widget.payload.email);
    if (!mounted) return;
    switch (r) {
      case Success(:final data):
        _startCooldown(data.clamp(30, 600));
        setState(() => _codeSentBanner = true);
      case Failure(:final error):
        if (error is RateLimitedException) {
          final seconds = error.retryAfterSeconds.clamp(1, 600);
          _startCooldown(seconds);
          setState(() => _codeSentBanner = true);
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
    final verify = await repo.confirmSignupEmailOtp(
      email: widget.payload.email,
      otp: _code,
    );
    if (!mounted) return;
    switch (verify) {
      case Success():
        await ref.read(authNotifierProvider.notifier).login(
              widget.payload.email,
              widget.payload.password,
            );
        if (!context.mounted) return;
        if (ref.read(authNotifierProvider).hasError) {
          WayoToast.error(context, t.signup.verify_then_sign_in);
          context.go('/login');
          return;
        }
        final s = ref.read(authNotifierProvider).valueOrNull;
        if (s is AuthAuthenticated) {
          clearPendingSignupVerifyPayload();
          final next = onboardingRedirectPath(s.user);
          context.go(next ?? '/dashboard');
        }
      case Failure(:final error):
        WayoToast.error(context, localizeAuthError(error, t));
        setState(() {
          _otpKey++;
          _code = '';
        });
    }
    if (mounted) setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
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
                onCodeChanged: (v) => setState(() => _code = v),
                onVerify: _submit,
                onResend: () async {
                  setState(() {
                    _otpKey++;
                    _code = '';
                  });
                  await _sendCode();
                },
                onDifferentAccount: () {
                  clearPendingSignupVerifyPayload();
                  context.go('/login');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
