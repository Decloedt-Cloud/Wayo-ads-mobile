import 'package:flutter/material.dart';

import '../../../../core/widgets/campaign_explorer_filter_menu.dart';
import '../../../../i18n/strings.g.dart';
import '../../../creator_campaigns/domain/creator_browse_campaign.dart';
import '../../domain/advertiser_campaign.dart';
import '../../domain/campaign_niche_catalog.dart';
import '../providers/advertiser_campaigns_providers.dart';

/// Options from the **current page** only; each menu appears when that
/// dimension has **at least one** value on the relevant slice (plus “All …”).
/// Status (active / draft / …) is always shown as a dropdown alongside type / niche / location when applicable.
class AdvertiserCampaignExplorerFilters extends StatelessWidget {
  const AdvertiserCampaignExplorerFilters({
    super.key,
    required this.campaigns,
    required this.t,
    required this.statusTab,
    required this.statusCounts,
    required this.onStatusChanged,
    required this.typeFilter,
    required this.nicheFilter,
    required this.locationFilter,
    required this.onTypeChanged,
    required this.onNicheChanged,
    required this.onLocationChanged,
  });

  final List<AdvertiserCampaign> campaigns;
  final Translations t;
  final AdvertiserCampaignsTab statusTab;
  final ({int active, int draft, int paused, int completed}) statusCounts;
  final void Function(AdvertiserCampaignsTab) onStatusChanged;
  final CreatorCampaignType? typeFilter;
  final String? nicheFilter;
  final String? locationFilter;
  final void Function(CreatorCampaignType?) onTypeChanged;
  final void Function(String?) onNicheChanged;
  final void Function(String?) onLocationChanged;

  Set<CreatorCampaignType> _types(List<AdvertiserCampaign> list) {
    return list
        .map((c) => c.campaignType)
        .where((x) => x != CreatorCampaignType.unknown)
        .toSet();
  }

  Set<String> _niches(List<AdvertiserCampaign> list) {
    return list
        .map((c) => normalizeCampaignNicheApiValue(c.niche))
        .whereType<String>()
        .toSet();
  }

  Set<String> _locations(List<AdvertiserCampaign> list) {
    return list
        .map((c) => normalizeCampaignLocationValue(c.location))
        .whereType<String>()
        .toSet();
  }

  String _typeLabel(CreatorCampaignType x) => switch (x) {
    CreatorCampaignType.link => t.creator.campaigns.type_link,
    CreatorCampaignType.video => t.creator.campaigns.type_video,
    CreatorCampaignType.shorts => t.creator.campaigns.type_shorts,
    CreatorCampaignType.unknown => '—',
  };

  @override
  Widget build(BuildContext context) {
    final afterType = typeFilter == null
        ? campaigns
        : campaigns.where((c) => c.campaignType == typeFilter).toList();

    final typeSet = _types(campaigns);

    final nicheScope = afterType;
    final nicheSet = _niches(nicheScope);

    final locScope = (nicheFilter ?? '').isEmpty
        ? nicheScope
        : nicheScope
              .where(
                (c) =>
                    normalizeCampaignNicheApiValue(c.niche) ==
                    normalizeCampaignNicheApiValue(nicheFilter),
              )
              .toList();
    final locSet = _locations(locScope);

    final menus = <Widget>[];

    if (typeSet.isNotEmpty) {
      final sorted = typeSet.toList()..sort((a, b) => a.name.compareTo(b.name));
      final items = <(String?, String)>[
        (null, t.campaigns_explorer.filter_all_types),
        for (final x in sorted) (x.name, _typeLabel(x)),
      ];
      menus.add(
        CampaignExplorerFilterMenu(
          selectedValue: typeFilter?.name,
          items: items,
          onChanged: (raw) => onTypeChanged(
            raw == null ? null : CreatorCampaignType.fromStoredName(raw),
          ),
        ),
      );
    }

    menus.add(
      CampaignExplorerFilterMenu(
        selectedValue: statusTab.name,
        items: [
          (
            AdvertiserCampaignsTab.active.name,
            '${t.advertiser_campaigns.tabs.active} (${statusCounts.active})',
          ),
          (
            AdvertiserCampaignsTab.draft.name,
            '${t.advertiser_campaigns.tabs.draft} (${statusCounts.draft})',
          ),
          (
            AdvertiserCampaignsTab.paused.name,
            '${t.advertiser_campaigns.tabs.paused} (${statusCounts.paused})',
          ),
          (
            AdvertiserCampaignsTab.completed.name,
            '${t.advertiser_campaigns.tabs.completed} (${statusCounts.completed})',
          ),
        ],
        onChanged: (raw) {
          if (raw == null) return;
          onStatusChanged(AdvertiserCampaignsTab.values.byName(raw));
        },
      ),
    );

    if (nicheSet.isNotEmpty) {
      final sorted = nicheSet.toList()..sort();
      final items = <(String?, String)>[
        (null, t.campaigns_explorer.filter_all_niches),
        for (final n in sorted) (n, campaignNicheFallbackLabel(n)),
      ];
      menus.add(
        CampaignExplorerFilterMenu(
          selectedValue: normalizeCampaignNicheApiValue(nicheFilter),
          items: items,
          onChanged: onNicheChanged,
        ),
      );
    }

    if (locSet.isNotEmpty) {
      final sorted = locSet.toList()..sort();
      final items = <(String?, String)>[
        (null, t.campaigns_explorer.filter_all_locations),
        for (final loc in sorted) (loc, loc),
      ];
      menus.add(
        CampaignExplorerFilterMenu(
          selectedValue: normalizeCampaignLocationValue(locationFilter),
          items: items,
          onChanged: onLocationChanged,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: menus,
    );
  }
}
