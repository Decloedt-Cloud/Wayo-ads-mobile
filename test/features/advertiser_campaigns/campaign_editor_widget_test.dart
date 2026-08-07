import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayoadsgo/core/errors/auth_exceptions.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/data/advertiser_campaigns_remote_datasource.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/data/advertiser_campaigns_repository.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/data/campaign_cost_remote.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/advertiser_campaign.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/advertiser_campaigns_page_result.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_application.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_cost_estimate.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/domain/campaign_editor_draft.dart';
import 'package:wayoadsgo/features/advertiser_campaigns/presentation/screens/campaign_editor_screen.dart';
import 'package:wayoadsgo/features/creator_campaigns/domain/creator_browse_page_result.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/advertiser_balance.dart';
import 'package:wayoadsgo/features/wallet/domain/wallet_models.dart';
import 'package:wayoadsgo/features/wallet/presentation/providers/advertiser_wallet_providers.dart';
import 'package:wayoadsgo/i18n/strings.g.dart';

/// Records create calls + idempotency keys for widget-level submit tests.
final class _RecordingFakeRemote implements AdvertiserCampaignsRemote {
  _RecordingFakeRemote({
    this.failUntilCall = 0,
    this.submitDelay = Duration.zero,
  });

  /// Fail with [NetworkException] while `createCalls <= failUntilCall`.
  final int failUntilCall;
  final Duration submitDelay;

  var createCalls = 0;
  final List<String?> idempotencyKeys = [];

  @override
  Future<Map<String, dynamic>> createCampaign(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    createCalls++;
    idempotencyKeys.add(idempotencyKey);
    if (submitDelay > Duration.zero) {
      await Future<void>.delayed(submitDelay);
    }
    if (createCalls <= failUntilCall) {
      throw const NetworkException();
    }
    return {
      'campaign': {
        'id': 'camp_widget_test',
        'status': body['status'] ?? 'DRAFT',
      },
    };
  }

  Never _unimplemented([String method = '']) =>
      throw UnimplementedError(method);

  @override
  Future<void> approveApplication(String campaignId, String applicationId) =>
      _unimplemented('approveApplication');

  @override
  Future<List<AdvertiserCampaign>> fetchAdvertiserCampaigns({int limit = 100}) =>
      _unimplemented('fetchAdvertiserCampaigns');

