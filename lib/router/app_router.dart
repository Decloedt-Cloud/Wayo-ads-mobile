import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_notifier.dart';
import '../features/auth/domain/wayo_ads_account_role.dart';
import '../features/auth/presentation/providers/current_account_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/domain/onboarding_gate.dart';
import '../features/auth/presentation/screens/email_verification_otp_onboarding_screen.dart';
import '../features/auth/presentation/screens/wayo_ads_role_onboarding_screen.dart';
import '../features/auth/presentation/screens/new_password_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/creator_campaigns/presentation/screens/creator_application_detail_screen.dart';
import '../features/creator_campaigns/presentation/screens/creator_campaign_detail_screen.dart';
import '../features/creator_dashboard/presentation/screens/creator_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/campaign_detail_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/notifications_screen.dart';
import '../features/chat/presentation/screens/chat_thread_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/shell_tabs.dart';
import '../features/wallet/presentation/screens/wallet_tab_screen.dart';
import '../screens/privacy_policy_screen.dart';

part 'app_router.g.dart';

/// Home tab — role-branching:
/// - [WayoAdsAccountRole.creator] → [CreatorDashboardScreen] (stats + analytics).
/// - Otherwise (advertiser / unknown) → [DashboardScreen] (balance + campaigns).
class _HomeTabScreen extends ConsumerWidget {
  const _HomeTabScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.creator) {
      return const CreatorDashboardScreen();
    }
    return const DashboardScreen();
  }
}

/// Root navigator for full-screen routes (detail, notifications).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

bool _isAuthOnboardingPath(String loc) {
  return loc == '/onboarding/wayo-ads-role' ||
      loc == '/onboarding/verify-email-otp';
}

/// Paths that never require an auth redirect away from the shell.
/// Note: [/login] is intentionally omitted — authenticated users must be sent to [/dashboard].
bool _isPublicPath(String loc) {
  if (loc == '/privacy') {
    return true;
  }
  if (loc.startsWith('/forgot-password')) {
    return true;
  }
  return false;
}

@Riverpod(keepAlive: true)
GoRouter goRouter(GoRouterRef ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (
    Object? previous,
    Object? next,
  ) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      if (loc == '/privacy') {
        return null;
      }

      if (loc.startsWith('/forgot-password')) {
        return auth.when(
          data: (s) {
            if (s is AuthAuthenticated) {
              final n = onboardingRedirectPath(s.user);
              return n ?? '/dashboard';
            }
            return null;
          },
          loading: () => null,
          error: (Object? err, StackTrace? stack) => null,
        );
      }

      if (loc == '/home') {
        return '/dashboard';
      }

      if (loc == '/') {
        return auth.when(
          data: (s) {
            if (s is AuthAuthenticated) {
              final n = onboardingRedirectPath(s.user);
              return n ?? '/dashboard';
            }
            return '/login';
          },
          loading: () => null,
          error: (Object? err, StackTrace? stack) => '/login',
        );
      }

      if (_isPublicPath(loc)) {
        return null;
      }

      return auth.when(
        data: (s) {
          if (s is AuthAuthenticated) {
            final next = onboardingRedirectPath(s.user);
            if (next != null) {
              if (loc == next) {
                return null;
              }
              return next;
            }
            if (loc.startsWith('/onboarding/')) {
              return '/dashboard';
            }
            if (loc == '/login') {
              return '/dashboard';
            }
            return null;
          }
          if (loc == '/login') {
            return null;
          }
          if (_isAuthOnboardingPath(loc)) {
            return '/login';
          }
          return '/login';
        },
        loading: () =>
            loc == '/login' || _isAuthOnboardingPath(loc) ? null : '/login',
        error: (Object? err, StackTrace? stack) =>
            loc == '/login' || _isAuthOnboardingPath(loc) ? null : '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final auth = ref.read(authNotifierProvider);
          return auth.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (Object? err, StackTrace? stack) => const SizedBox.shrink(),
          );
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding/wayo-ads-role',
        builder: (context, state) => const WayoAdsRoleOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/verify-email-otp',
        builder: (context, state) =>
            const EmailVerificationOtpOnboardingScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final email = state.extra is String ? state.extra! as String : '';
              return OtpVerificationScreen(email: email);
            },
          ),
          GoRoute(
            path: 'new-password',
            builder: (context, state) {
              final token = state.extra is String ? state.extra! as String : '';
              return NewPasswordScreen(resetToken: token);
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const _HomeTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/campaigns',
                builder: (context, state) => const CampaignsTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatTabScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/campaigns/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          String? coverUrl;
          String? brandLogoUrl;
          String? title;
          final extra = state.extra;
          if (extra is Map) {
            coverUrl = extra['coverUrl'] as String?;
            brandLogoUrl = extra['brandLogoUrl'] as String?;
            title = extra['title'] as String?;
          }
          return MaterialPage<void>(
            key: ValueKey('advertiser-campaign-$id'),
            child: CampaignDetailScreen(
              id: id,
              coverUrl: coverUrl,
              brandLogoUrl: brandLogoUrl,
              title: title,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/creator/campaigns/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          String? coverUrl;
          String? brandLogoUrl;
          String? title;
          final extra = state.extra;
          if (extra is Map) {
            coverUrl = extra['coverUrl'] as String?;
            brandLogoUrl = extra['brandLogoUrl'] as String?;
            title = extra['title'] as String?;
          }
          return MaterialPage<void>(
            key: ValueKey('creator-campaign-$id'),
            child: CreatorCampaignDetailScreen(
              id: id,
              coverUrl: coverUrl,
              brandLogoUrl: brandLogoUrl,
              title: title,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/creator/campaigns/:id/application',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          String? title;
          final extra = state.extra;
          if (extra is Map) {
            title = extra['title'] as String?;
          }
          return MaterialPage<void>(
            key: ValueKey('creator-application-$id'),
            child: CreatorApplicationDetailScreen(campaignId: id, title: title),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/chat/thread/:conversationId',
        builder: (context, state) {
          final raw = state.pathParameters['conversationId']!;
          final id = int.tryParse(raw);
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid conversation')),
            );
          }
          return ChatThreadScreen(conversationId: id);
        },
      ),
    ],
  );
}
