import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_wallet_remote_datasource.dart';
import '../../domain/creator_business_profile.dart';
import '../../domain/stripe_connect_catalog.dart';
import '../providers/creator_wallet_providers.dart';

/// Opens the Business Info modal as a bottom sheet so the wallet page stays
/// visible behind it.
///
/// Returns `true` when the user successfully saved a complete profile (and the
/// wallet screen should flip its CTA to "Connect your bank account").
Future<bool> showBusinessInfoDialog(
  BuildContext context, {
  required CreatorBusinessProfile initial,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => _BusinessInfoDialog(initial: initial),
  );
  return result == true;
}

class _BusinessInfoDialog extends ConsumerStatefulWidget {
  const _BusinessInfoDialog({required this.initial});

  final CreatorBusinessProfile initial;

  @override
  ConsumerState<_BusinessInfoDialog> createState() =>
      _BusinessInfoDialogState();
}

class _BusinessInfoDialogState extends ConsumerState<_BusinessInfoDialog> {
  final _formKey = GlobalKey<FormState>();

  late CreatorBusinessType _businessType;
  late TextEditingController _companyName;
  late TextEditingController _vatNumber;
  late TextEditingController _addressLine1;
  late TextEditingController _addressLine2;
  late TextEditingController _city;
  late TextEditingController _postalCode;
  late TextEditingController _state;
  String? _countryCode;
  String? _currency;
  bool _submitting = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _businessType = p.businessType;
    _companyName = TextEditingController(text: p.companyName ?? '');
    _vatNumber = TextEditingController(text: p.vatNumber ?? '');
    _addressLine1 = TextEditingController(text: p.addressLine1 ?? '');
    _addressLine2 = TextEditingController(text: p.addressLine2 ?? '');
    _city = TextEditingController(text: p.city ?? '');
    _postalCode = TextEditingController(text: p.postalCode ?? '');
    _state = TextEditingController(text: p.state ?? '');
    _countryCode = _validCountry(p.countryCode);
    _currency = _validCurrency(p.currency);
  }

  @override
  void dispose() {
    _companyName.dispose();
    _vatNumber.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _postalCode.dispose();
    _state.dispose();
    super.dispose();
  }

  String? _validCountry(String? v) {
    if (v == null) return null;
    for (final o in StripeConnectCatalog.countries) {
      if (o.code == v) return o.code;
    }
    return null;
  }

  String? _validCurrency(String? v) {
    if (v == null) return null;
    for (final o in StripeConnectCatalog.currencies) {
      if (o.code == v) return o.code;
    }
    return null;
  }

  Future<void> _submit() async {
    final t = context.t;
    FocusScope.of(context).unfocus();
    if (_countryCode == null || _currency == null) {
      _formKey.currentState?.validate();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final input = CreatorBusinessProfileInput(
      businessType: _businessType,
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim().isEmpty
          ? null
          : _addressLine2.text.trim(),
      city: _city.text.trim(),
      postalCode: _postalCode.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      countryCode: _countryCode!,
      currency: _currency!,
      companyName: _companyName.text.trim().isEmpty
          ? null
          : _companyName.text.trim(),
      vatNumber: _vatNumber.text.trim().isEmpty ? null : _vatNumber.text.trim(),
    );

    setState(() {
      _submitting = true;
      _apiError = null;
    });
    try {
      final profile = await ref
          .read(creatorWalletRepositoryProvider)
          .updateBusinessProfile(input);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // Cascade: stripe status & wallet page depend on the business profile.
      // ignore: unused_result
      ref.refresh(creatorBusinessProfileProvider);
      // ignore: unused_result
      ref.refresh(creatorStripeStatusProvider);
      // ignore: unused_result
      ref.refresh(creatorWalletPageProvider);
      Navigator.of(context).pop(profile.businessInfoComplete);
    } on CreatorWalletApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = e.message;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = '$e'.isEmpty ? t.creator.business.save_error : '$e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final insets = MediaQuery.viewInsetsOf(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          padding: EdgeInsets.only(bottom: insets.bottom),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            children: [
              _DragHandle(),
              _DialogHeader(
                title: t.creator.business.dialog_title,
                subtitle: t.creator.business.dialog_subtitle,
                onClose: () => Navigator.of(context).pop(false),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(label: t.creator.business.section_type),
                        const SizedBox(height: 8),
                        _BusinessTypeSelector(
                          value: _businessType,
                          onChanged: (v) => setState(() => _businessType = v),
                        ),
                        const SizedBox(height: 20),
                        if (_businessType ==
                            CreatorBusinessType.registeredCompany) ...[
                          _SectionLabel(
                            label: t.creator.business.section_company,
                          ),
                          const SizedBox(height: 8),
                          _RequiredField(
                            controller: _companyName,
                            label: t.creator.business.company_name,
                            validatorKey: t.creator.business.error_required,
                          ),
                          const SizedBox(height: 12),
                          _RequiredField(
                            controller: _vatNumber,
                            label: t.creator.business.vat_number,
                            validatorKey: t.creator.business.error_required,
                            capitalize: true,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _SectionLabel(
                          label: t.creator.business.section_address,
                        ),
                        const SizedBox(height: 8),
                        _RequiredField(
                          controller: _addressLine1,
                          label: t.creator.business.address_line1,
                          validatorKey: t.creator.business.error_required,
                        ),
                        const SizedBox(height: 12),
                        _OptionalField(
                          controller: _addressLine2,
                          label: t.creator.business.address_line2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _RequiredField(
                                controller: _city,
                                label: t.creator.business.city,
                                validatorKey: t.creator.business.error_required,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RequiredField(
                                controller: _postalCode,
                                label: t.creator.business.postal_code,
                                validatorKey: t.creator.business.error_required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _OptionalField(
                          controller: _state,
                          label: t.creator.business.state_region,
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(label: t.creator.business.section_stripe),
                        const SizedBox(height: 8),
                        _StripeConnectDropdown(
                          label: t.creator.business.country,
                          errorRequired: t.creator.business.error_required,
                          items: StripeConnectCatalog.countries,
                          value: _countryCode,
                          onChanged: (v) => setState(() => _countryCode = v),
                        ),
                        const SizedBox(height: 12),
                        _StripeConnectDropdown(
                          label: t.creator.business.currency,
                          errorRequired: t.creator.business.error_required,
                          items: StripeConnectCatalog.currencies,
                          value: _currency,
                          onChanged: (v) => setState(() => _currency = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StickyFooter(
                apiError: _apiError,
                submitting: _submitting,
                onSubmit: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({
    required this.apiError,
    required this.submitting,
    required this.onSubmit,
  });

  final String? apiError;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: AppColors.borderOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (apiError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apiError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    submitting
                        ? t.creator.business.submitting
                        : t.creator.business.save_and_continue,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CreatorColors.primaryOf(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.creator.business.footer_info,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textMutedOf(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMutedOf(context),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimaryOf(context),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _BusinessTypeSelector extends StatelessWidget {
  const _BusinessTypeSelector({required this.value, required this.onChanged});

  final CreatorBusinessType value;
  final ValueChanged<CreatorBusinessType> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        _typeTile(
          context,
          type: CreatorBusinessType.personal,
          icon: Icons.person_outline_rounded,
          title: t.creator.business.type_personal_title,
          subtitle: t.creator.business.type_personal_subtitle,
        ),
        const SizedBox(height: 8),
        _typeTile(
          context,
          type: CreatorBusinessType.soleProprietor,
          icon: Icons.business_center_outlined,
          title: t.creator.business.type_sole_title,
          subtitle: t.creator.business.type_sole_subtitle,
        ),
        const SizedBox(height: 8),
        _typeTile(
          context,
          type: CreatorBusinessType.registeredCompany,
          icon: Icons.apartment_rounded,
          title: t.creator.business.type_company_title,
          subtitle: t.creator.business.type_company_subtitle,
        ),
      ],
    );
  }

  Widget _typeTile(
    BuildContext context, {
    required CreatorBusinessType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = value == type;
    final accent = CreatorColors.primaryOf(context);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.1)
          : AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(type);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : AppColors.borderOf(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? accent : AppColors.textMutedOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accent : AppColors.borderOf(context),
                    width: 2,
                  ),
                  color: selected ? accent : Colors.transparent,
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    required this.validatorKey,
    this.capitalize = false,
  });

  final TextEditingController controller;
  final String label;
  final String validatorKey;
  final bool capitalize;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: capitalize
          ? TextCapitalization.characters
          : TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? validatorKey : null,
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _StripeConnectDropdown extends StatelessWidget {
  const _StripeConnectDropdown({
    required this.label,
    required this.errorRequired,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String errorRequired;
  final List<StripeConnectOption> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 320,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final o in items)
          DropdownMenuItem<String>(
            value: o.code,
            child: Text('${o.code} — ${o.name}'),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => (v == null || v.isEmpty) ? errorRequired : null,
    );
  }
}
