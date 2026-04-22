import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Placeholder so `flutter test test/widget/` succeeds in CI when this folder
/// is the only intended target; add more widget tests here or under test/features/…
void main() {
  testWidgets('smoke: MaterialApp mounts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
