import 'dart:async';
import 'dart:math' show cos, pi, sin;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../auth/presentation/widgets/noise_overlay.dart';
import 'controllers/splash_sequence.dart';
import 'painters/particle_system_painter.dart';
import 'painters/ripple_radar_painter.dart';
import 'painters/scan_line_painter.dart';
import 'painters/shockwave_painter.dart';
import 'painters/wayo_mark_painter.dart';
import 'painters/wordmark_painter.dart';
import 'widgets/liquid_metal_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  AnimationController? _master;
  late final AnimationController _ripple;
  final _particles = ParticleSystem(count: 80);
  final Set<int> _firedHaptic = {};
  bool _skipped = false;
  bool _navigated = false;
  bool _seeded = false;
  bool _splashBooted = false;
  bool _reducedMotion = false;
  bool _secondLaunch = false;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _useSensorTilt = true;
  double _tiltX = 0;
  double _tiltY = 0;
  SplashWordmarkLayout? _wordmarkLayout;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _seeded) {
        return;
      }
      _seeded = true;
      _particles.seed(MediaQuery.sizeOf(context));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_splashBooted) {
      return;
    }
    _splashBooted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_startSplashTimeline());
    });
  }

  /// Visual timeline; navigation when animation completes (or skip).
  Future<void> _startSplashTimeline() async {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final prefs = ref.read(appPrefsProvider);
    final second =
        !reduced && prefs.getString(SplashPrefKeys.completedOnce) == '1';
    final visual = reduced
        ? SplashSequence.reducedMotionDuration
        : second
        ? SplashSequence.secondLaunchDuration
        : SplashSequence.totalDuration;

    if (!mounted) {
      return;
    }
    setState(() {
      _reducedMotion = reduced;
      _secondLaunch = second;
      _master = AnimationController(vsync: this, duration: visual)
        ..addListener(_onMasterTick);
    });

    if (!reduced && !kIsWeb) {
      _scheduleAccelerometer();
    }

    final m = _master;
    if (m == null) {
      return;
    }
    try {
      await m.forward();
    } catch (_) {
      // Interrupted during dispose / stop: still exit below if allowed.
    }
    if (!mounted || _skipped || _navigated) {
      return;
    }
    await _onComplete();
  }

  bool get _supportsNativeSensors {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  void _scheduleAccelerometer() {
    if (!_supportsNativeSensors) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _reducedMotion) {
        return;
      }
      _tryListenAccelerometer();
    });
  }

  void _tryListenAccelerometer() {
    if (!mounted || _reducedMotion || _accelSub != null) {
      return;
    }
    try {
      _accelSub = accelerometerEventStream().listen(
        _onAccel,
        onError: (Object error, StackTrace stackTrace) {
          _onAccelerometerUnavailable();
        },
        cancelOnError: true,
      );
    } on MissingPluginException catch (_) {
      _onAccelerometerUnavailable();
    } catch (_) {
      _onAccelerometerUnavailable();
    }
  }

  void _onAccelerometerUnavailable() {
    unawaited(_detachAccelerometer());
    if (mounted) {
      setState(() => _useSensorTilt = false);
    } else {
      _useSensorTilt = false;
    }
  }

  Future<void> _detachAccelerometer() async {
    final sub = _accelSub;
    _accelSub = null;
    if (sub == null) {
      return;
    }
    try {
      await sub.cancel();
    } on MissingPluginException catch (_) {
      // Channel not registered (e.g. hot restart without native rebuild).
    } catch (_) {}
  }

  void _onAccel(AccelerometerEvent e) {
    if (!_useSensorTilt) {
      return;
    }
    final nx = (e.y / 9.81).clamp(-1.0, 1.0) * 0.12;
    final ny = (-e.x / 9.81).clamp(-1.0, 1.0) * 0.12;
    setState(() {
      _tiltX = _tiltX * 0.88 + nx * 0.12;
      _tiltY = _tiltY * 0.88 + ny * 0.12;
    });
  }

  void _onMasterTick() {
    final master = _master;
    if (master == null) {
      return;
    }
    final v = master.value;
    for (var i = 0; i < SplashSequence.hapticBeats.length; i++) {
      final beat = SplashSequence.hapticBeats[i];
      if (v >= beat - 0.002 && !_firedHaptic.contains(i)) {
        _firedHaptic.add(i);
        _fireHaptic(i);
      }
    }
  }

  void _fireHaptic(int index) {
    switch (index) {
      case 0:
        HapticFeedback.selectionClick();
      case 1:
        HapticFeedback.lightImpact();
      case 2:
        HapticFeedback.mediumImpact();
      case 3:
        HapticFeedback.heavyImpact();
      default:
        break;
    }
  }

  Future<void> _onComplete() async {
    if (_navigated || !mounted) {
      return;
    }
    _navigated = true;
    try {
      await ref
          .read(appPrefsProvider)
          .setString(SplashPrefKeys.completedOnce, '1');
    } catch (_) {
      // Prefs channel hiccup: still navigate.
    }
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  void _handleSkip() {
    if (_skipped || _navigated) {
      return;
    }
    final master = _master;
    if (master == null) {
      return;
    }
    final msTotal =
        master.duration?.inMilliseconds ??
        SplashSequence.totalDuration.inMilliseconds;
    final elapsed = Duration(milliseconds: (msTotal * master.value).round());
    final minSkip = _secondLaunch && !_reducedMotion
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 1200);
    if (elapsed < minSkip) {
      return;
    }
    _skipped = true;
    master.removeListener(_onMasterTick);
    master.stop();
    unawaited(_persistAndNavigate());
  }

  Future<void> _persistAndNavigate() async {
    if (_navigated || !mounted) {
      return;
    }
    _navigated = true;
    try {
      await ref
          .read(appPrefsProvider)
          .setString(SplashPrefKeys.completedOnce, '1');
    } catch (_) {}
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  SplashWordmarkLayout _layoutWordmark() {
    return _wordmarkLayout ??= SplashWordmarkLayout(
      TextPainter(
        text: TextSpan(
          text: 'wayo ads',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }

  @override
  void dispose() {
    final master = _master;
    if (master != null) {
      master.removeListener(_onMasterTick);
      master.dispose();
    }
    _ripple.dispose();
    unawaited(_detachAccelerometer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final master = _master;
    if (master == null) {
      return Semantics(
        label: 'Wayo Ads starting',
        child: const Scaffold(
          backgroundColor: AppColors.black,
          body: SizedBox.expand(),
        ),
      );
    }

    final wordLayout = _layoutWordmark();

    return Semantics(
      label: 'Wayo Ads starting',
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleSkip,
          child: _reducedMotion
              ? _ReducedSplashBody(master: master, wordmark: wordLayout)
              : _FullSplashBody(
                  master: master,
                  ripple: _ripple,
                  particles: _particles,
                  wordmark: wordLayout,
                  useSensorTilt: _useSensorTilt,
                  tiltX: _tiltX,
                  tiltY: _tiltY,
                ),
        ),
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF141414), AppColors.black],
        ),
      ),
    );
  }
}

