import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Token packages catalog — `GET|POST|PUT /api/admin/token-packages`.
class TokenPackagesScreen extends ConsumerWidget {
  const TokenPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTokenPackagesProvider);
    final money = NumberFormat.simpleCurrency();

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Token packages'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminTokenPackagesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageForm(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New package'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: '$e',
          onRetry: () => ref.invalidate(adminTokenPackagesProvider),
        ),
        data: (packages) {
          if (packages.isEmpty) {
            return _EmptyBody(onCreate: () => _showPackageForm(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminTokenPackagesProvider);
              await ref.read(adminTokenPackagesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: packages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = packages[i];
                return _PackageTile(
                  package: p,
                  money: money,
                  onEdit: () => _showPackageForm(context, ref, package: p),
                  onToggle: (active) => _toggleActive(context, ref, p, active),
                  onSyncStripe: () => _syncStripe(context, ref, p),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPackageForm(
    BuildContext context,
    WidgetRef ref, {
    AdminTokenPackage? package,
  }) async {
    final result = await showModalBottomSheet<_PackageFormValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PackageFormSheet(package: package),
    );
    if (result == null || !context.mounted) return;

    final remote = ref.read(superadminOpsRemoteProvider);
    try {
      if (package == null) {
        await remote.createTokenPackage(
          slug: result.slug,
          name: result.name,
          tokens: result.tokens,
          bonusTokens: result.bonusTokens,
          priceCents: result.priceCents,
          currency: result.currency,
          isActive: result.isActive,
          isBestValue: result.isBestValue,
          appleProductId: result.appleProductId,
          googleProductId: result.googleProductId,
        );
        if (!context.mounted) return;
        WayoToast.success(context, 'Package created');
      } else {
        await remote.updateTokenPackage(
          slug: package.slug,
          name: result.name,
          tokens: result.tokens,
          bonusTokens: result.bonusTokens,
          priceCents: result.priceCents,
          currency: result.currency,
          isActive: result.isActive,
          isBestValue: result.isBestValue,
          appleProductId: result.appleProductId,
          googleProductId: result.googleProductId,
        );
        if (!context.mounted) return;
        WayoToast.success(context, 'Package updated');
      }
      ref.invalidate(adminTokenPackagesProvider);
    } catch (e) {
      if (!context.mounted) return;
      WayoToast.error(context, '$e');
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    AdminTokenPackage package,
    bool active,
  ) async {
    try {
      await ref.read(superadminOpsRemoteProvider).setTokenPackageActive(
            slug: package.slug,
            isActive: active,
          );
      ref.invalidate(adminTokenPackagesProvider);
      if (!context.mounted) return;
      WayoToast.success(context, active ? 'Activated' : 'Paused');
    } catch (e) {
      if (!context.mounted) return;
      WayoToast.error(context, '$e');
    }
  }

  Future<void> _syncStripe(
    BuildContext context,
    WidgetRef ref,
    AdminTokenPackage package,
  ) async {
    try {
      await ref
          .read(superadminOpsRemoteProvider)
          .syncTokenPackageStripe(package.slug);
      ref.invalidate(adminTokenPackagesProvider);
      if (!context.mounted) return;
      WayoToast.success(context, 'Synced to Stripe');
    } catch (e) {
      if (!context.mounted) return;
      WayoToast.error(context, '$e');
    }
  }
}

class _PackageFormValues {
  const _PackageFormValues({
    required this.slug,
    required this.name,
    required this.tokens,
    required this.bonusTokens,
    required this.priceCents,
    required this.currency,
    required this.isActive,
    required this.isBestValue,
    required this.appleProductId,
    required this.googleProductId,
  });

  final String slug;
  final String name;
  final int tokens;
  final int bonusTokens;
  final int priceCents;
  final String currency;
  final bool isActive;
  final bool isBestValue;
  final String appleProductId;
  final String googleProductId;
}

class _PackageFormSheet extends StatefulWidget {
  const _PackageFormSheet({this.package});

  final AdminTokenPackage? package;

  @override
  State<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends State<_PackageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slug;
  late final TextEditingController _name;
  late final TextEditingController _tokens;
  late final TextEditingController _bonusTokens;
  late final TextEditingController _priceCents;
  late final TextEditingController _currency;
  late final TextEditingController _appleProductId;
  late final TextEditingController _googleProductId;
  late bool _isActive;
  late bool _isBestValue;

  bool get _isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _slug = TextEditingController(text: p?.slug ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _tokens = TextEditingController(text: p != null ? '${p.tokens}' : '');
    _bonusTokens =
        TextEditingController(text: p != null ? '${p.bonusTokens}' : '0');
    _priceCents =
        TextEditingController(text: p != null ? '${p.priceCents}' : '');
    _currency = TextEditingController(text: p?.currency ?? 'USD');
    _appleProductId = TextEditingController(text: p?.appleProductId ?? '');
    _googleProductId = TextEditingController(text: p?.googleProductId ?? '');
    _isActive = p?.isActive ?? true;
    _isBestValue = p?.isBestValue ?? false;
  }

  @override
  void dispose() {
    _slug.dispose();
    _name.dispose();
    _tokens.dispose();
    _bonusTokens.dispose();
    _priceCents.dispose();
    _currency.dispose();
    _appleProductId.dispose();
    _googleProductId.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PackageFormValues(
        slug: _slug.text.trim(),
        name: _name.text.trim(),
        tokens: int.parse(_tokens.text.trim()),
        bonusTokens: int.tryParse(_bonusTokens.text.trim()) ?? 0,
        priceCents: int.parse(_priceCents.text.trim()),
        currency: _currency.text.trim().toUpperCase(),
        isActive: _isActive,
        isBestValue: _isBestValue,
        appleProductId: _appleProductId.text.trim(),
        googleProductId: _googleProductId.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
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
                      color: AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Edit package' : 'New package',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? 'Update metadata — Stripe sync stays on web.'
                      : 'Create a Creator Studio token package.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _slug,
                        enabled: !_isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Slug',
                          hintText: 'growth',
                        ),
                        validator: (v) {
                          if (_isEditing) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Growth',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tokens,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Base tokens',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) return 'Enter tokens';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bonusTokens,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Bonus tokens',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCents,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (cents)',
                          hintText: '1999',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0) return 'Enter price';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _currency,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          hintText: 'USD',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Native store IDs (optional) — set to enable in-app purchase '
                  'on Studio mobile; leave blank to keep Stripe for that platform.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _appleProductId,
                        decoration: const InputDecoration(
                          labelText: 'Apple product ID',
                          hintText: 'com.wayo.studio.growth',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _googleProductId,
                        decoration: const InputDecoration(
                          labelText: 'Google product ID',
                          hintText: 'studio_growth',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Best value badge'),
                  value: _isBestValue,
                  onChanged: (v) => setState(() => _isBestValue = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_isEditing ? 'Save changes' : 'Create package'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.money,
    required this.onEdit,
    required this.onToggle,
    required this.onSyncStripe,
  });

  final AdminTokenPackage package;
  final NumberFormat money;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSyncStripe;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${package.totalTokens} tokens'
                      '${package.bonusTokens > 0 ? ' (+${package.bonusTokens} bonus)' : ''}'
                      ' · ${money.format(package.priceCents / 100)} ${package.currency}'
                      '${package.isBestValue ? ' · best value' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    Text(
                      package.slug,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onSyncStripe,
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Sync Stripe'),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: package.isActive,
                onChanged: onToggle,
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textMutedOf(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No packages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New package" to create one',
            style: TextStyle(color: AppColors.textMutedOf(context)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New package'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
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
