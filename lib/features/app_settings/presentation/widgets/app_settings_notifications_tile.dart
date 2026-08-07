import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/push/system_push_permission.dart';
import '../../../../core/push/push_notifications_status_provider.dart';
import '../../../../core/push/user_push_notifications_preference.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';

/// Push notifications toggle in the preferences panel (creator + advertiser).
class AppSettingsNotificationsTile extends ConsumerStatefulWidget {
  const AppSettingsNotificationsTile({super.key});

  @override
  ConsumerState<AppSettingsNotificationsTile> createState() =>
      _AppSettingsNotificationsTileState();
}

class _AppSettingsNotificationsTileState
    extends ConsumerState<AppSettingsNotificationsTile> {
  bool _userEnabled = true;
  bool _systemGranted = false;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_reload());
    });
  }

  Future<void> _reload() async {
    final prefs = ref.read(appPrefsProvider);
    final enabled = await isUserPushNotificationsEnabled(prefs);
    final granted = await areSystemPushNotificationsGranted();
    if (!mounted) return;
    setState(() {
      _userEnabled = enabled;
      _systemGranted = granted;
      _loaded = true;
    });
  }

  String _statusLabel(Translations t) {
    if (!_userEnabled) {
      return t.app_settings.notifications_status_disabled;
    }
    if (!_systemGranted) {
      return t.app_settings.notifications_status_permission_denied;
    }
    return t.app_settings.notifications_status_enabled;
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    final t = context.t;
    final prefs = ref.read(appPrefsProvider);
    final dio = ref.read(wayoAdsDioProvider);
    try {
      if (value) {
        final ok = await enableUserPushNotifications(
          wayoAdsDio: dio,
          prefs: prefs,
        );
        if (!mounted) return;
        if (!ok) {
          WayoToast.error(
            context,
            t.app_settings.notifications_enable_error,
            duration: const Duration(seconds: 6),
          );
        }
      } else {
        await disableUserPushNotifications(wayoAdsDio: dio, prefs: prefs);
      }
      await _reload();
      ref.read(pushNotificationsActiveProvider.notifier).refresh();
    } catch (_) {
      if (mounted) {
        WayoToast.error(context, t.app_settings.notifications_update_error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final showSettingsLink =
        _userEnabled && !_systemGranted && !_busy;

    return Material(
      color: scheme.surface.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: scheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.app_settings.notifications_toggle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch.adaptive(
                    value: _userEnabled,
                    onChanged: _onChanged,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 6, top: 2),
              child: Text(
                _statusLabel(t),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            if (showSettingsLink) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => unawaited(openAppSettings()),
                  child: Text(t.app_settings.notifications_open_settings),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
