/// Notification preference categories — mirrors web `preference-categories.ts`.
library;

enum NotificationPrefCategory {
  video,
  applications,
  payouts,
  wallet,
  tokens,
  campaigns,
  security;

  static const all = NotificationPrefCategory.values;

  static NotificationPrefCategory? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

enum NotificationPrefAudience { creator, advertiser }

/// Who can see each category in Settings (web CATEGORY_AUDIENCE).
const Map<NotificationPrefCategory, List<NotificationPrefAudience>>
kCategoryAudience = {
  NotificationPrefCategory.video: [
    NotificationPrefAudience.creator,
    NotificationPrefAudience.advertiser,
  ],
  NotificationPrefCategory.applications: [
    NotificationPrefAudience.creator,
    NotificationPrefAudience.advertiser,
  ],
  NotificationPrefCategory.payouts: [NotificationPrefAudience.creator],
  NotificationPrefCategory.wallet: [NotificationPrefAudience.advertiser],
  NotificationPrefCategory.tokens: [], // hidden until wired
  NotificationPrefCategory.campaigns: [NotificationPrefAudience.creator],
  NotificationPrefCategory.security: [NotificationPrefAudience.creator],
};

final class CategoryChannelPrefs {
  const CategoryChannelPrefs({this.inApp = true, this.email = true});

  final bool inApp;
  final bool email;

  CategoryChannelPrefs copyWith({bool? inApp, bool? email}) =>
      CategoryChannelPrefs(
        inApp: inApp ?? this.inApp,
        email: email ?? this.email,
      );

  factory CategoryChannelPrefs.fromJson(Object? json) {
    if (json is! Map) return const CategoryChannelPrefs();
    return CategoryChannelPrefs(
      inApp: json['inApp'] != false,
      email: json['email'] != false,
    );
  }
}

final class NotificationPreferencesSnapshot {
  const NotificationPreferencesSnapshot({
    required this.allowInApp,
    required this.allowEmail,
    required this.allowSound,
    required this.allowBrowserPush,
    required this.categories,
  });

  final bool allowInApp;
  final bool allowEmail;
  final bool allowSound;
  final bool allowBrowserPush;
  final Map<NotificationPrefCategory, CategoryChannelPrefs> categories;

  static Map<NotificationPrefCategory, CategoryChannelPrefs>
  defaultCategories() {
    return {
      for (final c in NotificationPrefCategory.all)
        c: const CategoryChannelPrefs(),
    };
  }

  factory NotificationPreferencesSnapshot.fromJson(Map<String, dynamic> json) {
    final cats = defaultCategories();
    final raw = json['categories'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final key = NotificationPrefCategory.tryParse('${e.key}');
        if (key != null) {
          cats[key] = CategoryChannelPrefs.fromJson(e.value);
        }
      }
    }
    return NotificationPreferencesSnapshot(
      allowInApp: json['allowInApp'] != false,
      allowEmail: json['allowEmail'] != false,
      allowSound: json['allowSound'] != false,
      allowBrowserPush: json['allowBrowserPush'] == true,
      categories: cats,
    );
  }

  NotificationPreferencesSnapshot copyWith({
    bool? allowInApp,
    bool? allowEmail,
    bool? allowSound,
    bool? allowBrowserPush,
    Map<NotificationPrefCategory, CategoryChannelPrefs>? categories,
  }) {
    return NotificationPreferencesSnapshot(
      allowInApp: allowInApp ?? this.allowInApp,
      allowEmail: allowEmail ?? this.allowEmail,
      allowSound: allowSound ?? this.allowSound,
      allowBrowserPush: allowBrowserPush ?? this.allowBrowserPush,
      categories: categories ?? this.categories,
    );
  }
}

/// Categories visible for product roles (CREATOR / ADVERTISER).
List<NotificationPrefCategory> categoriesForRoles(
  Iterable<String> roles,
) {
  final upper = roles.map((e) => e.trim().toUpperCase()).toSet();
  final isCreator = upper.contains('CREATOR');
  final isAdvertiser = upper.contains('ADVERTISER');
  final audiences = <NotificationPrefAudience>[
    if (isCreator) NotificationPrefAudience.creator,
    if (isAdvertiser) NotificationPrefAudience.advertiser,
    if (!isCreator && !isAdvertiser) ...[
      NotificationPrefAudience.creator,
      NotificationPrefAudience.advertiser,
    ],
  ];
  return NotificationPrefCategory.all
      .where(
        (id) => kCategoryAudience[id]!.any(audiences.contains),
      )
      .toList(growable: false);
}
