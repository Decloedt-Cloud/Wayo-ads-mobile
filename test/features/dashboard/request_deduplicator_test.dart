import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/network/request_deduplicator.dart';

void main() {
  test('parallel identical keys share one execution', () async {
    final d = RequestDeduplicator();
    var hits = 0;
    final a = d.run<int>('k', () async {
      hits++;
      return 1;
    });
    final b = d.run<int>('k', () async {
      hits++;
      return 2;
    });
    expect(await Future.wait([a, b]), [1, 1]);
    expect(hits, 1);
  });
}
