import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../data/creator_campaigns_remote_datasource.dart';
import '../../domain/creator_campaign_detail.dart';
import '../providers/creator_campaigns_providers.dart';

/// Modal bottom-sheet to submit a YouTube post URL for a campaign. Server-side
/// validates the URL (extractable video id, privacy, min duration, vertical…).
///
/// Returns `true` if the submission was accepted so the caller can refresh.
Future<bool?> showCreatorSubmitPostSheet(
  BuildContext context, {
  required CreatorCampaignDetail campaign,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _SubmitPostSheet(campaign: campaign),
  );
}

class _SubmitPostSheet extends ConsumerStatefulWidget {
  const _SubmitPostSheet({required this.campaign});

  final CreatorCampaignDetail campaign;

  @override
  ConsumerState<_SubmitPostSheet> createState() => _SubmitPostSheetState();
}

class _SubmitPostSheetState extends ConsumerState<_SubmitPostSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlCtrl;
  late String _platform;
  bool _submitting = false;
  String? _error;

  static const _supportedPlatforms = <String>['YOUTUBE'];

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    _platform = widget.campaign.requiredPlatform ?? 'YOUTUBE';
    if (!_supportedPlatforms.contains(_platform)) {
      _platform = 'YOUTUBE';
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  String? _validateUrl(String? raw, Translations t) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return t.creator.campaigns.submit_url_required;
    final uri = Uri.tryParse(v);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return t.creator.campaigns.submit_url_invalid;
    }
    if (_platform == 'YOUTUBE') {
      final host = uri.host.toLowerCase();
      final ok = host.contains('youtube.com') || host.contains('youtu.be');
      if (!ok) return t.creator.campaigns.submit_url_youtube_only;
    }
    return null;
  }

  Future<void> _submit() async {
    final t = context.t;
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(creatorCampaignsRepositoryProvider);
      await repo.submitPost(
        campaignId: widget.campaign.id,
        platform: _platform,
        postUrl: _urlCtrl.text.trim(),
      );
      ref.invalidate(creatorMySubmissionsProvider(widget.campaign.id));
      ref.invalidate(creatorCampaignDetailProvider(widget.campaign.id));
      ref.invalidate(creatorApplicationsProvider);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CreatorCampaignsApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _error = t.creator.campaigns.submit_error;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: _buildForm(context, t, bottomInset),
        ),
        const WayoBlackBottomBar(),
      ],
    );
  }

  Widget _buildForm(BuildContext context, Translations t, double bottomInset) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondaryOf(
                    context,
                  ).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t.creator.campaigns.submit_title,
              style: AppTextStyles.pageTitle(context),
            ),
            const SizedBox(height: 4),
            Text(
              t.creator.campaigns.submit_subtitle,
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 16),
            Text(
              t.creator.campaigns.submit_platform_label,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.ondemand_video_rounded,
                    color: CreatorColors.primaryOf(context),
                  ),
                  const SizedBox(width: 10),
                  Text(_platform, style: AppTextStyles.bodyLarge(context)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.creator.campaigns.submit_url_label,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              validator: (v) => _validateUrl(v, t),
              decoration: InputDecoration(
                hintText: t.creator.campaigns.submit_url_hint,
                filled: true,
                fillColor: AppColors.surfaceElevatedOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: CreatorColors.primaryOf(context),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CreatorColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  _submitting
                      ? t.creator.campaigns.submit_in_progress
                      : t.creator.campaigns.submit_cta,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.creator.campaigns.submit_footer,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
