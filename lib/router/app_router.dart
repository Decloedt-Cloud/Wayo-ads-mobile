import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/data/models/app_user.dart';
import '../features/auth/domain/auth_notifier.dart';
import '../features/auth/domain/wayo_ads_account_role.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/domain/onboarding_gate.dart';
import '../features/auth/presentation/screens/email_verification_otp_onboarding_screen.dart';
import '../features/auth/presentation/screens/signup_email_verification_screen.dart';
import '../features/auth/presentation/screens/signup_register_screen.dart';
import '../features/auth/presentation/screens/wayo_ads_role_onboarding_screen.dart';
import '../features/auth/presentation/models/pending_signup_verify_store.dart';
import '../features/auth/presentation/models/signup_verify_payload.dart';
import '../features/auth/presentation/screens/new_password_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/creator_campaigns/presentation/screens/creator_application_detail_screen.dart';
import '../features/creator_campaigns/presentation/screens/creator_campaign_detail_screen.dart';
import '../features/creator_dashboard/presentation/screens/creator_dashboard_screen.dart';
import '../features/advertiser_video_reviews/domain/advertiser_submitted_video.dart';
import '../features/advertiser_video_reviews/presentation/screens/advertiser_video_reviews_screen.dart';
import '../features/dashboard/presentation/screens/campaign_detail_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/notifications_screen.dart';
import '../features/chat/presentation/screens/chat_thread_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/shell_tab_signed_in_gate.dart';
import '../features/shell/shell_tabs.dart';
import '../features/wallet/presentation/screens/wallet_tab_screen.dart';
import '../features/invoices/presentation/screens/invoices_tab_screen.dart';
import '../features/invoices/presentation/screens/invoice_detail_screen.dart';
import '../features/account_deletion/presentation/screens/account_deletion_screen.dart';
import '../features/profile/presentation/screens/profile_settings_screen.dart';
import '../features/security/presentation/screens/security_settings_screen.dart';
import '../features/security/presentation/screens/trusted_devices_screen.dart';
import '../features/notification_prefs/presentation/screens/notification_preferences_screen.dart';
import '../features/app_settings/presentation/screens/privacy_export_screen.dart';
import '../features/app_settings/presentation/screens/web_only_security_screens.dart';
import '../features/auth/passkey/passkeys_manage_screen.dart';
import '../features/app_settings/presentation/screens/guides_resources_screen.dart';
import '../features/superadmin/presentation/screens/superadmin_home_screen.dart';
import '../features/superadmin/presentation/screens/ai_usage_screen.dart';
import '../features/superadmin/presentation/screens/ledger_screen.dart';
import '../features/superadmin/presentation/screens/banned_users_screen.dart';
import '../features/superadmin/presentation/screens/announcements_screen.dart';
import '../features/superadmin/presentation/screens/superadmin_browse_campaigns_screen.dart';
import '../features/superadmin/presentation/screens/tax_rates_screen.dart';
import '../features/superadmin/presentation/screens/payment_audits_screen.dart';
import '../features/superadmin/presentation/screens/audit_log_screen.dart';
import '../features/superadmin/presentation/screens/platform_health_screen.dart';
import '../features/superadmin/presentation/screens/token_purchases_screen.dart';
import '../features/superadmin/presentation/screens/click_pipeline_screen.dart';
import '../features/superadmin/presentation/screens/creator_velocity_screen.dart';
import '../features/superadmin/presentation/screens/email_logs_screen.dart';
import '../features/superadmin/presentation/screens/email_settings_screen.dart';
import '../features/superadmin/presentation/screens/email_templates_screen.dart';
import '../features/superadmin/presentation/screens/recent_activity_screen.dart';
import '../features/superadmin/presentation/screens/financial_documents_screen.dart';
import '../features/superadmin/presentation/screens/youtube_monitoring_screen.dart';
import '../features/superadmin/presentation/screens/admin_jobs_screen.dart';
import '../features/superadmin/presentation/screens/token_packages_screen.dart';
import '../features/superadmin/presentation/screens/platform_settings_screen.dart';
import '../features/superadmin/presentation/screens/stripe_settings_screen.dart';
import '../features/superadmin/presentation/screens/broadcast_screen.dart';
import '../screens/cookie_policy_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_and_conditions_screen.dart';
import '../features/advertiser_campaigns/presentation/screens/campaign_analytics_screen.dart';
import '../features/advertiser_campaigns/presentation/screens/campaign_editor_screen.dart';
import '../features/advertiser_campaigns/presentation/screens/campaign_financial_health_screen.dart';
import '../features/advertiser_creators/presentation/screens/advertiser_creators_screen.dart';
import '../features/creator_analytics/presentation/screens/creator_analytics_screen.dart';
import '../features/youtube_connection/presentation/screens/youtube_settings_screen.dart';
import '../features/auth/presentation/providers/current_account_providers.dart';
import '../features/creator_wallet/presentation/screens/business_info_host_screen.dart';
import '../features/splash/splash_screen.dart';

