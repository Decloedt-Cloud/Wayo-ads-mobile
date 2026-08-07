/// Create succeeded (draft or active).
final class CampaignMutationResult {
  const CampaignMutationResult({
    required this.id,
    required this.status,
  });

  final String id;
  final String status;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
