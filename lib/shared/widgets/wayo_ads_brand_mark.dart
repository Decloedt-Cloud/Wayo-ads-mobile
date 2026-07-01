import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Orange Wayo Ads icon mark only (no wordmark). Used in dashboard headers.
class WayoAdsBrandIcon extends StatelessWidget {
  const WayoAdsBrandIcon({super.key, this.size = 36});

  static const String assetPath = 'assets/branding/wayo_splash_p1.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      height: size,
      width: size,
    );
  }
}

/// Theme-aware Wayo Ads brand lockup: orange logo mark + "Wayo Ads" wordmark.
///
/// The SVG mark is orange (visible on light and dark backgrounds) and the
/// "Ads" word follows [ColorScheme.onSurface] so it adapts to the active theme.
class WayoAdsBrandMark extends StatelessWidget {
  const WayoAdsBrandMark({
    super.key,
    this.iconSize = 40,
    this.fontSize = 24,
    this.spacing = 10,
  });

  static const _amber = Color(0xFFF47A1F);

  final double iconSize;
  final double fontSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          WayoAdsBrandIcon.assetPath,
          height: iconSize,
          width: iconSize,
        ),
        SizedBox(width: spacing),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Wayo ',
                style: TextStyle(
                  color: _amber,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'Ads',
                style: TextStyle(
                  color: onSurface,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
