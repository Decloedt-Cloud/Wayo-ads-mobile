import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/invoice.dart';
import 'invoice_status_pill.dart';
import 'invoice_type_chip.dart';

/// Premium invoice tile — typed icon, accent stripe, monumental amount,
/// status pill and animated tap. Designed to feel like a financial product
/// (Apple Card, Revolut, Stripe Dashboard) — not a generic list item.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.locale,
    required this.onTap,
    required this.onDownloadPdf,
  });

  final Invoice invoice;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDownloadPdf;

  String _fmtDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final diff = now.difference(local).inDays;
    if (diff == 0) return DateFormat.Hm(locale).format(local);
    if (diff == 1) {
      // “Yesterday” via Intl relative date — fallback to plain DateFormat if
      // the locale isn't loaded for relative formatting.
      return DateFormat.MMMd(locale).format(local);
    }
    if (diff < 7) {
      return DateFormat.E(locale).add_d().format(local);
    }
    return DateFormat.yMMMd(locale).format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    final typeVisual = invoiceTypeVisual(context, invoice.type);
    final isDark = theme.brightness == Brightness.dark;
    final surface = AppColors.surfaceElevatedOf(context);
    final border = AppColors.borderOf(context);
    final amountText = MoneyFormatter.format(
      invoice.totalMajor,
      currency: invoice.currency,
      locale: locale,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: typeVisual.accent.withValues(alpha: 0.12),
        highlightColor: typeVisual.accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: typeVisual.accent.withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Accent stripe on the leading edge.
              Positioned.fill(
                left: 0,
                right: null,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        typeVisual.accent.withValues(alpha: 0.92),
                        typeVisual.accent.withValues(alpha: 0.32),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: typeVisual.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: typeVisual.accent.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Icon(
                            typeVisual.icon,
                            color: typeVisual.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                invoice.invoiceNumber,
                                style: TextStyle(
                                  color: AppColors.textPrimaryOf(context),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _fmtDate(context, invoice.createdAt),
                                style: TextStyle(
                                  color: AppColors.textMutedOf(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InvoiceStatusPill(status: invoice.status, dense: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InvoiceTypeChip(type: invoice.type),
                              const SizedBox(height: 8),
                              Text(
                                amountText,
                                style: TextStyle(
                                  color: AppColors.textPrimaryOf(context),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PdfIconButton(
                          accent: typeVisual.accent,
                          tooltip: t.invoices.action_download_pdf,
                          onTap: onDownloadPdf,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfIconButton extends StatelessWidget {
  const _PdfIconButton({
    required this.accent,
    required this.tooltip,
    required this.onTap,
  });

  final Color accent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: 0.32)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.picture_as_pdf_rounded, color: accent, size: 20),
          ),
        ),
      ),
    );
  }
}
