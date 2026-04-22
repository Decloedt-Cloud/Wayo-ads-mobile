import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/root_scaffold_messenger_key.dart';
import 'features/dashboard/presentation/widgets/realtime_notification_toast_host.dart';
import 'i18n/strings.g.dart';
import 'router/app_router.dart';
import 'shared/widgets/connectivity_overlay.dart';

class WayoAdsGoApp extends ConsumerWidget {
  const WayoAdsGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Wayo Ads',
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => ConnectivityOverlay(
        child: RealtimeNotificationToastHost(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
