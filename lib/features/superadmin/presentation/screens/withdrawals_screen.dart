import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/withdrawal.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/admin_stat_card.dart';

class WithdrawalsScreen extends ConsumerStatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  ConsumerState<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends ConsumerState<WithdrawalsScreen> {
  final _scrollController = ScrollController();
  WithdrawalStatus? _statusFilter;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted) {
        ref.invalidate(withdrawalsNotifierProvider(status: _statusFilter));
      }
    });
  }

  void _setFilter(WithdrawalStatus? filter) {
    if (_statusFilter == filter) return;
    setState(() => _statusFilter = filter);
    _startPolling();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(withdrawalsNotifierProvider(status: _statusFilter).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(superadminWithdrawalsLivePulseProvider);
    ref.listen<int>(superadminWithdrawalsLivePulseProvider, (prev, next) {
      if (prev == next) return;
      ref.invalidate(withdrawalsNotifierProvider(status: _statusFilter));
    });

    final withdrawalsAsync = ref.watch(
      withdrawalsNotifierProvider(status: _statusFilter),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Withdrawals'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _LivePayoutsBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _statusFilter == null,
                  onTap: () => _setFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  isSelected: _statusFilter == WithdrawalStatus.pending,
                  color: const Color(0xFFF59E0B),
                  onTap: () => _setFilter(WithdrawalStatus.pending),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Approved',
                  isSelected: _statusFilter == WithdrawalStatus.validated,
                  color: AppColors.success,
                  onTap: () => _setFilter(WithdrawalStatus.validated),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cancelled',
                  isSelected: _statusFilter == WithdrawalStatus.cancelled,
                  color: AppColors.error,
                  onTap: () => _setFilter(WithdrawalStatus.cancelled),
                ),
              ],
            ),
          ),
          // Summary cards
          withdrawalsAsync.when(
            data: (page) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AdminMiniStatCard(
                      label: 'Pending',
                      value: '\$${(page.summary.pendingAmountCents / 100).toStringAsFixed(0)}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminMiniStatCard(
                      label: 'Validated',
                      value: '\$${(page.summary.validatedAmountCents / 100).toStringAsFixed(0)}',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminMiniStatCard(
                      label: 'Paid',
                      value: '\$${(page.summary.paidAmountCents / 100).toStringAsFixed(0)}',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: withdrawalsAsync.when(
              data: (page) => page.withdrawals.isEmpty
                  ? _buildEmptyState()
                  : _buildWithdrawalsList(page),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(
                () => ref.invalidate(withdrawalsNotifierProvider(status: _statusFilter)),
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
              color: AppColors.textMutedOf(context).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 48,
              color: AppColors.textMutedOf(context).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No withdrawals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All withdrawals are processed',
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
            'Failed to load withdrawals',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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

  Widget _buildWithdrawalsList(WithdrawalsPage page) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(withdrawalsNotifierProvider(status: _statusFilter));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: page.withdrawals.length + 1,
        itemBuilder: (context, index) {
          if (index == page.withdrawals.length) {
            if (page.page >= page.totalPages) {
              return const SizedBox(height: 80);
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _WithdrawalCard(
            withdrawal: page.withdrawals[index],
            onApprove: () => _confirmApprove(page.withdrawals[index]),
            onCancel: () => _confirmCancel(page.withdrawals[index]),
          );
        },
      ),
    );
  }

  Future<void> _confirmApprove(Withdrawal withdrawal) async {
    final confirmed = await _showConfirmDialog(
      'Approve Withdrawal',
      'Approve \$${withdrawal.amountUsd.toStringAsFixed(2)} withdrawal for ${withdrawal.creatorEmail}?',
      'Approve',
      AppColors.success,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(withdrawalsNotifierProvider(status: _statusFilter).notifier)
          .approve(withdrawal.id);
      _showResultSnackbar(success, 'Withdrawal approved', 'Failed to approve');
    }
  }

  Future<void> _confirmCancel(Withdrawal withdrawal) async {
    final confirmed = await _showConfirmDialog(
      'Cancel Withdrawal',
      'Cancel \$${withdrawal.amountUsd.toStringAsFixed(2)} withdrawal for ${withdrawal.creatorEmail}?',
      'Cancel Withdrawal',
      AppColors.error,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(withdrawalsNotifierProvider(status: _statusFilter).notifier)
          .cancel(withdrawal.id);
      _showResultSnackbar(success, 'Withdrawal cancelled', 'Failed to cancel');
    }
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String content,
    String actionLabel,
    Color actionColor,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(title),
        content: Text(content),
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
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _showResultSnackbar(bool success, String successMsg, String failureMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? successMsg : failureMsg),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      effectiveColor.withValues(alpha: 0.15),
                      effectiveColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : AppColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : AppColors.borderOf(context).withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? effectiveColor : AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({
    required this.withdrawal,
    required this.onApprove,
    required this.onCancel,
  });

  final Withdrawal withdrawal;
  final VoidCallback onApprove;
  final VoidCallback onCancel;

  static final _dateFormat = DateFormat('MMM d, yyyy HH:mm');
  static final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      withdrawal.creatorName ?? withdrawal.creatorEmail,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (withdrawal.creatorName != null)
                      Text(
                        withdrawal.creatorEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _currencyFormat.format(withdrawal.amountUsd),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusBadge(status: withdrawal.status),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMutedOf(context)),
              const SizedBox(width: 4),
              Text(
                _dateFormat.format(withdrawal.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
          if (withdrawal.status == WithdrawalStatus.pending) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: AppColors.borderOf(context).withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final WithdrawalStatus status;

  Color get _color {
    switch (status) {
      case WithdrawalStatus.pending:
        return const Color(0xFFF59E0B);
      case WithdrawalStatus.validated:
        return AppColors.success;
      case WithdrawalStatus.paid:
        return AppColors.primary;
      case WithdrawalStatus.cancelled:
        return AppColors.error;
      case WithdrawalStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePayoutsBadge extends StatelessWidget {
  const _LivePayoutsBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
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
    );
  }
}
