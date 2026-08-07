import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/notification_prefs/domain/notification_preferences.dart';

void main() {
  group('categoriesForRoles', () {
    test('creator sees creator audience categories', () {
      final cats = categoriesForRoles(['CREATOR']);
      expect(cats, contains(NotificationPrefCategory.video));
      expect(cats, contains(NotificationPrefCategory.applications));
      expect(cats, contains(NotificationPrefCategory.payouts));
      expect(cats, contains(NotificationPrefCategory.campaigns));
      expect(cats, contains(NotificationPrefCategory.security));
      expect(cats, isNot(contains(NotificationPrefCategory.wallet)));
      expect(cats, isNot(contains(NotificationPrefCategory.tokens)));
    });

    test('advertiser sees wallet not payouts', () {
      final cats = categoriesForRoles(['ADVERTISER']);
      expect(cats, contains(NotificationPrefCategory.wallet));
      expect(cats, contains(NotificationPrefCategory.video));
      expect(cats, isNot(contains(NotificationPrefCategory.payouts)));
      expect(cats, isNot(contains(NotificationPrefCategory.campaigns)));
    });

    test('both roles union audiences', () {
      final cats = categoriesForRoles(['creator', 'advertiser']);
      expect(cats, contains(NotificationPrefCategory.payouts));
      expect(cats, contains(NotificationPrefCategory.wallet));
    });

    test('unknown role falls back to both audiences', () {
      final cats = categoriesForRoles(const []);
      expect(cats, contains(NotificationPrefCategory.payouts));
      expect(cats, contains(NotificationPrefCategory.wallet));
    });
  });

  group('NotificationPreferencesSnapshot.fromJson', () {
    test('parses channels and categories', () {
      final snap = NotificationPreferencesSnapshot.fromJson({
        'allowInApp': false,
        'allowEmail': true,
        'allowSound': false,
        'allowBrowserPush': true,
        'categories': {
          'video': {'inApp': false, 'email': true},
          'payouts': {'inApp': true, 'email': false},
        },
      });
      expect(snap.allowInApp, isFalse);
      expect(snap.allowEmail, isTrue);
      expect(snap.allowSound, isFalse);
      expect(snap.allowBrowserPush, isTrue);
      expect(snap.categories[NotificationPrefCategory.video]?.inApp, isFalse);
      expect(snap.categories[NotificationPrefCategory.video]?.email, isTrue);
      expect(snap.categories[NotificationPrefCategory.payouts]?.email, isFalse);
      expect(
        snap.categories[NotificationPrefCategory.wallet]?.inApp,
        isTrue,
        reason: 'missing categories default to on',
      );
    });
  });
}
