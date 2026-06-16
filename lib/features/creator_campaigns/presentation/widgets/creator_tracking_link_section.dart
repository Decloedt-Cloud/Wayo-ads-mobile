import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/creator_tracking_link.dart';

/// Displays the creator's unique tracking short link for a LINK campaign.
class CreatorTrackingLinkSection extends StatelessWidget {
  const CreatorTrackingLinkSection({
    super.key,
    required this.links,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<CreatorTrackingLink> links;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    if (loading) {
      return _Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(
              color: CreatorColors.primaryOf(context),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.creator.campaigns.tracking_link_title,
              style: AppTextStyles.labelLarge(context),
            ),
            const SizedBox(height: 8),
            Text(
              t.creator.campaigns.tracking_link_error,
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t.dashboard.errors.retry),
              ),
            ],
          ],
        ),
      );
    }

    if (links.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.creator.campaigns.tracking_link_title,
              style: AppTextStyles.labelLarge(context),
            ),
            const SizedBox(height: 8),
            Text(
              t.creator.campaigns.tracking_link_preparing,
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.creator.campaigns.tracking_link_title,
          style: AppTextStyles.labelLarge(context).copyWith(fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          t.creator.campaigns.tracking_link_subtitle,
          style: AppTextStyles.caption(context).copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LinkTile(link: link),
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatefulWidget {
  const _LinkTile({required this.link});

  final CreatorTrackingLink link;

  @override
  State<_LinkTile> createState() => _LinkTileState();
}

class _LinkTileState extends State<_LinkTile> {
  bool _copied = false;

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    if (!mounted) return;
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final link = widget.link;
    final fullUrl = buildPublicTrackingLinkUrl(link.slug) ?? '/t/${link.slug}';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: 20,
                color: CreatorColors.primaryOf(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fullUrl,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.creator.campaigns.tracking_link_stats(
              validated: link.validatedClicks,
              recorded: link.totalClicks,
            ),
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copy(fullUrl),
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _copied
                        ? t.creator.campaigns.tracking_link_copied
                        : t.creator.campaigns.tracking_link_copy,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CreatorColors.primaryOf(context),
                    side: BorderSide(
                      color: CreatorColors.primaryOf(context)
                          .withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () async {
                  final uri = Uri.tryParse(fullUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: CreatorColors.primaryOf(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: child,
    );
  }
}
