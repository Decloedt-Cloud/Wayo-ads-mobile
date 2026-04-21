import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/network/rate_limiter.dart';

void main() {
  test('immediately after mark, same key is blocked', () {
    final r = RateLimiter(minInterval: const Duration(seconds: 2));
    expect(r.canCall('a'), true);
    r.mark('a');
    expect(r.canCall('a'), false);
  });
}
