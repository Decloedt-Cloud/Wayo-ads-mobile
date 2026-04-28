import 'package:equatable/equatable.dart';

final class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.priority,
    this.type,
    this.actionUrl,
    this.metadata,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  /// e.g. `P0_CRITICAL`, `P1_HIGH` (Wayo-ads list API).
  final String? priority;

  /// e.g. `CREATOR_APPLIED`, `CAMPAIGN_PAUSED` (Wayo-ads list API).
  final String? type;

  /// In-app / web path from Wayo-ads.
  final String? actionUrl;

  /// JSON metadata (e.g. `campaignId`, `applicationId` for [CREATOR_APPLIED]).
  final Map<String, dynamic>? metadata;

  /// True when this row is about a creator who applied — advertiser may approve/reject.
  ///
  /// Wayo-ads may omit [type]; if [metadata] resolves both ids we still show actions.
  bool get isCreatorAppliedNotification {
    if (_creatorApplyLikeType(type)) return true;

    final m = metadata;
    if (m != null) {
      for (final key in const <String>[
        'type',
        'notificationType',
        'eventType',
        'notification_type',
      ]) {
        if (_creatorApplyLikeType(m[key]?.toString())) return true;
      }
    }
    // Same event often ships only `{ campaignId, applicationId }` without explicit type.
    if (metadataCampaignId != null && metadataApplicationId != null)
      return true;

    return false;
  }

  static bool _creatorApplyLikeType(String? raw) {
    if (raw == null) return false;
    final s = raw.trim();
    if (s.isEmpty) return false;
    final u = s.toUpperCase().replaceAll(RegExp(r'[\s.-]'), '_');
    if (u == 'CREATOR_APPLIED') return true;
    if (u.contains('CREATOR') &&
        (u.contains('APPLIED') || u.contains('APPLICATION'))) {
      return true;
    }
    if (u.contains('NEW_APPLICATION')) return true;
    if (u.contains('CREATOR') && u.contains('APPLY')) return true;
    return false;
  }

  /// Campaign id when present in [metadata] (mobile approve flow).
  String? get metadataCampaignId {
    final m = metadata;
    if (m != null) {
      final direct = m['campaignId'] ?? m['campaign_id'];
      final fromDirect = _nonEmptyStringLike(direct);
      if (fromDirect != null) {
        return fromDirect;
      }
      final app = m['application'];
      if (app is Map) {
        final camp = app['campaign'];
        final nested =
            app['campaignId'] ??
            app['campaign_id'] ??
            (camp is Map ? camp['id'] : null);
        final fromApp = _nonEmptyStringLike(nested);
        if (fromApp != null) {
          return fromApp;
        }
      }
    }
    return _parseActionUrlIds(actionUrl).$1;
  }

  String? get metadataApplicationId {
    final m = metadata;
    if (m != null) {
      final direct = m['applicationId'] ?? m['application_id'];
      final fromDirect = _nonEmptyStringLike(direct);
      if (fromDirect != null) {
        return fromDirect;
      }
      final app = m['application'];
      if (app is Map) {
        final fromApp = _nonEmptyStringLike(app['id'] ?? app['applicationId']);
        if (fromApp != null) {
          return fromApp;
        }
      }
    }
    return _parseActionUrlIds(actionUrl).$2;
  }

  /// Deep link / web URL from [actionUrl] when ids are not in JSON metadata.
  static (String?, String?) _parseActionUrlIds(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (null, null);
    }
    try {
      final uri = Uri.parse(raw);
      String? camp;
      String? app;
      for (final e in uri.queryParameters.entries) {
        final k = e.key.toLowerCase();
        if ((k == 'campaignid' || k == 'campaign_id') && e.value.isNotEmpty) {
          camp ??= e.value;
        }
        if ((k == 'applicationid' ||
                k == 'application_id' ||
                k == 'creatorapplicationid') &&
            e.value.isNotEmpty) {
          app ??= e.value;
        }
      }
      final seg = uri.pathSegments;
      for (var i = 0; i + 1 < seg.length; i++) {
        if (seg[i] == 'campaigns') {
          camp ??= seg[i + 1];
        } else if (seg[i] == 'applications' && i + 1 < seg.length) {
          app ??= seg[i + 1];
        }
      }
      return (camp, app);
    } catch (_) {
      return (null, null);
    }
  }

  static String? _nonEmptyStringLike(dynamic v) {
    if (v is String) {
      return v.isNotEmpty ? v : null;
    }
    if (v != null) {
      final s = v.toString();
      return s.isNotEmpty ? s : null;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    isRead,
    createdAt,
    priority,
    type,
    actionUrl,
    metadata,
  ];
}
