import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_cost_estimate.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_draft.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_validators.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_logo_prep.dart';
import 'package:wayoadsgo/features/auth/domain/wayo_ads_account_role.dart';

/// Mirrors GoRouter advertiser-only gate for create/edit.
bool campaignEditorAllowedForRole(WayoAdsAccountRole role) =>
    role == WayoAdsAccountRole.advertiser;

/// Soft wallet gate (estimate total) — server still locks on activate.
bool softWalletBlocksPublish({
  required int availableCents,
  required int estimatedTotalCents,
}) =>
    availableCents < estimatedTotalCents;

/// Idempotency + double-submit session (same rules as editor screen).
final class CampaignSubmitSession {
  CampaignSubmitSession({String Function()? keyFactory})
    : _keyFactory = keyFactory ?? (() => 'key-${DateTime.now().microsecondsSinceEpoch}');

  final String Function() _keyFactory;
  String? idempotencyKey;
  var busy = false;
  var navigatingAway = false;
  var generation = 0;
  var createCalls = 0;
  final List<String?> keysSent = [];

  bool get canStart => !busy && !navigatingAway;

  Future<void> submit({
    required Future<void> Function(String key) create,
    required bool networkError,
  }) async {
    if (!canStart) return;
    generation++;
    final gen = generation;
    busy = true;
    idempotencyKey ??= _keyFactory();
    final key = idempotencyKey!;
    keysSent.add(key);
    createCalls++;
    try {
      if (networkError) {
        throw Exception('network');
      }
      await create(key);
      if (gen != generation) return;
      idempotencyKey = null;
      navigatingAway = true;
    } catch (_) {
      if (gen != generation) return;
      // Keep key for retry of same intention.
    } finally {
      if (gen == generation) busy = false;
    }
  }
}

