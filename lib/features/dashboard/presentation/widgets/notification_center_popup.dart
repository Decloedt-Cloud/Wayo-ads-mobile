import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/dashboard_state_providers.dart';
import '../../../../router/app_router.dart';

const int _kPreviewCount = 8;

/// Opens a dark “notification center” sheet (web-style) anchored top-right.
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
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
          scale: Tween<double>(
            begin: 0.96,
            end: 1,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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

    final bg = isDark
        ? const Color(0xFF181818)
        : AppColors.surfaceElevatedOf(context);
    final border = isDark
        ? const Color(0xFF2A2A2A)
        : AppColors.borderOf(context).withValues(alpha: 0.55);
    final muted = isDark
        ? const Color(0xFFA0A0A0)
        : AppColors.textMutedOf(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.dashboard.notifications_title,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();
                    try {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markAllRead();
                      ref.invalidate(notificationsListProvider);
                      ref.invalidate(dashboardStreamProvider);
                    } catch (_) {}
                  },
                  child: Text(
                    t.dashboard.notifications_mark_all_read,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: async.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t.dashboard.notifications_empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                  );
                }
                final preview = list.take(_kPreviewCount).toList();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: preview.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: border.withValues(alpha: 0.6)),
                  itemBuilder: (context, i) {
                    final n = preview[i];
                    return _PopupNotificationTile(
                      item: n,
                      muted: muted,
                      onMarkRead: () async {
                        if (n.isRead) return;
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markRead(n.id);
                        ref.invalidate(notificationsListProvider);
                        ref.invalidate(dashboardStreamProvider);
                      },
                      onDismiss: () async {
                        try {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .dismiss(n.id);
                          ref.invalidate(notificationsListProvider);
                          ref.invalidate(dashboardStreamProvider);
                        } catch (_) {}
                      },
                      onOpenDetail: () async {
                        if (!n.isRead) {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .markRead(n.id);
                          ref.invalidate(dashboardStreamProvider);
                        }
                        onClose();
                        Future<void>.microtask(() {
                          ref
                              .read(goRouterProvider)
                              .push(_notificationsListUri(role));
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
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
                    : AppColors.surfaceElevatedOf(
                        context,
                      ).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _notificationsListUri(WayoAdsAccountRole role) {
  final r = switch (role) {
    WayoAdsAccountRole.creator => 'creator',
    WayoAdsAccountRole.advertiser => 'advertiser',
    _ => 'app',
  };
  return '/notifications?role=$r';
}

class _PopupNotificationTile extends StatelessWidget {
  const _PopupNotificationTile({
    required this.item,
    required this.muted,
    required this.onMarkRead,
    required this.onDismiss,
    required this.onOpenDetail,
  });

  final NotificationItem item;
  final Color muted;
  final Future<void> Function() onMarkRead;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final important = _isHighPriority(item.priority);
    final (icon, iconColor) = _iconFor(item, important);

    final dateStr = item.createdAt != null
        ? DateFormat.yMd(
            Localizations.localeOf(context).toString(),
          ).format(item.createdAt!.toLocal())
        : '';

    return InkWell(
      onTap: onOpenDetail,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 10),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (important)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        t.dashboard.notifications_important,
                        style: const TextStyle(
                          color: Color(0xFFFF4D4D),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: item.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(color: muted, fontSize: 11.5),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: muted,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: item.isRead
                        ? muted
                        : AppColors.textPrimaryOf(context),
                  ),
                  onPressed: () => onMarkRead(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  onPressed: () => onDismiss(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isHighPriority(String? p) {
  if (p == null) return false;
  return p.startsWith('P0') || p.startsWith('P1');
}

(IconData, Color) _iconFor(NotificationItem n, bool important) {
  if (important) {
    return (Icons.warning_amber_rounded, const Color(0xFFFFA500));
  }
  final ty = n.type?.toUpperCase() ?? '';
  if (ty.contains('CREDENTIALS') ||
      ty.contains('FRAUD') ||
      ty.contains('SUSPICIOUS')) {
    return (Icons.warning_amber_rounded, const Color(0xFFFFA500));
  }
  if (ty.contains('CAMPAIGN') ||
      ty.contains('CREATOR') ||
      ty.contains('VIDEO')) {
    return (Icons.info_outline_rounded, const Color(0xFFF4A237));
  }
  return (Icons.notifications_none_rounded, const Color(0xFFF4A237));
}
