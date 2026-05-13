import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kOrange = Color(0xFFF57C20);
const Color _kOrangeGlow = Color(0xB3F57C20);

/// Premium logo + wordmark driven by [animation] on `0→1` (splash timeline).
///
/// Mirrors the HTML reference: clipped paint‑in on part 1, staggered parts 2–3,
/// blurred/sliding “Wayo Ads”, soft radial backdrop. [reduceMotion] jumps to the
/// final readable frame.
class PremiumSplashAnimatedLogo extends StatelessWidget {
  const PremiumSplashAnimatedLogo({
    super.key,
    required this.animation,
    required this.reduceMotion,
    required this.maxLogoSize,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final double maxLogoSize;

  static const String assetP1 = 'assets/branding/wayo_splash_p1.svg';
  static const String assetP2 = 'assets/branding/wayo_splash_p2.svg';
  static const String assetP3 = 'assets/branding/wayo_splash_p3.svg';

  double _clamp01(double x) => x.clamp(0.0, 1.0);

  /// Smooth step with cubic easing between [a] and [b] for normalized [u] in [0,1].
  double _smoothRange(double u, double a, double b, Curve curve) {
    if (u <= a) return 0;
    if (u >= b) return 1;
    return curve.transform((u - a) / (b - a));
  }

  @override
  Widget build(BuildContext context) {
    final u = animation.value;

    if (reduceMotion) {
      return _StaticLogoRow(maxLogoSize: maxLogoSize);
    }

    // Timings scaled from the 5s HTML loop to a single forward pass (~2.5s feel).
    final clipReveal = _smoothRange(u, 0.0, 0.42, Curves.easeInOutCubic);
    final p1Opacity = _smoothRange(u, 0.0, 0.14, Curves.easeOutCubic);
    final p1Scale = 0.98 + 0.02 * _smoothRange(u, 0.0, 0.22, Curves.easeOutCubic);
    final p1Dy = 5.0 * (1.0 - _smoothRange(u, 0.0, 0.18, Curves.easeOutCubic));
    final pulse = 1.0 + 0.018 * math.sin(u * math.pi * 3);

    final p2Opacity =
        _smoothRange(u, 0.20, 0.38, Curves.easeInOutCubic); // stagger ~1.0s of 5s
    final p2Scale =
        0.9 + 0.1 * _smoothRange(u, 0.20, 0.38, Curves.easeOutCubic);
    final p2Dy = 5.0 * (1.0 - _smoothRange(u, 0.20, 0.38, Curves.easeOutCubic));

    final p3Opacity =
        _smoothRange(u, 0.26, 0.44, Curves.easeInOutCubic); // stagger ~1.25s of 5s
    final p3Scale =
        0.9 + 0.1 * _smoothRange(u, 0.26, 0.44, Curves.easeOutCubic);
    final p3Dy = 5.0 * (1.0 - _smoothRange(u, 0.26, 0.44, Curves.easeOutCubic));

    final textOpacity =
        _smoothRange(u, 0.38, 0.58, Curves.easeInOutCubic); // delay ~1.8s / 5s
    final textSlideT = _smoothRange(u, 0.38, 0.58, Curves.easeOutCubic);
    final textDx = -28.0 * (1.0 - textSlideT);
    final textBlur = 7.5 * (1.0 - textSlideT);

    final ambientPulse =
        0.35 + 0.35 * (0.5 - 0.5 * math.cos(u * math.pi * 2));

    final fontSize = (maxLogoSize * 0.36).clamp(26.0, 56.0);
    final gap = (maxLogoSize * 0.11).clamp(12.0, 22.0);

    Widget logoStack(double size) {
      Widget layered() {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: clipReveal.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: (_clamp01(p1Opacity * clipReveal)),
                  child: Transform.translate(
                    offset: Offset(0, p1Dy),
                    child: Transform.scale(
                      scale: p1Scale * pulse,
                      child: SvgPicture.asset(
                        assetP1,
                        width: size,
                        height: size,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: _clamp01(p2Opacity),
              child: Transform.translate(
                offset: Offset(0, p2Dy),
                child: Transform.scale(
                  scale: p2Scale,
                  child: SvgPicture.asset(
                    assetP2,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: _clamp01(p3Opacity),
              child: Transform.translate(
                offset: Offset(0, p3Dy),
                child: Transform.scale(
                  scale: p3Scale,
                  child: SvgPicture.asset(
                    assetP3,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Opacity(
              opacity: 0.35,
              child: SvgPicture.asset(
                assetP1,
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            ),
          ),
          layered(),
        ],
      );
    }

    final row = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: ambientPulse.clamp(0.2, 0.85),
            child: Container(
              width: maxLogoSize * 3.8,
              height: maxLogoSize * 3.8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x14F57C20),
                    Color(0x00F57C20),
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: maxLogoSize,
              height: maxLogoSize,
              child: logoStack(maxLogoSize),
            ),
            SizedBox(width: gap),
            ImageFiltered(
              imageFilter:
                  ImageFilter.blur(sigmaX: textBlur, sigmaY: textBlur),
              child: Opacity(
                opacity: textOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(textDx, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Wayo',
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.02 * fontSize,
                          height: 1.0,
                          color: _kOrange,
                          shadows: const [
                            Shadow(
                              color: _kOrangeGlow,
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ' Ads',
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.02 * fontSize,
                          height: 1.0,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Color(0x1AFFFFFF),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: RepaintBoundary(
        child: row,
      ),
    );
  }
}

class _StaticLogoRow extends StatelessWidget {
  const _StaticLogoRow({required this.maxLogoSize});

  final double maxLogoSize;

  @override
  Widget build(BuildContext context) {
    final fontSize = (maxLogoSize * 0.36).clamp(26.0, 56.0);
    final gap = (maxLogoSize * 0.11).clamp(12.0, 22.0);
    final size = maxLogoSize;

    final mark = SvgPicture.asset(
      PremiumSplashAnimatedLogo.assetP1,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    final p2 = SvgPicture.asset(
      PremiumSplashAnimatedLogo.assetP2,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    final p3 = SvgPicture.asset(
      PremiumSplashAnimatedLogo.assetP3,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [mark, p2, p3],
            ),
          ),
          SizedBox(width: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Wayo',
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.02 * fontSize,
                  height: 1.0,
                  color: _kOrange,
                  shadows: const [
                    Shadow(
                      color: _kOrangeGlow,
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              Text(
                ' Ads',
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.02 * fontSize,
                  height: 1.0,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Color(0x1AFFFFFF),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
