import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width campaign cover for detail screens.
///
/// Uses a fixed 16:9 aspect ratio (clamped bounds) with rounded corners.
/// When no cover/logo is available it falls back to a branded gradient placeholder.
class CampaignCoverImage extends StatelessWidget {
  const CampaignCoverImage({
    super.key,
    this.coverUrl,
    this.brandLogoUrl,
    required this.fallbackIcon,
    this.borderRadius = 20,
    this.accent,
  });

  final String? coverUrl;
  final String? brandLogoUrl;
  final IconData fallbackIcon;
  final double borderRadius;
  final Color? accent;

  static const double _defaultAspect = 16 / 9;
  static const int _memCacheW = 960;
  static const int _memCacheH = 540;

  String? get _resolvedUrl {
    final cover = coverUrl?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    final logo = brandLogoUrl?.trim();
    if (logo != null && logo.isNotEmpty) return logo;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    final accent = this.accent ?? AppColors.primary;
    final radius = BorderRadius.circular(borderRadius);

    if (url == null) {
      return _Fallback(
        icon: fallbackIcon,
        accent: accent,
        borderRadius: radius,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: _defaultAspect,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: _memCacheW,
          memCacheHeight: _memCacheH,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (context, _) => ColoredBox(
            color: AppColors.surfaceElevatedOf(context),
          ),
          errorWidget: (context, _, _) => _Fallback(
            icon: fallbackIcon,
            accent: accent,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.icon,
    required this.accent,
    required this.borderRadius,
  });

  final IconData icon;
  final Color accent;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: CampaignCoverImage._defaultAspect,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.22),
                AppColors.surfaceElevatedOf(context),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 48,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
