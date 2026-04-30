import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/data/advertiser_campaigns_repository.dart';
import '../../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/dashboard_state_providers.dart';

/// Approve / reject when [NotificationItem.isCreatorAppliedNotification] and [metadata]
/// includes `campaignId` + `applicationId` (or nested `application`).
class CreatorApplicationNotificationActions extends ConsumerWidget {
  const CreatorApplicationNotificationActions({
    super.key,
    required this.item,
    this.compact = false,
  });

  final NotificationItem item;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    final routeRole = _routeRoleQueryParameter(context);
    final onAdvertiserRoute = routeRole?.toLowerCase() == 'advertiser';
    final isAdvertiserContext =
        role == WayoAdsAccountRole.advertiser ||
        role == WayoAdsAccountRole.superAdmin ||
        (onAdvertiserRoute && role == WayoAdsAccountRole.unknown);
    if (!isAdvertiserContext) {
      return const SizedBox.shrink();
    }
    if (!item.isCreatorAppliedNotification) {
      return const SizedBox.shrink();
    }
    final cid = item.metadataCampaignId;
    final aid = item.metadataApplicationId;
    if (cid == null || aid == null) {
      return const SizedBox.shrink();
    }
    return _ApproveRejectRow(
      campaignId: cid,
      applicationId: aid,
      compact: compact,
    );
  }
}

/// go_router v14 has no `GoRouterState.maybeOf`; [GoRouterState.of] throws off-router.
String? _routeRoleQueryParameter(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.queryParameters['role'];
  } catch (_) {
    return null;
  }
}

class _ApproveRejectRow extends ConsumerStatefulWidget {
  const _ApproveRejectRow({
    required this.campaignId,
    required this.applicationId,
    required this.compact,
  });

  final String campaignId;
  final String applicationId;
  final bool compact;

  @override
  ConsumerState<_ApproveRejectRow> createState() => _ApproveRejectRowState();
}

class _ApproveRejectRowState extends ConsumerState<_ApproveRejectRow> {
  bool _busyApprove = false;
  bool _busyReject = false;

  Future<void> _afterSuccess(Translations t, {required bool approved}) async {
    ref.invalidate(advertiserCampaignsPagedProvider);
    ref.invalidate(advertiserCampaignsCountsProvider);
    ref.invalidate(advertiserCampaignDetailProvider(widget.campaignId));
    ref.invalidate(dashboardStreamProvider);
    ref.invalidate(notificationsListProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? t.dashboard.application_approved
              : t.dashboard.application_rejected,
        ),
      ),
    );
  }

  String _err(Object e, Translations t) {
    if (e is NetworkException) {
      return t.errors.network;
    }
    if (e is ServerException) {
      return e.message.isNotEmpty ? e.message : t.errors.server_generic;
    }
    return t.dashboard.application_action_failed;
  }

  Future<void> _approve(Translations t) async {
    if (_busyApprove || _busyReject) {
      return;
    }
    setState(() => _busyApprove = true);
    try {
      await ref
          .read(advertiserCampaignsRepositoryProvider)
          .approveApplication(widget.campaignId, widget.applicationId);
      await _afterSuccess(t, approved: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_err(e, t))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyApprove = false);
      }
    }
  }

  Future<void> _reject(Translations t) async {
    if (_busyApprove || _busyReject) {
      return;
    }
    setState(() => _busyReject = true);
    try {
      await ref
          .read(advertiserCampaignsRepositoryProvider)
          .rejectApplication(widget.campaignId, widget.applicationId);
      await _afterSuccess(t, approved: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_err(e, t))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyReject = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pad = widget.compact
        ? const EdgeInsets.only(top: 8)
        : const EdgeInsets.only(top: 10);
    final vpad = widget.compact ? 8.0 : 10.0;
    final loading = _busyApprove || _busyReject;

    return Padding(
      padding: pad,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _reject(t);
                    },
              icon: _busyReject
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    )
                  : const Icon(Icons.close_rounded, size: 18),
              label: Text(t.dashboard.application_reject),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimaryOf(context),
                padding: EdgeInsets.symmetric(vertical: vpad),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: BorderSide(color: AppColors.borderOf(context)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _approve(t);
                    },
              icon: _busyApprove
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(t.dashboard.application_approve),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: vpad),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