  @override
  Future<AdvertiserCampaignsPageResult> fetchAdvertiserCampaignsPage({
    required int page,
    int limit = 10,
    String? status,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) =>
      _unimplemented('fetchAdvertiserCampaignsPage');

  @override
  Future<Map<String, dynamic>> fetchCampaignAnalytics(String id) =>
      _unimplemented('fetchCampaignAnalytics');

  @override
  Future<Map<String, dynamic>> fetchCampaignDetailJson(String id) =>
      _unimplemented('fetchCampaignDetailJson');

  @override
  Future<Map<String, dynamic>> fetchCampaignFinancialSummary(String id) =>
      _unimplemented('fetchCampaignFinancialSummary');

  @override
  Future<List<CampaignApplication>> fetchCampaignApplications(
    String campaignId,
  ) =>
      _unimplemented('fetchCampaignApplications');

  @override
  Future<CreatorBrowsePageResult> fetchMarketplaceBrowsePage({
    required int page,
    int limit = 10,
    String? search,
    String? type,
    String? niche,
    String? countryCode,
  }) =>
      _unimplemented('fetchMarketplaceBrowsePage');

  @override
  Future<void> rejectApplication(String campaignId, String applicationId) =>
      _unimplemented('rejectApplication');

  @override
  Future<Map<String, dynamic>> setCampaignStatus(String id, String status) =>
      _unimplemented('setCampaignStatus');

  @override
  Future<Map<String, dynamic>> updateCampaign(
    String id,
    Map<String, dynamic> body,
  ) =>
      _unimplemented('updateCampaign');

  @override
  Future<String> uploadCampaignLogoDataUrl(String dataUrl) =>
      _unimplemented('uploadCampaignLogoDataUrl');
}

Future<void> _pumpCreateWizard(
  WidgetTester tester, {
  required _RecordingFakeRemote fake,
  List<Override> extraOverrides = const [],
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final seededDraft = CampaignEditorDraft(
    title: 'Widget test campaign',
    niche: 'FASHION_APPAREL',
    landingUrl: 'https://example.com/landing',
    totalBudgetCents: 10000,
    cpcCents: 10,
    campaignEndDate: '2026-12-31',
  );
  SharedPreferences.setMockInitialValues({
    'wayo_ads_campaign_editor_draft_v1': jsonEncode(seededDraft.toLocalJson()),
  });
  await LocaleSettings.setLocale(AppLocale.en);

  final router = GoRouter(
    initialLocation: '/advertiser/campaigns/new',
    routes: [
      GoRoute(
        path: '/advertiser/campaigns/new',
        builder: (context, state) => const CampaignEditorScreen(),
      ),
      GoRoute(
        path: '/campaigns/:id',
        builder: (context, state) => Scaffold(
          body: Text('detail:${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        advertiserCampaignsRepositoryProvider.overrideWith(
          (ref) => AdvertiserCampaignsRepository(fake),
        ),
        advertiserWalletPageProvider.overrideWith(
          (ref) async => const AdvertiserWalletPageData(
            balance: AdvertiserBalance(
              available: 500,
              locked: 0,
              spent: 0,
              currency: 'USD',
            ),
            transactions: [],
            canSimulate: false,
          ),
        ),
        campaignCostEstimateProvider.overrideWith(
          (ref, budgetCents) async => CampaignCostEstimate.assemble(
            budgetCents: budgetCents,
            platformFeePercentage: 5,
            taxCents: 0,
            taxRate: 0,
          ),
        ),
        ...extraOverrides,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goToReviewFromBudget(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(find.text('Step 3 of 3'), findsOneWidget);
  expect(find.text('Review'), findsOneWidget);
}

Future<void> _advanceToReview(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(find.text('Step 2 of 3'), findsOneWidget);
  await _goToReviewFromBudget(tester);
}

void main() {
  group('CampaignEditorScreen widget', () {
    testWidgets('three-step wizard shows identity → budget → review', (
      tester,
    ) async {
      final fake = _RecordingFakeRemote();
      await _pumpCreateWizard(tester, fake: fake);

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Campaign type'), findsOneWidget);
      expect(find.text('Widget test campaign'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Total budget'), findsOneWidget);

      await _goToReviewFromBudget(tester);
      expect(find.text('Save as draft'), findsOneWidget);
      expect(find.text('Create and activate'), findsOneWidget);
      expect(fake.createCalls, 0);
    });

    testWidgets('double-tap save draft issues single create call', (
      tester,
    ) async {
      final fake = _RecordingFakeRemote(submitDelay: const Duration(milliseconds: 80));
      await _pumpCreateWizard(tester, fake: fake);
      await _advanceToReview(tester);

      await tester.tap(find.text('Save as draft'));
      await tester.tap(find.text('Save as draft'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(fake.createCalls, 1);
      expect(fake.idempotencyKeys.whereType<String>(), hasLength(1));
    });

    testWidgets('network retry reuses same Idempotency-Key', (tester) async {
      final fake = _RecordingFakeRemote(failUntilCall: 1);
      await _pumpCreateWizard(tester, fake: fake);
      await _advanceToReview(tester);

      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();
      expect(find.text('Save as draft'), findsOneWidget);
      expect(fake.createCalls, 1);
      expect(fake.idempotencyKeys.first, isNotNull);

      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, 2);
      expect(fake.idempotencyKeys[0], fake.idempotencyKeys[1]);
      expect(find.text('detail:camp_widget_test'), findsOneWidget);
    });
  });
}
