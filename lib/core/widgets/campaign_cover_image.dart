import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width campaign cover for detail screens.
///
/// Renders the image at its *natural* aspect ratio (clamped to sane bounds so
/// extreme portrait/panorama assets stay readable) with rounded corners. When
/// no cover/logo is available it falls back to a branded gradient placeholder —
/// matching the web detail layout.
class CampaignCoverImage extends StatefulWidget {
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

  /// Aspect-ratio guards: never taller than ~5:4, never wider than ~2.4:1.
  static const double _minAspect = 0.8;
  static const double _maxAspect = 2.4;
  static const double _defaultAspect = 16 / 9;

  @override
  State<CampaignCoverImage> createState() => _CampaignCoverImageState();
}

class _CampaignCoverImageState extends State<CampaignCoverImage> {
  ImageStreamListener? _listener;
  ImageStream? _stream;
  double? _aspectRatio;
  bool _failed = false;

  String? get _resolvedUrl {
    final cover = widget.coverUrl?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    final logo = widget.brandLogoUrl?.trim();
    if (logo != null && logo.isNotEmpty) return logo;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant CampaignCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.brandLogoUrl != widget.brandLogoUrl) {
      _aspectRatio = null;
      _failed = false;
      _disposeStream();
      _resolveAspectRatio();
    }
  }

  void _resolveAspectRatio() {
    final url = _resolvedUrl;
    if (url == null) return;
    final provider = CachedNetworkImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (h <= 0 || w <= 0) return;
        if (!mounted) return;
        setState(() => _aspectRatio = (w / h).clamp(
              CampaignCoverImage._minAspect,
              CampaignCoverImage._maxAspect,
            ));
      },
      onError: (_, _) {
        if (!mounted) return;
        setState(() => _failed = true);
      },
    );
    _stream = stream..addListener(listener);
    _listener = listener;
  }

  void _disposeStream() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _disposeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    final accent = widget.accent ?? AppColors.primary;
    final radius = BorderRadius.circular(widget.borderRadius);

    if (url == null || _failed) {
      return _Fallback(
        icon: widget.fallbackIcon,
        accent: accent,
        borderRadius: radius,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: _aspectRatio ?? CampaignCoverImage._defaultAspect,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          fadeInDuration: const Duration(milliseconds: 220),
          placeholder: (context, _) => ColoredBox(
            color: AppColors.surfaceElevatedOf(context),
          ),
          errorWidget: (context, _, _) => _Fallback(
            icon: widget.fallbackIcon,
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
