import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_wallet_remote_datasource.dart';
import '../../domain/creator_business_profile.dart';
import '../../domain/creator_withdrawal_fee_estimate.dart';
import '../../domain/creator_wallet_models.dart';
import '../providers/creator_wallet_providers.dart';
import 'creator_withdraw_fee_breakdown.dart';

/// Modal bottom sheet to request a new payout.
///
/// Validates locally against the **same rules** as the backend (min/max,
/// sufficient funds) to give instant feedback, but the server remains the
/// source of truth (it re-validates on `POST /api/creator/withdrawal`).
Future<bool> showCreatorWithdrawSheet(
  BuildContext context, {
  required CreatorWalletPage page,
  required String moneyLocale,
  CreatorBusinessProfile? businessProfile,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CreatorWithdrawSheet(
      page: page,
      moneyLocale: moneyLocale,
      businessProfile: businessProfile,
    ),
  );
  return ok == true;
}

class _CreatorWithdrawSheet extends ConsumerStatefulWidget {
  const _CreatorWithdrawSheet({
    required this.page,
    required this.moneyLocale,
    this.businessProfile,
  });

  final CreatorWalletPage page;
  final String moneyLocale;
  final CreatorBusinessProfile? businessProfile;

  @override
  ConsumerState<_CreatorWithdrawSheet> createState() =>
      _CreatorWithdrawSheetState();
}

class _CreatorWithdrawSheetState extends ConsumerState<_CreatorWithdrawSheet> {
  late final TextEditingController _controller;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onAmountChanged);
    _controller.dispose();
    super.dispose();
  }

  int? _amountCents() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final d = double.tryParse(raw);
    if (d == null || d <= 0) return null;
    return (d * 100).round();
  }

  String? _validate(Translations t) {
    final amountCents = _amountCents();
    final balance = widget.page.balance;
    final limits = widget.page.limits;
    if (amountCents == null) return t.creator.wallet.withdraw_error_invalid;
    if (amountCents < limits.minimumWithdrawalCents) {
      return t.creator.wallet.withdraw_error_min.replaceAll(
        '{min}',
        MoneyFormatter.format(
          limits.minimumWithdrawal,
          currency: balance.currency,
          locale: widget.moneyLocale,
        ),
      );
    }
    if (amountCents > balance.availableCents) {
      return t.creator.wallet.withdraw_error_insufficient;
    }
    return null;
  }

  Future<void> _submit() async {
    final t = context.t;
    final err = _validate(t);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final amountCents = _amountCents()!;
      await ref
          .read(creatorWalletRepositoryProvider)
          .requestWithdrawal(amountCents: amountCents);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // Invalidate so the sheet closer sees fresh data.
      // ignore: unused_result
      ref.refresh(creatorWalletPageProvider);
      Navigator.of(context).pop(true);
    } on WithdrawalInsufficientFundsException {
      if (!mounted) return;
      setState(() {
        _error = t.creator.wallet.withdraw_error_insufficient;
        _submitting = false;
      });
    } on CreatorWalletApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final balance = widget.page.balance;
    final limits = widget.page.limits;
    final insets = MediaQuery.viewInsetsOf(context);
    final sym = MoneyFormatter.currencySymbol(balance.currency);
    final preset10 = MoneyFormatter.format(
      10,
      currency: balance.currency,
      locale: widget.moneyLocale,
    );
    final preset50 = MoneyFormatter.format(
      50,
      currency: balance.currency,
      locale: widget.moneyLocale,
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + insets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.textMutedOf(context).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              t.creator.wallet.withdraw_sheet_title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              t.creator.wallet.withdraw_sheet_body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.creator.wallet.withdraw_sheet_subtitle.replaceAll(
                '{available}',
                MoneyFormatter.format(
                  balance.available,
                  currency: balance.currency,
                  locale: widget.moneyLocale,
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                prefixText: '$sym ',
                prefixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                labelText: t.creator.wallet.withdraw_amount_label,
                hintText: MoneyFormatter.format(
                  limits.minimumWithdrawal,
                  currency: balance.currency,
                  locale: widget.moneyLocale,
                ),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.creator.wallet.withdraw_quick_amounts.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _WithdrawPresetChip(
                    label: preset10,
                    onTap: () => _fillPresetMajorUnits(10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _WithdrawPresetChip(
                    label: preset50,
                    onTap: () => _fillPresetMajorUnits(50),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _WithdrawPresetChip(
                    label: t.creator.wallet.withdraw_preset_all,
                    onTap: () => _fill(balance.availableCents),
                  ),
                ),
              ],
            ),
            if (estimateCreatorWithdrawalFees(
                  grossCents: _amountCents(),
                  profile: widget.businessProfile,
                )
                case final estimate?
                when estimate.hasTax) ...[
              const SizedBox(height: 14),
              CreatorWithdrawFeeBreakdown(
                estimate: estimate,
                currency: balance.currency,
                moneyLocale: widget.moneyLocale,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.call_made_rounded, size: 18),
                label: Text(
                  _submitting
                      ? t.creator.wallet.withdraw_submitting
                      : t.creator.wallet.withdraw_submit,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CreatorColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.creator.wallet.withdraw_secure_footer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
        ),
    );
  }

  /// Fills [majorUnits] (e.g. 10.00 USD) as cents, capped by available balance.
  void _fillPresetMajorUnits(double majorUnits) {
    final cents = (majorUnits * 100).round();
    _fill(cents.clamp(0, widget.page.balance.availableCents));
  }

  void _fill(int cents) {
    if (cents <= 0) return;
    _controller.text = (cents / 100.0).toStringAsFixed(2);
    setState(() => _error = null);
  }
}

/// Dark-style preset pill (quick amount / all).
class _WithdrawPresetChip extends StatelessWidget {
  const _WithdrawPresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.surfaceElevated.withValues(alpha: 0.85)
        : AppColors.surfaceElevatedOf(context);
    final fg = AppColors.textPrimaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.45),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
