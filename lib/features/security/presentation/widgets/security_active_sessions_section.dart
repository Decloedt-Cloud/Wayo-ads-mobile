import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../app_settings/data/active_sessions_remote.dart';
import '../../../app_settings/presentation/providers/active_sessions_providers.dart';

/// Active sessions list — web settings security card parity.
class SecurityActiveSessionsSection extends ConsumerStatefulWidget {
  const SecurityActiveSessionsSection({super.key});

  @override
  ConsumerState<SecurityActiveSessionsSection> createState() =>
      _SecurityActiveSessionsSectionState();
}

class _SecurityActiveSessionsSectionState
    extends ConsumerState<SecurityActiveSessionsSection> {
  String? _revokingId;
  var _revokingOthers = false;
  String? _inlineError;
  final Set<String> _optimisticallyRevoked = <String>{};

  String _locale(AppLocale l) => switch (l) {
    AppLocale.fr => 'fr_FR',
    AppLocale.ar => 'ar_MA',
    AppLocale.en => 'en_US',
  };

  Future<List<ActiveSession>> _reload() async {
    ref.invalidate(activeSessionsProvider);
    return ref.read(activeSessionsProvider.future);
  }

  Future<void> _revokeOne(ActiveSession session) async {
    final t = context.t;
    final confirmed = await showWayoConfirmDialog(
      context: context,
      title: t.app_settings.session_revoke_confirm_title,
      message: t.app_settings.session_revoke_confirm_desc,
      cancelLabel: t.app_settings.session_revoke_cancel,
      confirmLabel: t.app_settings.session_revoke_confirm,
      tone: WayoDialogTone.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _revokingId = session.id;
      _inlineError = null;
    });
    try {
      await ref.read(activeSessionsRemoteProvider).revokeSession(session.id);
      if (mounted) {
        setState(() => _optimisticallyRevoked.add(session.id));
      }
      final fresh = await _reload();
      if (!mounted) return;
      final stillActive = fresh.any((s) => s.id == session.id);
      setState(() {
        if (stillActive) {
          _optimisticallyRevoked.remove(session.id);
          _inlineError = t.app_settings.sessions_error_revoke;
        } else {
          _optimisticallyRevoked.remove(session.id);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _optimisticallyRevoked.remove(session.id);
          _inlineError = t.app_settings.sessions_error_revoke;
        });
      }
    } finally {
      if (mounted) setState(() => _revokingId = null);
    }
  }

  Future<void> _revokeOthers() async {
    final t = context.t;
    final confirmed = await showWayoConfirmDialog(
      context: context,
      title: t.app_settings.session_revoke_others_confirm_title,
      message: t.app_settings.session_revoke_others_confirm_desc,
      cancelLabel: t.app_settings.session_revoke_cancel,
      confirmLabel: t.app_settings.session_revoke_confirm,
      tone: WayoDialogTone.destructive,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _revokingOthers = true;
      _inlineError = null;
    });
    try {
      final localId = ref.read(mobileSessionIdProvider).valueOrNull;
      final current = ref.read(activeSessionsProvider).valueOrNull ?? const [];
      await ref.read(activeSessionsRemoteProvider).revokeOtherSessions();
      if (mounted) {
        setState(() {
          for (final s in current) {
            if (!_isThisDevice(s, localId)) {
              _optimisticallyRevoked.add(s.id);
            }
          }
        });
      }
      final fresh = await _reload();
      if (!mounted) return;
      final remainingOthers =
          fresh.where((s) => !_isThisDevice(s, localId)).map((s) => s.id).toSet();
      setState(() {
        _optimisticallyRevoked.removeWhere(remainingOthers.contains);
        if (remainingOthers.isNotEmpty) {
          _inlineError = t.app_settings.sessions_error_revoke;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _optimisticallyRevoked.clear();
          _inlineError = t.app_settings.sessions_error_revoke;
        });
      }
    } finally {
      if (mounted) setState(() => _revokingOthers = false);
    }
  }

  bool _isThisDevice(ActiveSession s, String? localSessionId) {
    if (s.current) return true;
    if (localSessionId != null &&
        localSessionId.isNotEmpty &&
        s.id == localSessionId) {
      return true;
    }
    return false;
  }

  IconData _deviceIcon(ActiveSession s) {
    final plat = (s.platform ?? '').toLowerCase();
    if (plat == 'android' || plat == 'ios' || plat == 'mobile') {
      return Icons.smartphone_rounded;
    }
    final hay = (s.deviceLabel ?? '').toLowerCase();
    if (hay.contains('android') ||
        hay.contains('iphone') ||
        hay.contains('mobile') ||
        hay.contains('wayo ads on')) {
      return Icons.smartphone_rounded;
    }
    if (hay.contains('ipad') || hay.contains('tablet')) {
      return Icons.tablet_rounded;
    }
    return Icons.computer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = _locale(ref.watch(localeProvider));
    final fmt = DateFormat.yMMMd(locale).add_jm();
    final async = ref.watch(activeSessionsProvider);
    final localSessionId = ref.watch(mobileSessionIdProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => Text(
        t.app_settings.sessions_error_load,
        style: TextStyle(color: AppColors.error, fontSize: 13),
      ),
      data: (allSessions) {
        final sessions = allSessions
            .where((s) => !_optimisticallyRevoked.contains(s.id))
            .toList(growable: false);
        if (sessions.isEmpty) {
          return Text(
            t.app_settings.sessions_empty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          );
        }

        final others =
            sessions.where((s) => !_isThisDevice(s, localSessionId)).toList();

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
              final isThisDevice = _isThisDevice(s, localSessionId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.surface.withValues(
                      alpha: isThisDevice ? 0.55 : 0.35,
                    ),
                    border: Border.all(
                      color: isThisDevice
                          ? AppColors.primary.withValues(alpha: 0.85)
                          : scheme.outlineVariant.withValues(alpha: 0.45),
                      width: isThisDevice ? 1.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _deviceIcon(s),
                              size: 20,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  if (isThisDevice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        t.app_settings.session_this_device,
                                        style: const TextStyle(
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
                        if (!isThisDevice) ...[
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _revokeOne(s);
                                  },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _revokingId == s.id
                                  ? t.app_settings.session_revoking
                                  : t.app_settings.session_revoke,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
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
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
