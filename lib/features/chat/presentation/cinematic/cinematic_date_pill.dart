import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cinematic_chat_colors.dart';

/// ━━━ [8] DATE SEPARATORS ━━━
class CinematicDatePill extends StatelessWidget {
  const CinematicDatePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: ct.textPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: ct.amber.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ct.muted,
          ),
        ),
      ),
    );
  }
}
