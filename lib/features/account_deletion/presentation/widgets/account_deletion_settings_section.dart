import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../../router/app_router.dart';
import '../providers/account_deletion_providers.dart';
import '../screens/account_deletion_screen.dart';

/// Account section in app settings — mirrors web `/settings?tab=danger`.
class AccountDeletionSettingsSection extends ConsumerStatefulWidget {
  const AccountDeletionSettingsSection({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<AccountDeletionSettingsSection> createState() =>
      _AccountDeletionSettingsSectionState();
}

class _AccountDeletionSettingsSectionState
    extends ConsumerState<AccountDeletionSettingsSection> {
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

  Future<void> _openDeletionScreen() async {
    HapticFeedback.selectionClick();
    widget.onClose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentContext;
      if (nav != null && nav.mounted) {
        GoRouter.of(nav).push('/settings/delete-account');
      }
    });
  }

  Future<void> _cancelDeletion() async {
    final t = context.t.account_deletion;
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
      WayoToast.success(context, t.toast_cancelled);
    } on DioException {
      if (!mounted) return;
      WayoToast.error(context, t.error_delete);
    } catch (_) {
      if (!mounted) return;
      WayoToast.error(context, t.error_delete);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    if (role == WayoAdsAccountRole.superAdmin) {
      return const SizedBox.shrink();
    }

    final requestedAt = ref.watch(accountDeletionScheduledAtProvider);
    final t = context.t.account_deletion;
    final settingsT = context.t.app_settings;
    final scheme = Theme.of(context).colorScheme;

    if (requestedAt == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: scheme.errorContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openDeletionScreen,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: scheme.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settingsT.delete_account_entry,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.error),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            settingsT.delete_account_entry_sub,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final purge = _purgeAt(requestedAt);
    final days = _daysLeft(purge);
    final grace = AccountDeletionScreen.graceDays;
    final progress = grace <= 0
        ? 0.0
        : ((grace - days) / grace).clamp(0.0, 1.0);
    final daysLabel = days == 1
        ? t.pending_days_remaining_one
        : t.pending_days_remaining_plural(n: days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
            color: scheme.errorContainer.withValues(alpha: 0.22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: scheme.error, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.pending_scheduled_status,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.pending_danger_card_body(date: _fmtDate(context, purge)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: scheme.error.withValues(alpha: 0.12),
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  daysLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _cancelling ? null : _cancelDeletion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: _cancelling
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.cancel_request),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _openDeletionScreen,
                  child: Text(settingsT.delete_account_manage),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
