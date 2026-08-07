import 'campaign_editor_draft.dart';

/// Client-side step validators mirroring web `STEP_FIELDS` + Zod refinements.
/// Server remains the authority — these only gate UX progression.
abstract final class CampaignEditorValidators {
  static const minBudgetCents = 1000;
  static const maxBudgetCents = 100000000;
  static const maxCpmCents = 1000000;
  static const maxCpcCents = 500000;
  static final endDateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final titleHtmlRe = RegExp(r'<[^>]+>');

  /// Allowed creative asset hosts (web `creative-assets-url`).
  static final _assetHostRe = RegExp(
    r'https://([a-z0-9.-]+\.)?(drive\.google\.com|docs\.google\.com|'
    r'onedrive\.live\.com|1drv\.ms|sharepoint\.com|dropbox\.com|'
    r'db\.tt|youtube\.com|youtu\.be|tiktok\.com|instagram\.com|vimeo\.com)/',
    caseSensitive: false,
  );

  /// Web wizard step 1 — identity.
  static String? validateIdentity(CampaignEditorDraft d) {
    final title = d.title.trim();
    if (title.isEmpty) return 'title_required';
    if (title.length > 200) return 'title_long';
    if (titleHtmlRe.hasMatch(title)) return 'title_html';
    if (d.niche == null || d.niche!.trim().isEmpty) return 'niche_required';

    if (d.type == CampaignTypeApi.link) {
      final url = d.landingUrl?.trim() ?? '';
      if (url.isEmpty) return 'landing_required';
      final normalized = _ensureHttps(url);
      if (Uri.tryParse(normalized)?.hasAbsolutePath != true &&
          Uri.tryParse(normalized)?.host.isEmpty != false) {
        final u = Uri.tryParse(normalized);
        if (u == null || !u.hasScheme || u.host.isEmpty) {
          return 'landing_invalid';
        }
      }
      final u = Uri.tryParse(_ensureHttps(url));
      if (u == null ||
          (u.scheme != 'http' && u.scheme != 'https') ||
          u.host.isEmpty) {
        return 'landing_invalid';
      }
    }

    if (d.type == CampaignTypeApi.video || d.type == CampaignTypeApi.shorts) {
      final assets = d.assetsUrl?.trim() ?? '';
      if (assets.isEmpty) return 'assets_required';
      final urls = assets
          .split(RegExp(r'[\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (urls.isEmpty || urls.length > 5) return 'assets_invalid';
      for (final u in urls) {
        if (!_assetHostRe.hasMatch(u)) {
          return 'assets_invalid';
        }
      }
    }
    return null;
  }

  /// Web wizard step 2 — budget & settings.
  static String? validateBudget(CampaignEditorDraft d) {
    if (d.totalBudgetCents < minBudgetCents) return 'budget_min';
    if (d.totalBudgetCents > maxBudgetCents) return 'budget_max';

    if (d.type == CampaignTypeApi.link) {
      final cpc = d.cpcCents ?? 0;
      if (cpc <= 0) return 'cpc_required';
      if (cpc > maxCpcCents) return 'cpc_max';
    } else {
      if (d.cpmCents <= 0) return 'cpm_required';
      if (d.cpmCents > maxCpmCents) return 'cpm_max';
    }

    final end = d.campaignEndDate?.trim() ?? '';
    if (!endDateRe.hasMatch(end)) return 'end_date';
    final parsed = DateTime.tryParse(end);
    if (parsed == null) return 'end_date';
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (!parsed.isAfter(todayDate.subtract(const Duration(days: 0))) &&
        parsed.isBefore(todayDate)) {
      return 'end_date_past';
    }
    // End of day UTC on server — require date >= today local.
    if (parsed.isBefore(todayDate)) return 'end_date_past';

    if (d.type == CampaignTypeApi.video) {
      final min = d.videoMinDurationMinutes ?? 0;
      if (min < 1 || min > 10) return 'video_duration';
    }
    if (d.type == CampaignTypeApi.shorts) {
      final maxSec = d.shortsMaxDurationSeconds ?? 0;
      if (maxSec < 15) return 'shorts_duration';
    }

    final maxPayout = d.maxPayoutCentsPerVideo;
    if (maxPayout != null && maxPayout > d.totalBudgetCents) {
      return 'max_payout';
    }

    if (d.isGeoTargeted) {
      final country = d.targetCountryCode?.trim() ?? '';
      if (country.isEmpty) return 'geo_country';
      final radius = d.targetRadiusKm ?? 50;
      if (radius < 1 || radius > 1000) return 'geo_radius';
    }
    return null;
  }

  /// Full form before submit (identity + budget).
  static String? validateAll(CampaignEditorDraft d) {
    return validateIdentity(d) ?? validateBudget(d);
  }

  static String _ensureHttps(String url) {
    final t = url.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }
}
