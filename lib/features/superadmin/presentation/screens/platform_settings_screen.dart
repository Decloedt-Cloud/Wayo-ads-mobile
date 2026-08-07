import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Platform fee / hold settings — `GET|PUT /api/admin/platform-settings`.
class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState
    extends ConsumerState<PlatformSettingsScreen> {
  final _feePct = TextEditingController();
  final _minWithdraw = TextEditingController();
  final _holdDays = TextEditingController();
  final _settleHours = TextEditingController();
  final _currency = TextEditingController();
  final _name = TextEditingController();
  var _hydrated = false;
  var _saving = false;

  @override
  void dispose() {
    _feePct.dispose();
    _minWithdraw.dispose();
    _holdDays.dispose();
    _settleHours.dispose();
    _currency.dispose();
    _name.dispose();
    super.dispose();
  }

  void _hydrate(PlatformSettingsSnapshot s) {
    if (_hydrated) return;
    _hydrated = true;
    _feePct.text = s.platformFeePercentage.toStringAsFixed(2);
    _minWithdraw.text = (s.minimumWithdrawalCents / 100).toStringAsFixed(2);
    _holdDays.text = '${s.pendingHoldDays}';
    _settleHours.text = '${s.viewSettlementHoldHours}';
    _currency.text = s.defaultCurrency;
    _name.text = s.platformName;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final feePct = double.tryParse(_feePct.text.trim()) ?? 5;
      final minMajor = double.tryParse(_minWithdraw.text.trim()) ?? 1;
      await ref.read(superadminOpsRemoteProvider).updatePlatformSettings(
            platformFeeRate: (feePct / 100).clamp(0, 1),
            defaultCurrency: _currency.text.trim().toUpperCase(),
            minimumWithdrawalCents:
                (minMajor * 100).round().clamp(100, 100000000),
            pendingHoldDays: int.tryParse(_holdDays.text.trim()) ?? 0,
            viewSettlementHoldHours:
                int.tryParse(_settleHours.text.trim()) ?? 24,
            platformName: _name.text.trim().isEmpty ? null : _name.text.trim(),
          );
      _hydrated = false;
      ref.invalidate(platformSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Platform settings'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [SuperadminChromeActions(trailingPadding: 12)],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) {
          _hydrate(s);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'Stripe mode: ${s.stripeActiveMode}',
                style: TextStyle(color: AppColors.textMutedOf(context)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Platform name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feePct,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Platform fee %',
                  helperText: 'e.g. 5 for 5%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currency,
                decoration:
                    const InputDecoration(labelText: 'Default currency'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minWithdraw,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum withdrawal (major units)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _holdDays,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Pending hold days'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _settleHours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'View settlement hold (hours)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
