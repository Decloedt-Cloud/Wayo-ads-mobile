import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rate line (CPC / per-view) on the hero of explorer grid tiles.
class CampaignGridRateBadge extends StatelessWidget {
  const CampaignGridRateBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 132),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black.withValues(alpha: 0.42),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
      ),
    );
  }
}

/// Icon + value with tooltip — used for views/clicks, creators, total on grid cards.
class CampaignGridMicroStat extends StatelessWidget {
  const CampaignGridMicroStat({
    super.key,
    required this.icon,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMutedOf(context)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
