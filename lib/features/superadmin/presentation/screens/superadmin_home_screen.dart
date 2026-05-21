import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import 'announcements_screen.dart';
import 'superadmin_dashboard_screen.dart';
import 'superadmin_shell_screen.dart';
import 'users_screen.dart';
import 'withdrawals_screen.dart';

class SuperadminHomeScreen extends ConsumerStatefulWidget {
  const SuperadminHomeScreen({super.key});

  @override
  ConsumerState<SuperadminHomeScreen> createState() => _SuperadminHomeScreenState();
}

class _SuperadminHomeScreenState extends ConsumerState<SuperadminHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    SuperadminDashboardScreen(),
    UsersScreen(),
    WithdrawalsScreen(),
    AnnouncementsScreen(),
    SuperadminMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    
    // Security check - only allow superadmin access
    if (authState is! AuthAuthenticated ||
        authState.user.wayoAdsRole != WayoAdsAccountRole.superAdmin) {
      return _AccessDeniedScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SuperadminBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
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
