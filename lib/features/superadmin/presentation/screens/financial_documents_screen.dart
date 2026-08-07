
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Admin invoices + payout statements — mirrors web financial-documents.
class FinancialDocumentsScreen extends ConsumerStatefulWidget {
  const FinancialDocumentsScreen({super.key});

  @override
  ConsumerState<FinancialDocumentsScreen> createState() =>
      _FinancialDocumentsScreenState();
}

class _FinancialDocumentsScreenState
    extends ConsumerState<FinancialDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  var _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Financial documents'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [SuperadminChromeActions(trailingPadding: 12)],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search number, name, email…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _InvoicesTab(query: _query),
                _PayoutsTab(query: _query),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesTab extends ConsumerStatefulWidget {
  const _InvoicesTab({required this.query});
  final String query;

  @override
  ConsumerState<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<_InvoicesTab> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminInvoicesProvider(widget.query));
    final money = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Retry(
        message: '$e',
        onRetry: () => ref.invalidate(adminInvoicesProvider(widget.query)),
      ),
      data: (page) {
        if (page.invoices.isEmpty) {
          return const Center(child: Text('No invoices found'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminInvoicesProvider(widget.query));
            await ref.read(adminInvoicesProvider(widget.query).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: page.invoices.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == page.invoices.length) {
                return Text(
                  '${page.total} total · page ${page.page}/${page.totalPages}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontSize: 12,
                  ),
                );
              }
              return _InvoiceCard(record: page.invoices[i], money: money);
            },
          ),
        );
      },
    );
  }
}

class _PayoutsTab extends ConsumerStatefulWidget {
  const _PayoutsTab({required this.query});
  final String query;

  @override
  ConsumerState<_PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends ConsumerState<_PayoutsTab> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminPaymentStatementsProvider(widget.query));
    final money = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Retry(
        message: '$e',
        onRetry: () => ref.invalidate(adminPaymentStatementsProvider(widget.query)),
      ),
      data: (page) {
        if (page.statements.isEmpty) {
          return const Center(child: Text('No payout statements found'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminPaymentStatementsProvider(widget.query));
            await ref.read(adminPaymentStatementsProvider(widget.query).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: page.statements.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == page.statements.length) {
                return Text(
                  '${page.total} total · page ${page.page}/${page.totalPages}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontSize: 12,
                  ),
                );
              }
              return _StatementCard(
                statement: page.statements[i],
                money: money,
              );
            },
          ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.record, required this.money});
  final AdminInvoiceRecord record;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final who = record.userName?.trim().isNotEmpty == true
        ? record.userName!
        : (record.userEmail ?? '—');
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.invoiceNumber.isEmpty
                        ? record.id
                        : record.invoiceNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(status: record.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              money.format(record.totalAmountCents / 100),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '$who · ${record.roleType} · ${record.invoiceType}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMd()
                        .add_Hm()
                        .format(record.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
                if (record.pdfUrl != null && record.pdfUrl!.isNotEmpty)
                  IconButton(
                    tooltip: 'Open PDF',
                    onPressed: () => _openPdf(context, record.pdfUrl!),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.statement, required this.money});
  final AdminPaymentStatement statement;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    statement.statementNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(status: statement.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              money.format(statement.netPayoutCents / 100),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '${statement.creatorName.isEmpty ? statement.creatorEmail : statement.creatorName}'
              ' · ${statement.paymentMethod}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            Text(
              'Gross ${money.format(statement.grossEarningsCents / 100)}'
              ' · fee ${money.format(statement.platformFeeCents / 100)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMd()
                        .add_Hm()
                        .format(statement.statementDate.toLocal()),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
                if (statement.pdfUrl != null && statement.pdfUrl!.isNotEmpty)
                  IconButton(
                    tooltip: 'Open PDF',
                    onPressed: () => _openPdf(context, statement.pdfUrl!),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Future<void> _openPdf(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open PDF')),
    );
  }
}
