import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/network/scrubber.dart';

void main() {
  test('scrubs Authorization case-insensitively', () {
    final input = <String, dynamic>{
      'Authorization': 'Bearer secret',
      'authorization': 'x',
      'AUTHORIZATION': 'y',
    };
    final out = scrub(input);
    expect(out['Authorization'], kRedacted);
    expect(out['authorization'], kRedacted);
    expect(out['AUTHORIZATION'], kRedacted);
  });

  test('recursive maps and lists', () {
    final input = <String, dynamic>{
      'outer': <String, dynamic>{
        'password': 'hunter2',
        'nested': <dynamic>[
          <String, dynamic>{'otp': '123456'},
        ],
      },
    };
    final out = scrub(input);
    final outer = out['outer'] as Map<String, dynamic>;
    expect(outer['password'], kRedacted);
    final list = outer['nested'] as List<dynamic>;
    expect((list.first as Map<String, dynamic>)['otp'], kRedacted);
  });

  test('does not mutate original map', () {
    final input = <String, dynamic>{'Authorization': 'keep'};
    final copy = Map<String, dynamic>.from(input);
    scrub(input);
    expect(input['Authorization'], 'keep');
    expect(copy['Authorization'], 'keep');
  });
}
