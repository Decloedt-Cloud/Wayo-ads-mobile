import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_scaffold.dart';

/// Payment audits — Transactions + By advertiser (web `/admin/payment-audits`).
class PaymentAuditsScreen extends ConsumerStatefulWidget {
  const PaymentAuditsScreen({super.key});

  @override
  ConsumerState<PaymentAuditsScreen> createState() =>
      _PaymentAuditsScreenState();
}

class _PaymentAuditsScreenState extends ConsumerState<PaymentAuditsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  var _query = '';
  var _txPage = 1;
  var _advPage = 1;
  String? _advertiserIdFilter;
  String? _reconcilingId;

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

  PaymentAuditsQuery get _txQuery => (
        search: _query,
        page: _txPage,
        advertiserId: _advertiserIdFilter,
      );

  AdvertiserDepositsQuery get _advQuery => (search: _query, page: _advPage);

  Future<void> _reconcile(PaymentAuditRecord row) async {
    if (_reconcilingId != null) return;
    setState(() => _reconcilingId = row.id);
    try {
      final result =
          await ref.read(superadminOpsRemoteProvider).reconcilePaymentAudit(row.id);
      if (!mounted) return;
      WayoToast.success(
        context,
        'Reconciled · ${result.reconciliationStatus}',
      );
      ref.invalidate(paymentAuditsProvider(_txQuery));
    } catch (e) {
      if (mounted) WayoToast.error(context, '$e');
    } finally {
      if (mounted) setState(() => _reconcilingId = null);
    }
  }

  Future<void> _openStripe(String pi) async {
    final id = pi.trim();
    if (id.isEmpty) return;
    final uri = Uri.parse('https://dashboard.stripe.com/payments/$id');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return SuperadminScaffold(
      title: 'Payment audits',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'By advertiser'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search PI, email, name…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty && _advertiserIdFilter == null
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {
                            _query = '';
                            _txPage = 1;
                            _advPage = 1;
                            _advertiserIdFilter = null;
                          });
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (v) => setState(() {
                _query = v.trim();
                _txPage = 1;
                _advPage = 1;
              }),
            ),
          ),
          if (_advertiserIdFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InputChip(
                label: Text('Advertiser ${_advertiserIdFilter!.substring(0, 8)}…'),
                onDeleted: () => setState(() {
                  _advertiserIdFilter = null;
                  _txPage = 1;
                }),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TransactionsTab(
                  query: _txQuery,
                  money: money,
                  reconcilingId: _reconcilingId,
                  onReconcile: _reconcile,
                  onOpenStripe: _openStripe,
                  onPrev: _txPage > 1
                      ? () => setState(() => _txPage -= 1)
                      : null,
                  onNext: () => setState(() => _txPage += 1),
                ),
                _ByAdvertiserTab(
                  query: _advQuery,
                  money: money,
                  onOpenTransactions: (advertiserId) {
                    setState(() {
                      _advertiserIdFilter = advertiserId;
                      _txPage = 1;
                    });
                    _tabs.animateTo(0);
                  },
                  onPrev: _advPage > 1
                      ? () => setState(() => _advPage -= 1)
                      : null,
                  onNext: () => setState(() => _advPage += 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab({
    required this.query,
    required this.money,
    required this.reconcilingId,
    required this.onReconcile,
    required this.onOpenStripe,
    required this.onPrev,
    required this.onNext,
  });

  final PaymentAuditsQuery query;
  final NumberFormat money;
  final String? reconcilingId;
  final ValueChanged<PaymentAuditRecord> onReconcile;
  final ValueChanged<String> onOpenStripe;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentAuditsProvider(query));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: '$e',
        onRetry: () => ref.invalidate(paymentAuditsProvider(query)),
      ),
      data: (page) {
        if (page.records.isEmpty) {
          return const Center(child: Text('No payment audits found'));
        }
        final totalPages = page.limit <= 0
            ? 1
            : ((page.total + page.limit - 1) / page.limit).ceil().clamp(1, 9999);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(paymentAuditsProvider(query));
            await ref.read(paymentAuditsProvider(query).future);
          },
          child: ListView.separated(
            padding: superadminPagePadding(context),
            itemCount: page.records.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == page.records.length) {
                return _Pager(
                  label: '${page.total} total · page ${page.page}/$totalPages',
                  onPrev: onPrev,
                  onNext: page.page < totalPages ? onNext : null,
                );
              }
              return _AuditCard(
                record: page.records[i],
                money: money,
                busy: reconcilingId == page.records[i].id,
                onReconcile: () => onReconcile(page.records[i]),
                onOpenStripe: () =>
                    onOpenStripe(page.records[i].stripePaymentIntentId),
              );
            },
          ),
        );
      },
    );
  }
}

