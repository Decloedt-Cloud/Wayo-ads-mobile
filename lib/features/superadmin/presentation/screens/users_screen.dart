import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/banned_user.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/superadmin_chrome_actions.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String? _searchQuery;
  RoleFilter _roleFilter = RoleFilter.all;
  JoinedFilter _joinedFilter = JoinedFilter.all;
  bool _showBannedOnly = false;
  bool _isPagingUsers = false;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshCurrentTab());
  }

  void _refreshCurrentTab() {
    if (!mounted) return;
    if (_showBannedOnly) {
      ref.invalidate(bannedUsersNotifierProvider(search: _searchQuery));
    } else {
      ref.invalidate(
        adminUsersNotifierProvider(
          search: _searchQuery, role: _roleFilter,
          joined: _joinedFilter, bannedOnly: false,
        ),
      );
    }
  }

  void _invalidateUsersList() {
    ref.invalidate(
      adminUsersNotifierProvider(
        search: _searchQuery, role: _roleFilter,
        joined: _joinedFilter, bannedOnly: false,
      ),
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _showBannedOnly = _tabController.index == 1);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    if (_showBannedOnly) {
      ref.read(bannedUsersNotifierProvider(search: _searchQuery).notifier).loadMore();
    }
  }

  AdminUsersNotifierProvider get _adminUsersProvider =>
      adminUsersNotifierProvider(
        search: _searchQuery,
        role: _roleFilter,
        joined: _joinedFilter,
        bannedOnly: false,
      );

  Future<void> _goToUsersPage(int page) async {
    if (_isPagingUsers) return;
    setState(() => _isPagingUsers = true);
    try {
      await ref.read(_adminUsersProvider.notifier).goToPage(page);
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (mounted) setState(() => _isPagingUsers = false);
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value.isEmpty ? null : value);
  }

  void _onRoleFilterChanged(RoleFilter filter) {
    setState(() => _roleFilter = filter);
  }

  void _onJoinedFilterChanged(JoinedFilter filter) {
    setState(() => _joinedFilter = filter);
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usersAsync = _showBannedOnly
        ? null
        : ref.watch(adminUsersNotifierProvider(
            search: _searchQuery, role: _roleFilter,
            joined: _joinedFilter, bannedOnly: false,
          ));
    final bannedAsync = _showBannedOnly
        ? ref.watch(bannedUsersNotifierProvider(search: _searchQuery))
        : null;

    if (!_showBannedOnly) {
      ref.listen(adminUsersNotifierProvider(
        search: _searchQuery, role: _roleFilter,
        joined: _joinedFilter, bannedOnly: false,
      ), (previous, next) {
        if (next.hasValue && mounted) setState(() {});
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!_showBannedOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (!_showBannedOnly && usersAsync != null)
            usersAsync.when(
              data: (page) => _buildStatsSection(page.stats, isDark),
              loading: () => const SliverToBoxAdapter(child: _StatsSkeleton()),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            )
          else if (_showBannedOnly && bannedAsync != null)
            bannedAsync.when(
              data: (page) => _buildBannedStatsSection(page, isDark),
              loading: () => _buildBannedStatsSection(
                const BannedUsersPage(bans: [], total: 0, limit: 50, offset: 0), isDark,
              ),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildSegmentedToggle(isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildSearchBar(isDark),
            ),
          ),
          if (!_showBannedOnly)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildFilterChips(isDark),
              ),
            ),
          _showBannedOnly
              ? (bannedAsync?.when(
                  data: (page) => page.bans.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : _buildBannedUsersSliverList(page),
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: _buildErrorState(() => ref.invalidate(
                      bannedUsersNotifierProvider(search: _searchQuery))),
                  ),
                ) ?? const SliverToBoxAdapter(child: SizedBox.shrink()))
              : (usersAsync?.when(
                  data: (page) => page.users.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : _buildUsersSliverList(page),
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: _buildErrorState(_invalidateUsersList),
                  ),
                ) ?? const SliverToBoxAdapter(child: SizedBox.shrink())),
        ],
      ),
    );
  }

  // ── Segmented Toggle ──
  Widget _buildSegmentedToggle(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.6) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => _tabController.animateTo(0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: _tabController.index == 0
                  ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)])
                  : null,
              color: _tabController.index == 0 ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _tabController.index == 0
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_rounded, size: 16,
                color: _tabController.index == 0 ? Colors.white : AppColors.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Text('All Users', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _tabController.index == 0 ? Colors.white : AppColors.textSecondaryOf(context))),
            ])),
          ),
        )),
        Expanded(child: GestureDetector(
          onTap: () => _tabController.animateTo(1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: _tabController.index == 1
                  ? LinearGradient(colors: [AppColors.error, AppColors.error.withValues(alpha: 0.85)])
                  : null,
              color: _tabController.index == 1 ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _tabController.index == 1
                  ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.block_rounded, size: 16,
                color: _tabController.index == 1 ? Colors.white : AppColors.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Text('Banned', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _tabController.index == 1 ? Colors.white : AppColors.textSecondaryOf(context))),
            ])),
          ),
        )),
      ]),
    );
  }

  // ── Search Bar ──
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.03), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: TextField(
        controller: _searchController, onChanged: _onSearch,
        style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15),
        decoration: InputDecoration(
          hintText: _showBannedOnly ? 'Search banned users...' : 'Search by name or email...',
          hintStyle: TextStyle(color: AppColors.textMutedOf(context).withValues(alpha: 0.7), fontSize: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(13),
            child: Icon(Icons.search_rounded, color: AppColors.textMutedOf(context), size: 20),
          ),
          suffixIcon: _searchQuery != null
              ? IconButton(
                  onPressed: () { _searchController.clear(); _onSearch(''); },
                  icon: Icon(Icons.close_rounded, color: AppColors.textMutedOf(context)),
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.6) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderOf(context).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.borderOf(context).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  // ── Filter Chips ──
  Widget _buildFilterChips(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        const _FilterLabel(text: 'Joined:'),
        const SizedBox(width: 8),
        ...JoinedFilter.values.map((filter) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _FilterChip(
            label: filter.displayName, isSelected: _joinedFilter == filter,
            onTap: () => _onJoinedFilterChanged(filter),
          ),
        )),
        const SizedBox(width: 10),
        Container(width: 1, height: 20,
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
        const SizedBox(width: 10),
        const _FilterLabel(text: 'Roles:'),
        const SizedBox(width: 8),
        ...RoleFilter.values.map((filter) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _FilterChip(
            label: filter.displayName, isSelected: _roleFilter == filter,
            onTap: () => _onRoleFilterChanged(filter),
          ),
        )),
      ]),
    );
  }

  // ── Stat Pill ──
  Widget _buildStatPill({
    required IconData icon, required String value, required String label,
    required Color color, required bool isDark,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceElevated : Colors.white,
            (isDark ? AppColors.surfaceElevated : Colors.white).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context), letterSpacing: -0.5, height: 1.1)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMutedOf(context))),
        ]),
      ]),
    );
  }

  // ── Stats Section ──
  Widget _buildStatsSection(AdminUsersStats stats, bool isDark) {
    final items = [
      _StatPillData(Icons.people_rounded, stats.total.toString(), 'Total Users', AppColors.primary),
      _StatPillData(Icons.videocam_rounded, stats.creators.toString(), 'Creators', const Color(0xFF8B5CF6)),
      _StatPillData(Icons.campaign_rounded, stats.advertisers.toString(), 'Advertisers', const Color(0xFF06B6D4)),
      _StatPillData(Icons.block_rounded, stats.banned.toString(), 'Banned', AppColors.error),
      _StatPillData(Icons.mark_email_unread_rounded, stats.unverified.toString(), 'Unverified', const Color(0xFFF59E0B)),
      _StatPillData(Icons.delete_rounded, stats.deletionRequests.toString(), 'Deletion Req.', const Color(0xFFEC4899)),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildStatPill(icon: item.icon, value: item.value, label: item.label, color: item.color, isDark: isDark),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBannedStatsSection(BannedUsersPage page, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(
          height: 90,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _buildStatPill(icon: Icons.block_rounded, value: page.total.toString(), label: 'Banned Users', color: AppColors.error, isDark: isDark),
          ]),
        ),
      ),
    );
  }

  // ── List Builders ──
  SliverList _buildUsersSliverList(AdminUsersPage page) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == page.users.length) return _buildPaginationFooter(page);
        return _UserCard(
          user: page.users[index],
          onBan: () => _showBanDialog(page.users[index]),
          onUnban: () => _confirmUnban(page.users[index]),
          onViewDetails: () => _showUserDetails(page.users[index]),
        );
      }, childCount: page.users.length + 1),
    );
  }

  SliverList _buildBannedUsersSliverList(BannedUsersPage page) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == page.bans.length) {
          if (page.offset + page.limit >= page.total) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('${page.total} banned users total',
                style: TextStyle(fontSize: 13, color: AppColors.textMutedOf(context)))),
            );
          }
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        return _BannedUserCard(user: page.bans[index], onUnban: () => _confirmUnbanBannedUser(page.bans[index]));
      }, childCount: page.bans.length + 1),
    );
  }

  // ── Pagination (Wayo-ads page / totalPages / limit) ──
  Widget _buildPaginationFooter(AdminUsersPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPrev = page.page > 1 && !_isPagingUsers;
    final canNext = page.page < page.totalPages && !_isPagingUsers;
    final start = page.total == 0 ? 0 : (page.page - 1) * page.limit + 1;
    final end = page.total == 0
        ? 0
        : (start + page.users.length - 1).clamp(0, page.total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevated.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderOf(context).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${page.page} / ${page.totalPages}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        page.total == 0
                            ? 'No users'
                            : '$start–$end of ${page.total} users',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isPagingUsers)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaginationIconButton(
                  icon: Icons.first_page_rounded,
                  enabled: canPrev,
                  onPressed: () => _goToUsersPage(1),
                ),
                _PaginationIconButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: canPrev,
                  onPressed: () => _goToUsersPage(page.page - 1),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${page.limit} / page',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                _PaginationIconButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: canNext,
                  onPressed: () => _goToUsersPage(page.page + 1),
                ),
                _PaginationIconButton(
                  icon: Icons.last_page_rounded,
                  enabled: canNext,
                  onPressed: () => _goToUsersPage(page.totalPages),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty & Error ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AppColors.textMutedOf(context).withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(_showBannedOnly ? Icons.check_circle_rounded : Icons.people_rounded,
            size: 48, color: AppColors.textMutedOf(context).withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),
        Text(_searchQuery != null ? 'No users found' : (_showBannedOnly ? 'No banned users' : 'No users yet'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 8),
        Text(_searchQuery != null ? 'Try a different search term' : (_showBannedOnly ? 'All users are in good standing' : 'Users will appear here'),
          style: TextStyle(fontSize: 14, color: AppColors.textMutedOf(context)),
        ),
      ]),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        Text('Failed to load users',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  // ── Dialogs ──
  Future<void> _showBanDialog(AdminUser user) async {
    final reasonController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, -6))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5,
            decoration: BoxDecoration(color: AppColors.borderOf(context).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.block_rounded, color: AppColors.error, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ban User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(user.email, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context))),
                ])),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceElevatedOf(context), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reason (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textMutedOf(context), letterSpacing: 0.4)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController, maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for banning this user...',
                      hintStyle: TextStyle(color: AppColors.textMutedOf(context).withValues(alpha: 0.7)),
                      filled: true, fillColor: AppColors.surfaceOf(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: AppColors.borderOf(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                  ),
                  child: const Text('Ban User', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ]),
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminUsersNotifierProvider(
            search: _searchQuery, role: _roleFilter, joined: _joinedFilter, bannedOnly: _showBannedOnly,
          ).notifier)
          .banUser(user.id, reason: reasonController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'User banned successfully' : 'Failed to ban user'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _confirmUnban(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          const Text('Unban User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Are you sure you want to unban ?', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context)),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.borderOf(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
            ),
            child: const Text('Unban', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminUsersNotifierProvider(
            search: _searchQuery, role: _roleFilter, joined: _joinedFilter, bannedOnly: _showBannedOnly,
          ).notifier)
          .unbanUser(user.authUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'User unbanned successfully' : 'Failed to unban user'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _confirmUnbanBannedUser(BannedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          const Text('Unban User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Are you sure you want to unban ?', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context)),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.borderOf(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
            ),
            child: const Text('Unban', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(bannedUsersNotifierProvider(search: _searchQuery).notifier)
          .unbanUser(user.authUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'User unbanned successfully' : 'Failed to unban user'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _showUserDetails(AdminUser user) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailsSheet(user: user),
    );
  }
}
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 90,
        child: ListView(scrollDirection: Axis.horizontal,
          children: List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(width: 180, height: 90,
              decoration: BoxDecoration(color: AppColors.surfaceElevatedOf(context), borderRadius: BorderRadius.circular(16)),
            ),
          )),
        ),
      ),
    );
  }
}

