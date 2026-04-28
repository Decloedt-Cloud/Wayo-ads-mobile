import 'package:flutter/material.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/creator_wallet_models.dart';

/// Earnings hero card — the teal gradient echoes the creator dashboard.
class CreatorWalletHero extends StatelessWidget {
  const CreatorWalletHero({
    super.key,
    required this.balance,
    required this.moneyLocale,
  });

  final CreatorBalance balance;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: CreatorColors.primaryGradient,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.creator.wallet.available_balance,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  MoneyFormatter.format(
                    balance.available,
                    currency: balance.currency,
                    locale: moneyLocale,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _InlineBalance(
                      icon: Icons.schedule_rounded,
                      label: t.creator.wallet.pending_balance,
                      value: MoneyFormatter.format(
                        balance.pending,
                        currency: balance.currency,
                        locale: moneyLocale,
                      ),
                    ),
                    _InlineBalance(
                      icon: Icons.trending_up_rounded,
                      label: t.creator.wallet.total_earned,
                      value: MoneyFormatter.format(
                        balance.totalEarned,
                        currency: balance.currency,
                        locale: moneyLocale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBalance extends StatelessWidget {
  const _InlineBalance({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
