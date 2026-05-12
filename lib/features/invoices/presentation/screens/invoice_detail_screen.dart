import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/invoice_pdf_service.dart';
import '../../domain/invoice.dart';
import '../providers/invoices_providers.dart';
import '../widgets/invoice_status_pill.dart';
import '../widgets/invoice_type_chip.dart';

/// Detail screen — resolves the invoice from the in-memory list provider so
/// no extra round trip is needed. Falls back to "not found" if the list hasn't
/// been loaded (e.g. deep link cold start).
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  double _downloadProgress = 0;
  bool _downloading = false;

  Future<void> _downloadAndShare(Invoice invoice) async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final pdfService = ref.read(invoicePdfServiceProvider);
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final file = await pdfService.downloadAndSave(
        invoice,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      setState(() {
        _downloading = false;
        _downloadProgress = 1;
      });
      await pdfService.share(
        file,
        subject: t.invoices.share_subject.replaceAll(
          '{number}',
          invoice.invoiceNumber,
        ),
      );
    } on AuthException catch (_) {
      setState(() => _downloading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.invoices.download_error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _downloadAndOpen(Invoice invoice) async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final pdfService = ref.read(invoicePdfServiceProvider);
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final file = await pdfService.downloadAndSave(
        invoice,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      setState(() {
        _downloading = false;
        _downloadProgress = 1;
      });
      await pdfService.open(file);
    } on AuthException catch (_) {
      setState(() => _downloading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.invoices.download_error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _copyNumber(Invoice invoice) async {
    await Clipboard.setData(ClipboardData(text: invoice.invoiceNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.invoices.copied_to_clipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = ref.watch(invoicesControllerProvider).valueOrNull;
    final invoice = state?.invoices.firstWhere(
      (i) => i.id == widget.invoiceId,
      orElse: () => Invoice(
        id: widget.invoiceId,
        invoiceNumber: widget.invoiceId,
        type: InvoiceType.unknown,
        roleType: InvoiceRoleType.unknown,
        status: InvoiceStatus.unknown,
        totalAmountCents: 0,
        taxAmountCents: 0,
        currency: 'EUR',
        referenceId: null,
        createdAt: DateTime.now(),
        paidAt: null,
      ),
    );

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final visual = invoiceTypeVisual(context, invoice.type);
    final locale = LocaleSettings.currentLocale.languageCode;
    final amount = MoneyFormatter.format(
      invoice.totalMajor,
      currency: invoice.currency,
      locale: locale,
    );

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            title: Text(
              t.invoices.details_title.replaceAll(
                '{number}',
                invoice.invoiceNumber,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBackdrop(invoice: invoice, visual: visual),
              collapseMode: CollapseMode.parallax,
            ),
            actions: [
              IconButton(
                tooltip: t.invoices.action_copy_number,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyNumber(invoice),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AmountBlock(amount: amount, invoice: invoice),
                  const SizedBox(height: 24),
                  _SectionTitle(label: t.invoices.details_section_summary),
                  const SizedBox(height: 8),
                  _MetaCard(
                    rows: [
                      _MetaRow(
                        label: t.invoices.details_invoice_number,
                        value: invoice.invoiceNumber,
                      ),
                      _MetaRow(
                        label: t.invoices.details_issued_at,
                        value: DateFormat.yMMMMd(locale).add_Hm().format(
                          invoice.createdAt.toLocal(),
                        ),
                      ),
                      if (invoice.paidAt != null)
                        _MetaRow(
                          label: t.invoices.details_paid_at,
                          value: DateFormat.yMMMMd(locale).add_Hm().format(
                            invoice.paidAt!.toLocal(),
                          ),
                        ),
                      _MetaRow(
                        label: t.invoices.details_type,
                        valueWidget: InvoiceTypeChip(type: invoice.type),
                      ),
                      _MetaRow(
                        label: t.invoices.details_status,
                        valueWidget: InvoiceStatusPill(status: invoice.status),
                      ),
                      _MetaRow(
                        label: t.invoices.details_role,
                        value: invoice.roleType == InvoiceRoleType.creator
                            ? t.invoices.role_creator
                            : t.invoices.role_advertiser,
                      ),
                      _MetaRow(
                        label: t.invoices.details_currency,
                        value: invoice.currency,
                      ),
                      if (invoice.referenceId != null)
                        _MetaRow(
                          label: t.invoices.details_reference,
                          value: invoice.referenceId!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(label: t.invoices.details_section_actions),
                  const SizedBox(height: 8),
                  _ActionsBlock(
                    progress: _downloadProgress,
                    downloading: _downloading,
                    onShare: () => _downloadAndShare(invoice),
                    onOpen: () => _downloadAndOpen(invoice),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.invoice, required this.visual});
  final Invoice invoice;
  final InvoiceTypeVisual visual;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            visual.accent.withValues(alpha: 0.95),
            visual.accent.withValues(alpha: 0.35),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.amount, required this.invoice});
  final String amount;
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        if (invoice.taxAmountCents > 0)
          Text(
            '${context.t.invoices.details_tax} · '
            '${MoneyFormatter.format(invoice.taxMajor, currency: invoice.currency)}',
            style: AppTextStyles.caption(context),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textPrimaryOf(context),
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.rows});
  final List<_MetaRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: AppColors.borderOf(context)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: rows[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, this.value, this.valueWidget})
      : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textMutedOf(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: valueWidget ??
                Text(
                  value!,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
          ),
        ),
      ],
    );
  }
}

class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock({
    required this.progress,
    required this.downloading,
    required this.onShare,
    required this.onOpen,
  });

  final double progress;
  final bool downloading;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: downloading
              ? Padding(
                  key: const ValueKey('progress'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.invoices.download_progress,
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: downloading ? null : onOpen,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(t.invoices.action_download_pdf),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: downloading ? null : onShare,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(t.invoices.action_share_pdf),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
