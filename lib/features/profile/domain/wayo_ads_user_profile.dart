import '../../../../core/config/auth_runtime_config.dart';
import '../../../features/auth/data/models/app_user.dart';
import '../../../features/auth/domain/wayo_ads_account_role.dart';

/// Wayo-ads `GET/PATCH /api/user/profile` user payload.
final class WayoAdsUserProfile {
  const WayoAdsUserProfile({
    required this.id,
    required this.email,
    required this.roles,
    required this.createdAt,
    this.name,
    this.image,
    this.deletionRequiresPassword = true,
  });

  final String id;
  final String email;
  final String? name;
  final String? image;
  final String roles;
  final DateTime createdAt;

  /// False when the account has no password (Google/Apple-only).
  final bool deletionRequiresPassword;

  bool get hasCreatorRole => roles.toUpperCase().contains('CREATOR');
  bool get hasAdvertiserRole => roles.toUpperCase().contains('ADVERTISER');

  WayoAdsUserProfile copyWith({
    String? name,
    String? image,
    bool clearImage = false,
  }) {
    return WayoAdsUserProfile(
      id: id,
      email: email,
      roles: roles,
      createdAt: createdAt,
      name: name ?? this.name,
      image: clearImage ? null : (image ?? this.image),
    );
  }

  bool get isPlaceholder => id.isEmpty;

  /// Instant UI while `GET /api/user/profile` is in flight.
  factory WayoAdsUserProfile.fromAuthSession(AppUser user) {
    final roles = _rolesFromAuthUser(user);
    return WayoAdsUserProfile(
      id: '',
      email: user.email,
      roles: roles,
      name: user.name?.trim().isNotEmpty == true ? user.name!.trim() : null,
      image: user.avatar,
      createdAt: DateTime.now(),
    );
  }

  static String _rolesFromAuthUser(AppUser user) {
    final slug = AuthRuntimeConfig.instance.authAppName.trim();
    final effectiveSlug = slug.isNotEmpty ? slug : 'wayo_ads';
    final parts = <String>{'USER'};
    for (final entry in user.appRoles) {
      if (entry.app == effectiveSlug) {
        final r = entry.role.trim().toUpperCase();
        if (r.isNotEmpty) parts.add(r);
      }
    }
    if (parts.length == 1) {
      final role = switch (user.wayoAdsRole) {
        WayoAdsAccountRole.creator => 'CREATOR',
        WayoAdsAccountRole.advertiser => 'ADVERTISER',
        WayoAdsAccountRole.superAdmin => 'SUPERADMIN',
        _ => '',
      };
      if (role.isNotEmpty) parts.add(role);
    }
    return parts.join(',');
  }

  static WayoAdsUserProfile fromResponseJson(Map<String, dynamic> json) {
    final u = json['user'];
    if (u is! Map<String, dynamic>) {
      throw const FormatException('Expected user object');
    }
    final createdRaw = u['createdAt'] ?? u['created_at'];
    DateTime createdAt = DateTime.now();
    if (createdRaw is String && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw) ?? createdAt;
    }
    final requiresPwRaw =
        u['deletionRequiresPassword'] ?? u['deletion_requires_password'];
    final requiresPassword = requiresPwRaw is bool ? requiresPwRaw : true;

    return WayoAdsUserProfile(
      id: _stringField(u['id']),
      email: _stringField(u['email']),
      roles: _stringField(u['roles']),
      name: u['name'] == null ? null : _stringField(u['name']),
      image: u['image'] == null ? null : _stringField(u['image']),
      createdAt: createdAt,
      deletionRequiresPassword: requiresPassword,
    );
  }

  static String _stringField(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}

String formatProfileRoles(String roles, {
  required String creatorLabel,
  required String advertiserLabel,
  required String userLabel,
}) {
  final upper = roles.toUpperCase();
  final labels = <String>[];
  if (upper.contains('CREATOR')) labels.add(creatorLabel);
  if (upper.contains('ADVERTISER')) labels.add(advertiserLabel);
  if (labels.isEmpty && upper.contains('USER')) labels.add(userLabel);
  if (labels.isEmpty) {
    final role = WayoAdsAccountRole.fromApiString(roles.split(',').last.trim());
    return switch (role) {
      WayoAdsAccountRole.creator => creatorLabel,
      WayoAdsAccountRole.advertiser => advertiserLabel,
      _ => userLabel,
    };
  }
  return labels.join(' · ');
}
