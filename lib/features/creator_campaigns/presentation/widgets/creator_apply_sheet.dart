import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../data/creator_campaigns_remote_datasource.dart';
import '../providers/creator_campaigns_providers.dart';

/// Modal bottom-sheet letting the creator add an optional pitch message and
/// submit their application to the campaign.
///
/// Returns `true` when the application was created successfully — callers use
/// that to invalidate the detail provider and refresh the UI.
Future<bool?> showCreatorApplySheet(
  BuildContext context, {
  required String campaignId,
  required String campaignTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ApplySheet(campaignId: campaignId, campaignTitle: campaignTitle),
  );
}

class _ApplySheet extends ConsumerStatefulWidget {
  const _ApplySheet({required this.campaignId, required this.campaignTitle});

  final String campaignId;
  final String campaignTitle;

  @override
  ConsumerState<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends ConsumerState<_ApplySheet> {
  late final TextEditingController _messageCtrl;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    final repo = ref.read(creatorCampaignsRepositoryProvider);
    final msg = _messageCtrl.text.trim();
    await repo.applyToCampaign(
      widget.campaignId,
      message: msg.isEmpty ? null : msg,
    );
    ref.invalidate(creatorApplicationsProvider);
    ref.invalidate(creatorBrowseCampaignsPagedProvider);
    ref.invalidate(creatorCampaignDetailProvider(widget.campaignId));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  bool _needsCreatorRoleTokenRefresh(CreatorCampaignsApiException e) {
    if (e.statusCode == 403) return true;
    final msg = e.message.toLowerCase();
    return msg.contains('creator role') || msg.contains('requires creator');
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _submitApplication();
    } on CreatorCampaignsApiException catch (e) {
      if (_needsCreatorRoleTokenRefresh(e)) {
        final refreshed = await ref
            .read(authNotifierProvider.notifier)
            .refreshAuthSessionAfterRoleChange();
        if (refreshed) {
          try {
            await _submitApplication();
            return;
          } on CreatorCampaignsApiException catch (retryError) {
            if (!mounted) return;
            setState(() {
              _error = retryError.message;
              _submitting = false;
            });
            return;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.t.creator.campaigns.apply_error;
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
            t.creator.campaigns.apply_title,
            style: AppTextStyles.pageTitle(context),
          ),
          const SizedBox(height: 4),
          Text(
            widget.campaignTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 16),
          Text(
            t.creator.campaigns.apply_message_label,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 5,
            minLines: 3,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: t.creator.campaigns.apply_message_hint,
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
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 32),
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
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _submitting
                    ? t.creator.campaigns.apply_in_progress
                    : t.creator.campaigns.apply_submit,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
            ],
          ),
        ),
        const WayoBlackBottomBar(),
      ],
    );
  }
}
