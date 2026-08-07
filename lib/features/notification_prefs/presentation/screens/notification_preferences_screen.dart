import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../app_settings/presentation/widgets/app_settings_notifications_tile.dart';
import '../../data/notification_prefs_remote.dart';
import '../../domain/notification_preferences.dart';

Future<void> openNotificationPreferencesScreen({
  VoidCallback? onClosePanel,
}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/settings/notifications');
    }
  });
}

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  String? _savingKey;
  NotificationPreferencesSnapshot? _local;

  List<String> _roleStrings() {
    final user = ref.read(currentAppUserProvider);
    final role = user?.wayoAdsRole;
    return switch (role) {
      WayoAdsAccountRole.creator => ['CREATOR'],
      WayoAdsAccountRole.advertiser => ['ADVERTISER'],
      WayoAdsAccountRole.superAdmin => ['CREATOR', 'ADVERTISER'],
      _ => const <String>[],
    };
  }

  Future<void> _patchChannel(String key, bool value) async {
    final prev = _local;
    if (prev == null) return;
    setState(() {
      _savingKey = key;
      _local = switch (key) {
        'allowInApp' => prev.copyWith(allowInApp: value),
        'allowEmail' => prev.copyWith(allowEmail: value),
        'allowSound' => prev.copyWith(allowSound: value),
        _ => prev,
      };
    });
    try {
      final next = await ref
          .read(notificationPrefsRemoteProvider)
          .patchChannel(key: key, value: value);
      if (!mounted) return;
      setState(() {
        _local = next;
        _savingKey = null;
      });
      ref.invalidate(notificationPreferencesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _local = prev;
        _savingKey = null;
      });
      final msg = e is AuthException ? e.toString() : context.t.app_settings.notif_prefs_error;
      WayoToast.error(context, msg);
    }
  }

  Future<void> _patchCategory(
    NotificationPrefCategory category,
    String channel,
    bool enabled,
  ) async {
    final prev = _local;
    if (prev == null) return;
    final saving = '${category.name}:$channel';
    final cats = Map<NotificationPrefCategory, CategoryChannelPrefs>.from(
      prev.categories,
    );
    final cur = cats[category] ?? const CategoryChannelPrefs();
    cats[category] = channel == 'email'
        ? cur.copyWith(email: enabled)
        : cur.copyWith(inApp: enabled);
    setState(() {
      _savingKey = saving;
      _local = prev.copyWith(categories: cats);
    });
    try {
      final next = await ref.read(notificationPrefsRemoteProvider).patchCategory(
            category: category,
            channel: channel,
            enabled: enabled,
          );
      if (!mounted) return;
      setState(() {
        _local = next;
        _savingKey = null;
      });
      ref.invalidate(notificationPreferencesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _local = prev;
        _savingKey = null;
      });
      WayoToast.error(context, context.t.app_settings.notif_prefs_error);
    }
  }

  String _categoryLabel(NotificationPrefCategory c, Translations t) {
    final n = t.app_settings;
    return switch (c) {
      NotificationPrefCategory.video => n.notif_cat_video,
      NotificationPrefCategory.applications => n.notif_cat_applications,
      NotificationPrefCategory.payouts => n.notif_cat_payouts,
      NotificationPrefCategory.wallet => n.notif_cat_wallet,
      NotificationPrefCategory.tokens => n.notif_cat_tokens,
      NotificationPrefCategory.campaigns => n.notif_cat_campaigns,
      NotificationPrefCategory.security => n.notif_cat_security,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.app_settings;
    final async = ref.watch(notificationPreferencesProvider);
    final visible = categoriesForRoles(_roleStrings());

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(t.notif_prefs_title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.notif_prefs_load_error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(notificationPreferencesProvider),
                  child: Text(t.notif_prefs_retry),
                ),
              ],
            ),
          ),
        ),
        data: (remote) {
          _local ??= remote;
          final prefs = _local ?? remote;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                t.notif_prefs_channels_title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                t.notif_prefs_channels_sub,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              _PrefSwitch(
                label: t.notif_prefs_in_app,
                value: prefs.allowInApp,
                busy: _savingKey == 'allowInApp',
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  _patchChannel('allowInApp', v);
                },
              ),
              _PrefSwitch(
                label: t.notif_prefs_email,
                value: prefs.allowEmail,
                busy: _savingKey == 'allowEmail',
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  _patchChannel('allowEmail', v);
                },
              ),
              _PrefSwitch(
                label: t.notif_prefs_sound,
                value: prefs.allowSound,
                busy: _savingKey == 'allowSound',
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  _patchChannel('allowSound', v);
                },
              ),
              const SizedBox(height: 20),
              Text(
                t.section_notifications,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const AppSettingsNotificationsTile(),
              const SizedBox(height: 24),
              Text(
                t.notif_prefs_categories_title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                t.notif_prefs_categories_sub,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              for (final cat in visible) ...[
                _CategoryCard(
                  title: _categoryLabel(cat, context.t),
                  inApp: prefs.categories[cat]?.inApp ?? true,
                  email: prefs.categories[cat]?.email ?? true,
                  busyInApp: _savingKey == '${cat.name}:inApp',
                  busyEmail: _savingKey == '${cat.name}:email',
                  inAppLabel: t.notif_prefs_in_app,
                  emailLabel: t.notif_prefs_email,
                  onInApp: (v) {
                    HapticFeedback.selectionClick();
                    _patchCategory(cat, 'inApp', v);
                  },
                  onEmail: (v) {
                    HapticFeedback.selectionClick();
                    _patchCategory(cat, 'email', v);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PrefSwitch extends StatelessWidget {
  const _PrefSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.busy,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: busy ? null : onChanged,
      secondary: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.inApp,
    required this.email,
    required this.onInApp,
    required this.onEmail,
    required this.busyInApp,
    required this.busyEmail,
    required this.inAppLabel,
    required this.emailLabel,
  });

  final String title;
  final bool inApp;
  final bool email;
  final ValueChanged<bool> onInApp;
  final ValueChanged<bool> onEmail;
  final bool busyInApp;
  final bool busyEmail;
  final String inAppLabel;
  final String emailLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(inAppLabel),
              value: inApp,
              onChanged: busyInApp ? null : onInApp,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(emailLabel),
              value: email,
              onChanged: busyEmail ? null : onEmail,
            ),
          ],
        ),
      ),
    );
  }
}
