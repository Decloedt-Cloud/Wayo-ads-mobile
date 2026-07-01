/// Realtime helpers for account soft-delete (30-day grace) — web parity.
library;

import 'account_deletion_anonymized.dart';

/// Parsed deletion schedule from a Reverb / FCM payload.
final class AccountDeletionRealtimeState {
  const AccountDeletionRealtimeState({
    this.deletionRequestedAt,
    this.hasExplicitState = false,
  });

  final DateTime? deletionRequestedAt;

  /// True when the payload explicitly carries (or clears) [deletionRequestedAt].
  final bool hasExplicitState;
}

String? _trimmedField(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

DateTime? _parseDeletionTimestamp(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;
    return DateTime.tryParse(s);
  }
  return null;
}

bool _mapDeclaresDeletionField(Map<String, dynamic> map) {
  return map.containsKey('deletionRequestedAt') ||
      map.containsKey('deletion_requested_at') ||
      map.containsKey('deletionRequested') ||
      map.containsKey('deletion_requested');
}

/// Reads `deletionRequestedAt` from nested Wayo-ads broadcast / FCM shapes.
AccountDeletionRealtimeState extractAccountDeletionStateFromPayload(
  Map<String, dynamic> data,
) {
  for (final key in const [
    'deletionRequestedAt',
    'deletion_requested_at',
  ]) {
    if (!data.containsKey(key)) continue;
    return AccountDeletionRealtimeState(
      deletionRequestedAt: _parseDeletionTimestamp(data[key]),
      hasExplicitState: true,
    );
  }

  final user = _asMap(data['user']);
  if (user != null && _mapDeclaresDeletionField(user)) {
    return AccountDeletionRealtimeState(
      deletionRequestedAt: _parseDeletionTimestamp(
        user['deletionRequestedAt'] ?? user['deletion_requested_at'],
      ),
      hasExplicitState: true,
    );
  }

  final notification = _asMap(data['notification']);
  if (notification != null) {
    final nested = extractAccountDeletionStateFromPayload(notification);
    if (nested.hasExplicitState) return nested;
  }

  final profile = _asMap(data['profile']);
  if (profile != null && _mapDeclaresDeletionField(profile)) {
    return AccountDeletionRealtimeState(
      deletionRequestedAt: _parseDeletionTimestamp(
        profile['deletionRequestedAt'] ?? profile['deletion_requested_at'],
      ),
      hasExplicitState: true,
    );
  }

  return const AccountDeletionRealtimeState();
}

bool _dedupeIndicatesDeletionChange(Map<String, dynamic> flat) {
  final dedupe = (_trimmedField(flat, 'dedupeKey') ??
          _trimmedField(flat, 'dedupe_key') ??
          '')
      .toLowerCase();
  return dedupe.contains('account.deletion');
}

/// Scheduled soft-delete (`SYSTEM_ALERT`, danger tab) — same heuristics as FCM.
bool isAccountDeletionScheduledNotificationPayload(Map<String, dynamic> data) {
  final flat = data;

  final dedupe = (_trimmedField(flat, 'dedupeKey') ??
          _trimmedField(flat, 'dedupe_key') ??
          '')
      .toLowerCase();
  if (dedupe.contains('account.deletion_requested')) {
    return true;
  }

  final type = (_trimmedField(flat, 'type') ??
          _trimmedField(flat, 'notificationType') ??
          _trimmedField(flat, 'notification_type') ??
          '')
      .toUpperCase();
  if (type == 'ACCOUNT.DELETION_REQUESTED') {
    return true;
  }
  if (type != 'SYSTEM_ALERT') {
    return false;
  }

  final actionUrl = (_trimmedField(flat, 'actionUrl') ??
          _trimmedField(flat, 'action_url') ??
          '')
      .toLowerCase();
  if (!actionUrl.contains('tab=danger') && !actionUrl.contains('/settings')) {
    return false;
  }

  final title = (_trimmedField(flat, 'title') ?? '').toLowerCase();
  final body = (_trimmedField(flat, 'body') ??
          _trimmedField(flat, 'message') ??
          '')
      .toLowerCase();
  final haystack = '$title $body';
  return haystack.contains('deletion') ||
      haystack.contains('delete') ||
      haystack.contains('supprim') ||
      haystack.contains('suppression') ||
      haystack.contains('حذف');
}

/// Cancellation broadcast / notification (web/mobile DELETE /api/user/delete-account).
bool isAccountDeletionCancelledNotificationPayload(Map<String, dynamic> data) {
  if (_dedupeIndicatesDeletionChange(data)) {
    final dedupe = (_trimmedField(data, 'dedupeKey') ??
            _trimmedField(data, 'dedupe_key') ??
            '')
        .toLowerCase();
    if (dedupe.contains('cancel')) return true;
  }

  final type = (_trimmedField(data, 'type') ??
          _trimmedField(data, 'notificationType') ??
          _trimmedField(data, 'notification_type') ??
          '')
      .toLowerCase();
  if (type == 'account.deletion_cancelled') {
    return true;
  }
  if (type.contains('deletion') && type.contains('cancel')) {
    return true;
  }

  final event = (_trimmedField(data, 'event') ?? '').toLowerCase();
  if (event == 'account.deletion_cancelled') {
    return true;
  }
  if (event.contains('deletion') && event.contains('cancel')) {
    return true;
  }

  return false;
}

/// Any Reverb / FCM signal that should refresh the grace-period banner.
bool isAccountDeletionStateChangedPayload(Map<String, dynamic> data) {
  if (isAccountDeletionCompletedPayload(data)) return true;
  if (isAccountDeletionScheduledNotificationPayload(data)) return true;
  if (isAccountDeletionCancelledNotificationPayload(data)) return true;
  if (extractAccountDeletionStateFromPayload(data).hasExplicitState) {
    return true;
  }
  return _dedupeIndicatesDeletionChange(data);
}

bool isAccountDeletionRealtimeEventName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('deletion')) return true;
  if (lower.contains('account') &&
      (lower.contains('delete') || lower.contains('purge'))) {
    return true;
  }
  if (lower.contains('profile') && lower.contains('updat')) return true;
  if (lower.contains('user') && lower.contains('updat')) return true;
  return false;
}
