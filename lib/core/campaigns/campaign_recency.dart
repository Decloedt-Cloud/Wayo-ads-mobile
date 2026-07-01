/// Recency helpers for campaign listings.
///
/// Mirrors the web "New" badge rule: a campaign is considered *new* when it was
/// created within the last [kNewCampaignWindow] (7 days).
library;

/// Window during which a freshly-created campaign is flagged as "New".
const Duration kNewCampaignWindow = Duration(days: 7);

/// Parses a backend timestamp (`createdAt`, `created_at`, …) into a UTC-aware
/// [DateTime]. Accepts ISO-8601 strings and epoch millis/seconds.
DateTime? parseCampaignTimestamp(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) {
    // Heuristic: treat 10-digit values as seconds, larger as milliseconds.
    final isSeconds = raw < 100000000000;
    return DateTime.fromMillisecondsSinceEpoch(
      isSeconds ? raw * 1000 : raw,
      isUtc: true,
    );
  }
  if (raw is num) return parseCampaignTimestamp(raw.toInt());
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// True when [createdAt] falls within the [kNewCampaignWindow] relative to now.
bool isCampaignNew(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) return false;
  final reference = now ?? DateTime.now();
  final diff = reference.toUtc().difference(createdAt.toUtc());
  if (diff.isNegative) return true; // created in the (slightly) future — still new.
  return diff <= kNewCampaignWindow;
}
