import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/auth_runtime_config.dart';
import 'core/observability/app_log.dart';
import 'core/observability/crash_reporter.dart';
import 'core/observability/sentry_bootstrap.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/app_prefs.dart';
import 'features/dashboard/data/dashboard_hive_store.dart';
import 'features/dashboard/presentation/realtime_dashboard_wire.dart';
import 'i18n/strings.g.dart';

/// [SharedPreferences] can throw Pigeon `channel-error` on Android after **hot restart**
/// (Dart VM resets while the embedding channel is stale). We fall back to in-memory prefs
/// so the app still runs; use **Stop** then **Run** (not hot restart) to test persistence.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

  // [AuthRuntimeConfig.ensureLoaded] only awaits in **debug** (reads dart_defines.json asset);
  // in release it short-circuits synchronously after applying compile-time constants — that
  // path is required for any provider that reads `AuthRuntimeConfig.instance` (api_client,
  // wayo_ads_dio, reverb_client, auth_repository…) when [runApp] mounts.
  final prefsFuture = SharedPreferences.getInstance();
  try {
    await AuthRuntimeConfig.ensureLoaded();
  } catch (e, st) {
    developer.log(
      'AuthRuntimeConfig.ensureLoaded failed (continuing): $e',
      name: 'wayo.main',
      error: e,
      stackTrace: st,
    );
  }

  final initialPrefs = await prefsFuture;
  unawaited(
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]),
  );

  // Crash reporter starts as no-op so [runApp] paints the animated splash without waiting
  // on [SentryFlutter.init] (~200–800 ms native channel setup). [_DeferredObservabilityBootstrap]
  // initialises Sentry after the first frame and hot-swaps the global instance — early errors
  // are still captured by [_installGlobalErrorHandlers] (just through the no-op until then).
  CrashReporterHolder.instance = NoopCrashReporter();
  _installGlobalErrorHandlers();
  await _runAppImmediate(initialPrefs);
}

/// First [runApp] shows [/splash] as soon as possible. Hive opens after first frame.
Future<void> _runAppImmediate(SharedPreferences initialPrefs) async {
  try {
    final prefs = _loadAppPrefsOrMemory(initialPrefs);
    final locCode = prefs.getString('app.locale');
    final initialLocale = locCode == null
        ? AppLocaleUtils.findDeviceLocale()
        : AppLocale.values.firstWhere(
            (l) => l.languageCode == locCode,
            orElse: () => AppLocale.en,
          );
    LocaleSettings.setLocaleSync(initialLocale);

    runApp(
      ProviderScope(
        overrides: [
          appPrefsProvider.overrideWithValue(prefs),
          crashReporterProvider.overrideWithValue(CrashReporterHolder.instance),
        ],
        child: TranslationProvider(
          child: _DeferredObservabilityBootstrap(
            child: _DeferredHiveBootstrap(
              child: RealtimeDashboardWire(child: WayoAdsGoApp()),
            ),
          ),
        ),
      ),
    );
  } catch (e, st) {
    debugPrint('Startup failed: $e');
    debugPrintStack(stackTrace: st);
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Startup failed. Please reinstall or contact support.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

AppPrefs _loadAppPrefsOrMemory(SharedPreferences sp) {
  try {
    return AppPrefs.shared(sp);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('SharedPreferences-backed AppPrefs failed ($e); using memory.');
      debugPrintStack(stackTrace: st);
    }
    return AppPrefs.memory();
  }
}

/// Initialises [SentryFlutter] **after** the first frame so the animated splash paints
/// immediately. Until init completes, [CrashReporterHolder.instance] stays a no-op; once
/// ready, it is swapped to [SentryCrashReporter] and existing error handlers route through it.
final class _DeferredObservabilityBootstrap extends StatefulWidget {
  const _DeferredObservabilityBootstrap({required this.child});

  final Widget child;

  @override
  State<_DeferredObservabilityBootstrap> createState() =>
      _DeferredObservabilityBootstrapState();
}

final class _DeferredObservabilityBootstrapState
    extends State<_DeferredObservabilityBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logConfigDiagnostics();
      unawaited(_initSentryWhenIdle());
    });
  }

  /// Out-of-hot-path diagnostics. All sinks are no-ops in normal release builds
  /// (guarded by [kDebugMode] / `WAYO_AUTH_DIAG`).
  void _logConfigDiagnostics() {
    final r = AuthRuntimeConfig.instance;
    wayoConfigDiagPrint(
      '[config] kReleaseMode=$kReleaseMode '
      'resolvedDioBaseUrl=${r.resolvedDioBaseUrl} '
      'AUTH_WAYO_BASE_URL=${r.authWayoBaseUrl} '
      'pins=${r.mergedPinnedSha256Base64.length} '
      'pinningOff=${AppConfig.disableCertPinning} '
      'googleClientIdSet=${r.googleServerClientId.isNotEmpty}',
    );
    debugPrint('[config] resolvedDioBaseUrl = ${r.resolvedDioBaseUrl}');
    debugPrint('[config] authWayoBaseUrl = ${r.authWayoBaseUrl}');
  }

  Future<void> _initSentryWhenIdle() async {
    if (!AuthRuntimeConfig.instance.effectiveSentryEnabled) return;
    try {
      await SentryFlutter.init(applySentryFlutterOptions);
      CrashReporterHolder.instance = SentryCrashReporter();
    } catch (e, st) {
      debugPrint('[sentry deferred] $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opens Hive + dashboard cache **after** the first Flutter frame so cold start paints
/// [SplashScreen] immediately.
final class _DeferredHiveBootstrap extends StatefulWidget {
  const _DeferredHiveBootstrap({required this.child});

  final Widget child;

  @override
  State<_DeferredHiveBootstrap> createState() => _DeferredHiveBootstrapState();
}

final class _DeferredHiveBootstrapState extends State<_DeferredHiveBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openHiveWhenIdle());
    });
  }

  Future<void> _openHiveWhenIdle() async {
    try {
      await Hive.initFlutter();
      await DashboardHiveStore.init().timeout(const Duration(seconds: 15));
    } catch (e, st) {
      debugPrint('[hive deferred] $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    unawaited(
      CrashReporterHolder.instance.captureException(
        details.exception,
        details.stack,
      ),
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(CrashReporterHolder.instance.captureException(error, stack));
    return true;
  };
}
