import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_wallet_remote_datasource.dart';
import '../../domain/business_profile_validation.dart';
import '../../domain/business_subdivisions.dart';
import '../../domain/creator_business_profile.dart';
import '../../domain/major_billing_catalog.dart';
import '../../domain/stripe_connect_catalog.dart';
import '../providers/creator_wallet_providers.dart';

const _businessProfileApiFieldKeys = <String>{
  'businessType',
  'companyName',
  'vatNumber',
  'addressLine1',
  'city',
  'postalCode',
  'state',
  'countryCode',
  'currency',
};

/// Opens business info on a dedicated full-screen page (keyboard-safe layout).
///
/// Returns `true` when the user successfully saved a complete profile.
Future<bool> openBusinessInfoScreen(
  BuildContext context, {
  required CreatorBusinessProfile initial,
  bool useGlobalBilling = false,
}) async {
  final result = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => BusinessInfoScreen(
        initial: initial,
        useGlobalBilling: useGlobalBilling,
      ),
    ),
  );
  return result == true;
}

class BusinessInfoScreen extends ConsumerStatefulWidget {
  const BusinessInfoScreen({
    super.key,
    required this.initial,
    this.useGlobalBilling = false,
  });

  final CreatorBusinessProfile initial;
  final bool useGlobalBilling;

