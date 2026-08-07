import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/format/money_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../i18n/strings.g.dart';
import '../../advertiser_campaigns/data/advertiser_campaigns_repository.dart';
import '../../auth/data/models/app_user.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/domain/wayo_ads_account_role.dart';
import '../../auth/presentation/providers/current_account_providers.dart';
import '../../creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import '../../creator_wallet/presentation/providers/creator_wallet_providers.dart';
import '../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../superadmin/presentation/providers/superadmin_providers.dart';
import '../data/widget_preferences_repository.dart';
import '../domain/wayo_ads_widget_snapshot.dart';
import '../domain/widget_auth_state.dart';

/// Builds sanitized [WayoAdsWidgetSnapshot] from existing authenticated APIs.
final class WidgetDataService {
  WidgetDataService(this._ref, {WidgetPreferencesRepository? prefs})
      : _prefs = prefs ?? const WidgetPreferencesRepository();

  final Ref _ref;
  final WidgetPreferencesRepository _prefs;

  String get _localeCode {
    try {
      return _ref.read(localeProvider).languageCode;
    } catch (_) {
      return LocaleSettings.currentLocale.languageCode;
    }
  }

  bool get _fr => _localeCode.startsWith('fr');

  String get _moneyLocale => _fr ? 'fr_FR' : 'en_US';

  Future<WayoAdsWidgetSnapshot> buildSnapshot() async {
    final locale = _localeCode;
    final authAsync = _ref.read(authNotifierProvider);
    final authState = authAsync.valueOrNull;
    final user = authState is AuthAuthenticated
        ? authState.user
        : _ref.read(currentAppUserProvider);

    if (user == null || authState is AuthUnauthenticated) {
      return WayoAdsWidgetSnapshot.loggedOut(localeCode: locale);
    }

    final storage = _ref.read(secureStorageProvider);
    final access = await storage.getAccessToken();
    if (access == null || access.isEmpty) {
      final previous = await _prefs.readSnapshot();
      return WayoAdsWidgetSnapshot.tokenExpired(
        previous: previous,
        localeCode: locale,
      );
    }

    final role = user.wayoAdsRole;
    try {
      return switch (role) {
        WayoAdsAccountRole.creator => await _buildCreator(user),
        WayoAdsAccountRole.superAdmin => await _buildSuperAdmin(user),
        _ => await _buildAdvertiser(user),
      };
    } on SessionInvalidException {
      final previous = await _prefs.readSnapshot();
      return WayoAdsWidgetSnapshot.tokenExpired(
        previous: previous,
        localeCode: locale,
      );
    } catch (_) {
      final previous = await _prefs.readSnapshot();
      if (previous != null && previous.authState == WidgetAuthState.loggedIn) {
        return previous;
      }
      return WayoAdsWidgetSnapshot(
        updatedAt: DateTime.now().toUtc(),
        authState: WidgetAuthState.loggedIn,
        role: role.name,
        accountIdHash: _hashAccount('${user.id}'),
        localeCode: locale,
        primaryMetricLabel: 'Wayo Ads',
        primaryMetricValue: '—',
        emptyHeadline: _fr ? 'Données indisponibles' : 'Data unavailable',
        emptyCta: _fr ? 'Ouvrir l’app →' : 'Open app →',
      );
    }
  }

