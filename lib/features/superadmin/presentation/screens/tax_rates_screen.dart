import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../domain/entities/country_tax_rate.dart';
import '../providers/superadmin_providers.dart';
import '../widgets/superadmin_scaffold.dart';

/// Superadmin tax rates — mirrors web `/admin` tax panel (GET/POST/DELETE
/// `/api/admin/tax-rates`).
class TaxRatesScreen extends ConsumerStatefulWidget {
  const TaxRatesScreen({super.key, this.countryCode});

  /// When set (e.g. US, CA), shows state/province rates instead of countries.
  final String? countryCode;

  @override
  ConsumerState<TaxRatesScreen> createState() => _TaxRatesScreenState();
}

class _TaxRatesScreenState extends ConsumerState<TaxRatesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _editingKey;
  final _editController = TextEditingController();
  bool _saving = false;

  bool get _isSubdivisions =>
      widget.countryCode != null && widget.countryCode!.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(taxRatesProvider);
  }

  Future<bool> _saveRate({
    required String countryCode,
    required double rate,
    String? subdivision,
    String? label,
  }) async {
    setState(() => _saving = true);
    final repo = ref.read(superadminRepositoryProvider);
    final result = await repo.upsertTaxRate(
      countryCode: countryCode,
      rate: rate,
      subdivision: subdivision,
      label: label,
    );
    if (!mounted) return false;
    setState(() => _saving = false);
    return result.when(
      success: (_) {
        ref.invalidate(taxRatesProvider);
        return true;
      },
      failure: (e) {
        WayoToast.error(context, e.toString());
        return false;
      },
    );
  }

  void _startEdit(String key, double currentRate) {
    setState(() {
      _editingKey = key;
      _editController.text = _formatRateInput(currentRate);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingKey = null;
      _editController.clear();
    });
  }

  String _formatRateInput(double rate) {
    if (rate == rate.roundToDouble()) return rate.toInt().toString();
    return rate.toString();
  }

  double? _parseRateInput(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  Future<void> _onSaveCountry(CountryTaxRate item) async {
    final rate = _parseRateInput(_editController.text);
    if (rate == null) {
      WayoToast.info(context, 'Enter a rate between 0 and 100');
      return;
    }
    final ok = await _saveRate(
      countryCode: item.code,
      rate: rate,
      label: '${item.name} — ${formatTaxRatePercent(rate)}',
    );
    if (ok && mounted) _cancelEdit();
  }

  Future<void> _onSaveSubdivision(TaxSubdivisionRate item) async {
    final rate = _parseRateInput(_editController.text);
    if (rate == null) {
      WayoToast.info(context, 'Enter a rate between 0 and 100');
      return;
    }
    final ok = await _saveRate(
      countryCode: item.countryCode,
      rate: rate,
      subdivision: item.subdivision,
      label: item.label ?? '${item.name} — ${formatTaxRatePercent(rate)}',
    );
    if (ok && mounted) _cancelEdit();
  }

  @override
  Widget build(BuildContext context) {
    final taxAsync = ref.watch(taxRatesProvider);
    final cc = widget.countryCode?.toUpperCase();

    return SuperadminScaffold(
      title: _isSubdivisions ? 'Tax rates — $cc' : 'Tax rates',
      leading: _isSubdivisions
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            )
          : null,
      body: taxAsync.when(
        data: (page) {
          if (_isSubdivisions) {
            return _buildSubdivisionsBody(context, page, cc!);
          }
          return _buildCountriesBody(context, page);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(onRetry: _refresh, message: e.toString()),
      ),
    );
  }

  Widget _buildCountriesBody(BuildContext context, TaxRatesPage page) {
    final q = _searchQuery.toLowerCase();
    final filtered = page.rates.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) || r.code.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View and edit VAT/GST rates per country. Changes apply to advertiser invoices.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryOf(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by country name or code',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceElevatedOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${page.rates.length} countries · tap a rate to edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No countries match your search')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _CountryTaxTile(
                    item: item,
                    isEditing: _editingKey == item.code,
                    editController: _editController,
                    saving: _saving,
                    onEdit: () => _startEdit(item.code, item.rate),
                    onCancel: _cancelEdit,
                    onSave: () => _onSaveCountry(item),
                    onOpenSubdivisions: item.hasSubdivisions
                        ? () => context.push(
                              '/superadmin/tax-rates/subdivisions/${item.code}',
                            )
                        : null,
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSubdivisionsBody(
    BuildContext context,
    TaxRatesPage page,
    String countryCode,
  ) {
    final subs = page.subdivisionsForCountry(countryCode);
    final q = _searchQuery.toLowerCase();
    final filtered = subs.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.subdivision.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countryCode == 'US'
                        ? 'State sales tax rates (override defaults per state).'
                        : 'Province tax rates (override defaults per province).',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryOf(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search state or code',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceElevatedOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${subs.length} regions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final key = item.code;
                return _SubdivisionTaxTile(
                  item: item,
                  isEditing: _editingKey == key,
                  editController: _editController,
                  saving: _saving,
                  onEdit: () => _startEdit(key, item.rate),
                  onCancel: _cancelEdit,
                  onSave: () => _onSaveSubdivision(item),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }
}

class _CountryTaxTile extends StatelessWidget {
  const _CountryTaxTile({
    required this.item,
    required this.isEditing,
    required this.editController,
    required this.saving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    this.onOpenSubdivisions,
  });

  final CountryTaxRate item;
  final bool isEditing;
  final TextEditingController editController;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback? onOpenSubdivisions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEditing ? null : onOpenSubdivisions,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceElevated.withValues(alpha: 0.45)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          item.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onOpenSubdivisions != null)
                    IconButton(
                      tooltip: 'State / province rates',
                      onPressed: onOpenSubdivisions,
                      icon: const Icon(Icons.map_rounded, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RateColumn(
                      label: 'Current',
                      child: isEditing
                          ? SizedBox(
                              width: 72,
                              child: TextField(
                                controller: editController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                ),
                                autofocus: true,
                              ),
                            )
                          : Text(
                              formatTaxRatePercent(item.rate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: _RateColumn(
                      label: 'Previous',
                      child: Text(
                        formatTaxRatePercent(item.defaultRate),
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _StatusChip(overridden: item.overridden),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: saving ? null : onCancel,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: saving ? null : onSave,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(0, 36),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ],
                      )
                    : OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubdivisionTaxTile extends StatelessWidget {
  const _SubdivisionTaxTile({
    required this.item,
    required this.isEditing,
    required this.editController,
    required this.saving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final TaxSubdivisionRate item;
  final bool isEditing;
  final TextEditingController editController;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.45)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Text(
            item.subdivision,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RateColumn(
                  label: 'Current',
                  child: isEditing
                      ? SizedBox(
                          width: 72,
                          child: TextField(
                            controller: editController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              suffixText: '%',
                              isDense: true,
                            ),
                            autofocus: true,
                          ),
                        )
                      : Text(
                          formatTaxRatePercent(item.rate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: _RateColumn(
                  label: 'Default',
                  child: Text(
                    formatTaxRatePercent(item.defaultRate),
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _StatusChip(overridden: item.overridden),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: saving ? null : onCancel,
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: saving ? null : onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  )
                : OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RateColumn extends StatelessWidget {
  const _RateColumn({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMutedOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.overridden});

  final bool overridden;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: overridden
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.textMutedOf(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        overridden ? 'Custom' : 'Default',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: overridden ? AppColors.primary : AppColors.textMutedOf(context),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load tax rates',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 8),
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
