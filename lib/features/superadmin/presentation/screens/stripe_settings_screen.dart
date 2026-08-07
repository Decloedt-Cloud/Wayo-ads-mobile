import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Stripe TEST/LIVE settings — edit, reveal, active-mode switch and
/// connection test. Mirrors the web `/admin/settings/stripe` sensitive ops.
class StripeSettingsScreen extends ConsumerWidget {
  const StripeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stripeSettingsStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Stripe settings'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(stripeSettingsStatusProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Active mode: ${s.activeMode}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _ActiveModeSwitch(currentMode: s.activeMode),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ModeCard(status: s.test, active: s.activeMode == 'TEST'),
            const SizedBox(height: 10),
            _ModeCard(status: s.live, active: s.activeMode == 'LIVE'),
          ],
        ),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nextMode == 'LIVE' ? AppColors.error : AppColors.primary,
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
      if (mounted) WayoToast.success(context, 'Active mode set to $nextMode');
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Failed to switch mode: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    return TextButton(
      onPressed: _toggle,
      child: Text('Switch to ${widget.currentMode == 'LIVE' ? 'TEST' : 'LIVE'}'),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRevealedValue(BuildContext context, String label, String value) {
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
              style: TextStyle(fontSize: 11, color: AppColors.textMutedOf(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              WayoToast.success(context, 'Copied', duration: const Duration(seconds: 1));
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
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  status.mode,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (widget.active) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: _expanded ? 'Collapse' : 'Edit',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.edit_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _KeyRow(
              label: 'Publishable',
              masked: status.publishableKeyMasked,
              onReveal: status.publishableKeyMasked == null
                  ? null
                  : () => _reveal('publishableKey', 'Publishable key'),
            ),
            _KeyRow(
              label: 'Secret',
              masked: status.secretKeyMasked,
              onReveal: status.secretKeyMasked == null
                  ? null
                  : () => _reveal('secretKey', 'Secret key'),
            ),
            _KeyRow(
              label: 'Webhook',
              masked: status.webhookSecretMasked,
              onReveal: status.webhookSecretMasked == null
                  ? null
                  : () => _reveal('webhookSecret', 'Webhook secret'),
            ),
            if (status.lastVerifiedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Verified ${DateFormat.yMMMd().add_Hm().format(status.lastVerifiedAt!.toLocal())}'
                  '${status.lastVerifiedOk == true ? ' · OK' : status.lastVerifiedOk == false ? ' · FAIL' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: status.lastVerifiedOk == false
                        ? AppColors.error
                        : AppColors.textMutedOf(context),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
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
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Divider(color: AppColors.borderOf(context).withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              _EditForm(mode: status.mode, hasSecret: status.secretKeyMasked != null),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.label, required this.masked, this.onReveal});
  final String label;
  final String? masked;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMutedOf(context)),
            ),
          ),
          Expanded(
            child: Text(
              masked ?? '—',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onReveal != null)
            IconButton(
              tooltip: 'Reveal',
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              onPressed: onReveal,
              icon: const Icon(Icons.visibility_rounded),
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
      WayoToast.warning(context, 'Secret key is required for initial configuration');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(superadminOpsRemoteProvider).updateStripeSettings(
            mode: widget.mode,
            publishableKey: _publishable.text.trim().isEmpty ? null : _publishable.text.trim(),
            secretKey: _secret.text.trim().isEmpty ? null : _secret.text.trim(),
            webhookSecret: _webhook.text.trim().isEmpty ? null : _webhook.text.trim(),
          );
      ref.invalidate(stripeSettingsStatusProvider);
      _publishable.clear();
      _secret.clear();
      _webhook.clear();
      if (mounted) WayoToast.success(context, '${widget.mode} credentials updated');
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave a field blank to keep its current value.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMutedOf(context)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _publishable,
          decoration: InputDecoration(
            labelText: 'Publishable key',
            hintText: 'pk_${widget.mode.toLowerCase()}_…',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _secret,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Secret key',
            hintText: 'sk_${widget.mode.toLowerCase()}_…',
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _webhook,
          obscureText: _obscure,
          decoration: const InputDecoration(
            labelText: 'Webhook secret',
            hintText: 'whsec_…',
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save ${widget.mode} credentials'),
          ),
        ),
      ],
    );
  }
}
