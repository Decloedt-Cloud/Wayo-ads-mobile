import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cinematic_chat_colors.dart';

/// Replaces the composer when the other participant deleted their account.
class CinematicPeerUnavailableBar extends StatelessWidget {
  const CinematicPeerUnavailableBar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: ct.bg.withValues(alpha: isDark ? 0.72 : 0.78),
        border: Border(
          top: BorderSide(
            color: ct.borderSoft.withValues(alpha: 0.4),
            width: 0.6,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ct.surface.withValues(alpha: isDark ? 0.55 : 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ct.borderSoft.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 16, color: ct.muted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ct.muted,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
