import '../../dashboard/domain/entities/campaign_status.dart';

/// Allowed owner status transitions matching Wayo-ads `handleStatusChange`.
List<({String labelKey, String apiStatus})> campaignOwnerStatusActions(
  CampaignStatus current,
) {
  switch (current) {
    case CampaignStatus.draft:
      return const [(labelKey: 'publish', apiStatus: 'ACTIVE')];
    case CampaignStatus.active:
      return const [
        (labelKey: 'pause', apiStatus: 'PAUSED'),
        (labelKey: 'cancel', apiStatus: 'CANCELLED'),
      ];
    case CampaignStatus.paused:
      return const [(labelKey: 'resume', apiStatus: 'ACTIVE')];
    case CampaignStatus.underReview:
    case CampaignStatus.completed:
    case CampaignStatus.cancelled:
    case CampaignStatus.unknown:
      return const [];
  }
}

bool campaignAllowsOwnerEdit(CampaignStatus status) {
  return status == CampaignStatus.draft ||
      status == CampaignStatus.active ||
      status == CampaignStatus.paused;
}
