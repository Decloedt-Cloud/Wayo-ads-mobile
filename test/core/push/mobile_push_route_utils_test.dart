import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/push/mobile_push_route_utils.dart';

void main() {
  test('maps creator dashboard paths to mobile routes', () {
    expect(
      normalizeMobilePushRoute('/dashboard/creator/withdrawals'),
      '/wallet',
    );
    expect(
      normalizeMobilePushRoute('/campaigns/abc/links'),
      '/creator/campaigns/abc/application',
    );
  });

  test('preserves chat thread deep links for FCM → conversation body', () {
    expect(
      normalizeMobilePushRoute('/chat/thread/42'),
      '/chat/thread/42',
    );
    expect(
      normalizeMobilePushRoute('/chat/thread/42?reply=1'),
      '/chat/thread/42?reply=1',
    );
    expect(
      normalizeMobilePushRoute('/messages/99'),
      '/chat/thread/99',
    );
    expect(normalizeMobilePushRoute('/chat'), '/chat');
    expect(
      normalizeWayoPushNavigationRoute('/chat/thread/7?peer=Alice'),
      '/chat/thread/7?peer=Alice',
    );
    expect(isAllowedWayoPushNavigationRoute('/chat/thread/7'), isTrue);
  });

  test('shellTabParentForPushRoute maps detail routes to shell tabs', () {
    expect(shellTabParentForPushRoute('/campaigns/abc'), '/campaigns');
    expect(shellTabParentForPushRoute('/creator/campaigns/abc'), '/dashboard');
    expect(shellTabParentForPushRoute('/chat/thread/1'), '/chat');
    expect(shellTabParentForPushRoute('/campaigns'), isNull);
  });

  test('isShellEmbeddedPushRoute detects in-shell campaign detail', () {
    expect(isShellEmbeddedPushRoute('/campaigns/abc'), isTrue);
    expect(isShellEmbeddedPushRoute('/campaigns/abc/extra'), isFalse);
    expect(isShellEmbeddedPushRoute('/creator/campaigns/abc'), isFalse);
  });

  test('allows advertiser campaign editor deep links', () {
    expect(
      isAllowedWayoPushNavigationRoute('/advertiser/campaigns/abc/edit'),
      isTrue,
    );
    expect(
      isAllowedWayoPushNavigationRoute('/advertiser/campaigns/new'),
      isTrue,
    );
    expect(isAllowedWayoPushNavigationRoute('/settings/youtube'), isTrue);
    expect(isAllowedWayoPushNavigationRoute('/creator/analytics'), isTrue);
    expect(isAllowedWayoPushNavigationRoute('/advertiser/creators'), isTrue);
  });

  test('maps and allows business profile routes', () {
    expect(
      normalizeMobilePushRoute('/advertiser/business'),
      '/advertiser/business',
    );
    expect(
      normalizeMobilePushRoute('/dashboard/creator/business'),
      '/creator/business',
    );
    expect(isAllowedWayoPushNavigationRoute('/advertiser/business'), isTrue);
    expect(isAllowedWayoPushNavigationRoute('/creator/business'), isTrue);
    expect(shellTabParentForPushRoute('/creator/business'), '/wallet');
  });
}