  Future<WayoAdsWidgetSnapshot> _buildAdvertiser(AppUser user) async {
    final remote = _ref.read(dashboardRemoteDatasourceProvider);
    final campaignsRepo = _ref.read(advertiserCampaignsRepositoryProvider);

    final balance = await remote.fetchBalance();
    final counts = await campaignsRepo.loadCampaignStatusCounts();
    final page = await campaignsRepo.loadCampaignsPage(
      status: 'ACTIVE',
      page: 1,
      limit: 20,
    );

    var views = 0;
    var clicks = 0;
    var spendCents = 0;
    for (final c in page.campaigns) {
      views += c.validViews;
      clicks += c.validClicks;
      spendCents += c.spentBudgetCents;
    }
    final ctr = views > 0 ? (clicks / views) * 100 : null;
    final spend = spendCents / 100.0;
    final money = _fmtMoney(spend, balance.currency);
    final balFmt = _fmtMoney(balance.available, balance.currency);
    final pendingFmt = _fmtMoney(balance.locked, balance.currency);

    final noCampaigns = counts.active == 0 && spend <= 0 && views == 0;
    final zeroWallet = balance.available <= 0 && balance.locked <= 0;

    String primaryValue;
    String primaryLabel;
    String leftLabel;
    String leftValue;
    String rightLabel;
    String rightValue;
    String tertiaryLabel = '';
    String tertiaryValue = '';
    String emptyHeadline = '';
    String emptyCta = '';

    if (noCampaigns) {
      primaryValue = balFmt;
      primaryLabel = _fr ? 'Budget disponible' : 'Available budget';
      leftLabel = '';
      leftValue = '';
      rightLabel = '';
      rightValue = '';
      emptyHeadline =
          _fr ? 'Aucune campagne active' : 'No active campaigns';
      emptyCta = _fr
          ? 'Créer votre première campagne →'
          : 'Create your first campaign →';
    } else {
      // Flagship: spend dominates when present; else active count.
      if (spend > 0) {
        primaryValue = money;
        primaryLabel = _fr ? 'Dépensé ce mois' : 'Spent this month';
      } else {
        primaryValue = '${counts.active}';
        primaryLabel = _fr ? 'Campagnes actives' : 'Active campaigns';
      }
      leftLabel = _fr ? 'Actives' : 'Active';
      leftValue = '${counts.active}';
      rightLabel = _fr ? 'Vues' : 'Views';
      rightValue = _compact(views);
      if (ctr != null) {
        tertiaryLabel = 'CTR';
        tertiaryValue = '${ctr.toStringAsFixed(1)}%';
      }
    }

    if (zeroWallet && noCampaigns) {
      emptyHeadline = _fr ? 'Aucun budget' : 'No budget yet';
      emptyCta =
          _fr ? 'Ajouter des fonds →' : 'Add funds to start a campaign →';
    }

    return WayoAdsWidgetSnapshot(
      updatedAt: DateTime.now().toUtc(),
      authState: WidgetAuthState.loggedIn,
      role: 'advertiser',
      accountIdHash: _hashAccount('${user.id}'),
      currency: balance.currency,
      balance: balance.available,
      pendingBalance: balance.locked,
      balanceFormatted: balFmt,
      pendingFormatted: balance.locked > 0 ? pendingFmt : '',
      availableLabel: _fr ? 'Budget disponible' : 'Available budget',
      pendingLabel: _fr ? 'Réservé' : 'Reserved',
      walletTitle: _fr ? 'Portefeuille Wayo' : 'Wayo Wallet',
      emptyHeadline: emptyHeadline,
      emptyCta: emptyCta,
      tertiaryLabel: tertiaryLabel,
      tertiaryValue: tertiaryValue,
      activeCampaigns: counts.active,
      spend: spend,
      clicks: clicks,
      views: views,
      ctr: ctr,
      primaryMetricLabel: primaryLabel,
      primaryMetricValue: primaryValue,
      secondaryLeftLabel: leftLabel,
      secondaryLeftValue: leftValue,
      secondaryRightLabel: rightLabel,
      secondaryRightValue: rightValue,
      localeCode: _localeCode,
    );
  }

