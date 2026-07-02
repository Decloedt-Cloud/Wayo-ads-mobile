import '../../../i18n/strings.g.dart';
import 'major_billing_catalog.dart';
import 'stripe_connect_catalog.dart';

/// Client-side validation aligned with `Wayo-ads/src/lib/validation/business-profile.ts`.
abstract final class BusinessProfileValidation {
  static final RegExp addressLine = RegExp(
    r"^[\p{L}\p{N}\s#\/.,\-&'()°]+$",
    unicode: true,
  );
  static final RegExp companyName = RegExp(
    r"^[\p{L}\p{N}\s.,\-&'/()]+$",
    unicode: true,
  );
  static final RegExp city = RegExp(
    r"^[\p{L}\p{N}\s.,\-']+$",
    unicode: true,
  );
  static final RegExp postal = RegExp(
    r"^[\p{L}\p{N}\s-]+$",
    unicode: true,
  );
  static final RegExp vat = RegExp(
    r"^[\p{L}\p{N}\s./-]{2,32}$",
    unicode: true,
  );
  static final RegExp state = RegExp(
    r"^[\p{L}\p{N}\s.,\-']+$",
    unicode: true,
  );

  static const Set<String> countriesRequiringState = {'US', 'CA'};

  static String? validateCompanyName(
    Translations t, {
    required bool required,
    required String? value,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return required ? t.creator.business.validation.company_name_required : null;
    }
    if (v.length > 200 || !companyName.hasMatch(v)) {
      return t.creator.business.validation.company_name_invalid;
    }
    return null;
  }

  static String? validateVat(
    Translations t, {
    required bool required,
    required String? value,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return required ? t.creator.business.validation.vat_number_required : null;
    }
    if (v.length > 32 || !vat.hasMatch(v)) {
      return t.creator.business.validation.vat_number_invalid;
    }
    return null;
  }

  static String? validateAddressLine1(Translations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.creator.business.validation.address_required;
    if (v.length > 200 || !addressLine.hasMatch(v)) {
      return t.creator.business.validation.address_line_invalid;
    }
    return null;
  }

  static String? validateAddressLine2(Translations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 200 || !addressLine.hasMatch(v)) {
      return t.creator.business.validation.address_line_invalid;
    }
    return null;
  }

  static String? validateCity(Translations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.creator.business.validation.city_required;
    if (v.length > 100 || !city.hasMatch(v)) {
      return t.creator.business.validation.city_invalid;
    }
    return null;
  }

  static String? validatePostal(Translations t, String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.creator.business.validation.postal_code_required;
    if (v.length > 20 || !postal.hasMatch(v)) {
      return t.creator.business.validation.postal_code_invalid;
    }
    return null;
  }

  static String? validateState(
    Translations t, {
    required String? countryCode,
    required String? value,
  }) {
    final country = countryCode?.trim().toUpperCase() ?? '';
    final v = value?.trim() ?? '';
    if (countriesRequiringState.contains(country)) {
      if (v.isEmpty) return t.creator.business.validation.state_required;
    } else if (v.isEmpty) {
      return null;
    }
    if (v.length > 100 || !state.hasMatch(v)) {
      return t.creator.business.validation.state_invalid;
    }
    return null;
  }

  static String? validateCountry(
    Translations t, {
    required bool useGlobalBilling,
    required String? value,
  }) {
    final code = value?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return t.creator.business.validation.country_required;
    if (useGlobalBilling) {
      if (!MajorBillingCatalog.isCountryCode(code)) {
        return t.creator.business.validation.country_global_invalid;
      }
    } else if (!StripeConnectCatalog.isCountryCode(code)) {
      return t.creator.business.validation.country_stripe_only;
    }
    return null;
  }

  static String? validateCurrency(
    Translations t, {
    required bool useGlobalBilling,
    required String? value,
  }) {
    final code = value?.trim().toUpperCase() ?? '';
    if (code.isEmpty) return t.creator.business.validation.currency_required;
    if (useGlobalBilling) {
      if (!MajorBillingCatalog.isCurrencyCode(code)) {
        return t.creator.business.validation.currency_global_invalid;
      }
    } else if (!StripeConnectCatalog.isCurrencyCode(code)) {
      return t.creator.business.validation.currency_stripe_only;
    }
    return null;
  }
}
