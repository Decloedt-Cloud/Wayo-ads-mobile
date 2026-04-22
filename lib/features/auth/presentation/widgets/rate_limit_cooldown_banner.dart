import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

/// Which copy set to show (login vs password-reset API).
enum RateLimitBannerVariant { login, passwordReset }

/// Animated cooldown UI with live countdown (HTTP 429 / [RateLimitedException]).
class RateLimitCooldownBanner extends StatefulWidget {
  const RateLimitCooldownBanner({
    super.key,
    required this.initialSeconds,
    required this.onComplete,
    this.variant = RateLimitBannerVariant.login,
  });

  final int initialSeconds;
  final VoidCallback onComplete;
  final RateLimitBannerVariant variant;

  @override
  State<RateLimitCooldownBanner> createState() =>
      _RateLimitCooldownBannerState();
}

class _RateLimitCooldownBannerState extends State<RateLimitCooldownBanner>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  Timer? _timer;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _secondsLeft = math.max(widget.initialSeconds, 0);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    if (_secondsLeft <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer t) {
    if (!mounted) return;
    setState(() => _secondsLeft--);
    if (_secondsLeft <= 0) {
      t.cancel();
      widget.onComplete();
    }
  }

  @override
  void didUpdateWidget(covariant RateLimitCooldownBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSeconds != widget.initialSeconds) {
      _timer?.cancel();
      _secondsLeft = math.max(widget.initialSeconds, 0);
      if (_secondsLeft <= 0) {
        widget.onComplete();
      } else {
        _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final total = math.max(widget.initialSeconds, 1);
    final progress = 1 - (_secondsLeft.clamp(0, total) / total);
    final title = switch (widget.variant) {
      RateLimitBannerVariant.login => t.login.rate_limit_title,
      RateLimitBannerVariant.passwordReset =>
        t.forgot_password.rate_limit_title,
    };
    final body = switch (widget.variant) {
      RateLimitBannerVariant.login => t.login.rate_limit_body,
      RateLimitBannerVariant.passwordReset => t.forgot_password.rate_limit_body,
    };
    final remaining = switch (widget.variant) {
      RateLimitBannerVariant.login => t.login.rate_limit_remaining(
        seconds: _secondsLeft,
      ),
      RateLimitBannerVariant.passwordReset =>
        t.forgot_password.rate_limit_remaining(seconds: _secondsLeft),
    };

    return Material(
          color: AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _spin,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(92, 92),
                            painter: _OrbitLoaderPainter(
                              rotation: _spin.value * 2 * math.pi,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.02, 1.0),
                          strokeWidth: 3.5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                            '$_secondsLeft',
                            style: AppTextStyles.headlineMedium(context)
                                .copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimaryOf(context),
                                  height: 1,
                                ),
                          )
                          .animate(key: ValueKey(_secondsLeft))
                          .scale(
                            duration: 200.ms,
                            begin: const Offset(0.82, 0.82),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLarge(context).copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        remaining,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

class _OrbitLoaderPainter extends CustomPainter {
  _OrbitLoaderPainter({required this.rotation, required this.color});

  final double rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 3;
    final rect = Rect.fromCircle(center: c, radius: radius);
    for (var i = 0; i < 2; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.25 + 0.45 * i);
      final start = rotation + i * math.pi;
      canvas.drawArc(rect, start, math.pi * 0.62, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitLoaderPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.color != color;
}