class _TaglineFader extends StatelessWidget {
  const _TaglineFader({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = ((controller.value - 0.72) / 0.2).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Center(
            child: Text(
              'connecting brands & creators',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReducedSplashBody extends StatelessWidget {
  const _ReducedSplashBody({required this.master, required this.wordmark});

  final AnimationController master;
  final SplashWordmarkLayout wordmark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _BackgroundGradient(),
        const RepaintBoundary(child: NoiseOverlay(opacity: 0.03)),
        AnimatedBuilder(
          animation: master,
          builder: (context, _) {
            final o = Curves.easeOut.transform(master.value);
            return Opacity(
              opacity: o,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: WayoMarkPainter(
                        snapProgress: 1,
                        flashProgress: 0,
                        assemblyProgress: 1,
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: WordmarkPainter(
                        layout: wordmark,
                        progress: master.value,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FullSplashBody extends StatelessWidget {
  const _FullSplashBody({
    required this.master,
    required this.ripple,
    required this.particles,
    required this.wordmark,
    required this.useSensorTilt,
    required this.tiltX,
    required this.tiltY,
  });

  final AnimationController master;
  final AnimationController ripple;
  final ParticleSystem particles;
  final SplashWordmarkLayout wordmark;
  final bool useSensorTilt;
  final double tiltX;
  final double tiltY;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: ripple,
            builder: (context, _) =>
                LiquidMetalBackground(time: ripple.value * pi * 2),
          ),
        ),
        const _BackgroundGradient(),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: ripple,
            builder: (context, _) => CustomPaint(
              painter: RippleRadarPainter(progress: ripple.value),
              size: Size.infinite,
            ),
          ),
        ),
        const Positioned.fill(
          child: RepaintBoundary(child: NoiseOverlay(opacity: 0.03)),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: master,
            builder: (context, _) {
              final t = master.value;
              final rx = useSensorTilt ? tiltX : sin(t * pi * 2) * 0.018;
              final ry = useSensorTilt ? tiltY : cos(t * pi * 2) * 0.014;
              final matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(ry)
                ..rotateY(rx);
              return Transform(
                alignment: Alignment.center,
                transform: matrix,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ScanLinePainter(
                          progress: SplashSequence.scan.transform(t),
                          dotProgress: SplashSequence.dot.transform(t),
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ParticleSystemPainter(
                          system: particles,
                          burstProgress: SplashSequence.burst.transform(t),
                          assemblyProgress: SplashSequence.assembly.transform(
                            t,
                          ),
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: WayoMarkPainter(
                          snapProgress: SplashSequence.snap.transform(t),
                          flashProgress: SplashSequence.flash.transform(t),
                          assemblyProgress: SplashSequence.assembly.transform(
                            t,
                          ),
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: WordmarkPainter(
                          layout: wordmark,
                          progress: SplashSequence.wordmark.transform(t),
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ShockwavePainter(
                          progress: SplashSequence.shockwave.transform(t),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: _TaglineFader(controller: master),
        ),
      ],
    );
  }
}
