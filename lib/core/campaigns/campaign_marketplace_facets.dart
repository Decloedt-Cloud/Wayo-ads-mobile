import '../../features/creator_campaigns/domain/creator_browse_campaign.dart';

/// Explorer facet options returned by `GET /api/campaigns` (`activeNiches`, …).
final class CampaignMarketplaceFacets {
  const CampaignMarketplaceFacets({
    this.activeTypes = const [],
    this.activeNiches = const [],
    this.activeCountries = const [],
  });

  final List<String> activeTypes;
  final List<String> activeNiches;
  final List<String> activeCountries;

  bool get isEmpty =>
      activeTypes.isEmpty && activeNiches.isEmpty && activeCountries.isEmpty;

  factory CampaignMarketplaceFacets.fromJson(Map<String, dynamic> body) {
    List<String> readList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    return CampaignMarketplaceFacets(
      activeTypes: readList(body['activeTypes']),
      activeNiches: readList(body['activeNiches']),
      activeCountries: readList(body['activeCountries']),
    );
  }
}

String? marketplaceCountryApiFromLocation(String? location) {
  final loc = location?.trim().toUpperCase();
  if (loc == null || loc.length != 2) return null;
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(loc)) return null;
  return loc;
}

String? marketplaceTypeApiFromFilter(CreatorCampaignType? type) => switch (type) {
  CreatorCampaignType.link => 'LINK',
  CreatorCampaignType.video => 'VIDEO',
  CreatorCampaignType.shorts => 'SHORTS',
  _ => null,
};

Set<CreatorCampaignType> marketplaceTypesFromFacets(CampaignMarketplaceFacets facets) {
  return facets.activeTypes
      .map(CreatorCampaignType.fromApi)
      .where((t) => t != CreatorCampaignType.unknown)
      .toSet();
}
