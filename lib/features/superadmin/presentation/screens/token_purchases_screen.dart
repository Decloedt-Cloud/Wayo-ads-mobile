import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Creator AI token purchases — `GET /api/admin/token-purchases`.
class TokenPurchasesScreen extends ConsumerStatefulWidget {
  const TokenPurchasesScreen({super.key});

  @override
  ConsumerState<TokenPurchasesScreen> createState() =>
      _TokenPurchasesScreenState();
}

class _TokenPurchasesScreenState extends ConsumerState<TokenPurchasesScreen> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tokenPurchasesProvider(_query));
    final money = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Token purchases'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [SuperadminChromeActions(trailingPadding: 12)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search creator name or email…',
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
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Retry(
                message: '$e',
                onRetry: () => ref.invalidate(tokenPurchasesProvider(_query)),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(tokenPurchasesProvider(_query));
                  await ref.read(tokenPurchasesProvider(_query).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: [
                        AdminStatCard(
                          title: 'Tokens sold',
                          value: '${page.totalTokens}',
                          icon: Icons.token_rounded,
                        ),
                        AdminStatCard(
                          title: 'Revenue',
                          value: money.format(page.totalRevenueCents / 100),
                          icon: Icons.euro_rounded,
                        ),
                      ],
                    ),
                    if (page.packageStats.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Packages',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      for (final s in page.packageStats.take(6))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PackageRow(stat: s, money: money),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Recent (${page.total})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (page.purchases.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No purchases found')),
                      )
                    else
                      for (final p in page.purchases) ...[
                        _PurchaseCard(record: p, money: money),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({required this.stat, required this.money});
  final TokenPackageStat stat;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        title: Text(
          stat.packageName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${stat.tokenCount} tokens · ${stat.sales} sales'),
        trailing: Text(
          money.format(stat.revenueCents / 100),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.record, required this.money});
  final TokenPurchaseRecord record;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final title = record.creatorName?.trim().isNotEmpty == true
        ? record.creatorName!
        : (record.creatorEmail ?? 'Unknown creator');
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
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  money.format(record.amountCents / 100),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${record.packageName} · ${record.tokenCount} tokens',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            Text(
              DateFormat.yMMMd().add_Hm().format(record.createdAt.toLocal()),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
        ),
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
