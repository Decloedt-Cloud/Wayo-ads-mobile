import 'package:flutter/material.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/invoice.dart';

/// Icon + accent for an invoice type. Re-used by the card, the detail screen and
/// the filter sheet so the visual language stays consistent.
@immutable
class InvoiceTypeVisual {
  const InvoiceTypeVisual({
    required this.icon,
    required this.accent,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String label;
}

InvoiceTypeVisual invoiceTypeVisual(BuildContext context, InvoiceType type) {
  final t = context.t;
  switch (type) {
    case InvoiceType.deposit:
      return InvoiceTypeVisual(
        icon: Icons.south_west_rounded,
        accent: const Color(0xFF22C55E),
        label: t.invoices.type_deposit,
      );
    case InvoiceType.billing:
      return InvoiceTypeVisual(
        icon: Icons.rocket_launch_rounded,
        accent: const Color(0xFFF4A237),
        label: t.invoices.type_billing,
      );
    case InvoiceType.payout:
      return InvoiceTypeVisual(
        icon: Icons.north_east_rounded,
        accent: const Color(0xFF6366F1),
        label: t.invoices.type_payout,
      );
    case InvoiceType.earnings:
      return InvoiceTypeVisual(
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF06B6D4),
        label: t.invoices.type_earnings,
      );
    case InvoiceType.unknown:
      return InvoiceTypeVisual(
        icon: Icons.receipt_long_rounded,
        accent: Theme.of(context).colorScheme.outline,
        label: t.invoices.type_unknown,
      );
  }
}

class InvoiceTypeChip extends StatelessWidget {
  const InvoiceTypeChip({super.key, required this.type});

  final InvoiceType type;

  @override
  Widget build(BuildContext context) {
    final v = invoiceTypeVisual(context, type);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: v.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: v.accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(v.icon, size: 14, color: v.accent),
            const SizedBox(width: 6),
            Text(
              v.label,
              style: TextStyle(
                color: v.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
