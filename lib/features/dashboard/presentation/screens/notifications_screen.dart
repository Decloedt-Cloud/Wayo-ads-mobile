import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/layout/wayo_system_insets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/dashboard_state_providers.dart';
import '../providers/notifications_feed_providers.dart';
import '../widgets/notification_list_tile.dart';
import '../widgets/notification_open_helper.dart';
import '../widgets/notification_time_groups.dart';

/// Full notification center — tabs, filters, infinite scroll (Wayo-ads web).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      ref.read(notificationsSearchQueryProvider.notifier).state = v.trim();
      ref.invalidate(notificationsFeedProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? const Color(0xFF2A2A2A)
        : AppColors.borderOf(context).withValues(alpha: 0.55);
    final tab = ref.watch(notificationsListTabProvider);
    final feed = ref.watch(notificationsFeedProvider);
    final counts = ref.watch(notificationsUnreadCountsProvider);

    final unreadTotal = counts.valueOrNull?.total ?? 0;
    final importantUnread = counts.valueOrNull?.important ?? 0;

    final bottomScrollPad = wayoScrollBottomReserve(context, gap: 24);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
      ),
      bottomNavigationBar: const WayoBlackBottomBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(notificationsFeedProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dashboard.notifications_center_title,
                      style: AppTextStyles.pageTitle(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unreadTotal > 0
                          ? t.dashboard.notifications_unread_count.replaceAll(
                              '{count}',
                              '$unreadTotal',
                            )
                          : t.dashboard.notifications_all_caught_up,
                      style: TextStyle(
                        color: AppColors.textMutedOf(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NotificationTabs(
                      unreadTotal: unreadTotal,
                      importantUnread: importantUnread,
                    ),
                    const SizedBox(height: 12),
                    _FilterRow(
                      searchCtrl: _searchCtrl,
                      onSearchChanged: _applySearch,
                      onFiltersChanged: () =>
                          ref.invalidate(notificationsFeedProvider),
                    ),
                  ],
                ),
              ),
            ),
            feed.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('$e')),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: AppColors.textMutedOf(context),
                          ),
                          const SizedBox(height: 12),
                          Text(t.dashboard.notifications_caught_up_subtitle),
                        ],
                      ),
                    ),
                  );
                }
                final groups = groupNotificationsByTime(state.items);
                final children = <Widget>[
                  if (tab == NotificationsListTab.all)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        t.dashboard.notifications_section_all,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    )
                  else if (tab == NotificationsListTab.important)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        t.dashboard.notifications_section_important,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        t.dashboard.notifications_section_archived,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  for (final section in groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        _timeGroupLabel(t, section.group).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.textMutedOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF181818)
                            : AppColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            for (var i = 0; i < section.items.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: border.withValues(alpha: 0.7),
                                ),
                              _FeedRow(item: section.items[i]),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.hasMore)
                    Center(
                      child: state.isLoadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              onPressed: () => ref
                                  .read(notificationsFeedProvider.notifier)
                                  .loadMore(),
                              child: Text(t.dashboard.notifications_load_more),
                            ),
                    ),
                ];
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomScrollPad),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(children),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _timeGroupLabel(dynamic t, NotificationTimeGroup g) {
    return switch (g) {
      NotificationTimeGroup.today => t.chat.date_today,
      NotificationTimeGroup.yesterday => t.chat.date_yesterday,
      NotificationTimeGroup.earlier => t.dashboard.notifications_earlier,
    };
  }
}

class _NotificationTabs extends ConsumerWidget {
  const _NotificationTabs({
    required this.unreadTotal,
    required this.importantUnread,
  });