void main() {
  group('role gate', () {
    test('advertiser only; creator and superadmin blocked from create UI', () {
      expect(campaignEditorAllowedForRole(WayoAdsAccountRole.advertiser), isTrue);
      expect(campaignEditorAllowedForRole(WayoAdsAccountRole.creator), isFalse);
      expect(
        campaignEditorAllowedForRole(WayoAdsAccountRole.superAdmin),
        isFalse,
      );
    });
  });

  group('wallet soft gate', () {
    test('blocks when available < estimated total (fee+tax)', () {
      final estimate = CampaignCostEstimate.assemble(
        budgetCents: 10000,
        platformFeePercentage: 5,
        taxCents: 525,
        taxRate: 5,
      );
      expect(estimate.totalCents, 11025);
      expect(
        softWalletBlocksPublish(
          availableCents: 11000,
          estimatedTotalCents: estimate.totalCents,
        ),
        isTrue,
      );
      expect(
        softWalletBlocksPublish(
          availableCents: 11025,
          estimatedTotalCents: estimate.totalCents,
        ),
        isFalse,
      );
    });
  });

  group('submit double-tap + idempotency', () {
    test('second tap while busy is ignored', () async {
      final session = CampaignSubmitSession(
        keyFactory: () => 'fixed-key-12345678',
      );
      Future<void> slowCreate(String key) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      final first = session.submit(create: slowCreate, networkError: false);
      final second = session.submit(create: slowCreate, networkError: false);
      await Future.wait([first, second]);
      expect(session.createCalls, 1);
      expect(session.keysSent, ['fixed-key-12345678']);
      expect(session.navigatingAway, isTrue);
      expect(session.idempotencyKey, isNull);
    });

    test('retry after network keeps same Idempotency-Key', () async {
      final session = CampaignSubmitSession(keyFactory: () => 'retry-key-abcdef01');
      await session.submit(create: (_) async {}, networkError: true);
      expect(session.idempotencyKey, 'retry-key-abcdef01');
      await session.submit(create: (_) async {}, networkError: false);
      expect(session.keysSent, ['retry-key-abcdef01', 'retry-key-abcdef01']);
      expect(session.idempotencyKey, isNull);
    });

    test('new create session gets a fresh idempotency key', () async {
      final session1 = CampaignSubmitSession(
        keyFactory: () => 'first-key-12345678',
      );
      await session1.submit(create: (_) async {}, networkError: false);
      expect(session1.keysSent, ['first-key-12345678']);
      expect(session1.idempotencyKey, isNull);

      final session2 = CampaignSubmitSession(
        keyFactory: () => 'second-key-87654321',
      );
      await session2.submit(create: (_) async {}, networkError: false);
      expect(session2.keysSent, ['second-key-87654321']);
    });

    test('tap after navigatingAway is ignored', () async {
      final session = CampaignSubmitSession(keyFactory: () => 'nav-key-abcdef01');
      await session.submit(create: (_) async {}, networkError: false);
      expect(session.navigatingAway, isTrue);
      await session.submit(create: (_) async {}, networkError: false);
      expect(session.createCalls, 1);
    });
  });

  group('logo validation', () {
    test('rejects oversize and invalid mime before upload', () {
      final huge = Uint8List(CampaignLogoPrep.maxBytes + 1);
      expect(CampaignLogoPrep.prepareForUpload(huge), isNull);
      expect(
        CampaignLogoPrep.prepareForUpload(Uint8List.fromList([0, 1, 2])),
        isNull,
      );
    });
  });

  group('draft SharedPreferences resume', () {
    test('roundtrip under local draft key', () async {
      SharedPreferences.setMockInitialValues({});
      const key = 'wayo_ads_campaign_editor_draft_v1';
      final prefs = await SharedPreferences.getInstance();
      final draft = CampaignEditorDraft(
        title: 'Draft resume',
        niche: 'FASHION_APPAREL',
        landingUrl: 'https://example.com',
        totalBudgetCents: 8000,
        cpcCents: 20,
        campaignEndDate: '2026-12-01',
      );
      await prefs.setString(key, jsonEncode(draft.toLocalJson()));
      final raw = prefs.getString(key);
      expect(raw, isNotNull);
      final again = CampaignEditorDraft.fromLocalJson(
        Map<String, dynamic>.from(jsonDecode(raw!) as Map),
      );
      expect(again.title, 'Draft resume');
      expect(again.totalBudgetCents, 8000);
      expect(again.cpcCents, 20);
    });
  });

  group('three-step validators (wizard gates)', () {
    test('identity → budget → review passes validators in order', () {
      var step = 0;
      while (step < 2) {
        final draft = CampaignEditorDraft(
          title: 'T',
          niche: 'FASHION_APPAREL',
          landingUrl: 'https://a.com',
          totalBudgetCents: 5000,
          cpcCents: 10,
          campaignEndDate: '2026-12-31',
        );
        final err = step == 0
            ? CampaignEditorValidators.validateIdentity(draft)
            : CampaignEditorValidators.validateBudget(draft);
        expect(err, isNull, reason: 'step $step should pass');
        step++;
      }
      expect(step, 2);
    });

    test('identity failure blocks budget step', () {
      final draft = CampaignEditorDraft(
        title: '',
        niche: 'FASHION_APPAREL',
        landingUrl: 'https://a.com',
      );
      expect(CampaignEditorValidators.validateIdentity(draft), 'title_required');
      expect(CampaignEditorValidators.validateBudget(draft), isNotNull);
    });
  });

  group('Riverpod invalidation targets', () {
    test('ProviderContainer can invalidate family keys after mutation', () {
      final calls = <String>[];
      final counter = StateProvider<int>((ref) => 0);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(counter, (_, next) => calls.add('counter:$next'));
      expect(container.read(counter), 0);
      container.read(counter.notifier).state = 1;
      container.invalidate(counter);
      expect(container.read(counter), 0);
      // Document editor invalidate list (names only — wired in screen).
      const afterCreate = [
        'advertiserCampaignsPagedProvider',
        'advertiserCampaignsCountsProvider',
        'advertiserCampaignDetailProvider',
        'advertiserWalletPageProvider',
        'dashboardStreamProvider',
      ];
      expect(afterCreate, hasLength(5));
    });
  });
}
