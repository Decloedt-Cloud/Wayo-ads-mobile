import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_scaffold.dart';

/// Stripe TEST/LIVE settings — edit, reveal, active-mode switch and
/// connection test. Mirrors the web `/admin/settings/stripe` sensitive ops.
class StripeSettingsScreen extends ConsumerWidget {
  const StripeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stripeSettingsStatusProvider);

    return SuperadminScaffold(
      title: 'Stripe settings',
      onRefresh: () => ref.invalidate(stripeSettingsStatusProvider),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(stripeSettingsStatusProvider),
        ),
        data: (s) {
          final isLive = s.activeMode == 'LIVE';
          return ListView(
            padding: superadminPagePadding(context),
            children: [
              _ActiveModeBanner(
                activeMode: s.activeMode,
                isLive: isLive,
              ),
              const SizedBox(height: 14),
              Text(
                'Environments',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 8),
              _ModeCard(status: s.test, active: s.activeMode == 'TEST'),
              const SizedBox(height: 10),
              _ModeCard(status: s.live, active: isLive),
              const SizedBox(height: 16),
              Text(
                'Keys are encrypted at rest. Reveal requires your account '
                'password and is never logged.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          );
        },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Couldn’t load Stripe settings',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
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

class _ActiveModeBanner extends StatelessWidget {
  const _ActiveModeBanner({
    required this.activeMode,
    required this.isLive,
  });

  final String activeMode;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? AppColors.error : const Color(0xFF6366F1);
    final subtitle = isLive
        ? 'Real charges use LIVE credentials'
        : 'Sandbox — no real money moves';

    return SuperadminSectionCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLive ? Icons.payments_rounded : Icons.science_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active mode',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      activeMode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isLive ? 'Production' : 'Sandbox',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          _ActiveModeSwitch(currentMode: activeMode),
        ],
      ),
    );
  }
}

class _ActiveModeSwitch extends ConsumerStatefulWidget {
  const _ActiveModeSwitch({required this.currentMode});
  final String currentMode;

  @override
  ConsumerState<_ActiveModeSwitch> createState() => _ActiveModeSwitchState();
}

class _ActiveModeSwitchState extends ConsumerState<_ActiveModeSwitch> {
  var _busy = false;

  Future<void> _toggle() async {
    final nextMode = widget.currentMode == 'LIVE' ? 'TEST' : 'LIVE';
    final confirmed = await showWayoDialog<bool>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Switch to $nextMode?'),
        content: Text(
          nextMode == 'LIVE'
              ? 'Real payments will be processed using LIVE Stripe credentials.'
              : 'Switch platform payments back to TEST credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  nextMode == 'LIVE' ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Switch to $nextMode'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(superadminOpsRemoteProvider).setStripeActiveMode(nextMode);
      ref.invalidate(stripeSettingsStatusProvider);
      ref.invalidate(platformSettingsProvider);
      if (mounted) {
        WayoToast.success(context, 'Active mode set to $nextMode');
      }
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Failed to switch mode: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.currentMode == 'LIVE' ? 'TEST' : 'LIVE';
    if (_busy) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return FilledButton.tonal(
      onPressed: _toggle,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        '→ $next',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );
  }
}

class _ModeCard extends ConsumerStatefulWidget {
  const _ModeCard({required this.status, required this.active});
  final StripeModeStatus status;
  final bool active;

