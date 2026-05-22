import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';

/// Bottom sheet: draft date range, committed on **Apply**.
class InvoiceDateRangeSheet extends StatefulWidget {
  const InvoiceDateRangeSheet({
    super.key,
    required this.initialFrom,
    required this.initialTo,
    required this.onApply,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final void Function(DateTime? from, DateTime? to) onApply;

  @override
  State<InvoiceDateRangeSheet> createState() => _InvoiceDateRangeSheetState();
}

class _InvoiceDateRangeSheetState extends State<InvoiceDateRangeSheet> {
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
                  widget.onApply(null, null);
                  Navigator.pop(context);
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
