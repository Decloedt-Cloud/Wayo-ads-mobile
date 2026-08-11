import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/network/auth_force_logout_hub.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/data/apple_sign_in_facade.dart';
import '../../../auth/data/auth_login_method_store.dart';
import '../../../auth/data/google_sign_in_facade.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../data/account_deletion_remote_datasource.dart';
import '../../domain/account_deletion_oauth_reauth.dart';
import '../../domain/account_deletion_realtime.dart' as deletion_rt;
import '../../domain/account_deletion_side_effects.dart';
import '../providers/account_deletion_providers.dart';

/// In-app account deletion: educate → password → confirm sheet → success (30-day grace, same as web API).
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  static const int graceDays = 30;
  static const int reminderDaysBeforePurge = 3;

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  WayoAdsDeletionProfile? _profile;
  bool _loadingProfile = true;
  String? _loadError;

  /// 0 intro, 1 password / OAuth re-auth, 2 success (scheduled or already pending).
  int _step = 0;
  bool _submitting = false;
  bool _cancelling = false;

  /// Fresh Google/Apple credential proving re-authentication for OAuth-only users.
  /// Consumed by the next [scheduleDeletion]; cleared after every attempt so a
  /// retry always requires a new sign-in (matches the web re-auth-to-delete step).
  Map<String, dynamic>? _pendingReauth;
  bool _reauthing = false;
  AuthLoginMethod? _lastLoginMethod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      unawaited(_loadLastLoginMethod());
    });
  }

  Future<void> _loadLastLoginMethod() async {
    final method = await AuthLoginMethodStore.read();
    if (!mounted) return;
    setState(() => _lastLoginMethod = method);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadingProfile = true;
      _loadError = null;
    });
    final ds = ref.read(accountDeletionRemoteProvider);
    try {
      final p = await ds.fetchProfile(bypassCache: true);
      if (!mounted) return;
      if (p.isAnonymized) {
        ref.read(accountDeletionScheduledAtProvider.notifier).clearScheduledAt();
        notifyAuthForceLogout();
        return;
      }
      final providerScheduled = ref.read(accountDeletionScheduledAtProvider);
      setState(() {
        _profile = p;
        _loadingProfile = false;
        if (p.deletionRequestedAt != null || providerScheduled != null) {
          _step = 2;
          if (p.deletionRequestedAt == null && providerScheduled != null) {
            _profile = p.withDeletionScheduledAt(providerScheduled);
          }
        }
      });
      ref
          .read(accountDeletionScheduledAtProvider.notifier)
          .applyFromProfile(p.deletionRequestedAt);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AccountDeletion] load failed: $e');
        debugPrintStack(stackTrace: st);
      }
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _loadError = _mapProfileLoadError(context, e);
      });
    }
  }

  PreferredSizeWidget _deletionAppBar(BuildContext context, String title) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
    );
  }

  String _mapProfileLoadError(BuildContext context, Object e) {
    final t = context.t.account_deletion;
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return t.error_load_unauthorized;
      }
      final tpe = e.type;
      if (tpe == DioExceptionType.connectionTimeout ||
          tpe == DioExceptionType.sendTimeout ||
          tpe == DioExceptionType.receiveTimeout ||
          tpe == DioExceptionType.connectionError ||
          tpe == DioExceptionType.badCertificate) {
        return t.error_load_network;
      }
    }
    return t.error_load;
  }

  String _fmtDate(DateTime d) {
    final loc = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(loc).format(d);
  }

  DateTime _purgeAt(DateTime requested) =>
      requested.add(const Duration(days: AccountDeletionScreen.graceDays));

  DateTime _reminderAt(DateTime requested) =>
      _purgeAt(requested).subtract(
        const Duration(days: AccountDeletionScreen.reminderDaysBeforePurge),
      );

  int _daysLeft(DateTime purgeLocal) {
    final now = DateTime.now();
    final a = DateTime(purgeLocal.year, purgeLocal.month, purgeLocal.day);
    final b = DateTime(now.year, now.month, now.day);
    return math.max(0, a.difference(b).inDays);
  }

  /// OAuth re-auth applies to Google/Apple-only accounts, and to users who signed
  /// in with a provider even when the profile API still reports password required.
  bool get _prefersOAuthReauth {
    final p = _profile;
    if (p == null) return false;
    if (!p.deletionRequiresPassword) return true;
    final m = _lastLoginMethod;
    return m == AuthLoginMethod.google || m == AuthLoginMethod.apple;
  }

  String _mapScheduleError(DioException e) {
    final t = context.t.account_deletion;
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String? serverError;
    if (data is Map) {
      final err = data['error'];
      if (err is String) serverError = err;
    }
    final err = serverError?.toLowerCase();
    if (code == 401 && err == 'reauth_required') {
      return t.error_reauth_required;
    }
    if (code == 403) {
      if (err == 'reauth_mismatch') {
        return t.oauth_reauth_mismatch;
      }
      if (err?.contains('superadmin') == true) {
        return t.error_superadmin;
      }
      return _prefersOAuthReauth ? t.error_reauth_required : t.error_password;
    }
    if (code == 400 && err?.contains('password') == true && _prefersOAuthReauth) {
      return t.error_reauth_required;
    }
    return t.error_delete;
  }

  Future<void> _showFinalDialog() async {
    final t = context.t.account_deletion;
    final requested = DateTime.now();
    final purge = _purgeAt(requested);
    final reminder = _reminderAt(requested);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Theme.of(ctx).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                t.dialog_title,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.dialog_body,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.tertiary.withValues(alpha: 0.45),
                  ),
                  color: Theme.of(ctx).colorScheme.tertiaryContainer.withValues(alpha: 0.35),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Theme.of(ctx).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.funds_warning,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _fmtDate(purge),
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _TimelineRow(
                labels: (
                  t.timeline_request,
                  t.timeline_reminder,
                  t.timeline_purge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.dialog_cancel_hint,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.reminder_approx(date: _fmtDate(reminder)),
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.labelMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t.dialog_confirm),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.dialog_dismiss),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true || !mounted) return;

    final p = _profile!;
    final reauthArg =
        (_pendingReauth != null && _pendingReauth!.isNotEmpty) ? _pendingReauth : null;
    String? passwordArg;
    if (reauthArg == null) {
      if (p.deletionRequiresPassword && !_prefersOAuthReauth) {
        passwordArg = _passwordController.text.trim();
        if (passwordArg.length < 8) {
          WayoToast.info(context, context.t.account_deletion.password_hint);
          return;
        }
      } else {
        WayoToast.error(context, context.t.account_deletion.error_reauth_required);
        return;
      }
    }

    setState(() => _submitting = true);
    final ds = ref.read(accountDeletionRemoteProvider);
    try {
      final res = await ds.scheduleDeletion(
        password:
            passwordArg != null && passwordArg.isNotEmpty ? passwordArg : null,
        reauth: reauthArg,
      );
      // Consume the single-use credential regardless of outcome.
      _pendingReauth = null;
      if (!mounted) return;

      DateTime? requestedFromPost;
      final parsedPost = deletion_rt.extractAccountDeletionStateFromPayload(res);
      requestedFromPost = parsedPost.deletionRequestedAt;
      final scheduledAt = requestedFromPost ?? DateTime.now().toUtc();
      ref
          .read(accountDeletionScheduledAtProvider.notifier)
          .setScheduledAt(scheduledAt);
      requestedFromPost = scheduledAt;

      await _load();
      if (!mounted) return;

      if (_profile?.deletionRequestedAt == null) {
        setState(() {
          _profile = _profile!.withDeletionScheduledAt(scheduledAt);
        });
      }

      if (!mounted) return;
      if (_profile == null) {
        setState(() => _submitting = false);
        WayoToast.error(context, context.t.account_deletion.error_delete);
        return;
      }

      await runAccountDeletionScheduledSideEffects(ref);

      setState(() {
        _submitting = false;
        _step = 2;
        _passwordController.clear();
      });
      ref.read(accountDeletionScheduledAtProvider.notifier).applyRealtimeSignal({
        'type': 'account.deletion_requested',
        'deletionRequestedAt': scheduledAt.toIso8601String(),
      });
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    } on DioException catch (e) {
      _pendingReauth = null;
      if (!mounted) return;
      setState(() => _submitting = false);
      WayoToast.error(context, _mapScheduleError(e));
    } catch (_) {
      _pendingReauth = null;
      if (!mounted) return;
      setState(() => _submitting = false);
      WayoToast.error(context, context.t.account_deletion.error_delete);
    }
  }

  /// Re-authenticates an OAuth-only user with [provider] ('google' | 'apple'),
  /// then opens the final confirmation sheet. The fresh credential is the mobile
  /// equivalent of the web "Re-authenticate to delete" step.
  Future<void> _reauthAndDelete(String provider) async {
    if (_reauthing || _submitting) return;
    final t = context.t.account_deletion;
    final loginT = context.t.login;
    setState(() => _reauthing = true);

    Map<String, dynamic>? reauth;
    try {
      if (provider == 'google') {
        final cid = AuthRuntimeConfig.instance.googleServerClientId;
        if (cid.isEmpty) {
          if (!mounted) return;
          setState(() => _reauthing = false);
          WayoToast.error(context, t.oauth_reauth_failed);
          return;
        }
        if (!AuthRuntimeConfig.looksLikeGoogleWebClientId(cid)) {
          if (!mounted) return;
          setState(() => _reauthing = false);
          WayoToast.error(context, loginT.google_wrong_client_id);
          return;
        }
        final idToken = await GoogleSignInFacade.signInForIdToken(cid);
        if (idToken == null || idToken.isEmpty) {
          if (!mounted) return;
          setState(() => _reauthing = false);
          WayoToast.info(context, t.oauth_reauth_cancelled);
          return;
        }
        reauth = buildGoogleDeletionReauth(idToken);
      } else {
        final cred = await AppleSignInFacade.signIn();
        if (cred == null) {
          if (!mounted) return;
          setState(() => _reauthing = false);
          WayoToast.info(context, t.oauth_reauth_cancelled);
          return;
        }
        reauth = buildAppleDeletionReauth(cred);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _reauthing = false);
      final msg = GoogleSignInFacade.isAndroidDeveloperConfigError(e)
          ? loginT.google_android_oauth_misconfigured
          : GoogleSignInFacade.looksLikeStaleChannel(e)
          ? loginT.google_channel_restart
          : t.oauth_reauth_failed;
      WayoToast.error(context, msg);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _reauthing = false);
      final cancelled = AppleSignInFacade.isUserCanceled(e);
      if (cancelled) {
        WayoToast.info(context, t.oauth_reauth_cancelled);
      } else {
        WayoToast.error(context, t.oauth_reauth_failed);
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _reauthing = false;
      _pendingReauth = reauth;
    });
    await _showFinalDialog();
  }

  List<Widget> _oauthReauthButtons(ColorScheme scheme) {
    final t = context.t.account_deletion;
    final busy = _reauthing || _submitting;

    Widget googleButton() => FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: busy ? null : () => _reauthAndDelete('google'),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.login_rounded, size: 20),
      label: Text(t.oauth_reauth_google),
    );

    Widget appleButton() => OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: busy ? null : () => _reauthAndDelete('apple'),
      icon: const Icon(Icons.apple, size: 20),
      label: Text(t.oauth_reauth_apple),
    );

    final showApple = AppleSignInFacade.isSupportedPlatform;
    final preferApple = _lastLoginMethod == AuthLoginMethod.apple;

    if (!showApple) {
      return [googleButton()];
    }

    if (preferApple) {
      return [
        appleButton(),
        const SizedBox(height: 10),
        googleButton(),
      ];
    }

    return [
      googleButton(),
      const SizedBox(height: 10),
      appleButton(),
    ];
  }

  Future<void> _cancelDeletion() async {
    setState(() => _cancelling = true);
    final ds = ref.read(accountDeletionRemoteProvider);
    try {
      await ds.cancelScheduledDeletion();
      if (!mounted) return;
      ref.read(accountDeletionScheduledAtProvider.notifier).clearScheduledAt();
      await _load();
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _step = 0;
      });
      WayoToast.success(context, context.t.account_deletion.toast_cancelled);
      HapticFeedback.lightImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      WayoToast.error(context, context.t.account_deletion.error_delete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.account_deletion;
    final scheme = Theme.of(context).colorScheme;
    final role = ref.watch(currentWayoAdsAccountRoleProvider);

    if (role == WayoAdsAccountRole.superAdmin) {
      return Scaffold(
        appBar: _deletionAppBar(context, t.nav_title),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t.error_superadmin,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    if (_loadingProfile) {
      return Scaffold(
        appBar: _deletionAppBar(context, t.nav_title),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: _deletionAppBar(context, t.nav_title),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: Text(context.t.connectivity.action_retry)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _deletionAppBar(context, t.nav_title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: switch (_step) {
            0 => _buildIntro(context, scheme),
            1 => _buildAuth(context, scheme),
            2 => _buildSuccess(context, scheme),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, ColorScheme scheme) {
    final t = context.t.account_deletion;
    final p = _profile!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.error.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.priority_high_rounded, color: scheme.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.subtitle_warning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      t.danger_zone_chip,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t.danger_zone_intro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.danger_what_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _DangerItemRow(text: t.danger_item_profile, scheme: scheme),
                if (p.hasAdvertiserRole || p.hasCreatorRole)
                  _DangerItemRow(text: t.danger_item_campaigns, scheme: scheme),
                if (p.hasAdvertiserRole) ...[
                  _DangerItemRow(text: t.danger_item_business, scheme: scheme),
                  _DangerItemRow(text: t.danger_item_wallet, scheme: scheme),
                ],
                _DangerItemRow(text: t.danger_item_notifications, scheme: scheme),
                _DangerItemRow(text: t.danger_item_access, scheme: scheme),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.danger_wayo_note,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_prefersOAuthReauth) ...[
          const SizedBox(height: 16),
          Text(
            t.oauth_deletion_intro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (p.hasAdvertiserRole) ...[
          const SizedBox(height: 12),
          Text(
            t.role_advertiser,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        if (p.hasCreatorRole) ...[
          const SizedBox(height: 6),
          Text(
            t.role_creator,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {
            showWayoDialog<void>(
              context: context,
              builder: (c) => WayoAlertDialog(
                title: Text(t.more_info_title),
                content: SingleChildScrollView(child: Text(t.more_info_body)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(MaterialLocalizations.of(c).okButtonLabel),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.info_outline_rounded),
          label: Text(t.more_info_title),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => setState(() => _step = 1),
          child: Text(t.continue_cta),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => context.pop(),
          child: Text(t.back),
        ),
      ],
    );
  }

  Widget _buildAuth(BuildContext context, ColorScheme scheme) {
    final t = context.t.account_deletion;
    final p = _profile!;
    final providerScheduled = ref.watch(accountDeletionScheduledAtProvider);
    final requested = p.deletionRequestedAt ?? providerScheduled;
    final hasPending = requested != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.step_auth_title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: hasPending
                ? scheme.errorContainer.withValues(alpha: 0.35)
                : scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  hasPending ? Icons.schedule_rounded : Icons.check_circle_outline,
                  color: hasPending ? scheme.error : scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasPending
                        ? t.status_pending(date: _fmtDate(_purgeAt(requested)))
                        : t.status_active,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasPending) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _cancelling ? null : _cancelDeletion,
            child: _cancelling
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.cancel_request),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _step = 0),
            child: Text(t.back),
          ),
        ] else ...[
          if (p.deletionRequiresPassword && !_prefersOAuthReauth) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: t.password_label,
                hintText: t.password_hint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _trySubmit(),
            ),
            const SizedBox(height: 8),
            Text(
              t.oauth_note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(t.forgot_password),
              ),
            ),
            Text(
              t.legal_recap(date: _fmtDate(_purgeAt(DateTime.now()))),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: (_submitting || _passwordController.text.length < 8)
                  ? null
                  : _trySubmit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.next_review),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              t.oauth_reauth_intro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.legal_recap(date: _fmtDate(_purgeAt(DateTime.now()))),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ..._oauthReauthButtons(scheme),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed:
                _submitting ? null : () => setState(() => _step = 0),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(t.back),
          ),
        ],
      ],
    );
  }

  void _trySubmit() {
    FocusScope.of(context).unfocus();
    if (_prefersOAuthReauth) return;
    final pw = _passwordController.text;
    if (pw.length < 8) return;
    _showFinalDialog();
  }

  Widget _buildSuccess(BuildContext context, ColorScheme scheme) {
    final t = context.t.account_deletion;
    final requested =
        _profile!.deletionRequestedAt ??
        ref.watch(accountDeletionScheduledAtProvider);
    if (requested == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.error_delete, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadingProfile ? null : _load,
            child: Text(context.t.connectivity.action_retry),
          ),
        ],
      );
    }
    final purge = _purgeAt(requested);
    final reminder = _reminderAt(requested);
    final days = _daysLeft(purge);
    final theme = Theme.of(context);
    final grace = AccountDeletionScreen.graceDays;
    final progressGrace = grace <= 0
        ? 0.0
        : ((grace - days) / grace).clamp(0.0, 1.0);
    final daysRemainingLabel = days == 1
        ? t.pending_days_remaining_one
        : t.pending_days_remaining_plural(n: days);
    final accent = scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_rounded, size: 64, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          t.success_title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.success_intro,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _Bullet(text: t.success_use_until, negative: false),
        _Bullet(text: t.success_reminder, negative: false),
        _Bullet(text: t.success_cancel_anytime, negative: false),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.pending_scheduled_status,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Semantics(
                          label: daysRemainingLabel,
                          hint: t.pending_scheduled_status,
                          child: LinearProgressIndicator(
                            value: progressGrace,
                            minHeight: 8,
                            backgroundColor: accent.withValues(alpha: 0.22),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      daysRemainingLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t.purge_date(date: _fmtDate(purge)),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.reminder_approx(date: _fmtDate(reminder)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _cancelling ? null : _cancelDeletion,
          child: _cancelling
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Text(t.cancel_request),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => context.go('/dashboard'),
          child: Text(t.go_home),
        ),
      ],
    );
  }
}

class _DangerItemRow extends StatelessWidget {
  const _DangerItemRow({required this.text, required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.remove_circle_outline_rounded,
              size: 20,
              color: scheme.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.negative});

  final String text;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              negative ? Icons.close_rounded : Icons.check_rounded,
              size: 18,
              color: negative ? scheme.error : scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.labels});

  final (String, String, String) labels;

  @override
  Widget build(BuildContext context) {
    final (a, b, c) = labels;
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        Expanded(child: Text(a, style: style, textAlign: TextAlign.center)),
        Icon(Icons.arrow_forward_rounded, size: 16, color: Theme.of(context).colorScheme.outline),
        Expanded(child: Text(b, style: style, textAlign: TextAlign.center)),
        Icon(Icons.arrow_forward_rounded, size: 16, color: Theme.of(context).colorScheme.outline),
        Expanded(child: Text(c, style: style, textAlign: TextAlign.center)),
      ],
    );
  }
}
