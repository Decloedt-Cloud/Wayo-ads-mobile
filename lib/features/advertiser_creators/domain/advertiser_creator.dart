/// Row from `GET /api/advertiser/creators`.
final class AdvertiserCreatorRow {
  const AdvertiserCreatorRow({
    required this.creatorId,
    required this.name,
    this.image,
    this.trustScore,
    this.views = 0,
    this.clicks = 0,
    this.earningsGenerated = 0,
    this.campaigns = const [],
  });

  final String creatorId;
  final String name;
  final String? image;
  final int? trustScore;
  final int views;
  final int clicks;
  final int earningsGenerated;
  final List<String> campaigns;

  factory AdvertiserCreatorRow.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    String id = '';
    String name = '—';
    String? image;
    if (creator is Map) {
      id = '${creator['id'] ?? ''}';
      name = (creator['name'] as String?)?.trim().isNotEmpty == true
          ? creator['name'] as String
          : '—';
      image = creator['image'] as String?;
    }
    final camps = <String>[];
    final rawCamps = json['campaigns'];
    if (rawCamps is List) {
      for (final c in rawCamps) {
        if (c is Map && c['title'] is String) {
          camps.add(c['title'] as String);
        }
      }
    }
    return AdvertiserCreatorRow(
      creatorId: id,
      name: name,
      image: image,
      trustScore: (json['trustScore'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      clicks: (json['clicks'] as num?)?.toInt() ?? 0,
      earningsGenerated: (json['earningsGenerated'] as num?)?.toInt() ?? 0,
      campaigns: camps,
    );
  }
}

final class AdvertiserCreatorsPage {
  const AdvertiserCreatorsPage({
    required this.creators,
    required this.page,
    required this.totalPages,
    required this.totalCount,
  });

  final List<AdvertiserCreatorRow> creators;
  final int page;
  final int totalPages;
  final int totalCount;

  factory AdvertiserCreatorsPage.fromJson(Map<String, dynamic> json) {
    final list = <AdvertiserCreatorRow>[];
    final raw = json['creators'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(AdvertiserCreatorRow.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return AdvertiserCreatorsPage(
      creators: list,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? list.length,
    );
  }
}
