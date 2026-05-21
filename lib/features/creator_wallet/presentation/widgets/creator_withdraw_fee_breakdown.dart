import 'package:flutter/material.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/creator_withdrawal_fee_estimate.dart';

/// Gross / platform fee / VAT / net — same layout as web creator wallet dialog.
class CreatorWithdrawFeeBreakdown extends StatelessWidget {
  const CreatorWithdrawFeeBreakdown({
    super.key,
    required this.estimate,
    required this.currency,
    required this.moneyLocale,
  });

  final CreatorWithdrawalFeeEstimate estimate;
  final String currency;
  final String moneyLocale;

  String _fmt(int cents) => MoneyFormatter.format(
    cents / 100.0,
    currency: currency,
    locale: moneyLocale,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t.creator.wallet;
    final feePct = (estimate.platformFeeRate * 100).toStringAsFixed(1);
    final feeColor = const Color(0xFFD97706);
    final netColor = const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          _row(context, t.withdraw_gross_amount, _fmt(estimate.grossCents)),
          const SizedBox(height: 6),
          _row(
            context,
            t.withdraw_platform_fee.replaceAll('{percent}', feePct),
            '-${_fmt(estimate.platformFeeCents)}',
            valueColor: feeColor,
          ),
          if (estimate.hasTax) ...[
            const SizedBox(height: 6),
            _row(
              context,
              t.withdraw_tax_vat.replaceAll(
                '{percent}',
                estimate.taxRatePercent.toStringAsFixed(
                  estimate.taxRatePercent.truncateToDouble() ==
                          estimate.taxRatePercent
                      ? 0
                      : 1,
                ),
              ),
              '-${_fmt(estimate.taxCents)}',
              valueColor: feeColor,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              color: AppColors.borderOf(context).withValues(alpha: 0.45),
            ),
          ),
          _row(
            context,
            t.withdraw_net_received,
            _fmt(estimate.netCents),
            labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context),
            ),
            valueStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: netColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    final base = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle ??
                base?.copyWith(color: AppColors.textSecondaryOf(context)),
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              base?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimaryOf(context),
              ),
        ),
      ],
    );
  }
}
