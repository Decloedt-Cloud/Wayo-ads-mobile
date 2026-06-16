import 'package:flutter/material.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/creator_wallet_models.dart';

/// Secondary wallet KPIs — mirrors the web creator wallet stat cards.
class CreatorWalletStatsRow extends StatelessWidget {
  const CreatorWalletStatsRow({
    super.key,
    required this.page,
    required this.moneyLocale,
  });

  final CreatorWalletPage page;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final currency = page.balance.currency;
    final pendingWithdrawals = MoneyFormatter.format(
      page.pendingWithdrawalsCents / 100.0,
      currency: currency,
      locale: moneyLocale,
    );
    final totalEarned = MoneyFormatter.format(
      page.calculatedTotalEarnedCents / 100.0,
      currency: currency,
      locale: moneyLocale,
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            iconBackground: const Color(0xFFF59E0B).withValues(alpha: 0.18),
            iconColor: const Color(0xFFF59E0B),
            title: t.creator.wallet.pending_withdrawals,
            value: pendingWithdrawals,
            subtitle: t.creator.wallet.in_transit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.payments_rounded,
            iconBackground: CreatorColors.primaryOf(context).withValues(alpha: 0.14),
            iconColor: CreatorColors.primaryOf(context),
            title: t.creator.wallet.total_earned,
            value: totalEarned,
            subtitle: t.creator.wallet.lifetime_earnings,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceElevatedOf(context),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textMutedOf(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
