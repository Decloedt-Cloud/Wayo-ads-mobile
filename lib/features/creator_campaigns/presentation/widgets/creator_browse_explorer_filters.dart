import 'package:flutter/material.dart';

import '../../../../core/widgets/campaign_explorer_filter_menu.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/domain/campaign_niche_catalog.dart';
import '../../domain/creator_browse_campaign.dart';

/// Web-style dropdown row: options from the **current page**; each menu is
/// shown when that dimension has **at least one** value (plus “All …”).
class CreatorBrowseExplorerFilters extends StatelessWidget {
  const CreatorBrowseExplorerFilters({
    super.key,
    required this.campaigns,
    required this.t,
    required this.typeFilter,
    required this.nicheFilter,
    required this.locationFilter,
    required this.onTypeChanged,
    required this.onNicheChanged,
    required this.onLocationChanged,
  });

  final List<CreatorBrowseCampaign> campaigns;
  final Translations t;
  final CreatorCampaignType? typeFilter;
  final String? nicheFilter;
  final String? locationFilter;
  final void Function(CreatorCampaignType?) onTypeChanged;
  final void Function(String?) onNicheChanged;
  final void Function(String?) onLocationChanged;

  static Set<CreatorCampaignType> _types(List<CreatorBrowseCampaign> list) {
    return list
        .map((c) => c.type)
        .where((x) => x != CreatorCampaignType.unknown)
        .toSet();
  }

  static Set<String> _niches(List<CreatorBrowseCampaign> list) {
    return list
        .map((c) => normalizeCampaignNicheApiValue(c.niche))
        .whereType<String>()
        .toSet();
  }

  static Set<String> _locations(List<CreatorBrowseCampaign> list) {
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
        : campaigns.where((c) => c.type == typeFilter).toList();

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
      final items = <(String?, String)>[
        (null, t.campaigns_explorer.filter_all_types),
        for (final x
            in (typeSet.toList()..sort((a, b) => a.name.compareTo(b.name))))
          (x.name, _typeLabel(x)),
      ];
      final sel = typeFilter?.name;
      menus.add(
        CampaignExplorerFilterMenu(
          caption: t.campaigns_explorer.filter_label_type,
          isActive: typeFilter != null,
          selectedValue: sel,
          items: items,
          onChanged: (raw) {
            if (raw == null) {
              onTypeChanged(null);
            } else {
              onTypeChanged(CreatorCampaignType.fromStoredName(raw));
            }
          },
        ),
      );
    }

    if (nicheSet.isNotEmpty) {
      final sorted = nicheSet.toList()..sort();
      final items = <(String?, String)>[
        (null, t.campaigns_explorer.filter_all_niches),
        for (final n in sorted) (n, campaignNicheFallbackLabel(n)),
      ];
      final nSel = normalizeCampaignNicheApiValue(nicheFilter);
      menus.add(
        CampaignExplorerFilterMenu(
          caption: t.campaigns_explorer.filter_label_niche,
          isActive: nSel != null && nSel.isNotEmpty,
          selectedValue: nSel,
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
      final lSel = normalizeCampaignLocationValue(locationFilter);
      menus.add(
        CampaignExplorerFilterMenu(
          caption: t.campaigns_explorer.filter_label_location,
          isActive: lSel != null && lSel.isNotEmpty,
          selectedValue: lSel,
          items: items,
          onChanged: onLocationChanged,
        ),
      );
    }

    if (menus.isEmpty) {
      return const SizedBox.shrink();
    }

    final gap = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoCols = constraints.maxWidth >= 360;
        if (!useTwoCols) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < menus.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                menus[i],
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < menus.length; i += 2) ...[
              if (i > 0) SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: menus[i]),
                  SizedBox(width: gap),
                  if (i + 1 < menus.length)
                    Expanded(child: menus[i + 1])
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
