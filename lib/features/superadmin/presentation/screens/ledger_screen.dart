import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ledger_entry.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/superadmin_scaffold.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _scrollController = ScrollController();
  LedgerEntryType? _typeFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ledgerNotifierProvider(
        type: _typeFilter,
        startDate: _startDate,
        endDate: _endDate,
      ).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(
      ledgerNotifierProvider(
        type: _typeFilter,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );

    return SuperadminScaffold(
      title: 'Ledger',
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.filter_list_rounded),
            ),
            if (_hasActiveFilters)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceOf(context),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Type filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _TypeChip(
                  label: 'All',
                  isSelected: _typeFilter == null,
                  onTap: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'View Payout',
                  isSelected: _typeFilter == LedgerEntryType.viewPayout,
                  onTap: () => setState(() => _typeFilter = LedgerEntryType.viewPayout),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Conversion',
                  isSelected: _typeFilter == LedgerEntryType.conversionPayout,
                  onTap: () =>
                      setState(() => _typeFilter = LedgerEntryType.conversionPayout),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Platform fee',
                  isSelected: _typeFilter == LedgerEntryType.platformFee,
                  onTap: () => setState(() => _typeFilter = LedgerEntryType.platformFee),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Reversal',
                  isSelected: _typeFilter == LedgerEntryType.reversal,
                  onTap: () => setState(() => _typeFilter = LedgerEntryType.reversal),
                ),
              ],
            ),
          ),
          ledgerAsync.when(
            data: (page) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AdminMiniStatCard(
                      label: 'Total',
                      value:
                          '\$${(page.summary.totalAmountCents / 100).toStringAsFixed(2)}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminMiniStatCard(
                      label: 'Entries',
                      value: page.total.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminMiniStatCard(
                      label: 'Pages',
                      value: '${page.page}/${page.totalPages}',
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          // Date range indicator
          if (_startDate != null || _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateRange(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ledgerAsync.when(
              data: (page) => page.entries.isEmpty
                  ? _buildEmptyState()
                  : _buildLedgerList(page),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(
                () => ref.invalidate(ledgerNotifierProvider(
                  type: _typeFilter,
                  startDate: _startDate,
                  endDate: _endDate,
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _startDate != null || _endDate != null;

  String _formatDateRange() {
    final format = DateFormat('MMM d');
    if (_startDate != null && _endDate != null) {
      return '${format.format(_startDate!)} - ${format.format(_endDate!)}';
    }
    if (_startDate != null) {
      return 'From ${format.format(_startDate!)}';
    }
    if (_endDate != null) {
      return 'Until ${format.format(_endDate!)}';
    }
    return '';
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
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textMutedOf(context).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ledger entries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a different filter to see results',
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
            'Failed to load ledger',
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

  Widget _buildLedgerList(LedgerPage page) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ledgerNotifierProvider(
          type: _typeFilter,
          startDate: _startDate,
          endDate: _endDate,
        ));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: page.entries.length + 1,
        itemBuilder: (context, index) {
          if (index == page.entries.length) {
            if (page.page >= page.totalPages) {
              return const SizedBox(height: 80);
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _LedgerEntryCard(entry: page.entries[index]);
        },
      ),
    );
  }

  Future<void> _showFilters() async {
    await showSuperadminSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOf(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.date_range_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primarySoft.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.borderOf(context).withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: date != null
                  ? AppColors.primary
                  : AppColors.borderOf(context).withValues(alpha: 0.3),
              width: date != null ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 14,
                    color: date != null ? AppColors.primary : AppColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date != null
                        ? DateFormat('MMM d, yyyy').format(date!)
                        : 'Select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? AppColors.textPrimaryOf(context)
                          : AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerEntryCard extends StatelessWidget {
  const _LedgerEntryCard({required this.entry});

  final LedgerEntry entry;

  static final _dateFormat = DateFormat('MMM d, HH:mm');
  static final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  Color _typeColor() {
    switch (entry.type) {
      case LedgerEntryType.viewPayout:
        return const Color(0xFF14B8A6);
      case LedgerEntryType.conversionPayout:
        return const Color(0xFF8B5CF6);
      case LedgerEntryType.platformFee:
        return const Color(0xFFF97316);
      case LedgerEntryType.reversal:
        return AppColors.error;
      case LedgerEntryType.unknown:
        return Colors.grey;
    }
  }

  IconData _typeIcon() {
    switch (entry.type) {
      case LedgerEntryType.viewPayout:
        return Icons.visibility_rounded;
      case LedgerEntryType.conversionPayout:
        return Icons.sync_alt_rounded;
      case LedgerEntryType.platformFee:
        return Icons.pie_chart_rounded;
      case LedgerEntryType.reversal:
        return Icons.undo_rounded;
      case LedgerEntryType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor();
    final isPositive = entry.amountCents >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.55) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(), size: 18, color: typeColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.type.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMutedOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          _dateFormat.format(entry.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${_currencyFormat.format(entry.amountUsd)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderOf(context).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: AppColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.campaignTitle != null || entry.creatorEmail != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (entry.campaignTitle != null)
                  _InfoChip(
                    icon: Icons.campaign_rounded,
                    label: entry.campaignTitle!,
                  ),
                if (entry.creatorEmail != null)
                  _InfoChip(
                    icon: Icons.person_rounded,
                    label: entry.creatorName ?? entry.creatorEmail!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMutedOf(context)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
