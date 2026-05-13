import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/domain/auth_notifier.dart';
import '../auth/domain/onboarding_gate.dart';
import 'premium_splash_animated_logo.dart';

/// Animated splash (~2.5s) + auth gate.
///
/// No `FlutterNativeSplash.preserve` in `main.dart` on purpose: `preserve` defers the first
/// Flutter frame, prolonging the static OS launch screen. Without it, the very first frame
/// painted by Flutter matches the native splash ([assets/branding/wayo_native_splash_logo.png]).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const int _timelineMs = 2500;

  late final AnimationController _controller;

  bool _exitScheduled = false;

  double get _t => _controller.value;

  double _introScale() {
    if (_t <= 0) return 0.94;
    const end = 550 / _timelineMs;
    if (_t >= end) return 1.0;
    return 0.94 + 0.06 * Curves.easeOutCubic.transform(_t / end);
  }

  double _screenFadeOpacity() {
    const start = 2300 / _timelineMs;
    if (_t < start) return 1.0;
    return 1.0 - Curves.easeIn.transform((_t - start) / (1.0 - start));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _timelineMs),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]));

    final Future<void> animationDone;
    if (reduceMotion) {
      _controller.value = 1.0;
      animationDone = Future<void>.value();
    } else {
      animationDone = _controller.forward();
    }

    var authThrew = false;
    final stateFuture = _authStateResolved().onError((Object _, StackTrace st) {
      authThrew = true;
      return const AuthUnauthenticated();
    });

    await Future.wait([animationDone, stateFuture]);

    if (!mounted || _exitScheduled) return;
    _exitScheduled = true;

    final state = await stateFuture;
    final target = _destinationFor(state);
    final snap = ref.read(authNotifierProvider);
    final sessionExpired = target == '/login' &&
        (authThrew || snap.hasError);

    if (!mounted) return;
    if (sessionExpired) {
      context.go('/login?sessionExpired=1');
    } else {
      context.go(target);
    }
  }

  Future<AuthState> _authStateResolved() async {
    try {
      final async = ref.read(authNotifierProvider);
      return await async.when(
        data: (AuthState s) => Future<AuthState>.value(s),
        loading: () => ref.read(authNotifierProvider.future),
        error: (Object e, StackTrace st) =>
            Future<AuthState>.value(const AuthUnauthenticated()),
      );
    } catch (_) {
      return const AuthUnauthenticated();
    }
  }

  String _destinationFor(AuthState state) {
    if (state is AuthAuthenticated) {
      return onboardingRedirectPath(state.user) ?? '/dashboard';
    }
    return '/login';
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final w = MediaQuery.sizeOf(context).width;
    /// Logo glyph box (wordmark sits beside); row is scaled down via [FittedBox] if needed.
    final maxLogo = (w * 0.34).clamp(120.0, 200.0);

    return Theme(
      data: ThemeData(brightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final screenOpacity =
                reduceMotion ? 1.0 : _screenFadeOpacity().clamp(0.0, 1.0);
            final scale = reduceMotion ? 1.0 : _introScale();

            return Opacity(
              opacity: screenOpacity,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PremiumSplashAnimatedLogo(
                        animation: _controller,
                        reduceMotion: reduceMotion,
                        maxLogoSize: maxLogo,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
