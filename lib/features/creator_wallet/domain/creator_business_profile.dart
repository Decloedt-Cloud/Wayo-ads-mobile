import 'package:equatable/equatable.dart';

/// Business type used for creator payout onboarding.
///
/// Mirrors `src/lib/validation/business-profile.ts` on Wayo-ads.
enum CreatorBusinessType {
  personal,
  soleProprietor,
  registeredCompany;

  /// API / DB string value (uppercased snake case).
  String get apiValue => switch (this) {
    CreatorBusinessType.personal => 'PERSONAL',
    CreatorBusinessType.soleProprietor => 'SOLE_PROPRIETOR',
    CreatorBusinessType.registeredCompany => 'REGISTERED_COMPANY',
  };

  static CreatorBusinessType fromApi(dynamic raw) {
    final s = (raw as String?)?.trim().toUpperCase() ?? '';
    return switch (s) {
      'PERSONAL' => CreatorBusinessType.personal,
      'SOLE_PROPRIETOR' => CreatorBusinessType.soleProprietor,
      'REGISTERED_COMPANY' => CreatorBusinessType.registeredCompany,
      _ => CreatorBusinessType.personal,
    };
  }
}

/// Read-only business info returned by `GET /api/creator/business-profile`.
final class CreatorBusinessProfile extends Equatable {
  const CreatorBusinessProfile({
    required this.businessType,
    required this.businessInfoComplete,
    this.companyName,
    this.vatNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postalCode,
    this.state,
    this.countryCode,
    this.currency,
  });

  final CreatorBusinessType businessType;
  final bool businessInfoComplete;
  final String? companyName;
  final String? vatNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postalCode;
  final String? state;
  final String? countryCode;
  final String? currency;

  factory CreatorBusinessProfile.empty() => const CreatorBusinessProfile(
    businessType: CreatorBusinessType.personal,
    businessInfoComplete: false,
  );

  /// The wallet endpoint shape is `{ profile: {...}, businessInfoComplete }`.
  factory CreatorBusinessProfile.fromEnvelope(Map<String, dynamic> json) {
    final raw = json['profile'];
    final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final complete = json['businessInfoComplete'] == true;
    if (map == null) {
      return CreatorBusinessProfile.empty()._withComplete(complete);
    }
    String? asStr(dynamic v) {
      if (v is String) {
        final s = v.trim();
        return s.isEmpty ? null : s;
      }
      return null;
    }

    return CreatorBusinessProfile(
      businessType: CreatorBusinessType.fromApi(map['businessType']),
      businessInfoComplete: complete,
      companyName: asStr(map['companyName']),
      vatNumber: asStr(map['vatNumber']),
      addressLine1: asStr(map['addressLine1']),
      addressLine2: asStr(map['addressLine2']),
      city: asStr(map['city']),
      postalCode: asStr(map['postalCode']),
      state: asStr(map['state']),
      countryCode: asStr(map['countryCode'])?.toUpperCase(),
      currency: asStr(map['currency'])?.toUpperCase(),
    );
  }

  CreatorBusinessProfile _withComplete(bool v) => CreatorBusinessProfile(
    businessType: businessType,
    businessInfoComplete: v,
    companyName: companyName,
    vatNumber: vatNumber,
    addressLine1: addressLine1,
    addressLine2: addressLine2,
    city: city,
    postalCode: postalCode,
    state: state,
    countryCode: countryCode,
    currency: currency,
  );

  @override
  List<Object?> get props => [
    businessType,
    businessInfoComplete,
    companyName,
    vatNumber,
    addressLine1,
    addressLine2,
    city,
    postalCode,
    state,
    countryCode,
    currency,
  ];
}

/// Payload for `PUT /api/creator/business-profile`.
///
/// Server enforces the same required fields per business type via
/// `creatorBusinessProfileSchema` (zod). We keep the client-side rules in sync
/// to fail fast.
final class CreatorBusinessProfileInput extends Equatable {
  const CreatorBusinessProfileInput({
    required this.businessType,
    required this.addressLine1,
    required this.city,
    required this.postalCode,
    required this.countryCode,
    required this.currency,
    this.companyName,
    this.vatNumber,
    this.addressLine2,
    this.state,
  });

  final CreatorBusinessType businessType;
  final String addressLine1;
  final String city;
  final String postalCode;
  final String countryCode;
  final String currency;
  final String? companyName;
  final String? vatNumber;
  final String? addressLine2;
  final String? state;

  Map<String, dynamic> toJson() => {
    'businessType': businessType.apiValue,
    'addressLine1': addressLine1,
    if (addressLine2 != null && addressLine2!.isNotEmpty)
      'addressLine2': addressLine2,
    'city': city,
    'postalCode': postalCode,
    if (state != null && state!.isNotEmpty) 'state': state,
    'countryCode': countryCode,
    'currency': currency,
    if (companyName != null && companyName!.isNotEmpty)
      'companyName': companyName,
    if (vatNumber != null && vatNumber!.isNotEmpty)
      'vatNumber': vatNumber!.toUpperCase(),
  };

  @override
  List<Object?> get props => [
    businessType,
    addressLine1,
    city,
    postalCode,
    countryCode,
    currency,
    companyName,
    vatNumber,
    addressLine2,
    state,
  ];
}