part 'app_router.g.dart';

/// Home tab — role-branching:
/// - [WayoAdsAccountRole.creator] → [CreatorDashboardScreen] (stats + analytics).
/// - Otherwise (advertiser / unknown) → [DashboardScreen] (balance + campaigns).
class _HomeTabScreen extends ConsumerWidget {
  const _HomeTabScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShellTabSignedInGate(
      builder: (context, ref, AppUser user) {
        if (user.wayoAdsRole == WayoAdsAccountRole.creator) {
          return const CreatorDashboardScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}

/// `/settings/business` → role-aware advertiser/creator business routes.
class _BusinessSettingsAliasScreen extends ConsumerStatefulWidget {
  const _BusinessSettingsAliasScreen();

  @override
  ConsumerState<_BusinessSettingsAliasScreen> createState() =>
      _BusinessSettingsAliasScreenState();
}

class _BusinessSettingsAliasScreenState
    extends ConsumerState<_BusinessSettingsAliasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentAppUserProvider);
      final path = user?.shouldUseAdvertiserGlobalBusinessSchema == true
          ? '/advertiser/business'
          : '/creator/business';
      context.go(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Root navigator for full-screen routes (detail, notifications).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

Page<void> _advertiserCampaignDetailPage(GoRouterState state) {
  final id = state.pathParameters['id']!;
  String? title;
  final extra = state.extra;
  if (extra is Map) {
    title = extra['title'] as String?;
  }
  return MaterialPage<void>(
    key: ValueKey('advertiser-campaign-$id'),
    child: CampaignDetailScreen(id: id, title: title),
  );
}

bool _isAuthOnboardingPath(String loc) {
  return loc == '/onboarding/wayo-ads-role' ||
      loc == '/onboarding/verify-email-otp';
}

bool _isSignupPath(String loc) {
  return loc == '/signup' || loc.startsWith('/signup/');
}

/// Paths that never require an auth redirect away from the shell.
/// Note: [/login] is intentionally omitted — authenticated users must be sent to [/dashboard].
bool _isPublicPath(String loc) {
  if (loc == '/privacy' || loc == '/terms' || loc == '/cookie-policy') {
    return true;
  }
  if (loc.startsWith('/forgot-password')) {
    return true;
  }
  return false;
}

/// Superadmin home is [/superadmin], but they may open shared full-screen routes
/// (notifications centre, campaign detail from a notif, chat thread, etc.).
bool _superadminAllowedPath(String loc) {
  if (loc.startsWith('/superadmin')) return true;
  if (loc == '/notifications') return true;
  if (loc.startsWith('/campaigns/')) return true;
  if (loc.startsWith('/superadmin/campaigns/')) return true;
  if (loc.startsWith('/creator/campaigns/')) return true;
  if (loc.startsWith('/chat/thread/')) return true;
  if (loc == '/chat' || loc.startsWith('/chat?')) return true;
  if (loc.startsWith('/chat/')) return true;
  if (loc.startsWith('/invoices/')) return true;
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
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      if (loc == '/splash') {
        return null;
      }

      if (loc == '/privacy' || loc == '/terms' || loc == '/cookie-policy') {
        return null;
      }

      /// Forgot-password must stay reachable while signed in (e.g. OAuth users
      /// setting a password from delete-account). Redirecting authed users to
      /// [/dashboard] broke that flow and could upset the root [Navigator]
      /// page stack (duplicate page keys with [GoRouter] + shell).
      if (loc.startsWith('/forgot-password')) {
        return null;
      }

      if (loc == '/home' || loc == '/') {
        return auth.when(
          data: (s) {
            if (s is AuthAuthenticated) {
              final n = onboardingRedirectPath(s.user);
              if (n != null) return n;
              // Superadmin goes directly to superadmin panel
              if (s.user.wayoAdsRole == WayoAdsAccountRole.superAdmin) {
                return '/superadmin';
              }
              return '/dashboard';
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
            final isSuperAdmin =
                s.user.wayoAdsRole == WayoAdsAccountRole.superAdmin;
            if (loc.startsWith('/onboarding/')) {
              return isSuperAdmin ? '/superadmin' : '/dashboard';
            }
            if (loc == '/login') {
              return isSuperAdmin ? '/superadmin' : '/dashboard';
            }
            if (_isSignupPath(loc)) {
              if (loc == '/signup/verify-otp') {
                return null;
              }
              if (s.user.emailVerified != true) {
                return '/onboarding/verify-email-otp';
              }
              return isSuperAdmin ? '/superadmin' : '/dashboard';
            }
            // Campaign create/edit is advertiser-only (creators use browse/apply).
            final isCampaignCreate = loc == '/advertiser/campaigns/new';
            final isCampaignEdit = RegExp(
              r'^/advertiser/campaigns/[^/]+/edit$',
            ).hasMatch(loc);
            if ((isCampaignCreate || isCampaignEdit) &&
                s.user.wayoAdsRole != WayoAdsAccountRole.advertiser) {
              return '/campaigns';
            }
            // Superadmin panel + shared deep links (notifications, etc.)
            if (isSuperAdmin && !_superadminAllowedPath(loc)) {
              return '/superadmin';
            }
            return null;
          }
          if (loc == '/login') {
            return null;
          }
          if (_isSignupPath(loc)) {
            return null;
          }
          if (_isAuthOnboardingPath(loc)) {
            return '/login';
          }
          return '/login';
        },
        loading: () =>
            loc == '/login' || _isSignupPath(loc) || _isAuthOnboardingPath(loc)
            ? null
            : '/login',
        error: (Object? err, StackTrace? stack) =>
            loc == '/login' || _isSignupPath(loc) || _isAuthOnboardingPath(loc)
            ? null
            : '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/cookie-policy',
        builder: (context, state) => const CookiePolicyScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        redirect: (context, state) {
          // Only bare `/signup` — do not steal `/signup/register` or `/signup/verify-otp`.
          if (state.uri.path != '/signup') return null;
          final role =
              state.uri.queryParameters['role']?.trim().toUpperCase() ?? '';
          if (role == 'CREATOR' || role == 'ADVERTISER') {
            return '/signup/register?role=$role';
          }
          return '/signup/register?role=CREATOR';
        },
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) {
              final role =
                  state.uri.queryParameters['role']?.trim().toUpperCase() ?? '';
              final resolved =
                  role == 'ADVERTISER' ? 'ADVERTISER' : 'CREATOR';
              return SignupRegisterScreen(role: resolved);
            },
          ),
          GoRoute(
            path: 'verify-otp',
            builder: (context, state) {
              final extra = state.extra;
              final payload = extra is SignupVerifyPayload
                  ? extra
                  : readPendingSignupVerifyPayload();
              if (payload == null) {
                return const LoginScreen();
              }
              return SignupEmailVerificationScreen(payload: payload);
            },
          ),
        ],
      ),
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
        parentNavigatorKey: rootNavigatorKey,
        path: '/forgot-password',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: const ValueKey<String>('forgot-password'),
          child: const ForgotPasswordScreen(),
        ),
        routes: [
          GoRoute(
            path: 'otp',
            pageBuilder: (context, state) {
              final email = state.extra is String ? state.extra! as String : '';
              return MaterialPage<void>(
                key: ValueKey<String>('forgot-password-otp-$email'),
                child: OtpVerificationScreen(email: email),
              );
            },
          ),
          GoRoute(
            path: 'new-password',
            pageBuilder: (context, state) {
              final token = state.extra is String ? state.extra! as String : '';
              return MaterialPage<void>(
                key: ValueKey<String>('forgot-password-new-$token'),
                child: NewPasswordScreen(resetToken: token),
              );
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
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) =>
                        _advertiserCampaignDetailPage(state),
                  ),
                ],
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
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoicesTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
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
        path: '/advertiser/video-reviews',
        pageBuilder: (context, state) {
          final initialFilter = AdvertiserVideoReviewFilter.fromQuery(
            state.uri.queryParameters['status'],
          );
          return MaterialPage<void>(
            key: ValueKey(
              'advertiser-video-reviews-${initialFilter?.apiValue ?? 'pending'}',
            ),
            child: AdvertiserVideoReviewsScreen(initialFilter: initialFilter),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/advertiser/campaigns/new',
        pageBuilder: (context, state) => const MaterialPage<void>(
          key: ValueKey('advertiser-campaign-new'),
          child: CampaignEditorScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/advertiser/campaigns/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage<void>(
            key: ValueKey('advertiser-campaign-edit-$id'),
            child: CampaignEditorScreen(campaignId: id),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/advertiser/campaigns/:id/analytics',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage<void>(
            key: ValueKey('advertiser-campaign-analytics-$id'),
            child: CampaignAnalyticsScreen(campaignId: id),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/advertiser/campaigns/:id/financial-health',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage<void>(
            key: ValueKey('advertiser-campaign-financial-$id'),
            child: CampaignFinancialHealthScreen(campaignId: id),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/advertiser/creators',
        builder: (context, state) => const AdvertiserCreatorsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/youtube',
        builder: (context, state) => const YouTubeSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/creator/analytics',
        builder: (context, state) => const CreatorAnalyticsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/advertiser/business',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: const ValueKey('advertiser-business'),
          child: BusinessInfoHostScreen.fromGoState(
            state,
            useGlobalBilling: true,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/creator/business',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: const ValueKey('creator-business'),
          child: BusinessInfoHostScreen.fromGoState(
            state,
            useGlobalBilling: false,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/creator/payouts',
        builder: (context, state) => const InvoicesTabScreen(standalone: true),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/business',
        builder: (context, state) => const _BusinessSettingsAliasScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/campaigns/:id',
        pageBuilder: (context, state) => _advertiserCampaignDetailPage(state),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/creator/campaigns/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          String? title;
          final extra = state.extra;
          if (extra is Map) {
            title = extra['title'] as String?;
          }
          return MaterialPage<void>(
            key: ValueKey('creator-campaign-$id'),
            child: CreatorCampaignDetailScreen(id: id, title: title),
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
        path: '/invoices/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage<void>(
            key: ValueKey('invoice-$id'),
            child: InvoiceDetailScreen(invoiceId: id),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/profile',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/notifications',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyExportScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/passkeys',
        builder: (context, state) => const PasskeysManageScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/connected-accounts',
        builder: (context, state) => const ConnectedAccountsInfoScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/resources',
        builder: (context, state) => const GuidesResourcesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/security',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/trusted-devices',
        builder: (context, state) => const TrustedDevicesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings/delete-account',
        builder: (context, state) => const AccountDeletionScreen(),
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
          final reply =
              state.uri.queryParameters['reply'] == '1' ||
              state.uri.queryParameters['reply'] == 'true';
          return ChatThreadScreen(conversationId: id, autoFocusComposer: reply);
        },
      ),
      // Superadmin routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin',
        builder: (context, state) => const SuperadminHomeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/ai-usage',
        builder: (context, state) => const AiUsageScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/ledger',
        builder: (context, state) => const LedgerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/withdrawals',
        redirect: (context, state) => '/superadmin?tab=withdrawals',
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin/withdrawals',
        redirect: (context, state) => '/superadmin?tab=withdrawals',
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/banned-users',
        builder: (context, state) => const BannedUsersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/browse-campaigns',
        builder: (context, state) => const SuperadminBrowseCampaignsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/tax-rates',
        builder: (context, state) => const TaxRatesScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'subdivisions/:countryCode',
            builder: (context, state) => TaxRatesScreen(
              countryCode: state.pathParameters['countryCode'],
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/payment-audits',
        builder: (context, state) => const PaymentAuditsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/audit-log',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/health',
        builder: (context, state) => const PlatformHealthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/token-purchases',
        builder: (context, state) => const TokenPurchasesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/click-pipeline',
        builder: (context, state) => const ClickPipelineScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/creator-velocity',
        builder: (context, state) => const CreatorVelocityScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/email-logs',
        builder: (context, state) => const EmailLogsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/email-templates',
        builder: (context, state) => const EmailTemplatesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/recent-activity',
        builder: (context, state) => const RecentActivityScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/financial-documents',
        builder: (context, state) => const FinancialDocumentsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/youtube-monitoring',
        builder: (context, state) => const YoutubeMonitoringScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/jobs',
        builder: (context, state) => const AdminJobsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/token-packages',
        builder: (context, state) => const TokenPackagesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/platform-settings',
        builder: (context, state) => const PlatformSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/stripe-settings',
        builder: (context, state) => const StripeSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/email-settings',
        builder: (context, state) => const EmailSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/superadmin/broadcast',
        builder: (context, state) => const BroadcastScreen(),
      ),
    ],
  );
}
