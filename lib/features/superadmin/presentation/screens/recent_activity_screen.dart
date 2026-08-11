import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_scaffold.dart';

/// Platform feed — `GET /api/admin/recent-activity`.
class RecentActivityScreen extends ConsumerStatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  ConsumerState<RecentActivityScreen> createState() =>
      _RecentActivityScreenState();
}

class _RecentActivityScreenState extends ConsumerState<RecentActivityScreen> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recentActivityProvider(_query));
    final money = NumberFormat.currency(symbol: '€', decimalDigits: 0);

    return SuperadminScaffold(
      title: 'Recent activity',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search title, name, email…',
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
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$e', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(recentActivityProvider(_query)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (page) {
                if (page.activities.isEmpty) {
                  return const Center(child: Text('No recent activity'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(recentActivityProvider(_query));
                    await ref.read(recentActivityProvider(_query).future);
                  },
                  child: ListView.separated(
                    padding: superadminPagePadding(context),
                    itemCount: page.activities.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == page.activities.length) {
                        return Text(
                          '${page.total} total',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                            fontSize: 12,
                          ),
                        );
                      }
                      return _ActivityCard(
                        item: page.activities[i],
                        money: money,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.money});
  final RecentActivityItem item;
  final NumberFormat money;

  IconData get _icon => switch (item.type) {
        'campaign_launched' || 'campaign_created' => Icons.campaign_rounded,
        'withdrawal_requested' => Icons.payments_rounded,
        'new_advertiser' => Icons.storefront_rounded,
        'new_creator' => Icons.person_add_alt_1_rounded,
        _ => Icons.event_note_rounded,
      };

  String get _label => item.type.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final who = item.userName?.trim().isNotEmpty == true
        ? item.userName!
        : (item.userEmail ?? '—');
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Icon(_icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          item.title?.trim().isNotEmpty == true ? item.title! : _label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            _label,
            who,
            if (item.amountCents != null)
              money.format(item.amountCents! / 100),
            DateFormat.MMMd().add_Hm().format(item.createdAt.toLocal()),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
