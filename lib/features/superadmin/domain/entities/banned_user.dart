import 'package:flutter/foundation.dart';

@immutable
class BannedUser {
  const BannedUser({
    required this.id,
    required this.authUserId,
    required this.wayoUserId,
    required this.email,
    this.name,
    this.reason,
    required this.bannedAt,
  });

  final int id;
  final int authUserId;
  final String wayoUserId;
  final String email;
  final String? name;
  final String? reason;
  final DateTime bannedAt;

  factory BannedUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    
    return BannedUser(
      id: _parseInt(json['id']),
      authUserId: _parseInt(user?['id'] ?? json['authUserId']),
      wayoUserId: (user?['wayoUserId'] ?? json['wayoUserId'] ?? '').toString(),
      email: (user?['email'] ?? json['email'] ?? '').toString(),
      name: user?['name']?.toString() ?? json['name']?.toString(),
      reason: json['reason']?.toString(),
      bannedAt: _parseDateTime(json['createdAt'] ?? json['bannedAt']),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static DateTime _parseDateTime(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

@immutable
class BannedUsersPage {
  const BannedUsersPage({
    required this.bans,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<BannedUser> bans;
  final int total;
  final int limit;
  final int offset;

  factory BannedUsersPage.fromJson(Map<String, dynamic> json) {
    final bansRaw = json['bans'];
    final bans = <BannedUser>[];
    if (bansRaw is List) {
      for (final item in bansRaw) {
        if (item is Map) {
          bans.add(BannedUser.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return BannedUsersPage(
      bans: bans,
      total: _parseInt(json['total']),
      limit: _parseInt(json['limit'], fallback: 50),
      offset: _parseInt(json['offset']),
    );
  }

  static int _parseInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }
}

@immutable
class SearchUser {
  const SearchUser({
    required this.id,
    required this.wayoUserId,
    required this.email,
    this.name,
    this.avatar,
    this.role,
  });

  /// Ads DB user id (`User.id` from Prisma — cuid string from admin search).
  final String id;
  /// Sent as `wayoUserId` to [POST /api/admin/app-bans]; same as [id] when the API only returns `id`.
  final String wayoUserId;
  final String email;
  final String? name;
  final String? avatar;
  final String? role;

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    final idRaw = (json['id'] ?? '').toString().trim();
    final wayoRaw = (json['wayoUserId'] ?? json['wayo_user_id'] ?? '')
        .toString()
        .trim();
    final resolvedId = idRaw.isNotEmpty ? idRaw : wayoRaw;
    final resolvedWayo = wayoRaw.isNotEmpty ? wayoRaw : idRaw;

    return SearchUser(
      id: resolvedId,
      wayoUserId: resolvedWayo,
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
      role: (json['role'] ?? json['roles'])?.toString(),
    );
  }
}
