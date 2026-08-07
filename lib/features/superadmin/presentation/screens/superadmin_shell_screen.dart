import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../shell/widgets/wayo_bottom_nav.dart';
import '../widgets/superadmin_chrome_actions.dart';

class SuperadminShellScreen extends ConsumerWidget {
  const SuperadminShellScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;

    // Security check - only allow superadmin access
    if (authState is! AuthAuthenticated ||
        authState.user.wayoAdsRole != WayoAdsAccountRole.superAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You must be a superadmin to access this area',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

class SuperadminBottomNav extends StatelessWidget {
  const SuperadminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.chatUnread = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Unread badge on the Chat tab (index 3).
  final int chatUnread;

  static const _items = [
    _NavItemData(icon: Icons.space_dashboard_rounded, label: 'Dashboard'),
    _NavItemData(icon: Icons.people_alt_rounded, label: 'Users'),
    _NavItemData(icon: Icons.payments_rounded, label: 'Payouts'),
    _NavItemData(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    _NavItemData(icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  static const int chatTabIndex = 3;

  void _select(int index) {
    HapticFeedback.lightImpact();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: kWayoBottomNavBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: WayoProNavTabItem(
                    icon: _items[index].icon,
                    label: _items[index].label,
                    isSelected: currentIndex == index,
                    onTap: () => _select(index),
                    coachAccent: AppColors.primary,
                    badge: index == chatTabIndex && chatUnread > 0
                        ? chatUnread
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class SuperadminMoreScreen extends ConsumerWidget {
  const SuperadminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [
          SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Tools & Settings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedOf(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.campaign_rounded,
            title: 'Announcements',
            subtitle: 'Publish platform-wide notices for creators and advertisers',
            gradientColors: const [
              Color(0xFFF47A1F),
              Color(0xFFEA580C),
            ],
            onTap: () => context.push('/superadmin/announcements'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.explore_rounded,
            title: 'Browse campaigns',
            subtitle: 'Live marketplace — budgets, views, and campaign details',
            gradientColors: const [
              Color(0xFF0EA5E9),
              Color(0xFF6366F1),
            ],
            onTap: () => context.push('/superadmin/browse-campaigns'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Usage',
            subtitle: 'Monitor AI consumption and platform costs',
            gradientColors: const [
              Color(0xFF7C3AED),
              Color(0xFF2563EB),
            ],
            onTap: () => context.push('/superadmin/ai-usage'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.receipt_long_rounded,
            title: 'Ledger',
            subtitle: 'View all financial transactions and history',
            gradientColors: [
              AppColors.primary,
              AppColors.primaryDeep,
            ],
            onTap: () => context.push('/superadmin/ledger'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.percent_rounded,
            title: 'Tax rates',
            subtitle: 'VAT/GST per country — applies to advertiser invoices',
            gradientColors: const [
              Color(0xFFEA580C),
              Color(0xFFC2410C),
            ],
            onTap: () => context.push('/superadmin/tax-rates'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.fact_check_rounded,
            title: 'Payment audits',
            subtitle: 'Stripe deposits, fees, and reconciliation status',
            gradientColors: const [
              Color(0xFF059669),
              Color(0xFF0D9488),
            ],
            onTap: () => context.push('/superadmin/payment-audits'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.history_edu_rounded,
            title: 'Audit log',
            subtitle: 'Admin and security actions across the platform',
            gradientColors: const [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
            ],
            onTap: () => context.push('/superadmin/audit-log'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.monitor_heart_rounded,
            title: 'Platform health',
            subtitle: 'KPIs and dependency probes (DB, Stripe, mail…)',
            gradientColors: const [
              Color(0xFFDC2626),
              Color(0xFFEA580C),
            ],
            onTap: () => context.push('/superadmin/health'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.token_rounded,
            title: 'Token purchases',
            subtitle: 'Creator Studio credits sold and package mix',
            gradientColors: const [
              Color(0xFF0891B2),
              Color(0xFF2563EB),
            ],
            onTap: () => context.push('/superadmin/token-purchases'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.account_tree_rounded,
            title: 'Click pipeline',
            subtitle: 'Billing statuses for visits in the last 24h',
            gradientColors: const [
              Color(0xFF0F766E),
              Color(0xFF115E59),
            ],
            onTap: () => context.push('/superadmin/click-pipeline'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.speed_rounded,
            title: 'Creator velocity',
            subtitle: 'Top traffic spikes and risk levels',
            gradientColors: const [
              Color(0xFFB45309),
              Color(0xFFD97706),
            ],
            onTap: () => context.push('/superadmin/creator-velocity'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.mark_email_read_rounded,
            title: 'Email logs',
            subtitle: 'Outbound delivery status and failures',
            gradientColors: const [
              Color(0xFF4338CA),
              Color(0xFF6366F1),
            ],
            onTap: () => context.push('/superadmin/email-logs'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.mail_outline_rounded,
            title: 'Email templates',
            subtitle: 'Catalog and plaintext preview',
            gradientColors: const [
              Color(0xFF5B21B6),
              Color(0xFF7C3AED),
            ],
            onTap: () => context.push('/superadmin/email-templates'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.timeline_rounded,
            title: 'Recent activity',
            subtitle: 'Campaigns, signups, and withdrawals feed',
            gradientColors: const [
              Color(0xFF334155),
              Color(0xFF475569),
            ],
            onTap: () => context.push('/superadmin/recent-activity'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.folder_shared_rounded,
            title: 'Financial documents',
            subtitle: 'Advertiser invoices and creator payout statements',
            gradientColors: const [
              Color(0xFF166534),
              Color(0xFF15803D),
            ],
            onTap: () => context.push('/superadmin/financial-documents'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.smart_display_rounded,
            title: 'YouTube monitoring',
            subtitle: 'Post statuses, quota and view-check job',
            gradientColors: const [
              Color(0xFFB91C1C),
              Color(0xFFDC2626),
            ],
            onTap: () => context.push('/superadmin/youtube-monitoring'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.bolt_rounded,
            title: 'Admin jobs',
            subtitle: 'Run payout, metrics and trust-score jobs',
            gradientColors: const [
              Color(0xFFCA8A04),
              Color(0xFFEAB308),
            ],
            onTap: () => context.push('/superadmin/jobs'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Token packages',
            subtitle: 'Create, edit metadata, or pause packages',
            gradientColors: const [
              Color(0xFF0369A1),
              Color(0xFF0EA5E9),
            ],
            onTap: () => context.push('/superadmin/token-packages'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.tune_rounded,
            title: 'Platform settings',
            subtitle: 'Fees, holds, currency and platform name',
            gradientColors: const [
              Color(0xFF57534E),
              Color(0xFF78716C),
            ],
            onTap: () => context.push('/superadmin/platform-settings'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.credit_card_rounded,
            title: 'Stripe settings',
            subtitle: 'Edit TEST/LIVE credentials, reveal, test & switch mode',
            gradientColors: const [
              Color(0xFF635BFF),
              Color(0xFF7A73FF),
            ],
            onTap: () => context.push('/superadmin/stripe-settings'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.email_rounded,
            title: 'Email settings',
            subtitle: 'SMTP configuration and test email',
            gradientColors: const [
              Color(0xFF0369A1),
              Color(0xFF0EA5E9),
            ],
            onTap: () => context.push('/superadmin/email-settings'),
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.campaign_rounded,
            title: 'Broadcast',
            subtitle: 'Send an in-app notification to all or a role',
            gradientColors: const [
              Color(0xFF9D174D),
              Color(0xFFDB2777),
            ],
            onTap: () => context.push('/superadmin/broadcast'),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.3) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderOf(context).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedOf(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showWayoDialog<bool>(
                        context: context,
                        builder: (context) => WayoAlertDialog(
                          backgroundColor: AppColors.surfaceOf(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(authNotifierProvider.notifier).logout();
                      }
                    },
                    icon: Icon(Icons.logout_rounded, color: AppColors.error),
                    label: Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionCard extends StatelessWidget {
  const _MoreOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors.first.withValues(alpha: 0.2),
                      gradientColors.last.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: gradientColors.first,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.borderOf(context).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
