import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../domain/entities/announcement.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/superadmin_chrome_actions.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [
          SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnouncementForm(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: announcementsAsync.when(
        data: (announcements) => announcements.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(announcementsNotifierProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) => _AnnouncementCard(
                    announcement: announcements[index],
                    onEdit: () => _showAnnouncementForm(
                      context,
                      ref,
                      announcement: announcements[index],
                    ),
                    onDelete: () => _confirmDelete(
                      context,
                      ref,
                      announcements[index],
                    ),
                    onToggle: () => _toggleActive(
                      context,
                      ref,
                      announcements[index],
                    ),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load announcements',
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(announcementsNotifierProvider),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.textMutedOf(context).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+" to create your first announcement',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnnouncementForm(
    BuildContext context,
    WidgetRef ref, {
    Announcement? announcement,
  }) async {
    final result = await showModalBottomSheet<Announcement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnnouncementFormSheet(
        announcement: announcement,
      ),
    );

    if (result != null) {
      final notifier = ref.read(announcementsNotifierProvider.notifier);
      final success = announcement != null
          ? await notifier.updateAnnouncement(announcement.id, result)
          : await notifier.create(result);

      if (context.mounted) {
        if (success) {
          WayoToast.success(
            context,
            announcement != null ? 'Updated' : 'Created',
          );
        } else {
          WayoToast.error(context, 'Failed to save');
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Announcement announcement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
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
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(announcementsNotifierProvider.notifier)
          .deleteAnnouncement(announcement.id);
      if (context.mounted) {
        if (success) {
          WayoToast.success(context, 'Deleted');
        } else {
          WayoToast.error(context, 'Failed to delete');
        }
      }
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    Announcement announcement,
  ) async {
    final updated = announcement.copyWith(active: !announcement.active);
    final success = await ref
        .read(announcementsNotifierProvider.notifier)
        .updateAnnouncement(announcement.id, updated);

    if (context.mounted) {
      if (success) {
        WayoToast.success(
          context,
          updated.active ? 'Activated' : 'Deactivated',
        );
      } else {
        WayoToast.error(context, 'Failed to update');
      }
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Announcement announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  static final _dateFormat = DateFormat('MMM d, yyyy');

  Color _typeColor() {
    switch (announcement.type) {
      case AnnouncementType.info:
        return const Color(0xFF3B82F6);
      case AnnouncementType.warning:
        return const Color(0xFFF59E0B);
      case AnnouncementType.success:
        return AppColors.success;
      case AnnouncementType.urgent:
        return AppColors.error;
    }
  }

  IconData _typeIcon() {
    switch (announcement.type) {
      case AnnouncementType.info:
        return Icons.info_outline_rounded;
      case AnnouncementType.warning:
        return Icons.warning_amber_rounded;
      case AnnouncementType.success:
        return Icons.check_circle_rounded;
      case AnnouncementType.urgent:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.55) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: announcement.active
              ? typeColor.withValues(alpha: 0.35)
              : AppColors.borderOf(context).withValues(alpha: 0.25),
          width: announcement.active ? 1.5 : 1,
        ),
        boxShadow: [
          if (announcement.active)
            BoxShadow(
              color: typeColor.withValues(alpha: isDark ? 0.06 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Icon(_typeIcon(), size: 18, color: typeColor),
                const SizedBox(width: 8),
                Text(
                  announcement.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    announcement.targetAudience.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
                const Spacer(),
                if (!announcement.active)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimaryOf(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.sort_rounded, size: 14, color: AppColors.textMutedOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Order: ${announcement.order}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textMutedOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      _dateFormat.format(announcement.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: announcement.active,
                      onChanged: (_) => onToggle(),
                      activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.borderOf(context).withValues(alpha: 0.2),
          ),
          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryOf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: AppColors.borderOf(context).withValues(alpha: 0.2),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

class _AnnouncementFormSheet extends StatefulWidget {
  const _AnnouncementFormSheet({this.announcement});

  final Announcement? announcement;

  @override
  State<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<_AnnouncementFormSheet> {
  late final TextEditingController _messageController;
  late AnnouncementType _type;
  late AnnouncementAudience _audience;
  late bool _active;
  late int _order;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.announcement?.message ?? '',
    );
    _type = widget.announcement?.type ?? AnnouncementType.info;
    _audience = widget.announcement?.targetAudience ?? AnnouncementAudience.all;
    _active = widget.announcement?.active ?? true;
    _order = widget.announcement?.order ?? 0;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primarySoft.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.announcement != null
                      ? 'Edit Announcement'
                      : 'New Announcement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                    letterSpacing: -0.3,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Message
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Enter announcement message...',
                      filled: true,
                      fillColor: AppColors.surfaceElevatedOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Type
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AnnouncementType.values.map((type) {
                      final isSelected = _type == type;
                      final tc = _getTypeColor(type);
                      return GestureDetector(
                        onTap: () => setState(() => _type = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tc.withValues(alpha: 0.15)
                                : AppColors.surfaceElevatedOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? tc
                                  : AppColors.borderOf(context).withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getTypeIcon(type), size: 16, color: isSelected ? tc : null),
                              const SizedBox(width: 6),
                              Text(
                                type.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? tc : AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Target audience
                  Text(
                    'Target Audience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AnnouncementAudience.values.map((audience) {
                      final isSelected = _audience == audience;
                      return GestureDetector(
                        onTap: () => setState(() => _audience = audience),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surfaceElevatedOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderOf(context).withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            audience.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Order and Active toggle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryOf(context),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    onPressed: _order > 0
                                        ? () => setState(() => _order--)
                                        : null,
                                    icon: Icon(
                                      Icons.remove_rounded,
                                      color: _order > 0
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '$_order',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    onPressed: _order < 999
                                        ? () => setState(() => _order++)
                                        : null,
                                    icon: Icon(
                                      Icons.add_rounded,
                                      color: _order < 999
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryOf(context),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Switch(
                            value: _active,
                            onChanged: (v) => setState(() => _active = v),
                            activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                            activeThumbColor: AppColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _messageController.text.isNotEmpty
                    ? () {
                        final announcement = Announcement(
                          id: widget.announcement?.id ?? '',
                          message: _messageController.text,
                          type: _type,
                          targetAudience: _audience,
                          active: _active,
                          order: _order,
                          createdAt: widget.announcement?.createdAt ?? DateTime.now(),
                        );
                        Navigator.pop(context, announcement);
                      }
                    : null,
                icon: Icon(
                  widget.announcement != null ? Icons.save_rounded : Icons.add_rounded,
                ),
                label: Text(widget.announcement != null ? 'Update' : 'Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.info:
        return const Color(0xFF3B82F6);
      case AnnouncementType.warning:
        return const Color(0xFFF59E0B);
      case AnnouncementType.success:
        return AppColors.success;
      case AnnouncementType.urgent:
        return AppColors.error;
    }
  }

  IconData _getTypeIcon(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.info:
        return Icons.info_outline_rounded;
      case AnnouncementType.warning:
        return Icons.warning_amber_rounded;
      case AnnouncementType.success:
        return Icons.check_circle_rounded;
      case AnnouncementType.urgent:
        return Icons.error_outline_rounded;
    }
  }
}
