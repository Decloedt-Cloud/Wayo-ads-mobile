import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/creator_campaign_detail.dart';
import '../../domain/creator_youtube_status.dart';

/// Whether this campaign needs a linked YouTube channel before submit.
bool campaignRequiresYoutubeConnection(CreatorCampaignDetail campaign) {
  if (!campaign.type.requiresVideoSubmission) return false;
  final platform = (campaign.requiredPlatform ?? 'YOUTUBE').toUpperCase();
  return platform == 'YOUTUBE';
}

Future<void> openCreatorYoutubeSettingsWeb() async {
  final url = buildCreatorYoutubeSettingsWebUrl();
  if (url == null) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Banner shown when the creator must connect YouTube on the web before submitting.
class CreatorYoutubeConnectBanner extends StatelessWidget {
  const CreatorYoutubeConnectBanner({
    super.key,
    required this.oauthStatus,
  });

  final CreatorYoutubeOAuthStatus oauthStatus;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isReconnect =
        oauthStatus == CreatorYoutubeOAuthStatus.reconnectRequired;
    final title = isReconnect
        ? t.creator.campaigns.youtube_reconnect_title
        : t.creator.campaigns.youtube_connect_title;
    final body = isReconnect
        ? t.creator.campaigns.youtube_reconnect_body
        : t.creator.campaigns.youtube_connect_body;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: CreatorColors.primaryOf(context).withValues(alpha: 0.08),
        border: Border.all(
          color: CreatorColors.primaryOf(context).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.link_rounded,
                color: CreatorColors.primaryOf(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textSecondaryOf(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                openCreatorYoutubeSettingsWeb();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: CreatorColors.primaryOf(context),
                side: BorderSide(
                  color: CreatorColors.primaryOf(context).withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                t.creator.campaigns.youtube_connect_cta,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
