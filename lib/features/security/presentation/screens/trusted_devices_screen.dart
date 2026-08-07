import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_system_nav_bar.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../app_settings/data/known_devices_remote.dart';
import '../../../app_settings/presentation/providers/known_devices_providers.dart';

class TrustedDevicesScreen extends ConsumerStatefulWidget {
  const TrustedDevicesScreen({super.key});

  @override
  ConsumerState<TrustedDevicesScreen> createState() =>
      _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends ConsumerState<TrustedDevicesScreen> {
  String? _revokingId;

  Future<void> _refresh() async {
    ref.invalidate(knownDevicesProvider);
    await ref.read(knownDevicesProvider.future);
  }

  Future<void> _revokeDevice(KnownDevice device) async {
    final t = context.t;
    final appSettings = t.app_settings;
    final confirmed = await showWayoConfirmDialog(
      context: context,
      title: appSettings.device_revoke_confirm_title,
      message: appSettings.device_revoke_confirm_desc,
      cancelLabel: appSettings.device_revoke_cancel,
      confirmLabel: appSettings.device_revoke_confirm,
      tone: WayoDialogTone.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() => _revokingId = device.id);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(knownDevicesRemoteProvider).revokeDevice(device.id);
      if (!mounted) return;
      _refresh();
      WayoToast.success(context, appSettings.device_revoked);
    } catch (_) {
      if (!mounted) return;
      WayoToast.error(context, appSettings.devices_error_revoke);
    } finally {
      if (mounted) setState(() => _revokingId = null);
    }
  }

  IconData _deviceIcon(KnownDevice device) {
    final platform = device.platform?.toLowerCase() ?? '';
    if (platform.contains('android')) return Icons.phone_android_rounded;
    if (platform.contains('ios') || platform.contains('iphone')) {
      return Icons.phone_iphone_rounded;
    }
    if (platform.contains('windows') || platform.contains('mac') ||
        platform.contains('linux')) {
      return Icons.computer_rounded;
    }
    if (device.deviceLabel?.toLowerCase().contains('phone') == true ||
        device.deviceLabel?.toLowerCase().contains('iphone') == true ||
        device.deviceLabel?.toLowerCase().contains('android') == true) {
      return Icons.smartphone_rounded;
    }
    if (device.deviceLabel?.toLowerCase().contains('tablet') == true ||
        device.deviceLabel?.toLowerCase().contains('ipad') == true) {
      return Icons.tablet_mac_rounded;
    }
    return Icons.devices_rounded;
  }

  String _deviceName(KnownDevice device) {
    final appSettings = context.t.app_settings;
    return device.deviceLabel?.isNotEmpty == true
        ? device.deviceLabel!
        : appSettings.device_unknown_device;
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.app_settings;
    final scheme = Theme.of(context).colorScheme;
    final devicesAsync = ref.watch(knownDevicesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: wayoSystemNavBarOverlay(context),
      child: Scaffold(
        backgroundColor: scheme.surface,
        bottomNavigationBar: const WayoSystemNavBarFill(),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 48,
                scrolledUnderElevation: 0,
                backgroundColor: scheme.surface.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                leadingWidth: 44,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  t.devices_nav_title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionHeader(
                      icon: Icons.verified_user_outlined,
                      title: t.devices_title,
                      subtitle: t.devices_desc,
                    ),
                    const SizedBox(height: 20),
                    devicesAsync.when(
                      data: (devices) {
                        if (devices.isEmpty) {
                          return _EmptyState(message: t.devices_empty)
                              .animate()
                              .fadeIn(duration: 280.ms);
                        }
                        return Column(
                          children: devices
                              .map(
                                (device) => _DeviceTile(
                                  device: device,
                                  isRevoking: _revokingId == device.id,
                                  deviceIcon: _deviceIcon(device),
                                  deviceName: _deviceName(device),
                                  formattedDate: _formatDate(
                                    device.firstSeenAt,
                                  ),
                                  onForget: () => _revokeDevice(device),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, _) => _ErrorState(
                        message: t.devices_error_load,
                        onRetry: _refresh,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isRevoking,
    required this.deviceIcon,
    required this.deviceName,
    required this.formattedDate,
    required this.onForget,
  });

  final KnownDevice device;
  final bool isRevoking;
  final IconData deviceIcon;
  final String deviceName;
  final String formattedDate;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final t = context.t.app_settings;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(deviceIcon, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            deviceName,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.current) ...[
                          const SizedBox(width: 6),
                          _CurrentBadge(label: t.device_this_device),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              if (!device.current) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: TextButton.icon(
                    onPressed: isRevoking ? null : onForget,
                    icon: isRevoking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                    label: Text(
                      isRevoking ? t.device_revoking : t.device_forget,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(
          begin: 0.03,
          curve: Curves.easeOutCubic,
        );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 40,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
