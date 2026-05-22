import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/dashboard_state_providers.dart';
import '../providers/notifications_feed_providers.dart';
import '../../../../router/app_router.dart';
import 'notification_list_tile.dart';
import 'notification_open_helper.dart';
import 'notification_time_groups.dart';

const int _kPreviewCount = 10;

/// Opens the Wayo-ads style notification center (web bell dropdown).
Future<void> showNotificationCenterPopup(
  BuildContext context,
  WidgetRef ref,
) async {
  await HapticFeedback.lightImpact();
  ref.invalidate(notificationsListProvider);
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, _) {
      return _NotificationCenterOverlay(
        onClose: () => Navigator.of(ctx, rootNavigator: true).pop(),
      );
    },
    transitionBuilder: (context, anim, _, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          alignment: Alignment.topRight,
          child: child,
        ),
      );
    },
  );
}

class _NotificationCenterOverlay extends StatelessWidget {
  const _NotificationCenterOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 52;
    final w = MediaQuery.sizeOf(context).width;
    final panelW = w < 420 ? w - 24 : 384.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          right: 12,
          top: top,
          width: panelW,
          child: Material(
            color: Colors.transparent,
            child: _NotificationCenterPanel(onClose: onClose),
          ),
        ),
      ],
    );
  }
}

class _NotificationCenterPanel extends ConsumerWidget {
  const _NotificationCenterPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(notificationsListProvider);
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    final snap = ref.watch(dashboardStreamProvider).valueOrNull;
    final unreadBadge = snap?.unreadCount ?? 0;

    final bg = isDark ? const Color(0xFF181818) : AppColors.surfaceElevatedOf(context);
    final border = isDark
        ? const Color(0xFF2A2A2A)
        : AppColors.borderOf(context).withValues(alpha: 0.55);
    final muted = isDark
        ? const Color(0xFF9A9A9A)
        : AppColors.textMutedOf(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        t.dashboard.notifications_title,
                        style: TextStyle(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (unreadBadge > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadBadge > 99 ? '99+' : '$unreadBadge',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (unreadBadge > 0)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      await HapticFeedback.selectionClick();
                      try {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markAllRead();
                        invalidateAllNotifications(ref);
                      } catch (_) {}
                    },
                    child: Text(
                      t.dashboard.notifications_mark_all_read,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          Flexible(
            child: async.when(
              data: (list) => _NotificationPopupList(
                list: sortNotificationsForDisplay(list)
                    .take(_kPreviewCount)
                    .toList(),
                border: border,
                muted: muted,
                onClose: onClose,
                role: role,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(36),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('$e', style: TextStyle(color: muted, fontSize: 13)),
              ),
            ),
          ),
          Divider(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimaryOf(context),
                side: BorderSide(color: border),
                backgroundColor: isDark
                    ? const Color(0xFF222222)
                    : AppColors.surfaceElevatedOf(context).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                onClose();
                Future<void>.microtask(() {
                  ref.read(goRouterProvider).push(_notificationsListUri(role));
                });
              },
              child: Text(
                t.dashboard.notifications_view_all,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPopupList extends ConsumerWidget {
  const _NotificationPopupList({
    required this.list,
    required this.border,
    required this.muted,
    required this.onClose,
    required this.role,
  });

  final List<NotificationItem> list;
  final Color border;
  final Color muted;
  final VoidCallback onClose;
  final WayoAdsAccountRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: muted,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.dashboard.notifications_caught_up_title,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.dashboard.notifications_caught_up_subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: list.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: border.withValues(alpha: 0.7)),
      itemBuilder: (context, i) {
        final n = list[i];
        return NotificationListTile(
          item: n,
          mode: NotificationTileMode.popup,
          role: ref.read(currentWayoAdsAccountRoleProvider),
          onTap: () async {
            onClose();
            await openNotificationItem(ref, n);
          },
          onMarkRead: () async {
            if (n.isRead) return;
            await ref.read(notificationsRepositoryProvider).markRead(n.id);
                      invalidateAllNotifications(ref);
          },
          onDismiss: () async {
            try {
              await ref.read(notificationsRepositoryProvider).dismiss(n.id);
                      invalidateAllNotifications(ref);
            } catch (_) {}
          },
        );
      },
    );
  }
}

String _notificationsListUri(WayoAdsAccountRole role) {
  final r = switch (role) {
    WayoAdsAccountRole.creator => 'creator',
    WayoAdsAccountRole.advertiser => 'advertiser',
    WayoAdsAccountRole.superAdmin => 'superadmin',
    _ => 'app',
  };
  return '/notifications?role=$r';
}
