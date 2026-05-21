import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../dashboard/presentation/theme/campaign_detail_premium_palette.dart';

/// Browse + detail chrome — **theme-aware** (light + dark).
abstract final class CreatorCampaignsChrome {
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Page / scaffold backdrop.
  static Color bg(BuildContext c) =>
      CampaignDetailPremiumPalette.bg(c);

  /// Elevated cards (browse tiles, inset panels).
  static Color card(BuildContext c) =>
      CampaignDetailPremiumPalette.surface1(c);

  static Color divider(BuildContext c) =>
      CampaignDetailPremiumPalette.rowSeparator(c);

  static Color amber(BuildContext c) =>
      CampaignDetailPremiumPalette.amber;

  /// Success accents (icons, badges on dark backgrounds).
  static const Color green = Color(0xFF4ADE80);

  /// Success pill backgrounds.
  static Color greenBg(BuildContext c) => _dark(c)
      ? const Color(0xFF1A3A2A)
      : const Color(0xFFD1FAE5);

  static Color muted(BuildContext c) =>
      CampaignDetailPremiumPalette.muted(c);

  static Color label(BuildContext c) =>
      CampaignDetailPremiumPalette.label(c);

  static Color typeBg(BuildContext c) => _dark(c)
      ? const Color(0xFF2A1500)
      : const Color(0xFFFFF4E6);

  static TextStyle heroTitle(BuildContext c) => GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: CampaignDetailPremiumPalette.value(c),
        height: 1.08,
      );

  static TextStyle heroSubtitle(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: CampaignDetailPremiumPalette.label(c),
      );

  static TextStyle sectionTitle(BuildContext c) =>
      CampaignDetailPremiumPalette.sectionTitle(c);

  static TextStyle cardTitle(BuildContext c) => GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: CampaignDetailPremiumPalette.value(c),
        height: 1.2,
      );

  static TextStyle bodyDm(BuildContext c, {Color? color, double size = 14}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? muted(c),
      );

  static BorderSide cardBorderSide(BuildContext c) => BorderSide(
        color: _dark(c) ? Colors.transparent : divider(c),
        width: 1,
      );

  static List<BoxShadow> cardElevation(BuildContext c) =>
      _dark(c)
          ? const []
          : CampaignDetailPremiumPalette.cardShadow(c, 0.06);

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

  static double heroScrimHeightFactor(BuildContext c) => _dark(c) ? 0.48 : 0.0;
}
