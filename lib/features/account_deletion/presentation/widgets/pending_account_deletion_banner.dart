import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../i18n/strings.g.dart';
import '../providers/account_deletion_providers.dart';
import '../screens/account_deletion_screen.dart';

/// Full-width status banner when Wayo Ads account deletion is in the grace period.
class PendingAccountDeletionBanner extends ConsumerStatefulWidget {
  const PendingAccountDeletionBanner({super.key});

  @override
  ConsumerState<PendingAccountDeletionBanner> createState() =>
      _PendingAccountDeletionBannerState();
}

class _PendingAccountDeletionBannerState
    extends ConsumerState<PendingAccountDeletionBanner> {
  bool _cancelling = false;

  String _fmtDate(BuildContext context, DateTime d) {
    final loc = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(loc).format(d);
  }

  DateTime _purgeAt(DateTime requested) => requested.add(
    const Duration(days: AccountDeletionScreen.graceDays),
  );

  int _daysLeft(DateTime purgeLocal) {
    final now = DateTime.now();
    final a = DateTime(purgeLocal.year, purgeLocal.month, purgeLocal.day);
    final b = DateTime(now.year, now.month, now.day);
    return math.max(0, a.difference(b).inDays);
  }

  Future<void> _confirmAndCancel(BuildContext context) async {
    final t = context.t.account_deletion;
    final toastCancelled = t.toast_cancelled;
    final errorDelete = t.error_delete;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.banner_cancel_dialog_title),
        content: Text(t.banner_cancel_dialog_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.banner_cancel_dialog_confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    final ds = ref.read(accountDeletionRemoteProvider);
    try {
      await ds.cancelScheduledDeletion();
      if (!mounted) return;
      ref.read(accountDeletionScheduledAtProvider.notifier).clearScheduledAt();
      await ref.read(accountDeletionScheduledAtProvider.notifier).syncFromRemote();
      if (!mounted) return;
      HapticFeedback.lightImpact();
      messenger?.showSnackBar(
        SnackBar(content: Text(toastCancelled)),
      );
    } on DioException {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(errorDelete)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(errorDelete)),
      );
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestedAt = ref.watch(accountDeletionScheduledAtProvider);
    final theme = Theme.of(context);

    if (requestedAt == null) {
      return const SizedBox.shrink();
    }
    final purge = _purgeAt(requestedAt);
    final n = _daysLeft(purge);
    final t = context.t.account_deletion;
    final onErr = theme.colorScheme.onError;

    return Material(
      color: theme.colorScheme.error,
      elevation: 3,
      shadowColor: theme.colorScheme.error.withValues(alpha: 0.45),
      child: SafeArea(
        bottom: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: onErr,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.banner_line(date: _fmtDate(context, purge), n: n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onErr,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              if (_cancelling)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onErr,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () => _confirmAndCancel(context),
                  style: TextButton.styleFrom(
                    foregroundColor: onErr,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    t.cancel_request,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: onErr,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: onErr,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
