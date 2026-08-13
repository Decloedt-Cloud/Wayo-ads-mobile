import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_system_nav_bar.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import 'passkey_exceptions.dart';
import 'passkey_feature_flags.dart';
import 'passkey_missing_sheet.dart';
import 'passkey_models.dart';
import 'passkey_service.dart';

/// Native passkey list / add / rename / revoke — aligned with Security settings chrome.
class PasskeysManageScreen extends ConsumerStatefulWidget {
  const PasskeysManageScreen({super.key});

  @override
  ConsumerState<PasskeysManageScreen> createState() =>
      _PasskeysManageScreenState();
}

class _PasskeysManageScreenState extends ConsumerState<PasskeysManageScreen> {
  List<PasskeyInfo>? _items;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  bool _canRegister = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    final flags = await PasskeyFeatureFlags.resolve();
    if (!mounted) return;
    setState(() => _canRegister = flags.registration);
    await _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(passkeyServiceProvider).listPasskeys();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return DateFormat.yMMMd().format(d.toLocal());
  }

  Future<void> _add() async {
    if (_busy || !_canRegister) return;
    final t = context.t.app_settings;
    final loginT = context.t.login;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(passkeyServiceProvider).createPasskey(
            friendlyName: t.passkeys_default_name,
          );
      if (!mounted) return;
      await showPasskeyCreatedSheet(
        context,
        title: loginT.passkey_created_title,
        body: loginT.passkey_created_body,
        actionLabel: loginT.passkey_created_action,
      );
      await _reload();
    } on PasskeyCancelled {
      // Quiet cancel — provider/OS refused or user dismissed.
    } on PasskeyAlreadyExists {
      // OS already showed its dialog; follow with calm Wayo copy (no red toast).
      if (!mounted) return;
      final empty = _items == null || _items!.isEmpty;
      await showPasskeyInfoSheet(
        context,
        title: empty ? t.passkeys_stale_title : t.passkeys_already_title,
        body: empty ? t.passkeys_stale_body : t.passkeys_already_body,
        actionLabel: t.passkeys_already_action,
        icon: Icons.vpn_key_rounded,
      );
    } on PasskeyLimitReached {
      if (!mounted) return;
      WayoToast.info(context, t.passkeys_limit_reached);
    } on PasskeyException catch (e) {
      if (!mounted) return;
      if (e is PasskeyUnavailable) {
        WayoToast.info(context, context.t.login.passkey_unavailable);
      } else if (e is PasskeyNetworkError) {
        WayoToast.error(context, context.t.login.passkey_network);
      } else {
        final empty = _items == null || _items!.isEmpty;
        await showPasskeyInfoSheet(
          context,
          title: empty ? t.passkeys_stale_title : t.passkeys_already_title,
          body: empty ? t.passkeys_stale_body : t.passkeys_already_body,
          actionLabel: t.passkeys_already_action,
          icon: Icons.vpn_key_rounded,
        );
      }
    } catch (_) {
      if (!mounted) return;
      final empty = _items == null || _items!.isEmpty;
      await showPasskeyInfoSheet(
        context,
        title: empty ? t.passkeys_stale_title : t.passkeys_already_title,
        body: empty ? t.passkeys_stale_body : t.passkeys_already_body,
        actionLabel: t.passkeys_already_action,
        icon: Icons.vpn_key_rounded,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(PasskeyInfo item) async {
    final t = context.t.app_settings;
    final scheme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController(text: item.name);
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.passkeys_rename_title,
                style: AppTextStyles.headlineMedium(ctx).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 120,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                decoration: InputDecoration(
                  hintText: t.passkeys_default_name,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(t.passkeys_rename),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.passkeys_remove_cancel),
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || name == item.name) return;
    setState(() => _busy = true);
    try {
      await ref.read(passkeyServiceProvider).renamePasskey(item.id, name);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      WayoToast.error(context, t.passkeys_error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PasskeyInfo item) async {
    final t = context.t.app_settings;
    final scheme = Theme.of(context).colorScheme;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.key_off_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.passkeys_remove_title,
                        style: AppTextStyles.headlineMedium(ctx).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t.passkeys_remove_body,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(t.passkeys_remove_confirm),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.passkeys_remove_cancel),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(passkeyServiceProvider).revokePasskey(item.id);
      await _reload();
    } on PasskeyLastCredential {
      if (!mounted) return;
      WayoToast.error(context, t.passkeys_last_lockout);
    } on PasskeyServerRejected catch (e) {
      if (!mounted) return;
      final msg = (e.message ?? '').toLowerCase();
      WayoToast.error(
        context,
        msg.contains('last') || msg.contains('another sign-in')
            ? t.passkeys_last_lockout
            : t.passkeys_error,
      );
    } catch (_) {
      if (!mounted) return;
      WayoToast.error(context, t.passkeys_error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.app_settings;
    final scheme = Theme.of(context).colorScheme;
    final count = _items?.length ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: wayoSystemNavBarOverlay(context),
      child: Scaffold(
        backgroundColor: scheme.surface,
        bottomNavigationBar: const WayoSystemNavBarFill(),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _reload,
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
                  t.passkeys_title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _PasskeyHeroCard(
                      title: t.passkeys_title,
                      subtitle: t.passkeys_manage_hint,
                      countLabel: _loading
                          ? null
                          : (count == 0
                              ? t.passkeys_empty
                              : (count == 1
                                  ? t.passkeys_count_one
                                  : t.passkeys_count_many(count: count))),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const _PasskeyLoadingBlock()
                    else if (_error != null)
                      _PasskeyErrorBlock(
                        message: t.passkeys_error,
                        onRetry: _reload,
                      )
                    else if (_items == null || _items!.isEmpty)
                      _PasskeyEmptyBlock(
                        title: t.passkeys_empty,
                        body: t.passkeys_manage_hint,
                      )
                    else
                      _PasskeyListCard(
                        children: [
                          for (var i = 0; i < _items!.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            _PasskeyRow(
                              name: _items![i].displayTitle,
                              subtitle: _items![i].displaySubtitle,
                              createdLabel: _items![i].createdAt == null
                                  ? null
                                  : t.passkeys_created(
                                      date: _fmt(_items![i].createdAt),
                                    ),
                              lastUsedLabel: _items![i].lastUsedAt == null
                                  ? t.passkeys_never_used
                                  : t.passkeys_last_used(
                                      date: _fmt(_items![i].lastUsedAt),
                                    ),
                              renameLabel: t.passkeys_rename,
                              removeLabel: t.passkeys_remove,
                              enabled: !_busy,
                              onRename: () => unawaited(_rename(_items![i])),
                              onRemove: () => unawaited(_remove(_items![i])),
                            ),
                          ],
                        ],
                      ),
                    if (_canRegister) ...[
                      const SizedBox(height: 18),
                      _AddPasskeyButton(
                        label: t.passkeys_add,
                        busy: _busy,
                        onPressed: () => unawaited(_add()),
                      ),
                    ],
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

class _PasskeyHeroCard extends StatelessWidget {
  const _PasskeyHeroCard({
    required this.title,
    required this.subtitle,
    this.countLabel,
  });

  final String title;
  final String subtitle;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.18),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ]
              : [
                  const Color(0xFFFFF4E8),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.key_rounded,
                color: isDark ? AppColors.primarySoft : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  if (countLabel != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        countLabel!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasskeyListCard extends StatelessWidget {
  const _PasskeyListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _PasskeyRow extends StatelessWidget {
  const _PasskeyRow({
    required this.name,
    this.subtitle,
    required this.createdLabel,
    required this.lastUsedLabel,
    required this.renameLabel,
    required this.removeLabel,
    required this.enabled,
    required this.onRename,
    required this.onRemove,
  });

  final String name;
  final String? subtitle;
  final String? createdLabel;
  final String lastUsedLabel;
  final String renameLabel;
  final String removeLabel;
  final bool enabled;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 22,
              color: isDark ? AppColors.primarySoft : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                if (createdLabel != null)
                  Text(
                    createdLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                Text(
                  lastUsedLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: enabled,
            tooltip: '',
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'rename') onRename();
              if (v == 'remove') onRemove();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: scheme.onSurface),
                    const SizedBox(width: 10),
                    Text(renameLabel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      removeLabel,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
            icon: Icon(
              Icons.more_horiz_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasskeyEmptyBlock extends StatelessWidget {
  const _PasskeyEmptyBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        child: Column(
          children: [
            Icon(
              Icons.key_off_outlined,
              size: 36,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasskeyLoadingBlock extends StatelessWidget {
  const _PasskeyLoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _PasskeyErrorBlock extends StatelessWidget {
  const _PasskeyErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPasskeyButton extends StatelessWidget {
  const _AddPasskeyButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}
