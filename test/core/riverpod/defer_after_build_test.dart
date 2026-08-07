import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/riverpod/defer_after_build.dart';

void main() {
  testWidgets('deferAfterBuild runs immediately when not building',
      (tester) async {
    var ran = false;
    deferAfterBuild(() => ran = true);
    expect(ran, isTrue);
  });

  testWidgets('deferAfterBuild completes after a pumped frame', (tester) async {
    var ran = false;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          deferAfterBuild(() => ran = true);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(ran, isTrue);
  });

  test('scheduler phases used by helper are defined', () {
    expect(SchedulerPhase.idle, isNotNull);
    expect(SchedulerPhase.persistentCallbacks, isNotNull);
  });
}
