import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wayoadsgo/app.dart';
import 'package:wayoadsgo/core/observability/crash_reporter.dart';
import 'package:wayoadsgo/core/providers/app_providers.dart';
import 'package:wayoadsgo/core/storage/app_prefs.dart';
import 'package:wayoadsgo/features/auth/domain/auth_notifier.dart';
import 'package:wayoadsgo/features/dashboard/presentation/realtime_dashboard_wire.dart';
import 'package:wayoadsgo/i18n/strings.g.dart';

final class _TestAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthUnauthenticated();
}

void main() {
  testWidgets('WayoAdsGoApp builds', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPrefsProvider.overrideWithValue(AppPrefs.shared(prefs)),
          crashReporterProvider.overrideWithValue(NoopCrashReporter()),
          authNotifierProvider.overrideWith(_TestAuth.new),
        ],
        child: TranslationProvider(
          child: const RealtimeDashboardWire(child: WayoAdsGoApp()),
        ),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
