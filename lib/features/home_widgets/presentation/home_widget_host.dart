import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../auth/domain/auth_notifier.dart';
import '../../auth/presentation/providers/current_account_providers.dart';
import '../../../router/app_router.dart';
import '../services/widget_data_service.dart';
import '../services/widget_deep_link_service.dart';
import '../services/widget_refresh_service.dart';

/// Wires home-widget lifecycle: init, resume refresh, deep-link routing.
class HomeWidgetHost extends ConsumerStatefulWidget {
  const HomeWidgetHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeWidgetHost> createState() => _HomeWidgetHostState();
}

class _HomeWidgetHostState extends ConsumerState<HomeWidgetHost>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _clickSub;
  var _bootstrapped = false;
  Timer? _navRetry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final prefs = ref.read(widgetPreferencesRepositoryProvider);
    await prefs.ensureConfigured();

    try {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initial != null && initial.toString().isNotEmpty) {
        WidgetDeepLinkService.stashPending(initial);
        if (kDebugMode) {
          debugPrint('[HomeWidget] cold launch uri=$initial');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] initiallyLaunched failed: $e');
    }

    _clickSub = HomeWidget.widgetClicked.listen((uri) {
      if (uri == null || uri.toString().isEmpty) return;
      if (kDebugMode) debugPrint('[HomeWidget] clicked uri=$uri');
      _handleUri(uri);
    });

    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is AuthAuthenticated) {
      unawaited(ref.read(widgetRefreshServiceProvider).refresh(force: true));
      _scheduleFlush();
    } else {
      unawaited(ref.read(widgetRefreshServiceProvider).writeLoggedOutShell());
    }
  }

  void _handleUri(Uri uri) {
    WidgetDeepLinkService.stashPending(uri);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _navRetry?.cancel();
    // Retry a few times: auth restore + go_router mount can lag behind the click.
    var attempt = 0;
    void tick() {
      attempt++;
      final ok = _flushPendingDeepLink();
      if (!ok && attempt < 12 && mounted) {
        _navRetry = Timer(const Duration(milliseconds: 250), tick);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      tick();
    });
  }

  /// Returns true when pending was consumed or there was nothing to do.
  bool _flushPendingDeepLink() {
    final pending = WidgetDeepLinkService.pending;
    if (pending == null) return true;

    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) {
      // Keep pending until login completes.
      return false;
    }

    final role = ref.read(currentWayoAdsAccountRoleProvider).name;
    final route = WidgetDeepLinkService.routeForUri(pending, role: role);
    if (route == null) {
      WidgetDeepLinkService.takePending();
      return true;
    }

    try {
      final router = ref.read(goRouterProvider);
      WidgetDeepLinkService.takePending();
      if (kDebugMode) {
        debugPrint('[HomeWidget] navigate → $route (from $pending, role=$role)');
      }
      router.go(route);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] navigate failed: $e');
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authNotifierProvider).valueOrNull;
      if (auth is AuthAuthenticated) {
        unawaited(ref.read(widgetRefreshServiceProvider).refresh());
      }
      // Re-read launch intent in case the stream missed a warm start.
      unawaited(_recheckLaunchIntent());
      _scheduleFlush();
    }
  }

  Future<void> _recheckLaunchIntent() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null && uri.toString().isNotEmpty) {
        WidgetDeepLinkService.stashPending(uri);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _navRetry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_clickSub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      final nextState = next.valueOrNull;
      final prevState = prev?.valueOrNull;
      if (nextState is AuthAuthenticated) {
        unawaited(ref.read(widgetRefreshServiceProvider).refresh(force: true));
        _scheduleFlush();
      } else if (nextState is AuthUnauthenticated &&
          prevState is AuthAuthenticated) {
        unawaited(ref.read(widgetRefreshServiceProvider).clearForLogout());
      }
    });
    return widget.child;
  }
}
