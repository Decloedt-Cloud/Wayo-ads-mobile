import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/errors/auth_exceptions.dart';
import 'package:wayoadsgo/core/network/rate_limiter.dart';
import 'package:wayoadsgo/core/network/request_deduplicator.dart';
import 'package:wayoadsgo/core/storage/secure_storage.dart';
import 'package:wayoadsgo/core/storage/secure_token_storage.dart';
import 'package:wayoadsgo/features/creator_campaigns/domain/creator_browse_campaign.dart';
import 'package:wayoadsgo/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:wayoadsgo/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/advertiser_balance.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/campaign_platform.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/campaign_status.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/campaign_summary.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/notification_item.dart';
import 'package:wayoadsgo/features/dashboard/domain/entities/user_profile.dart';
import 'package:wayoadsgo/features/dashboard/domain/advertiser_campaigns_page_result.dart';

class _FakeRemote implements DashboardRemote {
  _FakeRemote({
    this.failBalance = false,
    this.campaigns = const [
      CampaignSummary(
        id: '1',
        name: 'A',
        status: CampaignStatus.active,
        platform: CampaignPlatform.youtube,
        creatorsCount: 2,
        campaignType: CreatorCampaignType.video,
        lockedBudgetCents: 500,
        spentBudgetCents: 100,
      ),
    ],
    this.budgetRollup,
  });

  final bool failBalance;
  final List<CampaignSummary> campaigns;
  final AdvertiserBudgetRollup? budgetRollup;

  @override
  Future<AdvertiserBalance> fetchBalance() async {
    if (failBalance) {
      throw const NetworkException();
    }
    return const AdvertiserBalance(
      available: 1,
      locked: 2,
      spent: 3,
      currency: 'EUR',
    );
  }

  @override
  Future<AdvertiserCampaignsPageResult> fetchCampaignsPage({
    int page = 1,
    int limit = 10,
  }) async {
    return AdvertiserCampaignsPageResult(
      campaigns: campaigns,
      total: campaigns.length,
      page: page,
      totalPages: campaigns.isEmpty ? 1 : (campaigns.length + limit - 1) ~/ limit,
      budgetRollup: budgetRollup,
    );
  }

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<List<NotificationItem>> fetchNotifications({
    bool unreadOnly = false,
  }) async => const [];

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<void> markAllNotificationsRead() async {}

  @override
  Future<void> dismissNotification(String id) async {}

  @override
  Future<UserProfile> fetchUser() async {
    return const UserProfile(id: 9, email: 'a@b.c', firstName: 'Sam');
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('emits snapshot with campaigns mapped from remote', () async {
    final repo = DashboardRepositoryImpl(
      remote: _FakeRemote(),
      deduplicator: RequestDeduplicator(),
      rateLimiter: RateLimiter(minInterval: Duration.zero),
      secureStorage: SecureStorageService(SecureTokenStorage()),
    );
    final last = await repo.watchDashboard().first;
    expect(last.user?.firstName, 'Sam');
    expect(last.campaigns, hasLength(1));
    expect(last.campaignsTotalCount, 1);
    expect(last.campaigns.single.platform, CampaignPlatform.youtube);
  });

  test('balance error keeps campaigns when remote fails balance', () async {
    final repo = DashboardRepositoryImpl(
      remote: _FakeRemote(failBalance: true),
      deduplicator: RequestDeduplicator(),
      rateLimiter: RateLimiter(minInterval: Duration.zero),
      secureStorage: SecureStorageService(SecureTokenStorage()),
    );
    final last = await repo.watchDashboard().first;
    expect(last.balance, isNull);
    expect(last.balanceError, isA<NetworkException>());
    expect(last.campaigns, isNotEmpty);
  });

  test(
    'merges locked and spent from campaign stats when balance loads',
    () async {
      final repo = DashboardRepositoryImpl(
        remote: _FakeRemote(
          campaigns: const [
            CampaignSummary(
              id: '1',
              name: 'Running',
              status: CampaignStatus.active,
              platform: CampaignPlatform.youtube,
              creatorsCount: 1,
              campaignType: CreatorCampaignType.video,
              lockedBudgetCents: 300,
              spentBudgetCents: 50,
            ),
            CampaignSummary(
              id: '2',
              name: 'Done',
              status: CampaignStatus.completed,
              platform: CampaignPlatform.youtube,
              creatorsCount: 2,
              campaignType: CreatorCampaignType.video,
              lockedBudgetCents: 0,
              spentBudgetCents: 700,
            ),
          ],
          budgetRollup: null,
        ),
        deduplicator: RequestDeduplicator(),
        rateLimiter: RateLimiter(minInterval: Duration.zero),
        secureStorage: SecureStorageService(SecureTokenStorage()),
      );
      final last = await repo.watchDashboard().first;
      expect(last.balance?.available, 1);
      expect(last.balance?.locked, 3.0);
      expect(last.balance?.spent, 7.0);
    },
  );

  test('uses budgetRollup for wallet merge when API provides it', () async {
    final repo = DashboardRepositoryImpl(
      remote: _FakeRemote(
        campaigns: const [
          CampaignSummary(
            id: '1',
            name: 'Running',
            status: CampaignStatus.active,
            platform: CampaignPlatform.youtube,
            creatorsCount: 1,
            campaignType: CreatorCampaignType.video,
            lockedBudgetCents: 999,
            spentBudgetCents: 999,
          ),
        ],
        budgetRollup: const AdvertiserBudgetRollup(
          lockedCents: 150,
          spentCents: 250,
        ),
      ),
      deduplicator: RequestDeduplicator(),
      rateLimiter: RateLimiter(minInterval: Duration.zero),
      secureStorage: SecureStorageService(SecureTokenStorage()),
    );
    final last = await repo.watchDashboard().first;
    expect(last.balance?.available, 1);
    expect(last.balance?.locked, 1.5);
    expect(last.balance?.spent, 2.5);
  });
}