  Future<WayoAdsWidgetSnapshot> _buildCreator(AppUser user) async {
    final stats = await _ref.read(creatorStatsProvider.future);
    double available = stats.totalEarningsCents / 100.0;
    double pending = stats.pendingEarningsCents / 100.0;
    var currency = stats.currency;
    try {
      final page = await _ref.read(creatorWalletPageProvider.future);
      available = page.balance.availableCents / 100.0;
      pending = page.balance.pendingCents / 100.0;
      currency = page.balance.currency;
    } catch (_) {}

    final views = stats.estimatedViews;
    final clicks = stats.totalValidClicks;
    final ctr = views > 0 ? (clicks / views) * 100 : null;
    final earnFmt = _fmtMoney(available, currency);
    final pendingFmt = _fmtMoney(pending, currency);
    final collabs = stats.approvedApplications;
    final noEarnings = available <= 0 && pending <= 0;
    final noCollabs = collabs <= 0 && views <= 0;

    String emptyHeadline = '';
    String emptyCta = '';
    if (noEarnings && noCollabs) {
      emptyHeadline = _fr ? 'Pas encore de gains' : 'No earnings yet';
      emptyCta =
          _fr ? 'Voir les opportunités →' : 'View opportunities →';
    } else if (noCollabs) {
      emptyHeadline =
          _fr ? 'Pas encore de collabs' : 'No collaborations yet';
      emptyCta =
          _fr ? 'Explorer les opportunités →' : 'Explore opportunities →';
    }

    return WayoAdsWidgetSnapshot(
      updatedAt: DateTime.now().toUtc(),
      authState: WidgetAuthState.loggedIn,
      role: 'creator',
      accountIdHash: _hashAccount('${user.id}'),
      currency: currency,
      balance: available,
      pendingBalance: pending,
      balanceFormatted: earnFmt,
      pendingFormatted: pending > 0 ? pendingFmt : '',
      availableLabel: _fr ? 'Disponible' : 'Available',
      pendingLabel: _fr ? 'En attente' : 'Pending',
      walletTitle: _fr ? 'Portefeuille Wayo' : 'Wayo Wallet',
      emptyHeadline: emptyHeadline,
      emptyCta: emptyCta,
      tertiaryLabel: '',
      tertiaryValue: '',
      activeCampaigns: collabs,
      clicks: clicks,
      views: views,
      ctr: ctr,
      primaryMetricLabel: _fr ? 'Gains' : 'Earnings',
      primaryMetricValue: earnFmt,
      secondaryLeftLabel: _fr ? 'Collabs' : 'Collabs',
      secondaryLeftValue: '$collabs',
      secondaryRightLabel: _fr ? 'Vues' : 'Views',
      secondaryRightValue: _compact(views),
      localeCode: _localeCode,
    );
  }

  Future<WayoAdsWidgetSnapshot> _buildSuperAdmin(AppUser user) async {
    try {
      final stats = await _ref.read(dashboardStatsProvider.future);
      return WayoAdsWidgetSnapshot(
        updatedAt: DateTime.now().toUtc(),
        authState: WidgetAuthState.loggedIn,
        role: 'superAdmin',
        accountIdHash: _hashAccount('${user.id}'),
        currency: 'USD',
        balance: stats.totalAmountUsd,
        balanceFormatted: _fmtMoney(stats.totalAmountUsd, 'USD'),
        availableLabel: _fr ? 'Volume plateforme' : 'Platform volume',
        walletTitle: _fr ? 'Admin Wayo' : 'Wayo Admin',
        activeCampaigns: stats.topCampaigns.length,
        primaryMetricLabel: _fr ? 'Volume plateforme' : 'Platform volume',
        primaryMetricValue: _fmtMoney(stats.totalAmountUsd, 'USD'),
        secondaryLeftLabel: _fr ? 'Transactions' : 'Transactions',
        secondaryLeftValue: _compact(stats.totalTransactions),
        secondaryRightLabel: _fr ? 'Top campagnes' : 'Top campaigns',
        secondaryRightValue: '${stats.topCampaigns.length}',
        localeCode: _localeCode,
      );
    } catch (_) {
      return WayoAdsWidgetSnapshot(
        updatedAt: DateTime.now().toUtc(),
        authState: WidgetAuthState.loggedIn,
        role: 'superAdmin',
        accountIdHash: _hashAccount('${user.id}'),
        localeCode: _localeCode,
        primaryMetricLabel: 'Admin',
        primaryMetricValue: _fr ? 'Ouvrir l’app' : 'Open app',
        emptyHeadline: _fr ? 'Données admin indisponibles' : 'Admin data unavailable',
      );
    }
  }

  static String _hashAccount(String id) {
    final digest = sha256.convert(utf8.encode(id));
    return digest.toString().substring(0, 12);
  }

  String _fmtMoney(double amount, String currency) {
    return MoneyFormatter.format(
      amount,
      currency: currency,
      locale: _moneyLocale,
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

final widgetDataServiceProvider = Provider<WidgetDataService>((ref) {
  return WidgetDataService(ref);
});

final widgetPreferencesRepositoryProvider =
    Provider<WidgetPreferencesRepository>((ref) {
  return const WidgetPreferencesRepository();
});
