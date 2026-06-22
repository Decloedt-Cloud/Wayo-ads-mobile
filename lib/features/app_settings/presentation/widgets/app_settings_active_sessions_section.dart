import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/active_sessions_remote.dart';
import '../providers/active_sessions_providers.dart';

/// Active browser sessions — mirrors web settings security card.
class AppSettingsActiveSessionsSection extends ConsumerStatefulWidget {
  const AppSettingsActiveSessionsSection({super.key});

  @override
  ConsumerState<AppSettingsActiveSessionsSection> createState() =>
      _AppSettingsActiveSessionsSectionState();
}

class _AppSettingsActiveSessionsSectionState
    extends ConsumerState<AppSettingsActiveSessionsSection> {
  String? _revokingId;
  var _revokingOthers = false;
  String? _inlineError;

  String _locale(AppLocale l) => switch (l) {
    AppLocale.fr => 'fr_FR',
    AppLocale.ar => 'ar_MA',
    AppLocale.en => 'en_US',
  };

  Future<void> _reload() async {
    ref.invalidate(activeSessionsProvider);
    await ref.read(activeSessionsProvider.future);
  }

  Future<void> _revokeOne(ActiveSession session) async {
    final t = context.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.app_settings.session_revoke_confirm_title),
        content: Text(t.app_settings.session_revoke_confirm_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.app_settings.session_revoke_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t.app_settings.session_revoke_confirm,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _revokingId = session.id;
      _inlineError = null;
    });
    try {
      await ref.read(activeSessionsRemoteProvider).revokeSession(session.id);
      await _reload();
    } catch (_) {
      if (mounted) {
        setState(() => _inlineError = t.app_settings.sessions_error_revoke);
      }
    } finally {
      if (mounted) setState(() => _revokingId = null);
    }
  }

  Future<void> _revokeOthers() async {
    final t = context.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.app_settings.session_revoke_others_confirm_title),
        content: Text(t.app_settings.session_revoke_others_confirm_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.app_settings.session_revoke_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t.app_settings.session_revoke_confirm,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _revokingOthers = true;
      _inlineError = null;
    });
    try {
      await ref.read(activeSessionsRemoteProvider).revokeOtherSessions();
      await _reload();
    } catch (_) {
      if (mounted) {
        setState(() => _inlineError = t.app_settings.sessions_error_revoke);
      }
    } finally {
      if (mounted) setState(() => _revokingOthers = false);
    }
  }

  IconData _deviceIcon(ActiveSession s) {
    final plat = (s.platform ?? '').toLowerCase();
    if (plat == 'android' || plat == 'ios' || plat == 'mobile') {
      return Icons.smartphone_outlined;
    }
    final hay = (s.deviceLabel ?? '').toLowerCase();
    if (hay.contains('wayo ads on android') ||
        hay.contains('wayo ads on iphone') ||
        hay.contains('iphone') ||
        hay.contains('android') ||
        hay.contains('mobile')) {
      return Icons.smartphone_outlined;
    }
    if (hay.contains('ipad') || hay.contains('tablet')) {
      return Icons.tablet_outlined;
    }
    return Icons.computer_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = _locale(ref.watch(localeProvider));
    final fmt = DateFormat.yMMMd(locale).add_jm();
    final async = ref.watch(activeSessionsProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => Text(
        t.app_settings.sessions_error_load,
        style: TextStyle(color: AppColors.error, fontSize: 13),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Text(
            t.app_settings.sessions_empty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        final others = sessions.where((s) => !s.current).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_inlineError != null) ...[
              Text(
                _inlineError!,
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            ...sessions.map((s) {
              final busy = _revokingId == s.id || _revokingOthers;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _deviceIcon(s),
                          size: 20,
                          color: AppColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.deviceLabel?.trim().isNotEmpty == true
                                          ? s.deviceLabel!.trim()
                                          : t.app_settings
                                              .session_unknown_device,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (s.current)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        t.app_settings.session_this_device,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (s.ipAddress?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  s.ipAddress!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMutedOf(context),
                                      ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${t.app_settings.session_last_active}: ${fmt.format(s.lastSeenAt.toLocal())}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMutedOf(context),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (!s.current) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _revokeOne(s);
                                  },
                            child: Text(
                              _revokingId == s.id
                                  ? t.app_settings.session_revoking
                                  : t.app_settings.session_revoke,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (others.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _revokingOthers || _revokingId != null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _revokeOthers();
                        },
                  child: Text(
                    _revokingOthers
                        ? t.app_settings.session_revoking
                        : t.app_settings.session_revoke_others,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
