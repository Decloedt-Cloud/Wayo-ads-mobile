import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../providers/invoices_providers.dart';

/// Compact row: search and date range (PDFs remain per-invoice).
class InvoiceAdvertiserToolbar extends ConsumerStatefulWidget {
  const InvoiceAdvertiserToolbar({super.key});

  @override
  ConsumerState<InvoiceAdvertiserToolbar> createState() =>
      _InvoiceAdvertiserToolbarState();
}

class _InvoiceAdvertiserToolbarState
    extends ConsumerState<InvoiceAdvertiserToolbar> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearchDebounced(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = v.trim();
      if (!mounted) return;
      ref.read(invoiceSearchQueryProvider.notifier).state = q;
    });
  }

  Future<void> _pickDateRange() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _InvoiceDateRangeSheet(
          initialFrom: ref.read(invoiceDateFromProvider),
          initialTo: ref.read(invoiceDateToProvider),
          onApply: (from, to) {
            ref.read(invoiceDateFromProvider.notifier).state = from;
            ref.read(invoiceDateToProvider.notifier).state = to;
            ref.invalidate(invoicesControllerProvider);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    if (role != WayoAdsAccountRole.advertiser &&
        role != WayoAdsAccountRole.superAdmin &&
        role != WayoAdsAccountRole.creator) {
      return const SizedBox.shrink();
    }

    final hasDates =
        ref.watch(invoiceDateFromProvider) != null ||
        ref.watch(invoiceDateToProvider) != null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _applySearchDebounced,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: t.invoices.search_hint,
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textMutedOf(context),
                ),
                filled: true,
                fillColor: AppColors.surfaceElevatedOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _pickDateRange,
            tooltip: t.invoices.date_range_title,
            style: IconButton.styleFrom(
              backgroundColor: hasDates
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceElevatedOf(context),
              foregroundColor:
                  hasDates ? AppColors.primary : AppColors.textPrimaryOf(context),
              padding: const EdgeInsets.all(12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.date_range_outlined, size: 22),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: edits a draft range; commits to providers only on **Apply**.
class _InvoiceDateRangeSheet extends StatefulWidget {
  const _InvoiceDateRangeSheet({
    required this.initialFrom,
    required this.initialTo,
    required this.onApply,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final void Function(DateTime? from, DateTime? to) onApply;

  @override
  State<_InvoiceDateRangeSheet> createState() => _InvoiceDateRangeSheetState();
}

class _InvoiceDateRangeSheetState extends State<_InvoiceDateRangeSheet> {
  late DateTime? _from;
  late DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _formatDay(DateTime? d) {
    if (d == null) return '—';
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickFrom() async {
    final ctx = context;
    final now = DateTime.now();
    final first = DateTime(2020);
    final cap = _dateOnly(now.add(const Duration(days: 365)));
    final toDay = _to;
    final DateTime last = toDay != null
        ? () {
            final t0 = _dateOnly(toDay);
            if (t0.isBefore(first)) return cap;
            if (t0.isAfter(cap)) return cap;
            return t0;
          }()
        : cap;

    var initial = _from ?? _to ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final d = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (d == null || !mounted) return;

    setState(() {
      _from = d;
      final end = _to;
      if (end != null && _dateOnly(d).isAfter(_dateOnly(end))) {
        _to = d;
      }
    });
  }

  Future<void> _pickTo() async {
    final ctx = context;
    final now = DateTime.now();
    final last = now.add(const Duration(days: 365));
    final fromDay = _from;
    final first = fromDay != null ? _dateOnly(fromDay) : DateTime(2020);
    var initial = _to ?? _from ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final d = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (d == null || !mounted) return;
    setState(() => _to = d);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.invoices.date_range_title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.invoices.date_from),
              subtitle: Text(_formatDay(_from)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickFrom,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.invoices.date_to),
              subtitle: Text(_formatDay(_to)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickTo,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                widget.onApply(_from, _to);
                Navigator.pop(context);
              },
              child: Text(t.invoices.date_apply),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _from = null;
                    _to = null;
                  });
                },
                child: Text(t.invoices.clear_dates),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
