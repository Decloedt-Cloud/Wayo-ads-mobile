import 'package:flutter/material.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/invoice.dart';

/// Premium animated status pill — uses a soft tinted background, dot indicator,
/// and color tokens that respect light/dark themes.
class InvoiceStatusPill extends StatelessWidget {
  const InvoiceStatusPill({
    super.key,
    required this.status,
    this.dense = false,
  });

  final InvoiceStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (Color base, Color foreground, String label) = switch (status) {
      InvoiceStatus.paid => (
        const Color(0xFF22C55E),
        const Color(0xFF0F5132),
        t.invoices.status_paid,
      ),
      InvoiceStatus.validated => (
        const Color(0xFF22C55E),
        const Color(0xFF0F5132),
        t.invoices.status_validated,
      ),
      InvoiceStatus.pending => (
        const Color(0xFFF4A237),
        const Color(0xFF7A3F00),
        t.invoices.status_pending,
      ),
      InvoiceStatus.cancelled => (
        const Color(0xFFFF4D4F),
        const Color(0xFF7A0014),
        t.invoices.status_cancelled,
      ),
      InvoiceStatus.unknown => (
        Theme.of(context).colorScheme.outline,
        Theme.of(context).colorScheme.onSurface,
        '—',
      ),
    };

    final bgColor = base.withValues(alpha: 0.16);
    final dotColor = base;
    final fg = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(Colors.white, base, 0.4) ?? base
        : foreground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LivePulseDot(
              color: dotColor,
              animate:
                  status == InvoiceStatus.paid || status == InvoiceStatus.validated,
            ),
            SizedBox(width: dense ? 5 : 7),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: dense ? 10.5 : 12,
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

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  // PERF: only spin a 60 fps ticker when this pill actually pulses. Non-animated
  // statuses (and every row of a long invoices list) render a static dot with
  // no AnimationController and no per-frame rebuilds.
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startController();
  }

  void _startController() {
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void didUpdateWidget(_LivePulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && _ctrl == null) {
      setState(_startController);
    } else if (!widget.animate && _ctrl != null) {
      _ctrl!.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Widget _staticDot() => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) return _staticDot();

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final pulse = 0.4 + 0.6 * (1 - (ctrl.value * 2 - 1).abs());
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.45 * pulse,
              child: Container(
                width: 14 * pulse,
                height: 14 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.5),
                ),
              ),
            ),
            _staticDot(),
          ],
        );
      },
    );
  }
}
