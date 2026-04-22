import 'package:flutter/material.dart';

/// ━━━ PREMIUM CHAT DESIGN TOKENS ━━━
///
/// Single source of truth for radii, elevation, gradients and spacing used by
/// the chat premium surfaces. Complements [LiquidNeuralTheme] and
/// [CinematicChatTheme] with semantic tokens that encode **the luxury look**:
///
/// * large rounded cards (radius 24–28)
/// * layered surfaces (`surfaceBase` < `surfaceElevated` < `surfaceCrown`)
/// * warm ambient orange glow (inner peach / outer amber)
/// * subtle premium shadows (dual-layer — sharp hairline + soft halo)
/// * refined typography spacing (letter-spacing tuned per scale)
@immutable
class PremiumChatTokens {
  const PremiumChatTokens._({
    required this.radiusXS,
    required this.radiusSM,
    required this.radiusMD,
    required this.radiusLG,
    required this.radiusXL,
    required this.radius2XL,
    required this.gutter,
    required this.surfaceBase,
    required this.surfaceElevated,
    required this.surfaceCrown,
    required this.borderHairline,
    required this.borderGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accentWarm,
    required this.accentWarmDeep,
    required this.accentAmberGlow,
    required this.accentPeach,
    required this.success,
    required this.danger,
    required this.unreadTint,
    required this.pinnedTint,
    required this.ambientOrbWarm,
    required this.ambientOrbCool,
    required this.cardGradient,
    required this.cardGradientUnread,
    required this.accentGradient,
    required this.sheen,
    required this.cardShadow,
    required this.hoverShadow,
    required this.pressedShadow,
    required this.warmGlow,
    required this.isDark,
  });

  /// Radii — tuned for a "premium rounded" aesthetic.
  final double radiusXS; // chips
  final double radiusSM; // icons
  final double radiusMD; // avatars
  final double radiusLG; // search, input
  final double radiusXL; // conversation cards
  final double radius2XL; // hero cards

  /// Spacing unit (8pt grid).
  final double gutter;

  /// Layered surfaces (back → front).
  final Color surfaceBase; // scaffold / canvas
  final Color surfaceElevated; // cards
  final Color surfaceCrown; // dialogs, sheets

  final Color borderHairline; // 0.6px border
  final Color borderGlass; // 0.6px glass border

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Brand warm accents.
  final Color accentWarm; // primary CTA warm (amber)
  final Color accentWarmDeep; // gradient end
  final Color accentAmberGlow; // highlight / ring glow
  final Color accentPeach; // soft tint (backgrounds)

  final Color success;
  final Color danger;

  /// Semantic tints.
  final Color unreadTint;
  final Color pinnedTint;

  /// Ambient orbs — blurred gradient blobs used in backgrounds.
  final Color ambientOrbWarm;
  final Color ambientOrbCool;

  /// Gradients.
  final LinearGradient cardGradient;
  final LinearGradient cardGradientUnread;
  final LinearGradient accentGradient;
  final LinearGradient sheen;

  /// Shadows (dual-layer premium recipe).
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> hoverShadow;
  final List<BoxShadow> pressedShadow;
  final List<BoxShadow> warmGlow;

  final bool isDark;

  static PremiumChatTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ───────────────────────────────── DARK ─────────────────────────────────
  static final PremiumChatTokens dark = PremiumChatTokens._(
    radiusXS: 10,
    radiusSM: 14,
    radiusMD: 18,
    radiusLG: 22,
    radiusXL: 26,
    radius2XL: 32,
    gutter: 8,
    surfaceBase: const Color(0xFF050508),
    surfaceElevated: const Color(0xFF101015),
    surfaceCrown: const Color(0xFF17171D),
    borderHairline: const Color(0x1AFFFFFF),
    borderGlass: const Color(0x26FFFFFF),
    textPrimary: const Color(0xFFFAFAF5),
    textSecondary: const Color(0xB3FFFFFF),
    textTertiary: const Color(0x80FFFFFF),
    accentWarm: const Color(0xFFFF8A3C),
    accentWarmDeep: const Color(0xFFFF6B00),
    accentAmberGlow: const Color(0xFFFFB266),
    accentPeach: const Color(0xFFFFDDC2),
    success: const Color(0xFF34D399),
    danger: const Color(0xFFFF4D6D),
    unreadTint: const Color(0x1AFF8A3C),
    pinnedTint: const Color(0x26FF8A3C),
    ambientOrbWarm: const Color(0x4DFF6B00),
    ambientOrbCool: const Color(0x2630465C),
    cardGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x14FFFFFF),
        Color(0x03FFFFFF),
      ],
    ),
    cardGradientUnread: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x29FF8A3C),
        Color(0x0AFF8A3C),
      ],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF8A3C),
        Color(0xFFFF5A1F),
      ],
    ),
    sheen: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x24FFFFFF),
        Color(0x00FFFFFF),
      ],
    ),
    cardShadow: const [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
    hoverShadow: const [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 32,
        offset: Offset(0, 12),
        spreadRadius: -6,
      ),
    ],
    pressedShadow: const [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 8,
        offset: Offset(0, 2),
        spreadRadius: -2,
      ),
    ],
    warmGlow: const [
      BoxShadow(
        color: Color(0x59FF6B00),
        blurRadius: 28,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x33FF8A3C),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    isDark: true,
  );

  // ──────────────────────────────── LIGHT ────────────────────────────────
  static final PremiumChatTokens light = PremiumChatTokens._(
    radiusXS: 10,
    radiusSM: 14,
    radiusMD: 18,
    radiusLG: 22,
    radiusXL: 26,
    radius2XL: 32,
    gutter: 8,
    surfaceBase: const Color(0xFFFBF8F4), // warm off-white / cream
    surfaceElevated: const Color(0xFFFFFFFF),
    surfaceCrown: const Color(0xFFFFFDF9),
    borderHairline: const Color(0x14000000),
    borderGlass: const Color(0x14FF8A3C),
    textPrimary: const Color(0xFF141418),
    textSecondary: const Color(0x99141418),
    textTertiary: const Color(0x66141418),
    accentWarm: const Color(0xFFFF7A1F),
    accentWarmDeep: const Color(0xFFFF5A1F),
    accentAmberGlow: const Color(0xFFFFAE6B),
    accentPeach: const Color(0xFFFFEADB),
    success: const Color(0xFF22A06B),
    danger: const Color(0xFFEF4C60),
    unreadTint: const Color(0x1FFF7A1F),
    pinnedTint: const Color(0x29FF7A1F),
    ambientOrbWarm: const Color(0x33FF7A1F),
    ambientOrbCool: const Color(0x1A5B8FC6),
    cardGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFF7EE),
      ],
    ),
    cardGradientUnread: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFE8D4),
        Color(0xFFFFF7EE),
      ],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF8A3C),
        Color(0xFFFF5A1F),
      ],
    ),
    sheen: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x1AFFFFFF),
        Color(0x00FFFFFF),
      ],
    ),
    cardShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 24,
        offset: Offset(0, 10),
        spreadRadius: -8,
      ),
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
    hoverShadow: const [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 32,
        offset: Offset(0, 14),
        spreadRadius: -10,
      ),
    ],
    pressedShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 8,
        offset: Offset(0, 2),
        spreadRadius: -2,
      ),
    ],
    warmGlow: const [
      BoxShadow(
        color: Color(0x3DFF7A1F),
        blurRadius: 26,
        offset: Offset(0, 10),
        spreadRadius: -6,
      ),
    ],
    isDark: false,
  );
}
