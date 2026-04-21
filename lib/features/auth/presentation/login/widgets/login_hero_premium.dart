import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../i18n/strings.g.dart';

/// Hero headline + slow breathing orange halo behind the title block.
class LoginHeroPremium extends StatefulWidget {
  const LoginHeroPremium({
    super.key,
    required this.reduceMotion,
  });

  final bool reduceMotion;

  @override
  State<LoginHeroPremium> createState() => _LoginHeroPremiumState();
}

class _LoginHeroPremiumState extends State<LoginHeroPremium>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LoginHeroPremium oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _pulse?.dispose();
      _pulse = null;
    } else if (!widget.reduceMotion && oldWidget.reduceMotion) {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final style = AppTextStyles.displayLarge(context).copyWith(
      fontSize: 36,
      height: 1.05,
      letterSpacing: -0.5,
    );

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.login.headline_line1,
          style: style.copyWith(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              t.login.headline_line2_prefix,
              style: style.copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                t.login.headline_brand,
                style: style.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              t.login.dot,
              style: style.copyWith(color: AppColors.textPrimaryOf(context)),
            ),
          ],
        ),
      ],
    );

    Widget wrapped = headline;
    if (!widget.reduceMotion) {
      wrapped = AnimatedBuilder(
        animation: _pulse!,
        builder: (context, _) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          final g = isLight
              ? 0.045 + _pulse!.value * 0.028
              : 0.11 + _pulse!.value * 0.06;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -28,
                top: -32,
                right: -40,
                bottom: -24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: g),
                        blurRadius: isLight ? 44 : 56,
                        spreadRadius: isLight ? -10 : -8,
                      ),
                    ],
                  ),
                ),
              ),
              headline,
            ],
          );
        },
      );
    }

    return wrapped;
  }
}
