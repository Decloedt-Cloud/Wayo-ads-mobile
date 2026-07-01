import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/dashboard/presentation/theme/campaign_detail_premium_palette.dart';
import '../../../i18n/strings.g.dart';

/// Creative assets folder link — shared creator + advertiser detail.
class CampaignDetailAssetsLink extends StatelessWidget {
  const CampaignDetailAssetsLink({super.key, required this.url});

  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          _open();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.08),
            border: Border.all(
              color: CampaignDetailPremiumPalette.amber.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.folder_open_rounded,
                color: CampaignDetailPremiumPalette.amber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.creator.campaigns.assets_title,
                      style: AppTextStyles.labelLarge(
                        context,
                      ).copyWith(fontSize: 14),
                    ),
                    Text(
                      t.creator.campaigns.assets_subtitle,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: CampaignDetailPremiumPalette.amber,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
