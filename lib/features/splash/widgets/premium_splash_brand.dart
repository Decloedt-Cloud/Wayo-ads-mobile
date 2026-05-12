import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium splash mark + wordmark (ported from HTML reference: paint-in hero,
/// staggered assembly paths, blurred sliding wordmark, ambient glow).
///
/// [progress] is 0→1 over the splash [AnimationController] duration (~2.5s).
class PremiumSplashBrand extends StatelessWidget {
  const PremiumSplashBrand({
    super.key,
    required this.progress,
    required this.reduceMotion,
  });

  final double progress;
  final bool reduceMotion;

  static const Color _bgOrange = Color(0xFFF57C20);
  static const Color _glow = Color(0xB3F57C20);

  /// Matches CSS `cubic-bezier(0.2, 0, 0.1, 1)`.
  static const Curve _cinematic = Cubic(0.2, 0.0, 0.1, 1.0);

  double _ease(double t, double start, double end, Curve curve) {
    if (reduceMotion) return 1.0;
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return curve.transform((t - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final t = reduceMotion ? 1.0 : progress.clamp(0.0, 1.0);
    final w = MediaQuery.sizeOf(context).width;
    final logoSide = (w * 0.26).clamp(88.0, 130.0);
    final fontSize = (w * 0.082).clamp(28.0, 40.0);

    // Timeline scaled from 5s HTML → ~0–1 (total controller ~4.6s).
    final clip1 = _ease(t, 0.0, 0.22, Curves.easeOutCubic);
    final fade1 = _ease(t, 0.0, 0.12, Curves.easeOut);
    final pulse = reduceMotion
        ? 1.0
        : 1.0 +
            0.018 *
                math.sin(
                  (t.clamp(0.12, 0.88) - 0.12) / 0.76 * math.pi * 4,
                );
    final s2 = _ease(t, 0.26, 0.52, _cinematic);
    final s3 = _ease(t, 0.33, 0.56, _cinematic);
    final textP = _ease(t, 0.40, 0.58, _cinematic);

    final op2 = Curves.easeOut.transform(s2);
    final sc2 = 0.9 + 0.1 * s2;
    final y2 = 5.0 * (1.0 - s2);

    final op3 = Curves.easeOut.transform(s3);
    final sc3 = 0.9 + 0.1 * s3;
    final y3 = 5.0 * (1.0 - s3);

    final blurSigma = 8.0 * (1.0 - textP);
    final slideX = -30.0 * (1.0 - Curves.easeOutCubic.transform(textP));
    final textOp = Curves.easeOut.transform(textP);

    final ambient = 0.32 + 0.28 * math.sin(t * math.pi * 2);

    Widget svg(String asset) => SvgPicture.asset(
          asset,
          fit: BoxFit.contain,
          width: logoSide,
          height: logoSide,
          clipBehavior: Clip.none,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: logoSide + 8,
          height: logoSide + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: reduceMotion ? 0.45 : ambient,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _glow.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.75],
                      ),
                    ),
                  ),
                ),
              ),
              // p1 (back in z for stack – draw order: p1 then p2 p3 on top per HTML)
              Transform.scale(
                scale: pulse,
                child: Opacity(
                  opacity: fade1,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: clip1.clamp(0.001, 1.0),
                      child: svg('assets/branding/wayo_splash_p1.svg'),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: op2,
                child: Transform.translate(
                  offset: Offset(0, y2),
                  child: Transform.scale(
                    scale: sc2,
                    child: svg('assets/branding/wayo_splash_p2.svg'),
                  ),
                ),
              ),
              Opacity(
                opacity: op3,
                child: Transform.translate(
                  offset: Offset(0, y3),
                  child: Transform.scale(
                    scale: sc3,
                    child: svg('assets/branding/wayo_splash_p3.svg'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: (w * 0.035).clamp(12.0, 20.0)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Transform.translate(
              offset: Offset(slideX, 0),
              child: Opacity(
                opacity: textOp.clamp(0.0, 1.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Wayo',
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          color: _bgOrange,
                          height: 1.0,
                          letterSpacing: 0.02 * fontSize,
                          shadows: [
                            Shadow(
                              color: _glow.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: ' Ads',
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: 0.02 * fontSize,
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
          ),
        ),
      ],
    );
  }
}
