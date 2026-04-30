import 'package:country_flags/country_flags.dart';
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
    _currency = _validCurrency(p.currency) ?? 'USD';
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
                        _ModernConnectSelect(
                          key: ValueKey('country_${_countryCode ?? '∅'}'),
                          label: t.creator.business.country,
                          errorRequired: t.creator.business.error_required,
                          items: StripeConnectCatalog.countries,
                          value: _countryCode,
                          showCountryFlag: true,
                          onChanged: (v) => setState(() => _countryCode = v),
                        ),
                        const SizedBox(height: 12),
                        _ModernConnectSelect(
                          key: ValueKey('currency_${_currency ?? '∅'}'),
                          label: t.creator.business.currency,
                          errorRequired: t.creator.business.error_required,
                          items: StripeConnectCatalog.currencies,
                          value: _currency,
                          showCountryFlag: false,
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

/// Stripe country / currency picker — shadcn-like surface, shadow, chevron motion.
class _ModernConnectSelect extends StatefulWidget {
  const _ModernConnectSelect({
    super.key,
    required this.label,
    required this.errorRequired,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.showCountryFlag,
  });

  final String label;
  final String errorRequired;
  final List<StripeConnectOption> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool showCountryFlag;

  @override
  State<_ModernConnectSelect> createState() => _ModernConnectSelectState();
}

class _ModernConnectSelectState extends State<_ModernConnectSelect>
    with SingleTickerProviderStateMixin {
  bool _menuOpen = false;
  late final AnimationController _chevronC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _chevronC.dispose();
    super.dispose();
  }

  StripeConnectOption? _optionFor(String? code) {
    if (code == null) return null;
    for (final o in widget.items) {
      if (o.code == code) return o;
    }
    return null;
  }

  void _setMenuOpen(bool open) {
    if (_menuOpen == open) return;
    setState(() => _menuOpen = open);
    if (open) {
      _chevronC.forward();
    } else {
      _chevronC.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = AppColors.borderOf(context);
    final surface = theme.colorScheme.surface;
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.08);

    return FormField<String>(
      initialValue: widget.value,
      validator: (v) =>
          (v == null || v.isEmpty) ? widget.errorRequired : null,
      builder: (field) {
        final hasError = field.hasError;
        final sel = _optionFor(field.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuAnchor(
              onOpen: () => _setMenuOpen(true),
              onClose: () => _setMenuOpen(false),
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(surface),
                elevation: const WidgetStatePropertyAll(14),
                shadowColor: WidgetStatePropertyAll(shadow),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 6),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: border.withValues(alpha: 0.65)),
                  ),
                ),
                maximumSize: WidgetStatePropertyAll(
                  Size(
                    MediaQuery.sizeOf(context).width - 40,
                    320,
                  ),
                ),
              ),
              menuChildren: [
                for (final o in widget.items)
                  MenuItemButton(
                    style: MenuItemButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      field.didChange(o.code);
                      widget.onChanged(o.code);
                    },
                    child: widget.showCountryFlag
                        ? Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: CountryFlag.fromCountryCode(
                                  o.code,
                                  height: 20,
                                  width: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${o.code} — ${o.name}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${o.code} — ${o.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
              ],
              builder: (context, controller, _) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: isDark ? 0.35 : 0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError
                              ? theme.colorScheme.error.withValues(alpha: 0.85)
                              : _menuOpen
                              ? CreatorColors.primaryOf(context)
                                  .withValues(alpha: 0.75)
                              : border,
                          width: hasError ? 1.4 : (_menuOpen ? 1.4 : 1),
                        ),
                        boxShadow: [
                          if (!_menuOpen)
                            BoxShadow(
                              color: shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          if (_menuOpen)
                            BoxShadow(
                              color: CreatorColors.primaryOf(context)
                                  .withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (widget.showCountryFlag && sel != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: CountryFlag.fromCountryCode(
                                sel.code,
                                height: 20,
                                width: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (!widget.showCountryFlag && sel != null) ...[
                            Text(
                              sel.code,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.textMutedOf(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sel != null
                                      ? sel.name
                                      : '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RotationTransition(
                            turns: Tween<double>(
                              begin: 0,
                              end: 0.5,
                            ).animate(
                              CurvedAnimation(
                                parent: _chevronC,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 26,
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (hasError && field.errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
