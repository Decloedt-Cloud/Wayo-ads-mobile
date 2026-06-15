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
}
