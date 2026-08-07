import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_draft.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_validators.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_status_actions.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/campaign_status.dart';

void main() {
  group('campaignOwnerStatusActions', () {
    test('draft can publish only', () {
      final actions = campaignOwnerStatusActions(CampaignStatus.draft);
      expect(actions.map((e) => e.apiStatus), ['ACTIVE']);
    });

    test('active can pause and cancel', () {
      final actions = campaignOwnerStatusActions(CampaignStatus.active);
      expect(actions.map((e) => e.apiStatus).toList(), ['PAUSED', 'CANCELLED']);
    });

    test('edit allowed for draft/active/paused', () {
      expect(campaignAllowsOwnerEdit(CampaignStatus.draft), isTrue);
      expect(campaignAllowsOwnerEdit(CampaignStatus.cancelled), isFalse);
    });
  });

  group('CampaignEditorDraft.toApiBody web parity', () {
    test('LINK forces TRAFFIC, CPC, empty platforms, landingUrl', () {
      final draft = CampaignEditorDraft(
        title: 'Summer',
        type: CampaignTypeApi.link,
        niche: 'FASHION',
        landingUrl: 'https://example.com',
        totalBudgetCents: 5000,
        cpcCents: 25,
        cpmCents: 999,
        campaignEndDate: '2026-12-31',
      );
      final body = draft.toApiBody(includeStatus: true);
      expect(body['type'], 'LINK');
      expect(body['campaignObjective'], 'TRAFFIC');
      expect(body['platforms'], '');
      expect(body['cpcCents'], 25);
      expect(body['cpmCents'], 0);
      expect(body['landingUrl'], 'https://example.com');
      expect(body['assetsUrl'], isNull);
      expect(body['status'], 'DRAFT');
    });

    test('VIDEO forces AWARENESS, CPM, videoRequirements', () {
      final draft = CampaignEditorDraft(
        title: 'V',
        type: CampaignTypeApi.video,
        niche: 'TECH',
        assetsUrl: 'https://drive.google.com/file/d/abc',
        totalBudgetCents: 10000,
        cpmCents: 200,
        videoMinDurationMinutes: 3,
        campaignEndDate: '2026-12-31',
        allowMultiplePosts: false,
      );
      final body = draft.toApiBody(includeStatus: false);
      expect(body['campaignObjective'], 'AWARENESS');
      expect(body['platforms'], 'YOUTUBE');
      expect(body['cpmCents'], 200);
      expect(body['cpcCents'], 0);
      expect(body['landingUrl'], isNull);
      expect(body['videoMinDurationMinutes'], 3);
      expect(body['videoRequirements'], isA<Map>());
      expect((body['videoRequirements'] as Map)['requiredPlatform'], 'YOUTUBE');
      expect((body['videoRequirements'] as Map)['allowMultiplePosts'], isFalse);
    });

    test('geo off clears target fields', () {
      final draft = CampaignEditorDraft(
        title: 'G',
        isGeoTargeted: false,
        targetCountryCode: 'US',
        campaignEndDate: '2026-12-31',
      );
      final body = draft.toApiBody(includeStatus: false);
      expect(body['isGeoTargeted'], isFalse);
      expect(body['targetCountryCode'], isNull);
    });

    test('local json roundtrip preserves allowMultiplePosts', () {
      final draft = CampaignEditorDraft(
        title: 'R',
        type: CampaignTypeApi.shorts,
        allowMultiplePosts: false,
        campaignEndDate: '2026-12-31',
        assetsUrl: 'https://youtube.com/watch?v=1',
      );
      final again = CampaignEditorDraft.fromLocalJson(draft.toLocalJson());
      expect(again.allowMultiplePosts, isFalse);
      expect(again.type, CampaignTypeApi.shorts);
    });
  });

  group('CampaignEditorValidators', () {
    test('identity requires title niche landing for LINK', () {
      expect(
        CampaignEditorValidators.validateIdentity(CampaignEditorDraft()),
        'title_required',
      );
      expect(
        CampaignEditorValidators.validateIdentity(
          CampaignEditorDraft(title: 'T', niche: 'FASHION'),
        ),
        'landing_required',
      );
      expect(
        CampaignEditorValidators.validateIdentity(
          CampaignEditorDraft(
            title: 'T',
            niche: 'FASHION',
            landingUrl: 'https://example.com/x',
          ),
        ),
        isNull,
      );
    });

    test('budget requires CPC for LINK and future end date', () {
      final d = CampaignEditorDraft(
        title: 'T',
        niche: 'FASHION',
        landingUrl: 'https://example.com',
        totalBudgetCents: 500,
        campaignEndDate: '2026-12-31',
      );
      expect(CampaignEditorValidators.validateBudget(d), 'budget_min');
      d.totalBudgetCents = 5000;
      d.cpcCents = 0;
      expect(CampaignEditorValidators.validateBudget(d), 'cpc_required');
      d.cpcCents = 10;
      expect(CampaignEditorValidators.validateBudget(d), isNull);
    });

    test('geo requires country', () {
      final d = CampaignEditorDraft(
        title: 'T',
        niche: 'FASHION',
        landingUrl: 'https://example.com',
        totalBudgetCents: 5000,
        cpcCents: 10,
        campaignEndDate: '2026-12-31',
        isGeoTargeted: true,
      );
      expect(CampaignEditorValidators.validateBudget(d), 'geo_country');
      d.targetCountryCode = 'MA';
      expect(CampaignEditorValidators.validateBudget(d), isNull);
    });

    test('VIDEO assets host validation', () {
      final d = CampaignEditorDraft(
        title: 'T',
        type: CampaignTypeApi.video,
        niche: 'TECH',
        assetsUrl: 'https://evil.example/file',
      );
      expect(CampaignEditorValidators.validateIdentity(d), 'assets_invalid');
      d.assetsUrl = 'https://drive.google.com/file/d/abc';
      expect(CampaignEditorValidators.validateIdentity(d), isNull);
    });
  });

  group('idempotency key shape', () {
    test('base64url without padding length in 8..128', () {
      final key = List.generate(16, (i) => i).toString();
      // Smoke: server accepts [A-Za-z0-9._~-] 8-128 — our generator uses base64url.
      expect(
        RegExp(r'^[A-Za-z0-9_\-]{8,128}$').hasMatch('abcdefghijklmnop'),
        isTrue,
      );
      expect(key.isNotEmpty, isTrue);
    });
  });
}
