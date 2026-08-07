import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/push/mobile_push_route_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../shell/shell_tabs.dart';
import '../../../shell/widgets/wayo_bottom_nav.dart';
import '../providers/superadmin_providers.dart';
import 'superadmin_dashboard_screen.dart';
import 'superadmin_shell_screen.dart';
import 'users_screen.dart';
import 'withdrawals_screen.dart';

class SuperadminHomeScreen extends ConsumerStatefulWidget {
  const SuperadminHomeScreen({super.key});

  @override
  ConsumerState<SuperadminHomeScreen> createState() =>
      _SuperadminHomeScreenState();
}

class _SuperadminHomeScreenState extends ConsumerState<SuperadminHomeScreen> {
  int _currentIndex = 0;
  String? _lastSyncedRouteTab;

  static const _tabCount = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyTabFromRouteIfNeeded();
  }

  /// Deep links (FCM / push) set `?tab=` on the route — sync local tab index.
  void _applyTabFromRouteIfNeeded() {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab == null || tab.isEmpty) {
      _lastSyncedRouteTab = null;
      return;
    }
    if (tab == _lastSyncedRouteTab) return;
    _lastSyncedRouteTab = tab;

    // Announcements moved out of the bottom nav → dedicated screen.
    if (tab.trim().toLowerCase() == 'announcements') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/superadmin/announcements');
      });
      return;
    }

    final next =
        superadminTabIndexFromQuery(tab).clamp(0, _tabCount - 1);
    if (next != _currentIndex) {
      setState(() => _currentIndex = next);
    }
  }

  void _selectTab(int index) {
    final safeIndex = index.clamp(0, _tabCount - 1);
    if (safeIndex == _currentIndex) {
      if (safeIndex == 2) {
        invalidateSuperadminWithdrawalData(ref);
      }
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _currentIndex = safeIndex);

    if (safeIndex == 2) {
      invalidateSuperadminWithdrawalData(ref);
    }

    final route = superadminShellRouteForTabIndex(safeIndex);
    _lastSyncedRouteTab =
        Uri.tryParse(route)?.queryParameters['tab'] ?? '';
    final currentPath = GoRouterState.of(context).uri.toString();
    if (currentPath != route) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;

    if (authState is! AuthAuthenticated ||
        authState.user.wayoAdsRole != WayoAdsAccountRole.superAdmin) {
      return const _AccessDeniedScreen();
    }

    final keyboardOpen = wayoShellKeyboardOpen(context);
    final chatUnread = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          SuperadminDashboardScreen(),
          UsersScreen(),
          WithdrawalsScreen(),
          ChatTabScreen(),
          SuperadminMoreScreen(),
        ],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              child: SuperadminBottomNav(
                currentIndex: _currentIndex,
                onTap: _selectTab,
                chatUnread: chatUnread,
              ),
            ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 64,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This area is restricted to superadmin accounts only. Please contact your administrator if you believe you should have access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