  final int unreadTotal;
  final int importantUnread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tab = ref.watch(notificationsListTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabChip(
            label: t.dashboard.notifications_tab_all,
            badge: unreadTotal > 0 ? unreadTotal : null,
            selected: tab == NotificationsListTab.all,
            isDark: isDark,
            onTap: () => _selectTab(ref, NotificationsListTab.all),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: t.dashboard.notifications_important,
            badge: importantUnread > 0 ? importantUnread : null,
            selected: tab == NotificationsListTab.important,
            isDark: isDark,
            onTap: () => _selectTab(ref, NotificationsListTab.important),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: t.dashboard.notifications_tab_archived,
            selected: tab == NotificationsListTab.archived,
            isDark: isDark,
            onTap: () => _selectTab(ref, NotificationsListTab.archived),
          ),
        ],
      ),
    );
  }

  void _selectTab(WidgetRef ref, NotificationsListTab next) {
    HapticFeedback.selectionClick();
    ref.read(notificationsListTabProvider.notifier).state = next;
    ref.invalidate(notificationsFeedProvider);
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.badge,
  });

  final String label;
  final int? badge;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (isDark ? const Color(0xFF2A2A2A) : AppColors.surfaceElevatedOf(context))
          : (isDark ? const Color(0xFF141414) : const Color(0xFFF2F2F4)),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge != null ? '$label ($badge)' : label,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onFiltersChanged,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFiltersChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final type = ref.watch(notificationsTypeFilterProvider);
    final priority = ref.watch(notificationsPriorityFilterProvider);
    final counts = ref.watch(notificationsUnreadCountsProvider);
    final unread = counts.valueOrNull?.total ?? 0;

    return Column(
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: t.dashboard.notifications_search_hint,
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: AppColors.textMutedOf(context),
            ),
            filled: true,
            fillColor: AppColors.surfaceElevatedOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: type == null
                    ? t.dashboard.notifications_filter_type_all
                    : _formatType(type),
                onTap: () => _pickType(context, ref),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdown(
                label: priority == null
                    ? t.dashboard.notifications_filter_priority_all
                    : _formatPriority(t, priority),
                onTap: () => _pickPriority(context, ref),
              ),
            ),
          ],
        ),
        if (unread > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markAllRead();
                onFiltersChanged();
                invalidateAllNotifications(ref);
              },
              child: Text(
                t.dashboard.notifications_mark_all_read,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _formatType(String type) =>
      type.replaceAll('_', ' ').toLowerCase();

  static String _formatPriority(dynamic t, String p) => switch (p) {
    'P0_CRITICAL' => t.dashboard.notifications_priority_critical,
    'P1_HIGH' => t.dashboard.notifications_priority_high,
    'P2_NORMAL' => t.dashboard.notifications_priority_normal,
    'P3_LOW' => t.dashboard.notifications_priority_low,
    _ => p,
  };

  Future<void> _pickType(BuildContext context, WidgetRef ref) async {
    final t = context.t;
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    final types = _typesForRole(role);
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t.dashboard.notifications_filter_type_all),
              onTap: () => Navigator.pop(ctx, null),
            ),
            for (final ty in types)
              ListTile(
                title: Text(_formatType(ty)),
                onTap: () => Navigator.pop(ctx, ty),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    ref.read(notificationsTypeFilterProvider.notifier).state = picked;
    onFiltersChanged();
  }

  Future<void> _pickPriority(BuildContext context, WidgetRef ref) async {
    final t = context.t;
    final options = <String?, String>{
      null: t.dashboard.notifications_filter_priority_all,
      'P0_CRITICAL': t.dashboard.notifications_priority_critical,
      'P1_HIGH': t.dashboard.notifications_priority_high,
      'P2_NORMAL': t.dashboard.notifications_priority_normal,
      'P3_LOW': t.dashboard.notifications_priority_low,
    };
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in options.entries)
              ListTile(
                title: Text(e.value),
                onTap: () => Navigator.pop(ctx, e.key),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    ref.read(notificationsPriorityFilterProvider.notifier).state = picked;
    onFiltersChanged();
  }

  static List<String> _typesForRole(WayoAdsAccountRole role) {
    const advertiser = [
      'CREATOR_APPLIED',
      'VIDEO_SUBMITTED',
      'BUDGET_LOW',
      'WALLET_CREDITED',
      'SYSTEM_ANNOUNCEMENT',
    ];
    const creator = [
      'CREATOR_APPLICATION_APPROVED',
      'VIDEO_APPROVED',
      'EARNINGS_AVAILABLE',
      'WITHDRAWAL_REQUESTED',
      'SYSTEM_ANNOUNCEMENT',
    ];
    return switch (role) {
      WayoAdsAccountRole.creator => creator,
      WayoAdsAccountRole.superAdmin => [...advertiser, ...creator],
      _ => advertiser,
    };
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.textMutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends ConsumerWidget {
  const _FeedRow({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(notificationsListTabProvider);
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    final showArchive = tab != NotificationsListTab.archived;

    return NotificationListTile(
      item: item,
      mode: NotificationTileMode.feed,
      role: role,
      showArchiveAction: showArchive,
      onTap: () async {
        HapticFeedback.lightImpact();
        await openNotificationItem(ref, item);
      },
      onMarkRead: () async {
        if (!item.isUnread) return;
        await ref.read(notificationsRepositoryProvider).markRead(item.id);
        invalidateAllNotifications(ref);
      },
      onDismiss: () async {
        await ref.read(notificationsRepositoryProvider).dismiss(item.id);
        invalidateAllNotifications(ref);
      },
      onArchive: showArchive
          ? () async {
              await ref.read(notificationsRepositoryProvider).archive(item.id);
              invalidateAllNotifications(ref);
            }
          : null,
    );
  }
}
