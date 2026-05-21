import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Campaign detail + creator browse — premium tokens (Sora / DM Sans / JetBrains Mono).
/// All surfaces and text tones are [BuildContext]-aware so **light mode** matches Material surfaces.
abstract final class CampaignDetailPremiumPalette {
  static const double kCardRadius = 16.0;
  static const double kCardPadding = 16.0;
  static const double kSectionGap = 20.0;
  static const double kHorizontalPadding = 16.0;

  static const EdgeInsets kScreenPadding =
      EdgeInsets.symmetric(horizontal: kHorizontalPadding);

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ─── Surfaces ───────────────────────────────────────────────

  static Color bg(BuildContext context) =>
      _dark(context) ? const Color(0xFF0A0A0F) : const Color(0xFFF1F3F9);

  static Color surface1(BuildContext context) =>
      _dark(context) ? const Color(0xFF13131A) : Colors.white;

  static Color surfaceGlass(BuildContext context) =>
      _dark(context) ? const Color(0xFF1C1C26) : const Color(0xFFEEF0F7);

  static Color divider(BuildContext context) =>
      _dark(context) ? const Color(0xFF2D2D3A) : const Color(0xFFDDE1EB);

  static Color rowSeparator(BuildContext context) =>
      _dark(context) ? const Color(0xFF2A2A35) : const Color(0xFFE8ECF4);

  // ─── Typography tones ────────────────────────────────────────

  static Color label(BuildContext context) =>
      _dark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

  static Color muted(BuildContext context) =>
      _dark(context) ? const Color(0xFF6B7280) : const Color(0xFF475569);

  static Color value(BuildContext context) =>
      _dark(context) ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

  // ─── Brand accents (same in both modes) ─────────────────────

  static const Color amber = Color(0xFFF59E0B);
  static const Color deepOrange = Color(0xFFEA580C);
  static const Color positive = Color(0xFF22C55E);

  static LinearGradient accentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, deepOrange],
  );

  // ─── Text styles ───────────────────────────────────────────

  static TextStyle sectionTitle(BuildContext c) => GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: value(c),
      );

  static TextStyle bodyLabel(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 12,
        color: label(c),
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodyValue(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 14,
        color: value(c),
        fontWeight: FontWeight.w600,
      );

  static TextStyle infoLabel(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 13,
        color: label(c),
        fontWeight: FontWeight.w400,
      );

  static TextStyle infoValue(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 14,
        color: value(c),
        fontWeight: FontWeight.w600,
      );

  static TextStyle metricMono(BuildContext c) => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        color: value(c),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle display(BuildContext c) =>
      GoogleFonts.sora(fontWeight: FontWeight.w700, color: value(c));

  static TextStyle labelStyle(BuildContext c) => bodyLabel(c);

  static TextStyle valueStyle(BuildContext c) => bodyValue(c);

  static TextStyle mono(BuildContext c) => metricMono(c);

  static TextStyle monoSmall(BuildContext c) => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: value(c),
        fontWeight: FontWeight.w600,
      );

  static List<BoxShadow> cardShadow(BuildContext context, double opacity) {
    if (_dark(context)) {
      return [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, opacity),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
      ];
    }
    final a = opacity * 0.5;
    return [
      BoxShadow(
        color: Color.fromRGBO(15, 23, 42, a.clamp(0.04, 0.14)),
        blurRadius: 18,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color.fromRGBO(15, 23, 42, (a * 0.35).clamp(0.02, 0.08)),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
