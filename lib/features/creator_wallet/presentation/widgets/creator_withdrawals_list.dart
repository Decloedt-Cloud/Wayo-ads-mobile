import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_wallet_remote_datasource.dart';
import '../../domain/creator_wallet_models.dart';
import '../providers/creator_wallet_providers.dart';

/// History of past payout requests — each row shows amount, status and date.
/// Pending rows expose a cancel action that hits
/// `DELETE /api/creator/withdrawal?id=...`.
///
/// The parent passes the **full** history; this widget shows 10 rows at a time
/// and grows locally (no extra network) when the user loads more.
class CreatorWithdrawalsList extends StatefulWidget {
  const CreatorWithdrawalsList({
    super.key,
    required this.items,
    required this.moneyLocale,
  });

  final List<CreatorWithdrawal> items;
  final String moneyLocale;

  @override
  State<CreatorWithdrawalsList> createState() => _CreatorWithdrawalsListState();
}

class _CreatorWithdrawalsListState extends State<CreatorWithdrawalsList> {
  static const int _pageSize = 10;
  int _visible = _pageSize;

  @override
  void didUpdateWidget(covariant CreatorWithdrawalsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) return;
    _visible = math.min(_visible, widget.items.length);
    if (_visible == 0) {
      _visible = math.min(_pageSize, widget.items.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final items = widget.items;
    if (items.isEmpty) {
      return _EmptyState(t: t);
    }
    final n = math.min(_visible, items.length);
    final slice = items.take(n).toList(growable: false);
    final hasMore = n < items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in slice)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _WithdrawalTile(w: w, moneyLocale: widget.moneyLocale),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () => setState(() {
                _visible = math.min(_visible + _pageSize, items.length);
              }),
              child: Text(t.invoices.load_more),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t});
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textMutedOf(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.creator.wallet.history_empty,
              style: AppTextStyles.bodyLarge(
                context,
              ).copyWith(color: AppColors.textSecondaryOf(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalTile extends ConsumerStatefulWidget {
  const _WithdrawalTile({required this.w, required this.moneyLocale});

  final CreatorWithdrawal w;
  final String moneyLocale;

  @override
  ConsumerState<_WithdrawalTile> createState() => _WithdrawalTileState();
}

class _WithdrawalTileState extends ConsumerState<_WithdrawalTile> {
  bool _cancelling = false;

  Future<void> _confirmAndCancel() async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.creator.wallet.cancel_dialog_title),
        content: Text(t.creator.wallet.cancel_dialog_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.creator.wallet.cancel_dialog_no),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.15),
              foregroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.creator.wallet.cancel_dialog_yes),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _cancel();
  }

  Future<void> _cancel() async {
    final t = context.t;
    setState(() => _cancelling = true);
    try {
      await ref
          .read(creatorWalletRepositoryProvider)
          .cancelWithdrawal(widget.w.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // ignore: unused_result
      ref.refresh(creatorWalletPageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            t.creator.wallet.cancel_success,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } on CreatorWalletApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.message, style: const TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('$e', style: const TextStyle(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final w = widget.w;
    final (label, color, icon) = _statusStyle(context, w.status, t);
    final isValidated = w.status.isValidated;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = MoneyFormatter.format(
      w.payoutHistoryGross,
      currency: w.currency,
      locale: widget.moneyLocale,
    );
    final canCancel = w.status == CreatorWithdrawalStatus.pending;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.04,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValidated
                  ? AppColors.success.withValues(alpha: 0.35)
                  : AppColors.error.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amount,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOf(context),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _formatDate(w.createdAt, widget.moneyLocale),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMutedOf(context),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (w.status == CreatorWithdrawalStatus.failed &&
                            w.failureReason != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              w.failureReason!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _cancelling ? null : _confirmAndCancel,
                      icon: _cancelling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        _cancelling
                            ? t.creator.wallet.cancel_in_progress
                            : t.creator.wallet.cancel_action,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d, String locale) {
    try {
      return DateFormat.yMMMd(locale).add_jm().format(d.toLocal());
    } catch (_) {
      return d.toLocal().toIso8601String();
    }
  }

  static (String, Color, IconData) _statusStyle(
    BuildContext context,
    CreatorWithdrawalStatus status,
    Translations t,
  ) {
    if (status.isValidated) {
      return (
        t.creator.wallet.history_status_succeeded,
        AppColors.success,
        Icons.verified_rounded,
      );
    }

    final label = switch (status) {
      CreatorWithdrawalStatus.pending => t.creator.wallet.history_status_pending,
      CreatorWithdrawalStatus.processing =>
        t.creator.wallet.history_status_processing,
      CreatorWithdrawalStatus.failed => t.creator.wallet.history_status_failed,
      CreatorWithdrawalStatus.cancelled =>
        t.creator.wallet.history_status_cancelled,
      CreatorWithdrawalStatus.unknown =>
        t.creator.wallet.history_status_pending,
      CreatorWithdrawalStatus.succeeded => t.creator.wallet.history_status_succeeded,
    };

    final icon = switch (status) {
      CreatorWithdrawalStatus.processing => Icons.sync_rounded,
      CreatorWithdrawalStatus.failed => Icons.cancel_rounded,
      CreatorWithdrawalStatus.cancelled => Icons.block_rounded,
      _ => Icons.schedule_rounded,
    };

    return (label, AppColors.error, icon);
  }
}
