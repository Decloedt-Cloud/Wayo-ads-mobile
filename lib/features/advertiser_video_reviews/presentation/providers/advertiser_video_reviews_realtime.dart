import 'dart:convert';

import '../../../../core/realtime/realtime_signal.dart';

const _videoReviewNotificationTypes = <String>{
  'video_submitted',
  'video_updated',
  'video_approved',
  'video_rejected',
  'creator_flagged',
};

/// Parses Reverb / notification payloads for video-review–related types.
bool isVideoReviewNotificationPayload(Object? raw) {
  final type = _notificationTypeFromRaw(raw).toLowerCase();
  if (type.isEmpty) return false;
  if (_videoReviewNotificationTypes.contains(type)) return true;
  return type.startsWith('video_');
}

String _notificationTypeFromRaw(Object? raw) {
  if (raw == null) return '';
  Map<String, dynamic>? map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is Map) {
    map = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) {
        map = d;
      } else if (d is Map) {
        map = Map<String, dynamic>.from(d);
      }
    } catch (_) {}
  }
  if (map == null) return '';

  final nested = map['notification'];
  if (nested is Map) {
    map = {...map, ...Map<String, dynamic>.from(nested)};
  }

  return (map['notification_type'] ??
          map['notificationType'] ??
          map['type'] ??
          map['eventType'] ??
          '')
      .toString();
}

/// Whether a Reverb signal should refresh advertiser video review queues.
bool shouldRefreshAdvertiserVideoReviews(RealtimeSignal sig) {
  if (isVideoReviewNotificationPayload(sig.raw)) {
    return true;
  }

  final lower = sig.name.toLowerCase();
  final channelLower = sig.channelName?.toLowerCase() ?? '';
  final fromAdvertiserChannel = channelLower.contains('advertiser');

  final videoNamedEvent =
      lower.contains('video') &&
      (lower.contains('submit') ||
          lower.contains('updat') ||
          lower.contains('approv') ||
          lower.contains('reject') ||
          lower.contains('review') ||
          lower.contains('flag'));
  if (videoNamedEvent) return true;

  final submissionNamedEvent =
      lower.contains('submission') &&
      (lower.contains('submit') ||
          lower.contains('updat') ||
          lower.contains('review'));
  if (submissionNamedEvent) return true;

  if (fromAdvertiserChannel &&
      (lower.contains('video') ||
          lower.contains('submission') ||
          lower.contains('post'))) {
    return true;
  }

  return false;
}
