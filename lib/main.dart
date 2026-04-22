import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/auth_runtime_config.dart';
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

  await AuthRuntimeConfig.ensureLoaded();

  final results = await Future.wait<Object?>([
    SharedPreferences.getInstance(),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);
  final initialPrefs = results[0] as SharedPreferences;

  if (AuthRuntimeConfig.instance.effectiveSentryEnabled) {
    await SentryFlutter.init(
      applySentryFlutterOptions,
      appRunner: () {
        CrashReporterHolder.instance = SentryCrashReporter();
        _installGlobalErrorHandlers();
        runApp(_WayoAdsBootstrap(sharedPreferences: initialPrefs));
      },
    );
  } else {
    CrashReporterHolder.instance = NoopCrashReporter();
    await CrashReporterHolder.instance.init();
    _installGlobalErrorHandlers();
    runApp(_WayoAdsBootstrap(sharedPreferences: initialPrefs));
  }
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

class _WayoAdsBootstrap extends StatefulWidget {
  const _WayoAdsBootstrap({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  State<_WayoAdsBootstrap> createState() => _WayoAdsBootstrapState();
}

class _WayoAdsBootstrapState extends State<_WayoAdsBootstrap> {
  late final Future<AppPrefs> _bootFuture;

  @override
  void initState() {
    super.initState();
    _bootFuture = _boot();
  }

  Future<AppPrefs> _boot() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    await AuthRuntimeConfig.ensureLoaded();
    await Hive.initFlutter();
    await DashboardHiveStore.init();

    late final AppPrefs prefs;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (attempt == 0) {
          prefs = AppPrefs.shared(widget.sharedPreferences);
        } else {
          prefs = AppPrefs.shared(await SharedPreferences.getInstance());
        }
        break;
      } catch (e, st) {
        if (attempt == 2) {
          if (kDebugMode) {
            debugPrint(
              'SharedPreferences unavailable after 3 attempts ($e). '
              'Using in-memory prefs (theme/locale not persisted until full app restart). '
              'Avoid hot restart to test persistence.',
            );
            debugPrintStack(stackTrace: st);
          }
          prefs = AppPrefs.memory();
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
      }
    }

    final locCode = prefs.getString('app.locale');
    final initialLocale = locCode == null
        ? AppLocaleUtils.findDeviceLocale()
        : AppLocale.values.firstWhere(
            (l) => l.languageCode == locCode,
            orElse: () => AppLocale.en,
          );

    try {
      await LocaleSettings.setLocale(initialLocale);
    } catch (e, st) {
      debugPrint('LocaleSettings.setLocale failed: $e\n$st');
      await LocaleSettings.setLocale(AppLocale.en);
    }

    return prefs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppPrefs>(
      future: _bootFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${snapshot.error}', textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
          );
        }

        return ProviderScope(
          overrides: [
            appPrefsProvider.overrideWithValue(snapshot.data!),
            crashReporterProvider.overrideWithValue(
              CrashReporterHolder.instance,
            ),
          ],
          child: TranslationProvider(
            child: const RealtimeDashboardWire(child: WayoAdsGoApp()),
          ),
        );
      },
    );
  }
}