class _StatPillData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPillData(this.icon, this.value, this.label, this.color);
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: TextStyle(
      fontSize: 12, color: AppColors.textMutedOf(context),
      fontWeight: FontWeight.w600, letterSpacing: 0.3,
    )));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)])
              : null,
          color: isSelected ? null : AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderOf(context),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
        )),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onBan,
    required this.onUnban,
    required this.onViewDetails,
  });

  final AdminUser user;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  final VoidCallback onViewDetails;

  /// Hours / minutes since [lastLogin] (Wayo-ads `lastLoginAt`).
  static String formatLastLoginHours(DateTime? lastLogin) {
    if (lastLogin == null) return 'Never connected';
    final diff = DateTime.now().difference(lastLogin);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? '1 minute ago' : '$m minutes ago';
    }
    final hours = diff.inHours;
    if (hours == 1) return '1 hour ago';
    return '$hours hours ago';
  }

  static int? lastLoginHoursAgo(DateTime? lastLogin) {
    if (lastLogin == null) return null;
    return DateTime.now().difference(lastLogin).inHours;
  }

  static Color lastLoginColor(BuildContext context, DateTime? lastLogin) {
    if (lastLogin == null) return AppColors.textMutedOf(context);
    final hours = lastLoginHoursAgo(lastLogin)!;
    if (hours < 24) return AppColors.success;
    if (hours < 24 * 7) return const Color(0xFFF59E0B);
    return AppColors.textMutedOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBanned = user.status == AdminUserStatus.banned;
    final accent = _roleAccent(user.role);
    final status = _getStatusInfo(user.status);
    final lastLoginHours = lastLoginHoursAgo(user.lastLogin);
    final lastLoginLabel = formatLastLoginHours(user.lastLogin);
    final lastLoginTint = lastLoginColor(context, user.lastLogin);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: isDark
                ? AppColors.surfaceElevated.withValues(alpha: 0.72)
                : Colors.white,
            child: InkWell(
              onTap: onViewDetails,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ModernUserAvatar(user: user),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.displayName,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.4,
                                                color: AppColors.textPrimaryOf(context),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 22,
                                            color: AppColors.textMutedOf(context)
                                                .withValues(alpha: 0.5),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.2,
                                          color: AppColors.textSecondaryOf(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_filled_rounded,
                                            size: 14,
                                            color: lastLoginTint,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              lastLoginHours != null
                                                  ? 'Last seen · $lastLoginLabel'
                                                  : lastLoginLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: lastLoginTint,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (lastLoginHours != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: lastLoginTint.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${lastLoginHours}h',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: lastLoginTint,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _RolePill(role: user.role),
                                          _StatusPill(
                                            label: status.$2,
                                            color: status.$1,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final tileWidth =
                                    (constraints.maxWidth - 8) / 2;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (user.role == AdminUserRole.creator)
                                      _UserMetricTile(
                                        width: tileWidth,
                                        icon: Icons.handshake_rounded,
                                        label: 'Collabs',
                                        value: '${user.approvedCollaborations}',
                                        color: user.approvedCollaborations > 0
                                            ? AppColors.success
                                            : AppColors.textMutedOf(context),
                                      ),
                                    _UserMetricTile(
                                      width: tileWidth,
                                      icon: Icons.credit_card_rounded,
                                      label: 'Stripe',
                                      value: user.stripeStatus.displayName,
                                      color: user.stripeStatus ==
                                              StripeStatus.connected
                                          ? AppColors.success
                                          : AppColors.textMutedOf(context),
                                    ),
                                    _UserMetricTile(
                                      width: tileWidth,
                                      icon: Icons.calendar_month_rounded,
                                      label: 'Joined',
                                      value: DateFormat('MMM d, yy')
                                          .format(user.joinedAt),
                                      color: AppColors.textMutedOf(context),
                                    ),
                                    _UserMetricTile(
                                      width: tileWidth,
                                      icon: Icons.schedule_rounded,
                                      label: 'Last login',
                                      value: lastLoginHours != null
                                          ? '$lastLoginHours h'
                                          : '—',
                                      subtitle: lastLoginHours != null
                                          ? lastLoginLabel
                                          : 'Never',
                                      color: lastLoginTint,
                                    ),
                                    if (user.ipAddress != null)
                                      _UserMetricTile(
                                        width: tileWidth,
                                        icon: Icons.public_rounded,
                                        label: 'IP',
                                        value: user.ipAddress!,
                                        color: AppColors.textMutedOf(context),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: AppColors.borderOf(context)
                                  .withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _CardActionButton(
                                    label: 'Details',
                                    icon: Icons.insights_rounded,
                                    foreground: AppColors.primary,
                                    background: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    onPressed: onViewDetails,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _CardActionButton(
                                    label: isBanned ? 'Unban' : 'Ban',
                                    icon: isBanned
                                        ? Icons.lock_open_rounded
                                        : Icons.gpp_bad_rounded,
                                    foreground: isBanned
                                        ? AppColors.success
                                        : AppColors.error,
                                    background: (isBanned
                                            ? AppColors.success
                                            : AppColors.error)
                                        .withValues(alpha: 0.1),
                                    onPressed: isBanned ? onUnban : onBan,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _roleAccent(AdminUserRole role) {
    switch (role) {
      case AdminUserRole.creator:
        return const Color(0xFF8B5CF6);
      case AdminUserRole.advertiser:
        return const Color(0xFF06B6D4);
      case AdminUserRole.superAdmin:
        return AppColors.primary;
      case AdminUserRole.unknown:
        return AppColors.textMuted;
    }
  }

  static (Color, String) _getStatusInfo(AdminUserStatus status) {
    switch (status) {
      case AdminUserStatus.active:
        return (AppColors.success, 'Active');
      case AdminUserStatus.emailUnverified:
        return (const Color(0xFFF59E0B), 'Unverified');
      case AdminUserStatus.banned:
        return (AppColors.error, 'Banned');
      case AdminUserStatus.pendingDeletion:
        return (const Color(0xFFEC4899), 'Deleting');
      case AdminUserStatus.unknown:
        return (AppColors.textMuted, 'Unknown');
    }
  }
}

class _ModernUserAvatar extends StatelessWidget {
  const _ModernUserAvatar({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final accent = _UserCard._roleAccent(user.role);
    Widget avatar;
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(user.avatar!),
        backgroundColor: accent.withValues(alpha: 0.15),
      );
    } else {
      avatar = CircleAvatar(
        radius: 26,
        backgroundColor: accent.withValues(alpha: 0.14),
        child: Text(
          user.initials,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.45)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceOf(context),
        ),
        child: avatar,
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final AdminUserRole role;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (role) {
      AdminUserRole.creator => (
          const Color(0xFF8B5CF6),
          const Color(0xFF8B5CF6).withValues(alpha: 0.14),
        ),
      AdminUserRole.advertiser => (
          const Color(0xFF06B6D4),
          const Color(0xFF06B6D4).withValues(alpha: 0.14),
        ),
      AdminUserRole.superAdmin => (
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.14),
        ),
      AdminUserRole.unknown => (
          AppColors.textMuted,
          AppColors.textMuted.withValues(alpha: 0.12),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMetricTile extends StatelessWidget {
  const _UserMetricTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderOf(context).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMutedOf(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDetailsSheet extends StatelessWidget {
  const _UserDetailsSheet({required this.user});
  final AdminUser user;
  static final _dateTimeFormat = DateFormat('MMM d, yyyy • hh:mm a');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.borderOf(context).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _buildLargeAvatar(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.displayName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.email));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied'), duration: Duration(seconds: 1)));
                      },
                      child: Row(children: [
                        Flexible(child: Text(user.email, style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context)))),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded, size: 14, color: AppColors.textMutedOf(context)),
                      ]),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 28),
              _buildDetailSection(context, 'Account Information', [
                _DetailRow(icon: Icons.badge_rounded, label: 'Role', value: user.role.displayName),
                _DetailRow(icon: Icons.verified_rounded, label: 'Status', value: user.status.displayName, valueColor: _getStatusColor(user.status)),
                _DetailRow(icon: Icons.mark_email_read_rounded, label: 'Email', value: user.isEmailVerified ? 'Verified' : 'Not verified',
                  valueColor: user.isEmailVerified ? AppColors.success : const Color(0xFFF59E0B)),
                _DetailRow(icon: Icons.school_rounded, label: 'Onboarding', value: user.isOnboardingCompleted ? 'Completed' : 'Pending',
                  valueColor: user.isOnboardingCompleted ? AppColors.success : AppColors.textMuted),
                _DetailRow(icon: Icons.fingerprint_rounded, label: 'User ID', value: user.id),
              ]),
              if (user.role == AdminUserRole.creator) ...[
                const SizedBox(height: 20),
                _buildDetailSection(context, 'Creator Stats', [
                  _DetailRow(icon: Icons.handshake_rounded, label: 'Approved Collabs', value: '${user.approvedCollaborations}',
                    valueColor: user.approvedCollaborations > 0 ? AppColors.success : null),
                ]),
              ],
              const SizedBox(height: 20),
              _buildDetailSection(context, 'Payment', [
                _DetailRow(icon: Icons.credit_card_rounded, label: 'Stripe', value: user.stripeStatus.displayName,
                  valueColor: user.stripeStatus == StripeStatus.connected ? AppColors.success : null),
              ]),
              const SizedBox(height: 20),
              _buildDetailSection(context, 'Activity', [
                _DetailRow(icon: Icons.calendar_month_rounded, label: 'Joined', value: _dateTimeFormat.format(user.joinedAt)),
                if (user.lastLogin != null) ...[
                  _DetailRow(
                    icon: Icons.login_rounded,
                    label: 'Last Login',
                    value: _dateTimeFormat.format(user.lastLogin!),
                  ),
                  _DetailRow(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Hours since login',
                    value: _UserCard.formatLastLoginHours(user.lastLogin),
                    valueColor: _UserCard.lastLoginColor(context, user.lastLogin),
                  ),
                ],
                if (user.ipAddress != null)
                  _DetailRow(icon: Icons.language_rounded, label: 'IP Address', value: user.ipAddress!),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildLargeAvatar(BuildContext context) {
    final bgColor = _getAvatarColor(user.role);
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return CircleAvatar(radius: 36, backgroundImage: NetworkImage(user.avatar!), backgroundColor: bgColor.withValues(alpha: 0.2));
    }
    return CircleAvatar(radius: 36, backgroundColor: bgColor.withValues(alpha: 0.15),
      child: Text(user.initials, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bgColor)),
    );
  }

  Color _getAvatarColor(AdminUserRole role) {
    switch (role) {
      case AdminUserRole.creator: return const Color(0xFF8B5CF6);
      case AdminUserRole.advertiser: return const Color(0xFF06B6D4);
      case AdminUserRole.superAdmin: return AppColors.primary;
      case AdminUserRole.unknown: return AppColors.textMuted;
    }
  }

  Color _getStatusColor(AdminUserStatus status) {
    switch (status) {
      case AdminUserStatus.active: return AppColors.success;
      case AdminUserStatus.emailUnverified: return const Color(0xFFF59E0B);
      case AdminUserStatus.banned: return AppColors.error;
      case AdminUserStatus.pendingDeletion: return const Color(0xFFEC4899);
      case AdminUserStatus.unknown: return AppColors.textMuted;
    }
  }

  Widget _buildDetailSection(BuildContext context, String title, List<_DetailRow> rows) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(children: [
          Container(width: 3, height: 14,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textMutedOf(context), letterSpacing: 0.6)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedOf(context), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOf(context).withValues(alpha: 0.3)),
        ),
        child: Column(children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.textMutedOf(context).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(entry.value.icon, size: 16, color: AppColors.textMutedOf(context)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.value.label, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)))),
                Flexible(child: Text(entry.value.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: entry.value.valueColor ?? AppColors.textPrimaryOf(context)),
                  textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
            if (!isLast) Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Divider(height: 1, color: AppColors.borderOf(context).withValues(alpha: 0.3)),
            ),
          ]);
        }).toList()),
      ),
    ]);
  }
}

