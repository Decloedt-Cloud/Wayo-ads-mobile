import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'superadmin_withdrawals_refresh_hub.dart';

/// Shell tab routes — use [GoRouter.go], not push.
const Set<String> kNotificationShellTabRoutes = {
  '/dashboard',
  '/campaigns',
  '/wallet',
  '/invoices',
  '/chat',
};

const String kSuperadminHomeRoute = '/superadmin';

/// Superadmin tabs that live inside [SuperadminHomeScreen] (bottom nav visible).
int superadminTabIndexFromQuery(String? tab) {
  switch (tab?.trim().toLowerCase()) {
    case 'users':
      return 1;
    case 'withdrawals':
    case 'payouts':
      return 2;
    case 'announcements':
      return 3;
    case 'more':
      return 4;
    default:
      return 0;
  }
}

String superadminShellRouteForTabIndex(int index) {
  const tabs = ['dashboard', 'users', 'withdrawals', 'announcements', 'more'];
  if (index <= 0) return kSuperadminHomeRoute;
  return '$kSuperadminHomeRoute?tab=${tabs[index]}';
}

/// True when a push/deep-link should open the superadmin Payouts tab.
bool isSuperadminWithdrawalsPushRoute(String route) {
  final uri = Uri.tryParse(route);
  if (uri == null) return false;
  switch (uri.path) {
    case '/superadmin/withdrawals':
    case '/admin/withdrawals':
      return true;
    case kSuperadminHomeRoute:
      final tab = uri.queryParameters['tab']?.trim().toLowerCase();
      return tab == 'withdrawals' || tab == 'payouts';
    default:
      return false;
  }
}

/// Maps legacy `/superadmin/*` shell paths into `?tab=` routes on the home shell.
String? resolveSuperadminShellTabRoute(String route) {
  final uri = Uri.tryParse(route);
  if (uri == null) return null;

  final base = uri.path;
  switch (base) {
    case kSuperadminHomeRoute:
      if (uri.queryParameters.containsKey('tab')) return route;
      return route;
    case '/superadmin/withdrawals':
      return '$kSuperadminHomeRoute?tab=withdrawals';
    case '/superadmin/announcements':
      return '$kSuperadminHomeRoute?tab=announcements';
    case '/admin/withdrawals':
      return '$kSuperadminHomeRoute?tab=withdrawals';
    default:
      return null;
  }
}

/// Shell tab to activate before pushing a full-screen deep link (detail, thread, …).
String? shellTabParentForPushRoute(String route) {
  final base = route.split('?').first;
  if (kNotificationShellTabRoutes.contains(base)) return null;

  if (RegExp(r'^/campaigns/[^/]+').hasMatch(base)) return '/campaigns';
  if (RegExp(r'^/creator/campaigns/').hasMatch(base)) return '/dashboard';
  if (base.startsWith('/chat/thread/')) return '/chat';
  if (RegExp(r'^/invoices/[^/]+').hasMatch(base)) return '/invoices';
  if (base == '/notifications') return '/dashboard';
  if (base.startsWith('/advertiser/')) return '/campaigns';
  return null;
}

/// Routes that live inside a shell tab (keep bottom nav visible).
bool isShellEmbeddedPushRoute(String route) {
  final base = route.split('?').first;
  return RegExp(r'^/campaigns/[^/]+$').hasMatch(base);
}

/// Maps any push/deep-link route into the in-app navigation target.
String normalizeWayoPushNavigationRoute(String route) {
  final shell = resolveSuperadminShellTabRoute(route);
  if (shell != null) return shell;

  final fromAction = normalizeMobilePushRoute(route);
  if (fromAction != null) return fromAction;

  return route;
}

/// Opens push / notification deep links without replacing the authenticated shell.
void navigateWayoPushRoute(GoRouter router, String route) {
  final target = normalizeWayoPushNavigationRoute(route);
  final base = target.split('?').first;
  if (kNotificationShellTabRoutes.contains(base)) {
    router.go(target);
    _notifyWithdrawalsRefreshIfNeeded(target);
    return;
  }
  if (base.startsWith('/superadmin')) {
    router.go(target);
    _notifyWithdrawalsRefreshIfNeeded(target);
    return;
  }

  // Advertiser campaign detail is nested under `/campaigns` in [AppShell].
  if (isShellEmbeddedPushRoute(target)) {
    router.go(target);
    return;
  }

  final parent = shellTabParentForPushRoute(target);
  if (parent != null) {
    router.go(parent);
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      router.push(target);
      _notifyWithdrawalsRefreshIfNeeded(target);
    });
    return;
  }

  router.push(target);
  _notifyWithdrawalsRefreshIfNeeded(target);
}

