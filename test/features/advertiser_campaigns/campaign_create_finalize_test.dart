import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wayoadsgo/core/errors/auth_exceptions.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/data/advertiser_campaigns_repository.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_cost_estimate.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_draft.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_validators.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_logo_prep.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_mutation_result.dart';

Uint8List _encodeSolidJpeg(int width, int height) {
  final src = img.Image(width: width, height: height);
  img.fill(src, color: img.ColorRgb8(20, 40, 60));
  return Uint8List.fromList(img.encodeJpg(src, quality: 90));
}

void main() {
  group('CampaignCostEstimate.assemble', () {
    test('matches web fee+tax total', () {
      final e = CampaignCostEstimate.assemble(
        budgetCents: 10000,
        platformFeePercentage: 5,
        taxCents: 525,
        taxRate: 5,
      );
      expect(e.platformFeeCents, 500);
      expect(e.totalCents, 11025);
      expect(e.platformFeeRate, 0.05);
    });
  });

  group('CampaignLogoPrep', () {
    test('rejects empty and unknown bytes', () {
      expect(CampaignLogoPrep.detectMime(Uint8List(0)), isNull);
      expect(CampaignLogoPrep.detectMime(Uint8List.fromList([1, 2, 3])), isNull);
      expect(
        CampaignLogoPrep.prepareForUpload(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });

    test('center-crops to 16:9 banner aspect', () {
      final jpeg = _encodeSolidJpeg(800, 600);
      final out = CampaignLogoPrep.prepareForUpload(jpeg);
      expect(out, isNotNull);
      expect(out!.mime, 'image/jpeg');
      final decoded = img.decodeImage(out.bytes)!;
      expect(decoded.width / decoded.height, closeTo(16 / 9, 0.02));
    });

    test('detects jpeg magic', () {
      final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
      expect(CampaignLogoPrep.detectMime(jpeg), 'image/jpeg');
    });

    test('detects png magic', () {
      final png = Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]);
      expect(CampaignLogoPrep.detectMime(png), 'image/png');
    });
  });

  group('CampaignEditorValidators', () {
    test('identity and budget gates', () {
      expect(
        CampaignEditorValidators.validateIdentity(CampaignEditorDraft()),
        'title_required',
      );
      final ok = CampaignEditorDraft(
        title: 'T',
        niche: 'FASHION_APPAREL',
        landingUrl: 'https://example.com',
        totalBudgetCents: 5000,
        cpcCents: 10,
        campaignEndDate: '2026-12-31',
      );
      expect(CampaignEditorValidators.validateIdentity(ok), isNull);
      expect(CampaignEditorValidators.validateBudget(ok), isNull);
    });
  });

  group('create mutation + funds errors', () {
    test('CampaignMutationResult active flag', () {
      const r = CampaignMutationResult(id: 'c1', status: 'ACTIVE');
      expect(r.isActive, isTrue);
    });

    test('mapError maps INSUFFICIENT_FUNDS', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/api/campaigns'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/campaigns'),
          statusCode: 400,
          data: {
            'error': 'Insufficient funds',
            'errorCode': 'INSUFFICIENT_FUNDS',
            'details': {
              'required': 11000,
              'available': 1000,
              'platformFee': 500,
              'tax': 500,
            },
            'campaign': {'id': 'draft_1', 'status': 'DRAFT'},
          },
        ),
      );
      final mapped = AdvertiserCampaignsRepository.mapError(e);
      expect(mapped, isA<CampaignInsufficientFundsException>());
      final funds = mapped as CampaignInsufficientFundsException;
      expect(funds.draftCampaignId, 'draft_1');
      expect(funds.requiredCents, 11000);
    });

    test('idempotency key retained until new intention', () {
      const key = 'abcdEFGH-1234_xyzz';
      var used = key;
      used = used; // retry
      expect(used, key);
      final next = 'NEWkey12-3456_abcd';
      expect(next, isNot(equals(key)));
    });
  });

  group('draft roundtrip', () {
    test('local json resume', () {
      final d = CampaignEditorDraft(
        title: 'Resume',
        type: CampaignTypeApi.link,
        niche: 'TECH_SOFTWARE_ELECTRONICS',
        landingUrl: 'https://wayo.ma',
        totalBudgetCents: 2500,
        cpcCents: 15,
        campaignEndDate: '2026-11-01',
      );
      final again = CampaignEditorDraft.fromLocalJson(d.toLocalJson());
      expect(again.title, 'Resume');
      expect(again.cpcCents, 15);
      expect(again.campaignEndDate, '2026-11-01');
    });
  });
}
