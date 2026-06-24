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
import 'core/push/wayo_push_service.dart';
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

  // Lets content draw behind system gesture/nav bars; avoids an OS-added black scrim seam
  // vs our scaffold color when floating bottom nav overlaps the gesture area (Android).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Larger decoded-image cache reduces evict/re-decode churn while fast-scrolling
  // image grids (campaign explorer, chat avatars). Bytes ceiling still caps RAM.
  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 * 1024 * 1024;

  // [AuthRuntimeConfig.ensureLoaded] only awaits in **debug** (reads dart_defines.json asset);
  // in release it short-circuits synchronously after applying compile-time constants — that
  // path is required for any provider that reads `AuthRuntimeConfig.instance` (api_client,
  // wayo_ads_dio, reverb_client, auth_repository…) when [runApp] mounts.
  final prefsFuture = SharedPreferences.getInstance();
  try {
    await AuthRuntimeConfig.ensureLoaded();
  } catch (e, st) {
    // SECURITY (fail-closed): in release, [ensureLoaded] runs
    // [validateProductionUrls] which throws on insecure (HTTP) config. We must
    // NOT boot with insecure transport config — refuse to start instead.
    if (kReleaseMode) {
      developer.log(
        'AuthRuntimeConfig.ensureLoaded failed in release — aborting startup',
        name: 'wayo.main',
        error: e,
        stackTrace: st,
      );
      runApp(_StartupFailedApp(error: e, stackTrace: st));
      return;
    }
    developer.log(
      'AuthRuntimeConfig.ensureLoaded failed (continuing in debug): $e',
      name: 'wayo.main',
      error: e,
      stackTrace: st,
    );
  }

  try {
    final pushOk = await initializeFirebaseForPush();
    if (!pushOk) {
      developer.log(
        'Firebase push not initialized (run flutterfire configure)',
        name: 'wayo.main',
      );
    }
  } catch (e, st) {
    developer.log(
      'initializeFirebaseForPush failed (continuing): $e',
      name: 'wayo.main',
      error: e,
      stackTrace: st,
    );
  }

  unawaited(
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]),
  );

  // Crash reporter starts as no-op so [runApp] paints the animated splash without waiting
  // on [SentryFlutter.init] (~200–800 ms native channel setup). [_DeferredObservabilityBootstrap]
  // initialises Sentry after the first frame and hot-swaps the global instance — early errors
  // are still captured by [_installGlobalErrorHandlers] (just through the no-op until then).
  CrashReporterHolder.instance = NoopCrashReporter();
  _installGlobalErrorHandlers();

  SharedPreferences? initialPrefs;
  try {
    initialPrefs = await prefsFuture;
  } catch (e, st) {
    developer.log(
      'SharedPreferences.getInstance failed (using in-memory prefs): $e',
      name: 'wayo.main',
      error: e,
      stackTrace: st,
    );
    initialPrefs = null;
  }
  await _runAppImmediate(initialPrefs);
}

/// First [runApp] shows [/splash] as soon as possible. Hive opens after first frame.
Future<void> _runAppImmediate(SharedPreferences? initialPrefs) async {
  try {
    final prefs = initialPrefs == null
        ? AppPrefs.memory()
        : _loadAppPrefsOrMemory(initialPrefs);

    AppLocale initialLocale = AppLocale.en;
    try {
      final locCode = prefs.getString('app.locale');
      initialLocale = locCode == null
          ? AppLocaleUtils.findDeviceLocale()
          : AppLocale.values.firstWhere(
              (l) => l.languageCode == locCode,
              orElse: () => AppLocale.en,
            );
    } catch (e, st) {
      developer.log(
        'Initial locale resolution failed, using en: $e',
        name: 'wayo.main',
        error: e,
        stackTrace: st,
      );
      initialLocale = AppLocale.en;
    }

    // Deferred locales (ar/fr) must be loaded asynchronously — [setLocaleSync] calls
    // [buildSync] which touches deferred imports and crashes on device (see slang lazy mode).
    try {
      await LocaleSettings.setLocale(initialLocale);
    } catch (e, st) {
      developer.log(
        'LocaleSettings.setLocale failed, falling back to en: $e',
        name: 'wayo.main',
        error: e,
        stackTrace: st,
      );
      try {
        await LocaleSettings.setLocale(AppLocale.en);
      } catch (e2, st2) {
        developer.log(
          'LocaleSettings.setLocale(en) also failed: $e2',
          name: 'wayo.main',
          error: e2,
          stackTrace: st2,
        );
        rethrow;
      }
      try {
        await prefs.setString('app.locale', AppLocale.en.languageCode);
      } catch (_) {
        // Best-effort; prefs channel can fail on some embedders.
      }
    }

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
    developer.log(
      'Startup failed',
      name: 'wayo.main',
      error: e,
      stackTrace: st,
    );
    runApp(_StartupFailedApp(error: e, stackTrace: st));
  }
}

/// Minimal UI when bootstrap throws; [kDebugMode] shows the exception (logcat / IDE).
final class _StartupFailedApp extends StatelessWidget {
  const _StartupFailedApp({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    final detail = kDebugMode ? '$error\n\n$stackTrace' : null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Startup failed. Please reinstall or contact support.${kDebugMode ? '\n\n(Debug: see details below)' : ''}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 24),
                    SelectionArea(
                      child: Text(
                        detail,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
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
      debugPrint(
        'SharedPreferences-backed AppPrefs failed ($e); using memory.',
      );
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
      unawaited(attachForegroundFcmHandlers());
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
    // Endpoint URLs only go to the console in debug builds — never in release logs.
    if (kDebugMode) {
      debugPrint('[config] resolvedDioBaseUrl = ${r.resolvedDioBaseUrl}');
      debugPrint('[config] authWayoBaseUrl = ${r.authWayoBaseUrl}');
    }
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
