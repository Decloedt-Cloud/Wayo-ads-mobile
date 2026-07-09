import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';

/// Browse list / grid chrome for advertiser campaigns — light + dark.
abstract final class AdvertiserCampaignsChrome {
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c) => CampaignDetailPremiumPalette.bg(c);

  static Color card(BuildContext c) =>
      CampaignDetailPremiumPalette.surface1(c);

  static Color divider(BuildContext c) =>
      CampaignDetailPremiumPalette.rowSeparator(c);

  static Color amber(BuildContext c) =>
      CampaignDetailPremiumPalette.amber;

  static Color label(BuildContext c) =>
      CampaignDetailPremiumPalette.label(c);

  static Color muted(BuildContext c) =>
      CampaignDetailPremiumPalette.muted(c);

  static Color value(BuildContext c) =>
      CampaignDetailPremiumPalette.value(c);

  static Color typeBg(BuildContext c) => _dark(c)
      ? const Color(0xFF2A1500)
      : const Color(0xFFFFF4E6);

  static const Color activeFg = Color(0xFF4ADE80);
  static const Color activeFgLight = Color(0xFF15803D);

  static Color activeBg(BuildContext c) => _dark(c)
      ? const Color(0xFF1A3A2A)
      : const Color(0xFFD1FAE5);

  static Color mutedChipBg(BuildContext c) => _dark(c)
      ? const Color(0xFF2A2A35)
      : CampaignDetailPremiumPalette.surfaceGlass(c);

  static Color mutedChipFg(BuildContext c) => label(c);

  static TextStyle heroTitle(BuildContext c) => GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: value(c),
        height: 1.08,
      );

  static TextStyle heroSubtitle(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: muted(c),
      );

  /// List/grid card outline — visible in light mode only.
  static BorderSide cardBorderSide(BuildContext c) => BorderSide(
        color: _dark(c) ? Colors.transparent : divider(c),
        width: 1,
      );

  /// Soft elevation on browse cards (light mode).
  static List<BoxShadow> cardElevation(BuildContext c) =>
      _dark(c)
          ? const []
          : CampaignDetailPremiumPalette.cardShadow(c, 0.06);

  /// Bottom fade on hero image. Dark: legibility scrim; light: blend into card.
  static BoxDecoration heroImageBottomFade(BuildContext c) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _dark(c)
              ? [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ]
              : [
                  Colors.transparent,
                  card(c).withValues(alpha: 0.97),
                ],
        ),
      );

  /// Fraction of hero height used for the bottom fade overlay (0 = none in light).
  static double heroScrimHeightFactor(BuildContext c) => _dark(c) ? 0.48 : 0.0;

  /// Status pill colors: (background, foreground, optional border).
  static (Color bg, Color fg, Color? border) statusChip(
    BuildContext c,
    CampaignStatus status,
  ) {
    final amberC = amber(c);
    return switch (status) {
      CampaignStatus.active => (
          activeBg(c),
          _dark(c) ? activeFg : activeFgLight,
          null,
        ),
      CampaignStatus.paused => (
          typeBg(c),
          amberC,
          amberC,
        ),
      CampaignStatus.underReview => (
          const Color(0x336366F1),
          const Color(0xFF6366F1),
          const Color(0xFF6366F1),
        ),
      CampaignStatus.cancelled => (
          const Color(0x33EF4444),
          const Color(0xFFEF4444),
          const Color(0xFFEF4444),
        ),
      CampaignStatus.completed ||
      CampaignStatus.draft ||
      CampaignStatus.unknown =>
        (
          mutedChipBg(c),
          mutedChipFg(c),
          null,
        ),
    };
  }
}
