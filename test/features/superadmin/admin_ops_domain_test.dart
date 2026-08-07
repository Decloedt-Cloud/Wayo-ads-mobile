import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/superadmin/domain/entities/admin_ops.dart';

void main() {
  group('PaymentAuditRecord.fromJson', () {
    test('parses nested advertiser and fee fields', () {
      final r = PaymentAuditRecord.fromJson({
        'id': 'pa_1',
        'stripePaymentIntentId': 'pi_abc',
        'amountCents': 12500,
        'currency': 'eur',
        'reconciliationStatus': 'MATCHED',
        'createdAt': '2026-08-01T12:00:00.000Z',
        'actualProcessingFeeCents': 100,
        'internationalFeeCents': 20,
        'additionalStripeFeeCents': 5,
        'depositMethod': 'card',
        'advertiser': {
          'id': 'adv_1',
          'email': 'a@wayo.ma',
          'name': 'Acme',
        },
      });

      expect(r.id, 'pa_1');
      expect(r.stripePaymentIntentId, 'pi_abc');
      expect(r.advertiserId, 'adv_1');
      expect(r.advertiserEmail, 'a@wayo.ma');
      expect(r.advertiserName, 'Acme');
      expect(r.amountCents, 12500);
      expect(r.currency, 'EUR');
      expect(r.totalFeeCents, 125);
      expect(r.depositMethod, 'card');
      expect(r.reconciliationStatus, 'MATCHED');
    });
  });

  group('PaymentAuditRecord.fromJson wire funding instructions', () {
    test('parses wireReference and normalized fundingInstructions', () {
      final r = PaymentAuditRecord.fromJson({
        'id': 'pa_2',
        'stripePaymentIntentId': 'pi_wire',
        'amountCents': 200000,
        'currency': 'usd',
        'reconciliationStatus': 'PENDING',
        'createdAt': '2026-08-05T09:00:00.000Z',
        'depositMethod': 'wire',
        'wireReference': 'WAYO-REF-42',
        'advertiser': {'id': 'adv_9', 'email': 'w@wayo.ma'},
        'fundingInstructions': {
          'amountRemainingCents': 200000,
          'currency': 'usd',
          'reference': 'WAYO-REF-42',
          'transferType': 'us_bank_transfer',
          'addresses': [
            {
              'network': 'ach',
              'accountHolderName': 'Wayo Inc',
              'bankName': 'Example Bank',
              'accountNumber': '000123456789',
              'routingNumber': '110000000',
              'country': 'US',
            },
          ],
        },
      });

      expect(r.depositMethod, 'wire');
      expect(r.wireReference, 'WAYO-REF-42');
      expect(r.fundingInstructions, isNotNull);
      expect(r.fundingInstructions!.currency, 'USD');
      expect(r.fundingInstructions!.transferType, 'us_bank_transfer');
      expect(r.fundingInstructions!.addresses, hasLength(1));
      expect(r.fundingInstructions!.addresses.first.bankName, 'Example Bank');
      expect(r.fundingInstructions!.addresses.first.routingNumber, '110000000');
    });

    test('fundingInstructions is null when absent or malformed', () {
      final r = PaymentAuditRecord.fromJson({
        'id': 'pa_3',
        'stripePaymentIntentId': 'pi_card',
        'amountCents': 1000,
        'currency': 'eur',
        'reconciliationStatus': 'MATCHED',
        'createdAt': '2026-08-05T09:00:00.000Z',
      });

      expect(r.fundingInstructions, isNull);
      expect(AdminFundingInstructions.tryParse('not a map'), isNull);
      expect(AdminFundingInstructions.tryParse({'currency': 'usd'}), isNull);
    });
  });

  group('PaymentAuditReconcileResult.fromJson', () {
    test('parses reconciliation outcome', () {
      final r = PaymentAuditReconcileResult.fromJson({
        'auditId': 'pa_1',
        'reconciliationStatus': 'MATCHED',
        'additionalStripeFeeCents': 12,
        'processingFeeSettled': true,
      });

      expect(r.auditId, 'pa_1');
      expect(r.reconciliationStatus, 'MATCHED');
      expect(r.additionalStripeFeeCents, 12);
      expect(r.processingFeeSettled, isTrue);
    });

    test('defaults optional fields to null', () {
      final r = PaymentAuditReconcileResult.fromJson({'auditId': 'pa_2'});

      expect(r.reconciliationStatus, 'UNKNOWN');
      expect(r.additionalStripeFeeCents, isNull);
      expect(r.processingFeeSettled, isNull);
    });
  });

  group('AdvertiserDepositTotalRow.fromJson / AdvertiserDepositsPage.fromJson', () {
    test('parses per-advertiser totals and pagination', () {
      final page = AdvertiserDepositsPage.fromJson({
        'rows': [
          {
            'advertiserId': 'adv_1',
            'advertiserEmail': 'a@wayo.ma',
            'advertiserName': 'Acme',
            'currency': 'eur',
            'depositCount': 4,
            'totalChargedCents': 40000,
            'totalStripeFeeCents': 1200,
            'totalInternationalFeeCents': 0,
            'totalAdditionalStripeFeeCents': 0,
            'totalNetCents': 38800,
            'walletAvailableCents': 500,
            'lastDepositAt': '2026-08-04T12:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
      });

      expect(page.rows, hasLength(1));
      expect(page.rows.first.advertiserName, 'Acme');
      expect(page.rows.first.depositCount, 4);
      expect(page.rows.first.totalNetCents, 38800);
      expect(page.rows.first.lastDepositAt, isNotNull);
      expect(page.total, 1);
      expect(page.totalPages, 1);
    });

    test('handles missing rows and advertiserName gracefully', () {
      final page = AdvertiserDepositsPage.fromJson({'total': 0});

      expect(page.rows, isEmpty);
      expect(page.total, 0);
      expect(page.totalPages, 1);
    });
  });

  group('AuditLogEntry.fromJson', () {
    test('parses actor/target fields', () {
      final e = AuditLogEntry.fromJson({
        'id': 'al_1',
        'source': 'security',
        'action': 'USER_BANNED',
        'createdAt': '2026-08-02T10:00:00.000Z',
        'actorId': 'sa_1',
        'actorEmail': 'admin@wayo.ma',
        'targetUserId': 'u_9',
        'targetEmail': 'bad@example.com',
        'reason': 'fraud',
      });

      expect(e.source, 'security');
      expect(e.action, 'USER_BANNED');
      expect(e.actorEmail, 'admin@wayo.ma');
      expect(e.targetEmail, 'bad@example.com');
      expect(e.reason, 'fraud');
    });
  });

  group('PlatformHealthSnapshot.fromJson', () {
    test('accepts alternate click keys', () {
      final h = PlatformHealthSnapshot.fromJson({
        'activeCampaigns': 12,
        'totalCreators': 80,
        'totalClicks24h': 400,
        'validatedClicks': 350,
        'rejectedFraudCount': 10,
        'fraudRatePct': 3,
        'pendingWithdrawals': 4,
        'platformFeeCents': 9900,
        'platformFeeActivationCents': 500,
      });

      expect(h.activeCampaigns, 12);
      expect(h.clicks24h, 400);
      expect(h.rejectedFraud, 10);
      expect(h.platformFeePayoutCents, 9900);
      expect(h.platformFeeActivationCents, 500);
    });
  });

  group('AdminServiceStatus', () {
    test('isOk for online/up/ok', () {
      expect(
        AdminServiceStatus.fromJson({'name': 'db', 'status': 'online'}).isOk,
        isTrue,
      );
      expect(
        AdminServiceStatus.fromJson({'name': 'stripe', 'status': 'UP'}).isOk,
        isTrue,
      );
      expect(
        AdminServiceStatus.fromJson({'name': 'mail', 'status': 'degraded'})
            .isDegraded,
        isTrue,
      );
      expect(
        AdminServiceStatus.fromJson({'name': 'mail', 'status': 'offline'}).isOk,
        isFalse,
      );
    });
  });

  group('TokenPurchaseRecord.fromJson', () {
    test('parses nested creator', () {
      final r = TokenPurchaseRecord.fromJson({
        'id': 'tp_1',
        'tokenCount': 500,
        'packageId': 'starter',
        'packageName': 'Starter (500 tokens)',
        'amountCents': 999,
        'taxCents': 99,
        'currency': 'eur',
        'createdAt': '2026-08-03T08:00:00.000Z',
        'creator': {
          'id': 'c1',
          'name': 'Maya',
          'email': 'maya@wayo.ma',
        },
      });
      expect(r.tokenCount, 500);
      expect(r.creatorName, 'Maya');
      expect(r.currency, 'EUR');
    });
  });

  group('ClickPipelineSnapshot.fromJson', () {
    test('sums counts and reads backlog age', () {
      final s = ClickPipelineSnapshot.fromJson({
        'counts': {
          'VALIDATED': 10,
          'PENDING_BUDGET': 2,
          'REJECTED_FRAUD': 1,
        },
        'oldestPendingBudgetAgeMinutes': 45,
      });
      expect(s.totalClicks, 13);
      expect(s.countFor('PENDING_BUDGET'), 2);
      expect(s.oldestPendingBudgetAgeMinutes, 45);
    });
  });

  group('CreatorVelocityRow.fromJson', () {
    test('parses percent change', () {
      final r = CreatorVelocityRow.fromJson({
        'creatorId': 'c1',
        'creatorName': 'Alex',
        'velocityChangePercent': 150.5,
        'riskLevel': 'HIGH',
        'trustScore': 42,
      });
      expect(r.velocityChangePercent, 150.5);
      expect(r.riskLevel, 'HIGH');
    });
  });

  group('EmailLogRecord.fromJson', () {
    test('parses failure', () {
      final e = EmailLogRecord.fromJson({
        'id': 'el_1',
        'toEmail': 'a@b.com',
        'subject': 'Welcome',
        'status': 'FAILED',
        'sentAt': '2026-08-04T09:00:00.000Z',
        'errorMessage': 'smtp timeout',
      });
      expect(e.status, 'FAILED');
      expect(e.errorMessage, 'smtp timeout');
    });
  });

  group('RecentActivityItem.fromJson', () {
    test('reads budget from data', () {
      final a = RecentActivityItem.fromJson({
        'id': 'campaign-1',
        'type': 'campaign_launched',
        'createdAt': '2026-08-04T10:00:00.000Z',
        'user': {'id': 'u1', 'name': 'Brand', 'email': 'b@wayo.ma'},
        'data': {'title': 'Summer', 'budgetCents': 50000},
      });
      expect(a.title, 'Summer');
      expect(a.amountCents, 50000);
      expect(a.userName, 'Brand');
    });
  });

  group('AdminInvoiceRecord.fromJson', () {
    test('parses nested user', () {
      final inv = AdminInvoiceRecord.fromJson({
        'id': 'inv_1',
        'invoiceNumber': 'INV-001',
        'invoiceType': 'DEPOSIT',
        'roleType': 'ADVERTISER',
        'status': 'PAID',
        'totalAmountCents': 12000,
        'taxAmountCents': 2000,
        'platformFeeCents': 0,
        'createdAt': '2026-08-01T12:00:00.000Z',
        'user': {'id': 'u1', 'name': 'Acme', 'email': 'a@wayo.ma'},
      });
      expect(inv.invoiceNumber, 'INV-001');
      expect(inv.userName, 'Acme');
      expect(inv.totalAmountCents, 12000);
    });
  });

  group('AdminPaymentStatement.fromJson', () {
    test('parses net payout', () {
      final s = AdminPaymentStatement.fromJson({
        'id': 'ps_1',
        'statementNumber': 'PS-9',
        'creatorName': 'Maya',
        'creatorEmail': 'm@wayo.ma',
        'grossEarningsCents': 10000,
        'platformFeeCents': 1000,
        'taxCents': 200,
        'netPayoutCents': 8800,
        'currency': 'eur',
        'paymentMethod': 'stripe',
        'statementDate': '2026-08-02T12:00:00.000Z',
        'status': 'PAID',
      });
      expect(s.netPayoutCents, 8800);
      expect(s.currency, 'EUR');
      expect(s.taxCents, 200);
    });
  });

  group('YoutubeMonitoringStats.fromJson', () {
    test('parses groupBy rows and quota', () {
      final s = YoutubeMonitoringStats.fromJson({
        'postsByStatus': [
          {'status': 'ACTIVE', '_count': 12},
          {'status': 'FLAGGED', '_count': 2},
        ],
        'quotaUsage': {'used': 500, 'limit': 10000, 'percentUsed': 5},
        'recentSnapshots': [{}, {}],
      });
      expect(s.countFor('ACTIVE'), 12);
      expect(s.totalPosts, 14);
      expect(s.quotaPercentUsed, 5);
      expect(s.recentSnapshotCount, 2);
    });
  });

  group('AdminTokenPackage.fromJson', () {
    test('sums bonus tokens', () {
      final p = AdminTokenPackage.fromJson({
        'slug': 'starter',
        'name': 'Starter',
        'tokens': 100,
        'bonusTokens': 20,
        'priceCents': 999,
        'currency': 'usd',
        'isActive': true,
        'isBestValue': false,
        'sortOrder': 1,
      });
      expect(p.totalTokens, 120);
      expect(p.currency, 'USD');
    });
  });

  group('PlatformSettingsSnapshot.fromJson', () {
    test('reads nested settings', () {
      final s = PlatformSettingsSnapshot.fromJson({
        'settings': {
          'platformFeeRate': 0.05,
          'platformFeePercentage': 5,
          'defaultCurrency': 'eur',
          'minimumWithdrawalCents': 1000,
          'pendingHoldDays': 7,
          'viewSettlementHoldHours': 48,
          'platformName': 'Wayo',
          'stripeActiveMode': 'TEST',
        },
      });
      expect(s.platformFeePercentage, 5);
      expect(s.defaultCurrency, 'EUR');
      expect(s.minimumWithdrawalCents, 1000);
    });
  });

  group('AdminEmailTemplate.fromJson', () {
    test('parses catalog fields', () {
      final t = AdminEmailTemplate.fromJson({
        'name': 'auth.verify_code',
        'subject': 'Your code',
        'previewText': 'Use this code',
        'category': 'authentication',
        'description': 'OTP',
      });
      expect(t.name, 'auth.verify_code');
      expect(t.category, 'authentication');
      expect(t.subject, 'Your code');
    });
  });

  group('AdminUserDetail.fromJson', () {
    test('parses campaigns and applications', () {
      final d = AdminUserDetail.fromJson({
        'campaigns': [
          {
            'id': 'c1',
            'title': 'Summer',
            'status': 'ACTIVE',
            'totalBudgetCents': 10000,
            'spentBudgetCents': 2500,
            'totalBillableViews': 40,
            'createdAt': '2026-08-01T12:00:00.000Z',
          },
        ],
        'applications': [
          {
            'id': 'a1',
            'campaignId': 'c9',
            'campaignTitle': 'Collab',
            'campaignStatus': 'ACTIVE',
            'status': 'APPROVED',
            'message': null,
            'createdAt': '2026-08-02T12:00:00.000Z',
            'reviewedAt': null,
          },
        ],
        'campaignsTotal': 1,
        'applicationsTotal': 1,
        'campaignsPage': 1,
        'applicationsPage': 1,
        'pageSize': 10,
      });
      expect(d.campaignsTotal, 1);
      expect(d.campaigns.first.title, 'Summer');
      expect(d.applications.first.campaignTitle, 'Collab');
      expect(d.applications.first.status, 'APPROVED');
    });
  });
}
