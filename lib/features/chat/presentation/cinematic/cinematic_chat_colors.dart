import 'package:flutter/material.dart';

/// Constantes marque (anneaux, peintures partagées).
abstract final class CinematicChatColors {
  static const Color amber = Color(0xFFF4A237);
  static const Color coral = Color(0xFFFF6B35);
}

/// Thème chat cinématique : **sombre** et **clair** (annonceur / créateur — même app).
@immutable
class CinematicChatTheme {
  const CinematicChatTheme({
    required this.bg,
    required this.surface,
    required this.amber,
    required this.amberDeep,
    required this.coral,
    required this.meshDeep,
    required this.textPrimary,
    required this.border,
    required this.borderSoft,
    required this.muted,
    required this.sentBubble,
    required this.avatarRing,
    required this.sentGlow,
    required this.headerBarTint,
    required this.meshNoiseAlpha,
    required this.meshGrainIsDark,
    required this.meshOrb1Opacity,
    required this.meshOrb2Opacity,
    required this.meshOrb3Opacity,
  });

  final Color bg;
  final Color surface;
  final Color amber;
  final Color amberDeep;
  final Color coral;
  final Color meshDeep;
  final Color textPrimary;
  final Color border;
  final Color borderSoft;
  final Color muted;
  final LinearGradient sentBubble;
  final LinearGradient avatarRing;
  final List<BoxShadow> sentGlow;
  final Color headerBarTint;
  final double meshNoiseAlpha;
  final bool meshGrainIsDark;
  final double meshOrb1Opacity;
  final double meshOrb2Opacity;
  final double meshOrb3Opacity;

  static CinematicChatTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static final CinematicChatTheme dark = CinematicChatTheme(
    bg: const Color(0xFF0A0A0A),
    surface: const Color(0xFF1C1C1E),
    amber: const Color(0xFFF4A237),
    amberDeep: const Color(0xFFFF8C00),
    coral: const Color(0xFFFF6B35),
    meshDeep: const Color(0xFF1A0F00),
    textPrimary: const Color(0xFFF5F0E8),
    border: const Color(0xFF2C2C2E),
    borderSoft: const Color(0xFF333333),
    muted: const Color(0xFF888888),
    sentBubble: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4A237), Color(0xFFFF8C00)],
    ),
    avatarRing: const LinearGradient(
      colors: [Color(0xFFF4A237), Color(0xFFFF6B35)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    sentGlow: [
      BoxShadow(
        color: const Color(0xFFF4A237).withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
    headerBarTint: const Color(0xB70A0A0A),
    meshNoiseAlpha: 0.03,
    meshGrainIsDark: false,
    meshOrb1Opacity: 0.14,
    meshOrb2Opacity: 0.10,
    meshOrb3Opacity: 0.22,
  );

  static final CinematicChatTheme light = CinematicChatTheme(
    bg: const Color(0xFFF2F2F5),
    surface: const Color(0xFFE8E8EE),
    amber: const Color(0xFFF4A237),
    amberDeep: const Color(0xFFFF8C00),
    coral: const Color(0xFFFF6B35),
    meshDeep: const Color(0xFFFFF0E5),
    textPrimary: const Color(0xFF1C1C1E),
    border: const Color(0xFFD0D0D6),
    borderSoft: const Color(0xFFC4C4CA),
    muted: const Color(0xFF636366),
    sentBubble: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4A237), Color(0xFFFF8C00)],
    ),
    avatarRing: const LinearGradient(
      colors: [Color(0xFFF4A237), Color(0xFFFF6B35)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    sentGlow: [
      BoxShadow(
        color: const Color(0xFFF4A237).withValues(alpha: 0.28),
        blurRadius: 28,
        offset: const Offset(0, 8),
      ),
    ],
    headerBarTint: const Color(0xE8FFFFFF),
    meshNoiseAlpha: 0.022,
    meshGrainIsDark: true,
    meshOrb1Opacity: 0.09,
    meshOrb2Opacity: 0.065,
    meshOrb3Opacity: 0.11,
  );
}
