import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Hero image for 2-column campaign grid tiles — always fills the aspect-ratio box.
///
/// Covers use [BoxFit.cover]. Brand logos (no cover) use a filled backdrop plus
/// [BoxFit.cover] so they scale to the hero instead of letterboxing in the center.
class CampaignGridHeroImage extends StatelessWidget {
  const CampaignGridHeroImage({
    super.key,
    this.coverUrl,
    this.brandLogoUrl,
    required this.fallback,
    this.backdropColor,
  });

  final String? coverUrl;
  final String? brandLogoUrl;
  final Widget fallback;

  /// Behind transparent logos; defaults to theme elevated surface.
  final Color? backdropColor;

  static const int _coverMemW = 640;
  static const int _coverMemH = 480;

  @override
  Widget build(BuildContext context) {
    final cover = coverUrl?.trim();
    final logo = brandLogoUrl?.trim();
    final hasCover = cover != null && cover.isNotEmpty;
    final hasLogo = logo != null && logo.isNotEmpty;
    final backdrop =
        backdropColor ?? AppColors.surfaceElevatedOf(context);

    Widget fullBleedImage({
      required String url,
      required Widget Function(BuildContext, String, Object?) onError,
    }) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: _coverMemW,
          memCacheHeight: _coverMemH,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, _) => fallback,
          errorWidget: onError,
        ),
      );
    }

    if (hasCover) {
      return fullBleedImage(
        url: cover,
        onError: (context, url, err) {
          if (hasLogo) {
            return _logoFill(context, logo, backdrop, fullBleedImage);
          }
          return fallback;
        },
      );
    }

    if (hasLogo) {
      return _logoFill(context, logo, backdrop, fullBleedImage);
    }

    return SizedBox.expand(child: fallback);
  }

  Widget _logoFill(
    BuildContext context,
    String logo,
    Color backdrop,
    Widget Function({
      required String url,
      required Widget Function(BuildContext, String, Object?) onError,
    }) fullBleedImage,
  ) {
    return ColoredBox(
      color: backdrop,
      child: fullBleedImage(
        url: logo,
        onError: (context, url, err) => fallback,
      ),
    );
  }
}
