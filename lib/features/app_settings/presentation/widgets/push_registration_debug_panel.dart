import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/observability/app_log.dart' show kWayoShowPushDebugUi;
import '../../../../core/providers/app_providers.dart';
import '../../../../core/push/push_registration_debug.dart';
import '../../../../core/push/user_push_notifications_preference.dart';

/// FCM registration diagnostics — visible in debug builds only ([kWayoShowPushDebugUi]).
class PushRegistrationDebugPanel extends ConsumerStatefulWidget {
  const PushRegistrationDebugPanel({super.key});

  @override
  ConsumerState<PushRegistrationDebugPanel> createState() =>
      _PushRegistrationDebugPanelState();
}

class _PushRegistrationDebugPanelState
    extends ConsumerState<PushRegistrationDebugPanel> {
  Map<String, String>? _snapshot;
  bool _loading = false;
  bool? _lastEnableOk;

  bool get _visible => kWayoShowPushDebugUi;

  @override
  void initState() {
    super.initState();
    if (_visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
    }
  }

  Future<void> _refresh() async {
    if (!_visible) return;
    setState(() => _loading = true);
    final snap = await PushRegistrationDebug.collectSnapshot(
      ref.read(appPrefsProvider),
    );
    if (!mounted) return;
    setState(() {
      _snapshot = snap;
      _loading = false;
    });
  }

  Future<void> _retryEnable() async {
    setState(() => _loading = true);
    final ok = await enableUserPushNotifications(
      wayoAdsDio: ref.read(wayoAdsDioProvider),
      prefs: ref.read(appPrefsProvider),
    );
    if (!mounted) return;
    setState(() => _lastEnableOk = ok);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final failure = PushRegistrationDebug.failureSummary;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'FCM debug (temp)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Permission: ${PushRegistrationDebug.lastPermissionGranted == true ? "granted" : PushRegistrationDebug.lastPermissionGranted == false ? "denied" : "?"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onErrorContainer,
                ),
              ),
              Text(
                'Token: ${PushRegistrationDebug.lastTokenPreview ?? "(not fetched)"}',
                style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
              ),
              Text(
                'Register: ${PushRegistrationDebug.lastRegisteredUserId ?? "(none)"} '
                'HTTP ${PushRegistrationDebug.lastHttpStatus ?? "-"}',
                style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
              ),
              if (failure != 'OK')
                Text(
                  'Last error: $failure',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                ),
              if (_lastEnableOk != null)
                Text(
                  'Retry result: ${_lastEnableOk! ? "SUCCESS" : "FAILED"}',
                  style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
                ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_snapshot != null)
                ..._snapshot!.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontFamily: 'monospace',
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => unawaited(_refresh()),
                    child: const Text('Refresh'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => unawaited(_retryEnable()),
                    child: const Text('Retry register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
