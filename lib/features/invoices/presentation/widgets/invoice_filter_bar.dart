import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../providers/invoices_providers.dart';

/// Segmented control for invoice type filters — role-aware (creator hides
/// "Deposits" and "Billing", advertiser hides "Earnings" and "Payouts" sense-wise).
class InvoiceFilterBar extends ConsumerWidget {
  const InvoiceFilterBar({super.key, required this.role});

  final WayoAdsAccountRole role;

  List<InvoiceFilter> _filtersForRole() {
    switch (role) {
      case WayoAdsAccountRole.creator:
        return [
          InvoiceFilter.all,
          InvoiceFilter.payout,
          InvoiceFilter.earnings,
        ];
      case WayoAdsAccountRole.advertiser:
      case WayoAdsAccountRole.superAdmin:
        return [
          InvoiceFilter.all,
          InvoiceFilter.deposit,
          InvoiceFilter.billing,
        ];
      case WayoAdsAccountRole.user:
      case WayoAdsAccountRole.unknown:
        return const [InvoiceFilter.all];
    }
  }

  String _label(BuildContext context, InvoiceFilter f) {
    final t = context.t;
    switch (f) {
      case InvoiceFilter.all:
        return t.invoices.filter_all;
      case InvoiceFilter.deposit:
        return t.invoices.filter_deposits;
      case InvoiceFilter.billing:
        return t.invoices.filter_billing;
      case InvoiceFilter.payout:
        return t.invoices.filter_payouts;
      case InvoiceFilter.earnings:
        return t.invoices.filter_earnings;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(invoicesFilterProvider);
    final filters = _filtersForRole();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final f in filters) ...[
            _Chip(
              label: _label(context, f),
              selected: current == f,
              onTap: () => ref.read(invoicesFilterProvider.notifier).state = f,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = selected
        ? AppColors.primary
        : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F4));
    final fg = selected ? Colors.white : AppColors.textPrimaryOf(context);
    final borderC = selected
        ? AppColors.primary.withValues(alpha: 0.5)
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderC),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
