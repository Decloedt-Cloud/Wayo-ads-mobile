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
}
