import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/notification_item.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../utils/notification_route_resolver.dart';
import 'creator_application_notification_actions.dart';
import 'notification_time_groups.dart';

enum NotificationTileMode { popup, feed }

/// Single notification row — popup bell or full feed (web centre).
class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMarkRead,
    required this.onDismiss,
    this.onArchive,
    this.showArchiveAction = true,
    this.showActions = true,
    this.mode = NotificationTileMode.popup,
    this.role = WayoAdsAccountRole.unknown,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;
  final VoidCallback? onArchive;
  final bool showArchiveAction;
  final bool showActions;
  final NotificationTileMode mode;
  final WayoAdsAccountRole role;

  static const Color _bellColor = Color(0xFFF4A237);

  bool get _compact => mode == NotificationTileMode.popup;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? const Color(0xFF9A9A9A)
        : AppColors.textMutedOf(context);
    final urgent = item.showUrgentBadge;
    final hasAction = notificationCanNavigate(item, role);

    final unreadBg = item.isUnread
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.05))
        : (mode == NotificationTileMode.feed && !item.isUnread
            ? (isDark
                ? const Color(0xFF141414)
                : AppColors.surfaceElevatedOf(context).withValues(alpha: 0.5))
            : Colors.transparent);

    return Material(
      color: unreadBg,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mode == NotificationTileMode.feed && item.isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 18),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (!_compact && item.isUnread)
                Container(width: 3, color: _priorityAccent(item.priority)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _compact ? (item.isUnread ? 11 : 14) : 12,
                    _compact ? 10 : 16,
                    showActions ? 4 : 14,
                    _compact ? 10 : 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Icon(
                          _leadingIcon(item, urgent),
                          size: 22,
                          color: _leadingColor(item, urgent),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (mode == NotificationTileMode.feed && urgent)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF4D4D,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        t.dashboard.notifications_urgent,
                                        style: const TextStyle(
                                          color: Color(0xFFFF4D4D),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _relativeLabel(t, item.createdAt),
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_compact && urgent)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  t.dashboard.notifications_important,
                                  style: const TextStyle(
                                    color: Color(0xFFFF4D4D),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: item.isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: _compact ? 14 : 15,
                                height: 1.25,
                              ),
                            ),
                            if (item.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                maxLines: _compact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: _compact ? 12.5 : 13.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            CreatorApplicationNotificationActions(
                              item: item,
                              compact: _compact,
                            ),
                            if (mode == NotificationTileMode.feed) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    formatNotificationTimeOfDay(
                                      item.createdAt,
                                    ),
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (hasAction) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: onTap,
                                      child: Text(
                                        t.dashboard.notifications_view_details,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ] else if (item.createdAt != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _formatDate(item.createdAt),
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  if (hasAction) ...[
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: muted.withValues(alpha: 0.85),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showActions) _buildActions(context, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, dynamic t) {
    final useArchive = onArchive != null &&
        mode == NotificationTileMode.feed &&
        showArchiveAction &&
        !item.isArchived;
    return Padding(
      padding: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _ActionIconButton(
            icon: Icons.check_rounded,
            tooltip: t.dashboard.notifications_mark_read,
            enabled: item.isUnread,
            onPressed: () {
              HapticFeedback.selectionClick();
              onMarkRead();
            },
          ),
          if (useArchive || mode == NotificationTileMode.popup)
            _ActionIconButton(
              icon: useArchive ? Icons.archive_outlined : Icons.close_rounded,
              tooltip: useArchive
                  ? t.dashboard.notifications_archive
                  : t.dashboard.notifications_dismiss,
              onPressed: () {
                HapticFeedback.selectionClick();
                if (useArchive) {
                  onArchive!();
                } else {
                  onDismiss();
                }
              },
            ),
        ],
      ),
    );
  }

  String _relativeLabel(dynamic t, DateTime? at) {
    if (at == null) return '';
    final rel = formatNotificationRelativeTime(at);
    if (rel == 'now') return t.dashboard.notifications_just_now;
    final now = DateTime.now();
    final diff = now.difference(at.toLocal());
    if (diff.inMinutes < 60) {
      return t.dashboard.notifications_minutes_ago.replaceAll(
        '{n}',
        '${diff.inMinutes}',
      );
    }
    if (diff.inHours < 24) {
      return t.dashboard.notifications_hours_ago.replaceAll(
        '{n}',
        '${diff.inHours}',
      );
    }
    if (diff.inDays == 1) return t.chat.date_yesterday;
    if (diff.inDays < 7) {
      return t.dashboard.notifications_days_ago.replaceAll(
        '{n}',
        '${diff.inDays}',
      );
    }
    return _formatDate(at);
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  static Color _priorityAccent(String? p) {
    if (p == null) return AppColors.primary;
    if (p.startsWith('P0')) return const Color(0xFFFF4D4D);
    if (p.startsWith('P1')) return AppColors.primary;
    return AppColors.primary;
  }

  static IconData _leadingIcon(NotificationItem n, bool urgent) {
    if (urgent) return Icons.warning_amber_rounded;
    final ty = n.type?.toUpperCase() ?? '';
    if (ty.contains('FRAUD') || ty.contains('SUSPICIOUS')) {
      return Icons.error_outline_rounded;
    }
    return Icons.notifications_outlined;
  }

  static Color _leadingColor(NotificationItem n, bool urgent) {
    if (urgent) return AppColors.primary;
    final ty = n.type?.toUpperCase() ?? '';
    if (ty.contains('FRAUD') || ty.contains('SUSPICIOUS')) {
      return const Color(0xFFFF4D4D);
    }
    return _bellColor;
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? AppColors.textPrimaryOf(context)
        : AppColors.textMutedOf(context).withValues(alpha: 0.45);
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20, color: fg),
    );
  }
}
