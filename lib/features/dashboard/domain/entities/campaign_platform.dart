enum CampaignPlatform {
  youtube,
  tiktok,
  instagram,
  unknown;

  static CampaignPlatform fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'youtube':
        return youtube;
      case 'tiktok':
        return tiktok;
      case 'instagram':
        return instagram;
      default:
        return unknown;
    }
  }
}
