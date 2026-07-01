import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Trendy "New" badge shown on campaign grid tiles for recently created
/// campaigns (mirrors the web marketplace badge).
///
/// A compact gradient pill with a soft glow and a sparkle glyph. Designed to
/// sit in a corner of the hero image [Stack].
class CampaignNewBadge extends StatelessWidget {
  const CampaignNewBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
