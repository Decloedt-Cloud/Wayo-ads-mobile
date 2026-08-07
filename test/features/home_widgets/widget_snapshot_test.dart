import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/home_widgets/domain/wayo_ads_widget_snapshot.dart';
import 'package:wayoadsgo/features/home_widgets/domain/widget_auth_state.dart';
import 'package:wayoadsgo/features/home_widgets/services/widget_deep_link_service.dart';

void main() {
  group('WayoAdsWidgetSnapshot', () {
    test('serializes and deserializes', () {
      final snap = WayoAdsWidgetSnapshot(
        updatedAt: DateTime.utc(2026, 8, 7, 12),
        authState: WidgetAuthState.loggedIn,
        role: 'advertiser',
        accountIdHash: 'abc123',
        currency: 'EUR',
        balance: 42.5,
        pendingBalance: 1.25,
        activeCampaigns: 3,
        spend: 10,
        clicks: 20,
        views: 400,
        ctr: 5,
        primaryMetricLabel: 'Active campaigns',
        primaryMetricValue: '3',
        secondaryLeftLabel: 'Spend',
        secondaryLeftValue: '€10.00',
        secondaryRightLabel: 'CTR',
        secondaryRightValue: '5.0%',
      );
      final roundtrip = WayoAdsWidgetSnapshot.fromJson(snap.toJson());
      expect(roundtrip.role, 'advertiser');
      expect(roundtrip.balance, 42.5);
      expect(roundtrip.ctr, 5);
      expect(roundtrip.authState, WidgetAuthState.loggedIn);
      expect(roundtrip.accountIdHash, 'abc123');
    });

    test('loggedOut clears private metrics shape', () {
      final snap = WayoAdsWidgetSnapshot.loggedOut();
      expect(snap.authState, WidgetAuthState.loggedOut);
      expect(snap.authState.statusMessage.toLowerCase(), contains('sign in'));
      expect(snap.balance, isNull);
    });

    test('tokenExpired preserves previous metrics', () {
      final previous = WayoAdsWidgetSnapshot(
        updatedAt: DateTime.utc(2026, 8, 1),
        authState: WidgetAuthState.loggedIn,
        role: 'creator',
        balance: 9,
        primaryMetricValue: '€9.00',
      );
      final expired = WayoAdsWidgetSnapshot.tokenExpired(previous: previous);
      expect(expired.authState, WidgetAuthState.tokenExpired);
      expect(expired.balance, 9);
      expect(expired.authState.statusMessage, contains('refresh'));
    });

    test('staleHint formats age', () {
      final snap = WayoAdsWidgetSnapshot(
        updatedAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
        authState: WidgetAuthState.loggedIn,
        role: 'advertiser',
      );
      expect(snap.isStale, isFalse);
      expect(snap.staleHint, contains('h ago'));
    });

    test('missing values default safely', () {
      final snap = WayoAdsWidgetSnapshot.fromJson({});
      expect(snap.role, 'unknown');
      expect(snap.primaryMetricValue, '—');
      expect(snap.authState, WidgetAuthState.loggedOut);
    });

    test('account switch detection via accountIdHash', () {
      final accountA = WayoAdsWidgetSnapshot(
        updatedAt: DateTime.utc(2026, 8, 1),
        authState: WidgetAuthState.loggedIn,
        role: 'advertiser',
        accountIdHash: 'aaaa1111bbbb',
        balance: 100,
        primaryMetricValue: '€100.00',
      );
      final accountBHash = 'cccc2222dddd';
      expect(accountA.accountIdHash, isNot(accountBHash));
      final cleared = WayoAdsWidgetSnapshot.loggedOut();
      expect(cleared.accountIdHash, isNull);
      expect(cleared.balance, isNull);
      expect(cleared.emptyHeadline, isNotEmpty);
    });

    test('empty state fields serialize', () {
      final snap = WayoAdsWidgetSnapshot(
        updatedAt: DateTime.utc(2026, 8, 7),
        authState: WidgetAuthState.loggedIn,
        role: 'creator',
        emptyHeadline: 'No earnings yet',
        emptyCta: 'View opportunities →',
        balanceFormatted: '€0.00',
      );
      final again = WayoAdsWidgetSnapshot.fromJson(snap.toJson());
      expect(again.emptyHeadline, 'No earnings yet');
      expect(again.emptyCta, contains('opportunities'));
      expect(again.balanceFormatted, '€0.00');
    });
  });

  group('WidgetDeepLinkService', () {
    test('maps advertiser routes', () {
      expect(
        WidgetDeepLinkService.routeForUri(Uri.parse('wayoads://dashboard')),
        '/dashboard',
      );
      expect(
        WidgetDeepLinkService.routeForUri(Uri.parse('wayoads://campaigns')),
        '/campaigns',
      );
      expect(
        WidgetDeepLinkService.routeForUri(
          Uri.parse('wayoads://campaigns/create'),
        ),
        '/advertiser/campaigns/new',
      );
      expect(
        WidgetDeepLinkService.routeForUri(Uri.parse('wayoads://wallet')),
        '/wallet',
      );
      expect(
        WidgetDeepLinkService.routeForUri(Uri.parse('wayoads://analytics')),
        '/dashboard',
      );
      expect(
        WidgetDeepLinkService.routeForUri(
          Uri.parse('wayoads://analytics'),
          role: 'creator',
        ),
        '/creator/analytics',
      );
      expect(
        WidgetDeepLinkService.routeForUri(
          Uri.parse('wayoads://campaigns/create'),
          role: 'creator',
        ),
        '/campaigns',
      );
    });

    test('pending stash / take for cold start', () {
      WidgetDeepLinkService.stashPending(Uri.parse('wayoads://wallet'));
      expect(WidgetDeepLinkService.pending?.host, 'wallet');
      final taken = WidgetDeepLinkService.takePending();
      expect(taken?.host, 'wallet');
      expect(WidgetDeepLinkService.pending, isNull);
    });

    test('ignores foreign schemes', () {
      expect(
        WidgetDeepLinkService.routeForUri(Uri.parse('https://example.com')),
        isNull,
      );
    });
  });

  group('role mapping', () {
    test('auth state storage roundtrip', () {
      for (final s in WidgetAuthState.values) {
        expect(WidgetAuthState.fromStorage(s.storageValue), s);
      }
    });
  });
}