  @override
  ConsumerState<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends ConsumerState<_ModeCard> {
  var _expanded = false;
  var _testing = false;

  Color get _accent =>
      widget.status.mode == 'LIVE' ? AppColors.error : const Color(0xFF6366F1);

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      final result = await ref
          .read(superadminOpsRemoteProvider)
          .testStripeConnection(mode: widget.status.mode);
      ref.invalidate(stripeSettingsStatusProvider);
      if (!mounted) return;
      if (result.success) {
        WayoToast.success(
          context,
          result.accountName != null
              ? '${result.message} · ${result.accountName}'
              : result.message,
        );
      } else {
        WayoToast.error(context, result.message);
      }
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Test failed: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _reveal(String field, String label) async {
    final password = await _promptPassword(context);
    if (password == null || password.isEmpty || !mounted) return;
    try {
      final value = await ref.read(superadminOpsRemoteProvider).revealStripeSecret(
            mode: widget.status.mode,
            field: field,
            password: password,
          );
      if (!mounted) return;
      await _showRevealedValue(context, label, value);
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Reveal failed: $e');
    }
  }

  Future<String?> _promptPassword(BuildContext context) {
    final controller = TextEditingController();
    return showWayoDialog<String>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm your password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Account password',
            filled: true,
            fillColor: AppColors.surfaceElevatedOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRevealedValue(
    BuildContext context,
    String label,
    String value,
  ) {
    return showWayoDialog<void>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Shown once — not logged or cached.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              WayoToast.success(
                context,
                'Copied',
                duration: const Duration(seconds: 1),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final verifiedOk = status.lastVerifiedOk;

    return SuperadminSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: widget.active ? 0.10 : 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    status.mode == 'LIVE'
                        ? Icons.lock_rounded
                        : Icons.bug_report_rounded,
                    size: 18,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            status.mode,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          if (widget.active) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (status.lastVerifiedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                verifiedOk == true
                                    ? Icons.check_circle_rounded
                                    : verifiedOk == false
                                        ? Icons.error_rounded
                                        : Icons.schedule_rounded,
                                size: 12,
                                color: verifiedOk == true
                                    ? AppColors.success
                                    : verifiedOk == false
                                        ? AppColors.error
                                        : AppColors.textMutedOf(context),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Verified ${DateFormat.MMMd().add_Hm().format(status.lastVerifiedAt!.toLocal())}'
                                  '${verifiedOk == true ? ' · OK' : verifiedOk == false ? ' · FAIL' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: verifiedOk == false
                                        ? AppColors.error
                                        : AppColors.textMutedOf(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _expanded ? 'Collapse' : 'Edit credentials',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.edit_outlined,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KeyTile(
                  label: 'Publishable key',
                  masked: status.publishableKeyMasked,
                  onReveal: status.publishableKeyMasked == null
                      ? null
                      : () => _reveal('publishableKey', 'Publishable key'),
                ),
                const SizedBox(height: 8),
                _KeyTile(
                  label: 'Secret key',
                  masked: status.secretKeyMasked,
                  onReveal: status.secretKeyMasked == null
                      ? null
                      : () => _reveal('secretKey', 'Secret key'),
                ),
                const SizedBox(height: 8),
                _KeyTile(
                  label: 'Webhook secret',
                  masked: status.webhookSecretMasked,
                  onReveal: status.webhookSecretMasked == null
                      ? null
                      : () => _reveal('webhookSecret', 'Webhook secret'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded, size: 16),
                    label: Text(_testing ? 'Testing…' : 'Test connection'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: AppColors.borderOf(context).withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 12),
                  _EditForm(
                    mode: status.mode,
                    hasSecret: status.secretKeyMasked != null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({
    required this.label,
    required this.masked,
    this.onReveal,
  });

  final String label;
  final String? masked;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final empty = masked == null || masked!.isEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  empty ? 'Not configured' : masked!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: empty
                        ? AppColors.textMutedOf(context)
                        : AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (onReveal != null)
            IconButton(
              tooltip: 'Reveal',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onReveal,
              icon: Icon(
                Icons.visibility_rounded,
                color: AppColors.textMutedOf(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.mode, required this.hasSecret});
  final String mode;
  final bool hasSecret;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _publishable = TextEditingController();
  final _secret = TextEditingController();
  final _webhook = TextEditingController();
  var _saving = false;
  var _obscure = true;

  @override
  void dispose() {
    _publishable.dispose();
    _secret.dispose();
    _webhook.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_publishable.text.trim().isEmpty &&
        _secret.text.trim().isEmpty &&
        _webhook.text.trim().isEmpty) {
      WayoToast.warning(context, 'Enter at least one field to update');
      return;
    }
    if (!widget.hasSecret && _secret.text.trim().isEmpty) {
      WayoToast.warning(
        context,
        'Secret key is required for initial configuration',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(superadminOpsRemoteProvider).updateStripeSettings(
            mode: widget.mode,
            publishableKey: _publishable.text.trim().isEmpty
                ? null
                : _publishable.text.trim(),
            secretKey:
                _secret.text.trim().isEmpty ? null : _secret.text.trim(),
            webhookSecret:
                _webhook.text.trim().isEmpty ? null : _webhook.text.trim(),
          );
      ref.invalidate(stripeSettingsStatusProvider);
      _publishable.clear();
      _secret.clear();
      _webhook.clear();
      if (mounted) {
        WayoToast.success(context, '${widget.mode} credentials updated');
      }
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDeco({
    required String label,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update credentials',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Leave a field blank to keep its current value.',
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.textMutedOf(context),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _publishable,
          decoration: _fieldDeco(
            label: 'Publishable key',
            hint: 'pk_${widget.mode.toLowerCase()}_…',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _secret,
          obscureText: _obscure,
          decoration: _fieldDeco(
            label: 'Secret key',
            hint: 'sk_${widget.mode.toLowerCase()}_…',
            suffix: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _webhook,
          obscureText: _obscure,
          decoration: _fieldDeco(
            label: 'Webhook secret',
            hint: 'whsec_…',
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _saving ? 'Saving…' : 'Save ${widget.mode} credentials',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
