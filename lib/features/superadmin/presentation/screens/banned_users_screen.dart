import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/banned_user.dart';
import '../providers/superadmin_providers.dart';

class BannedUsersScreen extends ConsumerStatefulWidget {
  const BannedUsersScreen({super.key});

  @override
  ConsumerState<BannedUsersScreen> createState() => _BannedUsersScreenState();
}

class _BannedUsersScreenState extends ConsumerState<BannedUsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(bannedUsersNotifierProvider(search: _searchQuery).notifier).loadMore();
    }
  }

  void _onSearch(String value) {
    setState(() {
      _searchQuery = value.isEmpty ? null : value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannedUsersAsync = ref.watch(
      bannedUsersNotifierProvider(search: _searchQuery),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Banned Users'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _showBanUserDialog,
            icon: const Icon(Icons.person_add_disabled_rounded),
            tooltip: 'Ban User',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by email or name...',
                hintStyle: TextStyle(color: AppColors.textMutedOf(context)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textMutedOf(context),
                ),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.textMutedOf(context),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevatedOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: bannedUsersAsync.when(
              data: (page) => page.bans.isEmpty
                  ? _buildEmptyState()
                  : _buildBannedUsersList(page),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(
                () => ref.invalidate(bannedUsersNotifierProvider(search: _searchQuery)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: AppColors.success.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery != null ? 'No results found' : 'No banned users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery != null
                ? 'Try a different search term'
                : 'All users are in good standing',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load banned users',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedUsersList(BannedUsersPage page) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bannedUsersNotifierProvider(search: _searchQuery));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: page.bans.length + 1,
        itemBuilder: (context, index) {
          if (index == page.bans.length) {
            if (page.offset + page.limit >= page.total) {
              return const SizedBox(height: 80);
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _BannedUserCard(
            user: page.bans[index],
            onUnban: () => _confirmUnban(page.bans[index]),
          );
        },
      ),
    );
  }

  Future<void> _confirmUnban(BannedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Unban User'),
        content: Text('Are you sure you want to unban ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Unban'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(bannedUsersNotifierProvider(search: _searchQuery).notifier)
          .unbanUser(user.authUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'User unbanned successfully' : 'Failed to unban user'),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showBanUserDialog() async {
    final searchController = TextEditingController();
    SearchUser? selectedUser;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderOf(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          color: AppColors.error,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ban User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by email...',
                      hintStyle: TextStyle(color: AppColors.textMutedOf(context)),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textMutedOf(context),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceElevatedOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: searchController.text.length >= 2
                      ? Consumer(
                          builder: (context, ref, _) {
                            final searchAsync = ref.watch(
                              userSearchProvider(query: searchController.text),
                            );
                            return searchAsync.when(
                              data: (users) => users.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No users found',
                                        style: TextStyle(
                                          color: AppColors.textMutedOf(context),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      itemCount: users.length,
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        final isSelected = selectedUser?.id == user.id;
                                        return _SearchUserTile(
                                          user: user,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setModalState(() {
                                              selectedUser = isSelected ? null : user;
                                            });
                                          },
                                        );
                                      },
                                    ),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(
                                child: Text(
                                  'Search failed',
                                  style: TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'Type at least 2 characters to search',
                            style: TextStyle(
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedUser != null
                          ? () => _executeBan(context, selectedUser!)
                          : null,
                      icon: const Icon(Icons.block_rounded),
                      label: Text(
                        selectedUser != null
                            ? 'Ban ${selectedUser!.email}'
                            : 'Select a user to ban',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _executeBan(BuildContext dialogContext, SearchUser user) async {
    if (user.wayoUserId.isEmpty) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: const Text('Missing user id — cannot ban. Try again or update the app.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    Navigator.pop(dialogContext);

    final success = await ref
        .read(bannedUsersNotifierProvider(search: _searchQuery).notifier)
        .banUser(user.wayoUserId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User banned successfully' : 'Failed to ban user'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

class _BannedUserCard extends StatelessWidget {
  const _BannedUserCard({
    required this.user,
    required this.onUnban,
  });

  final BannedUser user;
  final VoidCallback onUnban;

  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.55) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                child: Icon(Icons.block_rounded, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Banned',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.reason != null && user.reason!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.borderOf(context).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.reason!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textMutedOf(context)),
                  const SizedBox(width: 4),
                  Text(
                    'Banned ${_dateFormat.format(user.bannedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onUnban,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Unban'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchUserTile extends StatelessWidget {
  const _SearchUserTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  final SearchUser user;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              )
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: user.avatar == null
              ? Text(
                  user.email.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name ?? user.email,
          style: TextStyle(
            fontWeight: user.name != null ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        subtitle: user.name != null
            ? Text(
                user.email,
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
              )
            : null,
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : null,
        selected: isSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