  @override
  ConsumerState<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends ConsumerState<BusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late CreatorBusinessType _businessType;
  late TextEditingController _companyName;
  late TextEditingController _vatNumber;
  late TextEditingController _addressLine1;
  late TextEditingController _city;
  late TextEditingController _postalCode;
  late TextEditingController _state;
  String? _countryCode;
  String? _currency;
  bool _submitting = false;
  String? _apiError;
  Map<String, String> _serverFieldErrors = {};

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _businessType = p.businessType;
    _companyName = TextEditingController(text: p.companyName ?? '');
    _vatNumber = TextEditingController(text: p.vatNumber ?? '');
    _addressLine1 = TextEditingController(
      text: _initialAddressText(p),
    );
    _city = TextEditingController(text: p.city ?? '');
    _postalCode = TextEditingController(text: p.postalCode ?? '');
    _state = TextEditingController(text: p.state ?? '');
    _countryCode = _validCountry(p.countryCode);
    _currency = _validCurrency(p.currency) ??
        (widget.useGlobalBilling ? 'USD' : 'USD');
    final normalizedState = BusinessSubdivisions.normalizeStored(
      _countryCode,
      p.state,
    );
    if (normalizedState != null) {
      _state.text = normalizedState;
    }
  }

  @override
  void dispose() {
    _companyName.dispose();
    _vatNumber.dispose();
    _addressLine1.dispose();
    _city.dispose();
    _postalCode.dispose();
    _state.dispose();
    super.dispose();
  }

  String _initialAddressText(CreatorBusinessProfile p) {
    final line1 = p.addressLine1?.trim() ?? '';
    final line2 = p.addressLine2?.trim() ?? '';
    if (line1.isEmpty) return line2;
    if (line2.isEmpty) return line1;
    return '$line1, $line2';
  }

  List<StripeConnectOption> get _countryOptions => widget.useGlobalBilling
      ? MajorBillingCatalog.countries
      : StripeConnectCatalog.countriesForBusinessType(_businessType);

  List<StripeConnectOption> get _currencyOptions => widget.useGlobalBilling
      ? MajorBillingCatalog.currencies
      : StripeConnectCatalog.currencies;

  bool get _stateUsesDropdown =>
      BusinessSubdivisions.countryUsesDropdown(_countryCode);

  String? _validCountry(String? v) {
    if (v == null) return null;
    final code = v.trim().toUpperCase();
    for (final o in _countryOptions) {
      if (o.code == code) return o.code;
    }
    return null;
  }

  String? _validCurrency(String? v) {
    if (v == null) return null;
    final code = v.trim().toUpperCase();
    for (final o in _currencyOptions) {
      if (o.code == code) return o.code;
    }
    return null;
  }

  void _onBusinessTypeChanged(CreatorBusinessType v) {
    setState(() {
      _businessType = v;
      _serverFieldErrors.remove('businessType');
      if (!widget.useGlobalBilling &&
          _countryCode != null &&
          v == CreatorBusinessType.personal &&
          StripeConnectCatalog.isCompanyOnlyCountry(_countryCode!)) {
        _countryCode = null;
        _serverFieldErrors.remove('countryCode');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.validate();
    });
  }

  void _onCountryChanged(String? v) {
    setState(() {
      _countryCode = v;
      _serverFieldErrors.remove('countryCode');
      if (BusinessSubdivisions.countryUsesDropdown(v)) {
        final normalized = BusinessSubdivisions.normalizeStored(
          v,
          _state.text,
        );
        if (normalized == null ||
            !BusinessSubdivisions.isValidCode(v, normalized)) {
          _state.clear();
        } else {
          _state.text = normalized;
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.validate();
    });
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
      city: _city.text.trim(),
      postalCode: _postalCode.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      countryCode: _countryCode!,
      currency: _currency!,
      companyName: _companyName.text.trim().isEmpty
          ? null
          : _companyName.text.trim(),
      vatNumber: _vatNumber.text.trim().isEmpty ? null : _vatNumber.text.trim(),
      profileValidationGlobal: widget.useGlobalBilling,
    );

    setState(() {
      _submitting = true;
      _apiError = null;
      _serverFieldErrors = {};
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
      _applyServerIssueFromApi(e);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = '$e'.isEmpty ? t.creator.business.save_error : '$e';
        _submitting = false;
      });
    }
  }

  void _onFieldEdited(String apiFieldKey) {
    setState(() => _serverFieldErrors.remove(apiFieldKey));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.validate();
    });
  }

  void _applyServerIssueFromApi(CreatorWalletApiException e) {
    final issues = e.validationIssues;
    if (issues == null || issues.isEmpty) {
      setState(() {
        _apiError = e.message;
        _submitting = false;
      });
      return;
    }
    final fieldErr = <String, String>{};
    final other = <String>[];
    for (final issue in issues) {
      final key = issue.fieldKey;
      if (key != null && _businessProfileApiFieldKeys.contains(key)) {
        fieldErr[key] = issue.message;
      } else if (issue.message.isNotEmpty) {
        other.add(issue.message);
      }
    }
    setState(() {
      _serverFieldErrors = fieldErr;
      _apiError = other.isNotEmpty
          ? other.join('\n')
          : (fieldErr.isEmpty ? e.message : null);
      _submitting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formKey.currentState?.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    final formBody = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.creator.business.dialog_subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(
            label: t.creator.business.section_type,
          ),
                          const SizedBox(height: 8),
                          _BusinessTypeSelector(
                            value: _businessType,
                            serverError:
                                _serverFieldErrors['businessType'],
                            onChanged: _onBusinessTypeChanged,
                          ),
                          const SizedBox(height: 20),
                          if (_businessType ==
                              CreatorBusinessType
                                  .registeredCompany) ...[
                            _SectionLabel(
                              label: t.creator.business.section_company,
                            ),
                            const SizedBox(height: 8),
                            _RequiredField(
                              controller: _companyName,
                              label: t.creator.business.company_name,
                              serverError:
                                  _serverFieldErrors['companyName'],
                              onClearServerError: () =>
                                  _onFieldEdited('companyName'),
                              validate: (v) =>
                                  BusinessProfileValidation.validateCompanyName(
                                    t,
                                    required: true,
                                    value: v,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _RequiredField(
                              controller: _vatNumber,
                              label: t.creator.business.vat_number,
                              capitalize: true,
                              serverError:
                                  _serverFieldErrors['vatNumber'],
                              onClearServerError: () =>
                                  _onFieldEdited('vatNumber'),
                              validate: (v) => BusinessProfileValidation
                                  .validateVat(
                                    t,
                                    required: true,
                                    value: v,
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ] else ...[
                            _OptionalField(
                              controller: _vatNumber,
                              label: t.creator.business.vat_optional,
                              capitalize: true,
                              serverError:
                                  _serverFieldErrors['vatNumber'],
                              onClearServerError: () =>
                                  _onFieldEdited('vatNumber'),
                              validate: (v) => BusinessProfileValidation
                                  .validateVat(
                                    t,
                                    required: false,
                                    value: v,
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _SectionLabel(
                            label: t.creator.business.section_address,
                          ),
                          const SizedBox(height: 8),
                          _RequiredField(
                            controller: _addressLine1,
                            label: t.creator.business.address,
                            serverError:
                                _serverFieldErrors['addressLine1'],
                            onClearServerError: () =>
                                _onFieldEdited('addressLine1'),
                            validate: (v) =>
                                BusinessProfileValidation.validateAddressLine1(
                                  t,
                                  v,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RequiredField(
                                  controller: _city,
                                  label: t.creator.business.city,
                                  serverError:
                                      _serverFieldErrors['city'],
                                  onClearServerError: () =>
                                      _onFieldEdited('city'),
                                  validate: (v) =>
                                      BusinessProfileValidation.validateCity(
                                        t,
                                        v,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RequiredField(
                                  controller: _postalCode,
                                  label:
                                      t.creator.business.postal_code,
                                  serverError:
                                      _serverFieldErrors[
                                          'postalCode'],
                                  onClearServerError: () =>
                                      _onFieldEdited('postalCode'),
                                  validate: (v) =>
                                      BusinessProfileValidation.validatePostal(
                                        t,
                                        v,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_stateUsesDropdown)
                            _StateDropdownField(
                              key: ValueKey('state_${_countryCode ?? '∅'}'),
                              countryCode: _countryCode,
                              value: _state.text.trim().isEmpty
                                  ? null
                                  : _state.text.trim(),
                              label: t.creator.business.state,
                              errorRequired:
                                  t.creator.business.validation.state_required,
                              serverError: _serverFieldErrors['state'],
                              onChanged: (v) {
                                _state.text = v ?? '';
                                _onFieldEdited('state');
                              },
                              validate: (v) =>
                                  BusinessProfileValidation.validateState(
                                    t,
                                    countryCode: _countryCode,
                                    value: v,
                                  ),
                            )
                          else
                            _OptionalField(
                              controller: _state,
                              label:
                                  t.creator.business.state_region,
                              serverError: _serverFieldErrors['state'],
                              onClearServerError: () =>
                                  _onFieldEdited('state'),
                              validate: (v) =>
                                  BusinessProfileValidation.validateState(
                                    t,
                                    countryCode: _countryCode,
                                    value: v,
                                  ),
                            ),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            label: widget.useGlobalBilling
                                ? t.creator.business.section_billing
                                : t.creator.business.section_stripe,
                          ),
                          const SizedBox(height: 8),
                          _ModernConnectSelect(
                            key: ValueKey(
                              'country_${_countryCode ?? '∅'}_${_businessType.name}',
                            ),
                            label: t.creator.business.country,
                            errorRequired:
                                t.creator.business.validation.country_required,
                            items: _countryOptions,
                            value: _countryCode,
                            showCountryFlag: true,
                            serverError:
                                _serverFieldErrors['countryCode'],
                            validate: (v) =>
                                BusinessProfileValidation.validateCountry(
                                  t,
                                  useGlobalBilling: widget.useGlobalBilling,
                                  value: v,
                                ),
                            onChanged: _onCountryChanged,
                          ),
                          const SizedBox(height: 12),
                          _ModernConnectSelect(
                            key: ValueKey(
                              'currency_${_currency ?? '∅'}_${widget.useGlobalBilling}',
                            ),
                            label: widget.useGlobalBilling
                                ? t.creator.business.billing_currency
                                : t.creator.business.currency,
                            errorRequired:
                                t.creator.business.validation.currency_required,
                            items: _currencyOptions,
                            value: _currency,
                            showCountryFlag: false,
                            serverError:
                                _serverFieldErrors['currency'],
                            validate: (v) =>
                                BusinessProfileValidation.validateCurrency(
                                  t,
                                  useGlobalBilling: widget.useGlobalBilling,
                                  value: v,
                                ),
                            onChanged: (v) {
                              setState(() {
                                _currency = v;
                                _serverFieldErrors
                                    .remove('currency');
                              });
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                if (mounted) {
                                  _formKey.currentState
                                      ?.validate();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _FormFooter(
                            apiError: _apiError,
                            submitting: _submitting,
                            useGlobalBilling: widget.useGlobalBilling,
                            onSubmit: _submit,
                          ),
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: const WayoBlackBottomBar(),
      appBar: AppBar(
        title: Text(
          t.creator.business.dialog_title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headlineMedium(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: formBody,
      ),
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.apiError,
    required this.submitting,
    required this.useGlobalBilling,
    required this.onSubmit,
  });

  final String? apiError;
  final bool submitting;
  final bool useGlobalBilling;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          useGlobalBilling
              ? t.creator.business.footer_info_global
              : t.creator.business.footer_info,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMutedOf(context),
          ),
        ),
      ],
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
  const _BusinessTypeSelector({
    required this.value,
    required this.onChanged,
    this.serverError,
  });

  final CreatorBusinessType value;
  final ValueChanged<CreatorBusinessType> onChanged;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final err = serverError?.trim();
    return DropdownButtonFormField<CreatorBusinessType>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceElevatedOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: CreatorColors.primaryOf(context),
            width: 1.5,
          ),
        ),
        errorText: err != null && err.isNotEmpty ? err : null,
      ),
      items: [
        DropdownMenuItem(
          value: CreatorBusinessType.personal,
          child: Text(t.creator.business.type_personal_title),
        ),
        DropdownMenuItem(
          value: CreatorBusinessType.registeredCompany,
          child: Text(t.creator.business.type_company_title),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        HapticFeedback.selectionClick();
        onChanged(v);
      },
    );
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    required this.validate,
    this.capitalize = false,
    this.serverError,
    this.onClearServerError,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validate;
  final bool capitalize;
  final String? serverError;
  final VoidCallback? onClearServerError;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return TextFormField(
      controller: controller,
      textCapitalization: capitalize
          ? TextCapitalization.characters
          : TextCapitalization.words,
      scrollPadding: EdgeInsets.only(bottom: bottomInset + 24),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onClearServerError?.call(),
      validator: (v) {
        final se = serverError?.trim();
        if (se != null && se.isNotEmpty) return se;
        return validate(v);
      },
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.controller,
    required this.label,
    this.capitalize = false,
    this.serverError,
    this.onClearServerError,
    this.validate,
  });

  final TextEditingController controller;
  final String label;
  final bool capitalize;
  final String? serverError;
  final VoidCallback? onClearServerError;
  final String? Function(String?)? validate;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return TextFormField(
      controller: controller,
      textCapitalization: capitalize
          ? TextCapitalization.characters
          : TextCapitalization.words,
      scrollPadding: EdgeInsets.only(bottom: bottomInset + 24),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onClearServerError?.call(),
      validator: (v) {
        final se = serverError?.trim();
        if (se != null && se.isNotEmpty) return se;
        return validate?.call(v);
      },
    );
  }
}

class _StateDropdownField extends StatelessWidget {
  const _StateDropdownField({
    super.key,
    required this.countryCode,
    required this.value,
    required this.label,
    required this.errorRequired,
    required this.onChanged,
    required this.validate,
    this.serverError,
  });

  final String? countryCode;
  final String? value;
  final String label;
  final String errorRequired;
  final ValueChanged<String?> onChanged;
  final String? Function(String?) validate;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    return _ModernConnectSelect(
      label: label,
      errorRequired: errorRequired,
      items: BusinessSubdivisions.pickerOptions(countryCode),
      value: value,
      showCountryFlag: false,
      serverError: serverError,
      validate: validate,
      onChanged: onChanged,
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
    required this.validate,
    this.serverError,
  });

  final String label;
  final String errorRequired;
  final List<StripeConnectOption> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool showCountryFlag;
  final String? Function(String?) validate;
  final String? serverError;

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
      validator: (v) {
        final se = widget.serverError?.trim();
        if (se != null && se.isNotEmpty) return se;
        final custom = widget.validate(v);
        if (custom != null) return custom;
        return (v == null || v.isEmpty) ? widget.errorRequired : null;
      },
      builder: (field) {
        final se = widget.serverError?.trim();
        final hasError = field.hasError || (se != null && se.isNotEmpty);
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
            if (hasError &&
                (field.errorText != null ||
                    (se != null && se.isNotEmpty))) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText ?? se ?? '',
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