class _DetailRow {
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _PaginationIconButton extends StatelessWidget {
  const _PaginationIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        foregroundColor: enabled
            ? AppColors.primary
            : AppColors.textMutedOf(context).withValues(alpha: 0.4),
        backgroundColor: enabled
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceElevatedOf(context),
      ),
    );
  }
}

class _BannedUserCard extends StatelessWidget {
  const _BannedUserCard({required this.user, required this.onUnban});

  final BannedUser user;
  final VoidCallback onUnban;

  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.14 : 0.1),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: isDark
                ? AppColors.surfaceElevated.withValues(alpha: 0.72)
                : Colors.white,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withValues(alpha: 0.4)],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      accent,
                                      accent.withValues(alpha: 0.45),
                                    ],
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceOf(context),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor:
                                        accent.withValues(alpha: 0.12),
                                    child: Icon(
                                      Icons.block_rounded,
                                      color: accent,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                        color: AppColors.textPrimaryOf(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondaryOf(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    _StatusPill(label: 'Banned', color: accent),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (user.reason != null &&
                              user.reason!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.report_gmailerrorred_rounded,
                                    size: 18,
                                    color: accent.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      user.reason!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: AppColors.textSecondaryOf(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _UserMetricTile(
                            width: double.infinity,
                            icon: Icons.event_busy_rounded,
                            label: 'Banned on',
                            value: _dateFormat.format(user.bannedAt),
                            color: accent,
                          ),
                          const SizedBox(height: 12),
                          _CardActionButton(
                            label: 'Unban user',
                            icon: Icons.lock_open_rounded,
                            foreground: AppColors.success,
                            background:
                                AppColors.success.withValues(alpha: 0.1),
                            onPressed: onUnban,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
