import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/campaign_status_actions.dart';
import '../providers/advertiser_campaigns_providers.dart';

/// Owner actions: status transitions + edit + insights links.
class CampaignOwnerActionsBar extends ConsumerStatefulWidget {
  const CampaignOwnerActionsBar({
    super.key,
    required this.campaignId,
    required this.status,
  });

  final String campaignId;
  final CampaignStatus status;

  @override
  ConsumerState<CampaignOwnerActionsBar> createState() =>
      _CampaignOwnerActionsBarState();
}

class _CampaignOwnerActionsBarState
    extends ConsumerState<CampaignOwnerActionsBar> {
  var _busy = false;

  TranslationsAdvertiserCampaignsActionsEn get _a =>
      context.t.advertiser_campaigns.actions;

  String _labelFor(String key) {
    final a = _a;
    return switch (key) {
      'publish' => a.publish,
      'pause' => a.pause,
      'resume' => a.resume,
      'cancel' => a.cancel,
      _ => key,
    };
  }

  Future<void> _runStatus(String apiStatus, {required bool destructive}) async {
    if (_busy) return;
    final a = _a;
    if (destructive) {
      final ok = await showWayoDialog<bool>(
        context: context,
        builder: (ctx) => WayoAlertDialog(
          title: Text(a.cancel_confirm_title),
          content: Text(a.cancel_confirm_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(a.dismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(a.confirm),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(advertiserCampaignsRepositoryProvider)
          .setCampaignStatus(widget.campaignId, apiStatus);
      ref.invalidate(advertiserCampaignDetailProvider(widget.campaignId));
      ref.invalidate(advertiserCampaignsPagedProvider);
      ref.invalidate(advertiserCampaignsCountsProvider);
      if (!mounted) return;
      WayoToast.success(context, a.status_updated);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthException ? e.toString() : a.status_error;
      WayoToast.error(context, msg.isEmpty ? a.status_error : msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final statusActions = campaignOwnerStatusActions(widget.status);
    final canEdit = campaignAllowsOwnerEdit(widget.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final action in statusActions)
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _runStatus(
                        action.apiStatus,
                        destructive: action.labelKey == 'cancel',
                      ),
                child: Text(_labelFor(action.labelKey)),
              ),
            if (canEdit)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => context.push(
                        '/advertiser/campaigns/${widget.campaignId}/edit',
                      ),
                child: Text(a.edit),
              ),
            OutlinedButton(
              onPressed: () => context.push(
                '/advertiser/campaigns/${widget.campaignId}/analytics',
              ),
              child: Text(a.analytics),
            ),
            OutlinedButton(
              onPressed: () => context.push(
                '/advertiser/campaigns/${widget.campaignId}/financial-health',
              ),
              child: Text(a.financial_health),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
