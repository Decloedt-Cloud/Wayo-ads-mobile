import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../providers/invoices_providers.dart';
import 'invoice_date_range_sheet.dart';

/// Date presets for creator statements and advertiser invoices (server `dateFrom` / `dateTo`).
class InvoiceDateFilterBar extends ConsumerWidget {
  const InvoiceDateFilterBar({super.key});

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _applyRange(WidgetRef ref, DateTime? from, DateTime? to) {
    ref.read(invoiceDateFromProvider.notifier).state = from;
    ref.read(invoiceDateToProvider.notifier).state = to;
    ref.invalidate(invoicesControllerProvider);
  }

  void _applyPreset(WidgetRef ref, InvoiceDatePreset preset) {
    ref.read(invoiceDatePresetProvider.notifier).state = preset;
    final now = DateTime.now();
    switch (preset) {
      case InvoiceDatePreset.all:
        _applyRange(ref, null, null);
      case InvoiceDatePreset.last30:
        final from = _dateOnly(now.subtract(const Duration(days: 30)));
        _applyRange(ref, from, _dateOnly(now));
      case InvoiceDatePreset.last90:
        final from = _dateOnly(now.subtract(const Duration(days: 90)));
        _applyRange(ref, from, _dateOnly(now));
      case InvoiceDatePreset.custom:
        break;
    }
  }

  Future<void> _openCustomSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return InvoiceDateRangeSheet(
          initialFrom: ref.read(invoiceDateFromProvider),
          initialTo: ref.read(invoiceDateToProvider),
          onApply: (from, to) {
            ref.read(invoiceDatePresetProvider.notifier).state =
                from == null && to == null
                ? InvoiceDatePreset.all
                : InvoiceDatePreset.custom;
            _applyRange(ref, from, to);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final preset = ref.watch(invoiceDatePresetProvider);
    final from = ref.watch(invoiceDateFromProvider);
    final to = ref.watch(invoiceDateToProvider);

    String customLabel = t.invoices.date_preset_custom;
    if (preset == InvoiceDatePreset.custom && (from != null || to != null)) {
      String fmt(DateTime? d) {
        if (d == null) return '…';
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      customLabel = '${fmt(from)} → ${fmt(to)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _DateChip(
                label: t.invoices.date_preset_all,
                selected: preset == InvoiceDatePreset.all,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _applyPreset(ref, InvoiceDatePreset.all);
                },
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: t.invoices.date_preset_30d,
                selected: preset == InvoiceDatePreset.last30,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _applyPreset(ref, InvoiceDatePreset.last30);
                },
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: t.invoices.date_preset_90d,
                selected: preset == InvoiceDatePreset.last90,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _applyPreset(ref, InvoiceDatePreset.last90);
                },
              ),
              const SizedBox(width: 8),
              _DateChip(
                label: customLabel,
                selected: preset == InvoiceDatePreset.custom,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(invoiceDatePresetProvider.notifier).state =
                      InvoiceDatePreset.custom;
                  _openCustomSheet(context, ref);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppColors.primary
          : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F4)),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimaryOf(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
