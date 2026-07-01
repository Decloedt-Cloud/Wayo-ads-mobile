/// Detects a Wayo-ads user row that was soft-deleted / purged.
bool isAnonymizedWayoAdsAccount({
  String? status,
  required String email,
}) {
  final normalizedStatus = status?.trim().toUpperCase();
  if (normalizedStatus == 'ANONYMIZED') return true;
  final e = email.trim().toLowerCase();
  return e.endsWith('@deleted.wayo.com') || e.endsWith('@deleted.wayo.local');
}

bool isAccountDeletionCompletedPayload(Map<String, dynamic> data) {
  final type = (data['type'] ?? data['event'] ?? '').toString().toLowerCase();
  if (type == 'account.deletion_completed') return true;
  final dedupe = (data['dedupeKey'] ?? data['dedupe_key'] ?? '')
      .toString()
      .toLowerCase();
  return dedupe.contains('account.deletion_completed');
}
