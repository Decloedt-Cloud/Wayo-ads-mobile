import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/app_providers.dart';

/// Ultra-cinematic splash with liquid morphing, glitch effects, and particle rain.
/// Features:
/// - Morphing liquid blob that breathes and undulates
/// - Cascading particle rain effect with parallax
/// - RGB glitch text animation (trendy, high-impact)
/// - Smooth fade transitions between layers
/// - Minimal performance impact (no shaders, GPU-friendly)
const Duration _kSplashDuration = Duration(milliseconds: 2000);

class SplashPrefKeys {
  SplashPrefKeys._();
  static const String completedOnce = 'splash.completed_once';
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _liquidFlow;
  late final AnimationController _particleRain;
  late final AnimationController _glitchPulse;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(appPrefsProvider);
    final secondLaunch = prefs.getString(SplashPrefKeys.completedOnce) == '1';

    _intro = AnimationController(
      vsync: this,
      duration: secondLaunch
          ? const Duration(milliseconds: 900)
          : _kSplashDuration,
    );

    _liquidFlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _particleRain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _glitchPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      unawaited(_intro.forward());
      HapticFeedback.selectionClick();
      await Future<void>.delayed(_intro.duration!);
      if (!mounted) return;
      await _exit();
    });
  }

  Future<void> _exit() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    try {
      await ref
          .read(appPrefsProvider)
          .setString(SplashPrefKeys.completedOnce, '1');
    } catch (_) {}
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _intro.dispose();
    _liquidFlow.dispose();
    _particleRain.dispose();
    _glitchPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wayo Ads launching',
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _exit,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animated gradient background with noise texture
              _AnimatedGradientBg(intro: _intro),

              // Particle rain overlay
              _ParticleRain(animation: _particleRain),

              // Center cinematic content
              AnimatedBuilder(
                animation: _intro,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_intro.value);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Morphing liquid blob
                        Transform.scale(
                          scale: 0.8 + t * 0.2,
                          child: Opacity(
                            opacity: t,
                            child: SizedBox(
                              width: 140,
                              height: 160,
                              child: _LiquidBlob(
                                animation: _liquidFlow,
                                glitchAnimation: _glitchPulse,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        // Glitchy brand text
                        Opacity(
                          opacity: (t - 0.15).clamp(0.0, 1.0),
                          child: _GlitchyBrandText(animation: _glitchPulse),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle with fade
                        Opacity(
                          opacity: (t - 0.3).clamp(0.0, 1.0),
                          child: Text(
                            'creators meet brands',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),

              // Bottom progress indicator
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) {
                    final t = Curves.easeOutCubic.transform(_intro.value);
                    return Opacity(
                      opacity: (t - 0.1).clamp(0.0, 1.0),
                      child: _CinematicProgressBar(progress: t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated gradient background with subtle noise and color shifts
class _AnimatedGradientBg extends StatelessWidget {
  final Animation<double> intro;

  const _AnimatedGradientBg({required this.intro});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: intro,
      builder: (context, _) {
        final hue = intro.value * 15; // Subtle hue shift
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSVColor.fromColor(const Color(0xFF0A0E27))
                    .withHue(
                      (HSVColor.fromColor(const Color(0xFF0A0E27)).hue + hue) %
                          360,
                    )
                    .toColor(),
                const Color(0xFF1A1F3A),
                const Color(0xFF0F1428),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Noise texture overlay
              Opacity(
                opacity: 0.04,
                child: CustomPaint(
                  painter: _NoisePainter(),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Liquid morphing blob with gradient and shadow
class _LiquidBlob extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> glitchAnimation;

  const _LiquidBlob({required this.animation, required this.glitchAnimation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final breath = (math.sin(animation.value * math.pi * 2) * 0.5 + 0.5)
                .toDouble();
            return Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFFB84D,
                    ).withValues(alpha: 0.3 + breath * 0.4),
                    blurRadius: 40 + breath * 20,
                    spreadRadius: 8 + breath * 12,
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFFFF6B6B,
                    ).withValues(alpha: 0.15 + breath * 0.2),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                ],
              ),
            );
          },
        ),

        // Morphing blob shape with gradient
        AnimatedBuilder(
          animation: Listenable.merge([animation, glitchAnimation]),
          builder: (context, _) {
            final flow = (math.sin(animation.value * math.pi * 2) * 0.5 + 0.5)
                .toDouble();
            final glitch =
                (math.sin(glitchAnimation.value * math.pi * 2) * 0.5 + 0.5)
                    .toDouble();

            return Transform.translate(
              offset: Offset(
                math.sin(flow * math.pi * 2) * 4 * glitch,
                math.cos(flow * math.pi * 2) * 6 * glitch,
              ),
              child: CustomPaint(
                size: const Size(140, 160),
                painter: _LiquidBlobPainter(
                  flowPhase: flow,
                  glitchPhase: glitch,
                ),
              ),
            );
          },
        ),

        // Inner highlight for depth
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final breath = (math.sin(animation.value * math.pi * 2) * 0.5 + 0.5)
                .toDouble();
            return Positioned(
              top: 30,
              left: 35,
              child: Container(
                width: 35,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15 + breath * 0.1),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Custom painter for liquid morphing blob - simplified oval shape
class _LiquidBlobPainter extends CustomPainter {
  final double flowPhase;
  final double glitchPhase;

  _LiquidBlobPainter({required this.flowPhase, required this.glitchPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          const Color(0xFFFFB84D),
          const Color(0xFFFF8C42),
          const Color(0xFFFF6B6B),
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Create a smooth oval with morphing distortion
    final path = Path();
    const segments = 32;

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * math.pi * 2;

      // Base oval dimensions
      final radiusX = 50.0;
      final radiusY = 60.0;

      // Add morphing distortion
      final distortion = math.sin(angle * 3 + flowPhase * math.pi * 2) * 12;
      final rx = radiusX + distortion;
      final ry = radiusY + distortion * 0.7;

      final x = center.dx + math.cos(angle) * rx;
      final y = center.dy + math.sin(angle) * ry;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidBlobPainter oldDelegate) =>
      oldDelegate.flowPhase != flowPhase ||
      oldDelegate.glitchPhase != glitchPhase;
}

/// Glitchy RGB text effect - inspired by cyberpunk design
class _GlitchyBrandText extends StatelessWidget {
  final Animation<double> animation;

  const _GlitchyBrandText({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final glitch = (math.sin(animation.value * math.pi * 2) * 0.5 + 0.5)
            .toDouble();
        final offset = (glitch - 0.5) * 4;

        return SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Red channel
              Transform.translate(
                offset: Offset(offset * 0.8, 0),
                child: Text(
                  'wayo',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              // Green channel (offset)
              Transform.translate(
                offset: Offset(offset * 0.4, offset * 0.3),
                child: Text(
                  'wayo',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              // Blue channel (more offset)
              Transform.translate(
                offset: Offset(offset * 1.2, -offset * 0.2),
                child: Text(
                  'wayo',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF745FFF).withValues(alpha: 0.5),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              // Main white text
              Text(
                'wayo',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              // Brand accent "ads"
              Positioned(
                right: -28,
                bottom: 4,
                child: Text(
                  'ads',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFB84D),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Particle rain effect with parallax
class _ParticleRain extends StatelessWidget {
  final Animation<double> animation;

  const _ParticleRain({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _ParticleRainPainter(phase: animation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Custom painter for particle rain
class _ParticleRainPainter extends CustomPainter {
  final double phase;

  _ParticleRainPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    const particleCount = 80;
    final random = math.Random(42); // Fixed seed for consistency

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 0.1;
      final x = (seed * 200 + phase * 500) % size.width;
      final y = (seed * 100 + phase * 800) % size.height;
      final size_ = 1.0 + (random.nextDouble() * 1.5);
      final opacity = 0.1 + random.nextDouble() * 0.2;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), size_, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticleRainPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Cinematic progress bar with gradient and glow
class _CinematicProgressBar extends StatelessWidget {
  final double progress;

  const _CinematicProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Column(
        children: [
          SizedBox(
            height: 3,
            child: Stack(
              children: [
                // Background track
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Animated progress fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB84D), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB84D).withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle noise texture painter
class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42);

    for (int i = 0; i < 3000; i++) {
      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.08);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
