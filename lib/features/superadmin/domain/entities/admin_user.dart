import 'package:flutter/foundation.dart';

/// Statistics for the admin users panel.
@immutable
class AdminUsersStats {
  const AdminUsersStats({
    required this.total,
    required this.creators,
    required this.advertisers,
    required this.banned,
    required this.unverified,
    required this.deletionRequests,
  });

  final int total;
  final int creators;
  final int advertisers;
  final int banned;
  final int unverified;
  final int deletionRequests;

  factory AdminUsersStats.fromJson(Map<String, dynamic> json) {
    return AdminUsersStats(
      total: _parseInt(json['total'] ?? json['totalUsers'] ?? json['total_users']),
      creators: _parseInt(
        json['creators'] ?? json['creator'] ?? json['totalCreators'],
      ),
      advertisers: _parseInt(
        json['advertisers'] ?? json['advertiser'] ?? json['totalAdvertisers'],
      ),
      banned: _parseInt(json['banned'] ?? json['bannedCount']),
      unverified: _parseInt(
        json['unverified'] ?? json['unverifiedCount'] ?? json['emailUnverified'],
      ),
      deletionRequests: _parseInt(
        json['deletionRequests'] ??
            json['deletionRequested'] ??
            json['deletion_requested'],
      ),
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

/// User status enum.
enum AdminUserStatus {
  active,
  emailUnverified,
  banned,
  pendingDeletion,
  unknown;

  /// Parse status from API fields (isBannedLocally, emailVerified, deletionRequestedAt)
  static AdminUserStatus fromApiFields({
    bool? isBannedLocally,
    Object? emailVerified,
    Object? deletionRequestedAt,
  }) {
    if (isBannedLocally == true) return banned;
    if (deletionRequestedAt != null && '$deletionRequestedAt'.isNotEmpty) {
      return pendingDeletion;
    }
    if (emailVerified == null || '$emailVerified'.isEmpty) {
      return emailUnverified;
    }
    return active;
  }

  static AdminUserStatus fromString(String? value) {
    if (value == null) return unknown;
    final lower = value.toLowerCase().replaceAll('_', '');
    if (lower.contains('active')) return active;
    if (lower.contains('unverified') || lower.contains('emailunverified')) {
      return emailUnverified;
    }
    if (lower.contains('banned')) return banned;
    if (lower.contains('deletion') || lower.contains('pending')) {
      return pendingDeletion;
    }
    return unknown;
  }

  String get displayName {
    switch (this) {
      case active:
        return 'Active';
      case emailUnverified:
        return 'Email unverified';
      case banned:
        return 'Banned';
      case pendingDeletion:
        return 'Pending deletion';
      case unknown:
        return 'Unknown';
    }
  }
}

/// User role enum.
enum AdminUserRole {
  creator,
  advertiser,
  superAdmin,
  unknown;

  /// Parse from comma-separated roles string like "USER,CREATOR" or "USER,ADVERTISER"
  static AdminUserRole fromString(String? value) {
    if (value == null || value.isEmpty) return unknown;
    final upper = value.toUpperCase();
    
    // Check for superadmin first (highest priority)
    if (upper.contains('SUPERADMIN') || upper.contains('SUPER_ADMIN')) {
      return superAdmin;
    }
    // Then advertiser
    if (upper.contains('ADVERTISER')) {
      return advertiser;
    }
    // Then creator
    if (upper.contains('CREATOR')) {
      return creator;
    }
    // If only USER, show as unknown (shouldn't happen in admin panel)
    if (upper == 'USER') {
      return unknown;
    }
    return unknown;
  }

  String get displayName {
    switch (this) {
      case creator:
        return 'Creator';
      case advertiser:
        return 'Advertiser';
      case superAdmin:
        return 'Super Admin';
      case unknown:
        return 'User';
    }
  }
}

/// Stripe connection status.
enum StripeStatus {
  connected,
  notConnected,
  noBusinessProfile,
  unknown;

  /// Parse from API fields (stripeChargesEnabled, stripeOnboardingCompleted, creatorBusinessProfile)
  static StripeStatus fromApiFields({
    bool? stripeChargesEnabled,
    bool? stripeOnboardingCompleted,
    bool? stripePayoutsEnabled,
    Object? creatorBusinessProfile,
  }) {
    // Check if Stripe is fully connected
    if (stripeChargesEnabled == true || 
        stripePayoutsEnabled == true || 
        stripeOnboardingCompleted == true) {
      return connected;
    }
    // Check if there's no business profile (for creators)
    if (creatorBusinessProfile == null) {
      return noBusinessProfile;
    }
    return notConnected;
  }

  static StripeStatus fromString(String? value) {
    if (value == null) return unknown;
    final lower = value.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (lower.contains('connected') && !lower.contains('not')) return connected;
    if (lower.contains('notconnected') || lower.contains('disconnected')) {
      return notConnected;
    }
    if (lower.contains('nobusiness') || lower.contains('noprofile')) {
      return noBusinessProfile;
    }
    return unknown;
  }

  String get displayName {
    switch (this) {
      case connected:
        return 'Connected';
      case notConnected:
        return 'Not connected';
      case noBusinessProfile:
        return 'No business profile';
      case unknown:
        return 'N/A';
    }
  }
}

/// A user in the admin panel.
@immutable
class AdminUser {
  const AdminUser({
    required this.id,
    required this.authUserId,
    required this.email,
    this.name,
    this.avatar,
    required this.role,
    required this.stripeStatus,
    this.ipAddress,
    this.lastLogin,
    required this.joinedAt,
    required this.status,
    this.approvedCollaborations = 0,
    this.isEmailVerified = false,
    this.isOnboardingCompleted = false,
  });

  final String id;
  final int authUserId;
  final String email;
  final String? name;
  final String? avatar;
  final AdminUserRole role;
  final StripeStatus stripeStatus;
  final String? ipAddress;
  final DateTime? lastLogin;
  final DateTime joinedAt;
  final AdminUserStatus status;
  
  /// Number of approved campaign applications (for creators)
  final int approvedCollaborations;
  
  /// Whether email is verified
  final bool isEmailVerified;
  
  /// Whether onboarding is completed
  final bool isOnboardingCompleted;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    // Parse role from "roles" field (comma-separated like "USER,CREATOR")
    final roles = json['roles']?.toString() ?? json['role']?.toString();
    
    // API `/all` returns bool; legacy payloads may use DateTime or null.
    final emailVerifiedRaw = json['emailVerified'];
    final isEmailVerified = emailVerifiedRaw == true ||
        (emailVerifiedRaw is String &&
            emailVerifiedRaw.isNotEmpty &&
            emailVerifiedRaw != 'null');
    
    // Check if banned
    final isBanned = json['isBannedLocally'] == true;
    
    // Check if deletion requested
    final deletionRequestedAt = json['deletionRequestedAt'];
    final hasDeletionRequest = deletionRequestedAt != null && 
        '$deletionRequestedAt'.isNotEmpty && 
        '$deletionRequestedAt' != 'null';
    
    // Determine true status
    AdminUserStatus status;
    if (isBanned) {
      status = AdminUserStatus.banned;
    } else if (hasDeletionRequest) {
      status = AdminUserStatus.pendingDeletion;
    } else if (!isEmailVerified) {
      status = AdminUserStatus.emailUnverified;
    } else {
      status = AdminUserStatus.active;
    }
    
    // Parse Stripe status (web `/all` uses onboarding + account status + profile flag).
    final stripeStatus = json['stripeStatus'] != null
        ? StripeStatus.fromString(json['stripeStatus']?.toString())
        : _stripeStatusFromApi(json, roles);
    
    // Count approved collaborations from applications array
    int approvedCount = 0;
    final applications = json['applications'];
    if (applications is List) {
      approvedCount = applications.where((app) {
        if (app is Map) {
          final appStatus = app['status']?.toString().toUpperCase();
          return appStatus == 'APPROVED';
        }
        return false;
      }).length;
    }
    // Or use pre-computed count if available
    if (json['approvedCollaborations'] != null) {
      approvedCount = _parseInt(json['approvedCollaborations']);
    }
    if (json['_count'] is Map) {
      final count = json['_count'] as Map;
      if (count['applications'] != null) {
        // This might be total, we need approved only
        // Keep the approvedCount from above if we already have it
      }
    }
    
    // Check onboarding completion
    final isOnboardingCompleted = json['onboardingCompleted'] == true;
    final email = (json['email'] ?? '').toString();

    return AdminUser(
      id: (json['id'] ?? '').toString(),
      authUserId: _parseInt(json['authUserId'] ?? json['auth_user_id']),
      email: email,
      name: json['name']?.toString(),
      avatar: json['image']?.toString() ?? json['avatar']?.toString(),
      role: AdminUserRole.fromString(roles),
      stripeStatus: stripeStatus,
      ipAddress: json['ipAddress']?.toString() ?? json['ip_address']?.toString(),
      lastLogin: _parseDateTime(json['lastLoginAt'] ?? json['lastLogin'] ?? json['last_login']),
      joinedAt: _parseDateTime(json['createdAt'] ?? json['joinedAt'] ?? json['joined_at']) 
          ?? DateTime.now(),
      status: status,
      approvedCollaborations: approvedCount,
      isEmailVerified: isEmailVerified,
      isOnboardingCompleted: isOnboardingCompleted,
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static DateTime? _parseDateTime(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  String get initials {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        final a = parts[0].isNotEmpty ? parts[0][0] : '';
        final b = parts[1].isNotEmpty ? parts[1][0] : '';
        final s = '$a$b'.toUpperCase();
        if (s.isNotEmpty) return s;
      }
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
      }
    }
    if (email.length >= 2) return email.substring(0, 2).toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}

/// Filter options for joined date.
enum JoinedFilter {
  all,
  last24Hours,
  last7Days,
  last30Days;

  String get displayName {
    switch (this) {
      case all:
        return 'All';
      case last24Hours:
        return '24 hours';
      case last7Days:
        return '7 days';
      case last30Days:
        return '30 days';
    }
  }

  /// ISO date for [GET /api/admin/users/all] `dateFrom` query param.
  String? get dateFromIso {
    final now = DateTime.now().toUtc();
    switch (this) {
      case all:
        return null;
      case last24Hours:
        return now.subtract(const Duration(hours: 24)).toIso8601String();
      case last7Days:
        return now.subtract(const Duration(days: 7)).toIso8601String();
      case last30Days:
        return now.subtract(const Duration(days: 30)).toIso8601String();
    }
  }
}

StripeStatus _stripeStatusFromApi(
  Map<String, dynamic> json,
  String? roles,
) {
  final onboarding = json['stripeOnboardingCompleted'] == true;
  final accountStatus = json['stripeAccountStatus']?.toString().toLowerCase();
  if (onboarding ||
      accountStatus == 'complete' ||
      accountStatus == 'enabled') {
    return StripeStatus.connected;
  }
  final isCreator = (roles ?? '').toUpperCase().contains('CREATOR');
  if (isCreator && json['hasCreatorProfile'] != true) {
    return StripeStatus.noBusinessProfile;
  }
  return StripeStatus.fromApiFields(
    stripeChargesEnabled: json['stripeChargesEnabled'] as bool?,
    stripeOnboardingCompleted: onboarding,
    stripePayoutsEnabled: json['stripePayoutsEnabled'] as bool?,
    creatorBusinessProfile:
        json['hasCreatorProfile'] == true ? const {} : json['creatorBusinessProfile'],
  );
}

/// Filter options for role.
enum RoleFilter {
  all,
  creator,
  advertiser;

  String get displayName {
    switch (this) {
      case all:
        return 'All';
      case creator:
        return 'Creator';
      case advertiser:
        return 'Advertiser';
    }
  }

  /// [GET /api/admin/users/all] expects `creator` / `advertiser` (lowercase).
  String? get apiValue {
    switch (this) {
      case all:
        return null;
      case creator:
        return 'creator';
      case advertiser:
        return 'advertiser';
    }
  }
}

/// Page size for [GET /api/admin/users/all] (`page` + `limit` query params).
const kAdminUsersPageSize = 20;

/// Paginated response for admin users.
@immutable
class AdminUsersPage {
  const AdminUsersPage({
    required this.users,
    required this.stats,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.limit,
  });

  final List<AdminUser> users;
  final AdminUsersStats stats;
  final int total;
  final int page;
  final int totalPages;
  final int limit;

  factory AdminUsersPage.fromJson(Map<String, dynamic> json) {
    final usersRaw = json['users'];
    final users = <AdminUser>[];
    if (usersRaw is List) {
      for (final item in usersRaw) {
        if (item is Map) {
          try {
            users.add(AdminUser.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {
            // Skip malformed rows so one bad user does not blank the whole page.
          }
        }
      }
    }

    final statsRaw = json['stats'];
    final statsMap = statsRaw is Map
        ? Map<String, dynamic>.from(statsRaw)
        : <String, dynamic>{};

    return AdminUsersPage(
      users: users,
      stats: statsMap.isNotEmpty
          ? AdminUsersStats.fromJson(statsMap)
          : AdminUsersStats.fromJson(json),
      total: _parseInt(json['total']),
      page: _parseInt(json['page'], fallback: 1),
      totalPages: _parseInt(json['totalPages'], fallback: 1),
      limit: _parseInt(json['limit'], fallback: kAdminUsersPageSize),
    );
  }

  static int _parseInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  AdminUsersPage copyWith({
    List<AdminUser>? users,
    AdminUsersStats? stats,
    int? total,
    int? page,
    int? totalPages,
    int? limit,
  }) {
    return AdminUsersPage(
      users: users ?? this.users,
      stats: stats ?? this.stats,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      limit: limit ?? this.limit,
    );
  }
}