void _notifyWithdrawalsRefreshIfNeeded(String route) {
  if (isSuperadminWithdrawalsPushRoute(route)) {
    notifySuperadminWithdrawalsRefresh();
  }
}

/// Pops a pushed detail route, or returns to the shell tab when opened via [go].
void popOrGoShellParent(BuildContext context, String route) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  final parent = shellTabParentForPushRoute(route);
  context.go(parent ?? '/dashboard');
}

String? _stripLocalePrefix(String path) {
  var p = path.trim();
  if (p.isEmpty) return null;
  p = p.replaceFirst(RegExp(r'^/(en|fr|ar)(?=/|$)'), '');
  if (p.isEmpty) return '/';
  if (!p.startsWith('/')) p = '/$p';
  return p;
}

bool isNotificationsCenterOnlyPath(String path) {
  final base = path.split('?').first;
  return base == '/notifications';
}

/// Extracts an app path from relative or absolute Wayo-ads [actionUrl].
String? extractNotificationPath(String? actionUrl) {
  final raw = (actionUrl ?? '').trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('/') && !raw.startsWith('//')) {
    return _stripLocalePrefix(raw);
  }
  try {
    final uri = Uri.parse(raw);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      final path = uri.path;
      if (path.isEmpty) return null;
      final q = uri.query.isNotEmpty ? '?${uri.query}' : '';
      return _stripLocalePrefix('$path$q');
    }
  } catch (_) {}
  return null;
}

/// Normalizes web [actionUrl] paths from Wayo-ads into Flutter go_router paths.
String? normalizeMobilePushRoute(String? actionUrl) {
  final path = extractNotificationPath(actionUrl);
  if (path == null) return null;
  if (isNotificationsCenterOnlyPath(path)) return null;

  final lower = path.toLowerCase();

  if (lower.contains('/chat') || lower.contains('/messages')) {
    return '/chat';
  }
  if (lower.contains('/invoices') || lower.contains('/invoice')) {
    return '/invoices';
  }
  if (lower.contains('/wallet') ||
      lower.contains('/deposit') ||
      lower.contains('/billing')) {
    return '/wallet';
  }

  if (lower.contains('/superadmin') &&
      (lower.contains('withdraw') || lower.contains('payout'))) {
    return '$kSuperadminHomeRoute?tab=withdrawals';
  }
  if (lower.contains('/admin') &&
      (lower.contains('withdraw') ||
          lower.contains('payout') ||
          lower.contains('payment'))) {
    return '$kSuperadminHomeRoute?tab=withdrawals';
  }

  final campaignMatch = RegExp(r'/campaigns/([^/?#]+)').firstMatch(lower);
  final campaignId = campaignMatch?.group(1);
  if (campaignId != null && campaignId.isNotEmpty) {
    if (lower.contains('/links') ||
        lower.contains('/application') ||
        lower.contains('/applications')) {
      return '/creator/campaigns/$campaignId/application';
    }
    if (lower.contains('/creator/') || lower.contains('/dashboard/creator')) {
      return '/creator/campaigns/$campaignId';
    }
    return '/campaigns/$campaignId';
  }

  if (lower.contains('/dashboard/creator')) {
    if (lower.contains('withdraw') ||
        lower.contains('earning') ||
        lower.contains('payout')) {
      return '/wallet';
    }
    return '/dashboard';
  }
  if (lower.contains('/dashboard/advertiser')) {
    if (lower.contains('wallet') || lower.contains('deposit')) {
      return '/wallet';
    }
    if (lower.contains('invoice')) return '/invoices';
    if (lower.contains('campaign')) return '/campaigns';
    return '/dashboard';
  }

  if (lower.contains('withdraw') || lower.contains('payout')) {
    return '$kSuperadminHomeRoute?tab=withdrawals';
  }

  return path.split('?').first;
}
