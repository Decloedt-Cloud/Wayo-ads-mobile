import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Shared chrome for overflow ⋮ menus (chat inbox, campaign cards, …).
abstract final class WayoPopupMenu {
  static const double iconSize = 20;
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );

  static ShapeBorder shape(BuildContext context) => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.borderOf(context).withValues(alpha: 0.55),
        ),
      );

  static Color color(BuildContext context) =>
      AppColors.surfaceElevatedOf(context);

  static PopupMenuThemeData theme(BuildContext context) => PopupMenuThemeData(
        color: color(context),
        shape: shape(context),
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        textStyle: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryOf(context),
          height: 1.2,
        ),
      );
}

/// Single overflow-menu row: icon + label, optional destructive styling.
class WayoPopupMenuRow extends StatelessWidget {
  const WayoPopupMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.error
        : AppColors.textPrimaryOf(context).withValues(alpha: 0.92);
    return Padding(
      padding: WayoPopupMenu.itemPadding,
      child: Row(
        children: [
          Icon(icon, size: WayoPopupMenu.iconSize, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                height: 1.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience [PopupMenuItem] with [WayoPopupMenuRow] padding already applied.
PopupMenuItem<T> wayoPopupMenuItem<T>({
  required T value,
  required IconData icon,
  required String label,
  bool destructive = false,
  bool enabled = true,
}) {
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    padding: EdgeInsets.zero,
    height: 48,
    child: WayoPopupMenuRow(
      icon: icon,
      label: label,
      destructive: destructive,
    ),
  );
}