class _ByAdvertiserTab extends ConsumerWidget {
  const _ByAdvertiserTab({
    required this.query,
    required this.money,
    required this.onOpenTransactions,
    required this.onPrev,
    required this.onNext,
  });

  final AdvertiserDepositsQuery query;
  final NumberFormat money;
  final ValueChanged<String> onOpenTransactions;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(advertiserDepositsProvider(query));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: '$e',
        onRetry: () => ref.invalidate(advertiserDepositsProvider(query)),
      ),
      data: (page) {
        if (page.rows.isEmpty) {
          return const Center(child: Text('No advertiser deposits found'));
        }
        final totalPages = page.limit <= 0
            ? 1
            : ((page.total + page.limit - 1) / page.limit).ceil().clamp(1, 9999);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(advertiserDepositsProvider(query));
            await ref.read(advertiserDepositsProvider(query).future);
          },
          child: ListView.separated(
            padding: superadminPagePadding(context),
            itemCount: page.rows.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == page.rows.length) {
                return _Pager(
                  label: '${page.total} advertisers · page ${page.page}/$totalPages',
                  onPrev: onPrev,
                  onNext: page.page < totalPages ? onNext : null,
                );
              }
              final row = page.rows[i];
              final who = (row.advertiserName?.trim().isNotEmpty == true)
                  ? row.advertiserName!
                  : row.advertiserEmail;
              return Material(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onOpenTransactions(row.advertiserId),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(who, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          row.advertiserEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${row.depositCount} deposits · '
                          '${money.format(row.totalChargedCents / 100)} charged',
                        ),
                        Text(
                          'Fees ${money.format(row.totalStripeFeeCents / 100)} · '
                          'Net ${money.format(row.totalNetCents / 100)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        if (row.walletAvailableCents != null)
                          Text(
                            'Wallet avail. ${money.format(row.walletAvailableCents! / 100)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                onOpenTransactions(row.advertiserId),
                            child: const Text('View transactions'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({
    required this.record,
    required this.money,
    required this.busy,
    required this.onReconcile,
    required this.onOpenStripe,
  });

  final PaymentAuditRecord record;
  final NumberFormat money;
  final bool busy;
  final VoidCallback onReconcile;
  final VoidCallback onOpenStripe;

  @override
  Widget build(BuildContext context) {
    final who = (record.advertiserName?.trim().isNotEmpty == true)
        ? record.advertiserName!
        : (record.advertiserEmail ?? record.advertiserId);
    final fees = record.actualProcessingFeeCents +
        record.internationalFeeCents +
        record.additionalStripeFeeCents;
    final fi = record.fundingInstructions;

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
                    who,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    record.reconciliationStatus,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(money.format(record.amountCents / 100)),
            Text(
              '${record.depositMethod ?? 'card'} · '
              '${DateFormat.yMMMd().add_Hm().format(record.createdAt.toLocal())}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            if (fees > 0)
              Text(
                'Fees ${money.format(fees / 100)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            if (record.wireReference != null &&
                record.wireReference!.isNotEmpty)
              Text(
                'Wire ref ${record.wireReference}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            if (fi != null) ...[
              const SizedBox(height: 8),
              Text(
                'Wire instructions · ${fi.currency} · '
                '${fi.addresses.length} address(es)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              if (fi.reference != null)
                Text(
                  'Ref ${fi.reference}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onOpenStripe,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Stripe'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onReconcile();
                        },
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reconcile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMutedOf(context),
            fontSize: 12,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: onPrev, child: const Text('Previous')),
            TextButton(onPressed: onNext, child: const Text('Next')),
          ],
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
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
