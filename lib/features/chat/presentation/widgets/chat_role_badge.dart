import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../i18n/strings.g.dart';
import '../formatting/chat_partner_role.dart';

/// Compact role pill (Creator / Advertiser) shown next to a chat partner's name.
class ChatRoleBadge extends StatelessWidget {
  const ChatRoleBadge({
    super.key,
    required this.role,
    this.compact = false,
  });

  final ChatPartnerRole role;

  /// Drops the icon + tightens padding (used in the dense inbox row).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (Color color, IconData icon, String label) = switch (role) {
      ChatPartnerRole.creator => (
          const Color(0xFF8B5CF6),
          Icons.auto_awesome_rounded,
          t.chat.role_creator,
        ),
      ChatPartnerRole.advertiser => (
          const Color(0xFFF59E0B),
          Icons.campaign_rounded,
          t.chat.role_advertiser,
        ),
      ChatPartnerRole.admin => (
          const Color(0xFF38BDF8),
          Icons.shield_rounded,
          t.chat.role_admin,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 9.5 : 10.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
