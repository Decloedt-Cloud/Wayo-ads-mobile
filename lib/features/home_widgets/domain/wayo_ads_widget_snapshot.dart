import 'widget_auth_state.dart';

/// Sanitized presentation snapshot for Wayo Ads home widgets.
///
/// Contains **no** access/refresh tokens, Stripe secrets, or bank details.
final class WayoAdsWidgetSnapshot {
  const WayoAdsWidgetSnapshot({
    required this.updatedAt,
    required this.authState,
    required this.role,
    this.accountIdHash,
    this.currency = 'USD',
    this.balance,
    this.pendingBalance,
    this.balanceFormatted = '',
    this.pendingFormatted = '',
    this.availableLabel = '',
    this.pendingLabel = '',
    this.walletTitle = '',
    this.emptyHeadline = '',
    this.emptyCta = '',
    this.tertiaryLabel = '',
    this.tertiaryValue = '',
    this.activeCampaigns = 0,
    this.spend,
    this.clicks = 0,
    this.views = 0,
    this.ctr,
    this.primaryMetricLabel = '',
    this.primaryMetricValue = '—',
    this.secondaryLeftLabel = '',
    this.secondaryLeftValue = '—',
    this.secondaryRightLabel = '',
    this.secondaryRightValue = '—',
    this.localeCode = 'en',
  });

  final DateTime updatedAt;
  final WidgetAuthState authState;

  /// `advertiser` | `creator` | `superAdmin` | `unknown`
  final String role;

  /// Non-reversible short hash of account id for account-switch detection.
  final String? accountIdHash;

  final String currency;
  final double? balance;
  final double? pendingBalance;
  final String balanceFormatted;
  final String pendingFormatted;
  final String availableLabel;
  final String pendingLabel;
  final String walletTitle;
  final String emptyHeadline;
  final String emptyCta;
  final String tertiaryLabel;
  final String tertiaryValue;
  final int activeCampaigns;
  final double? spend;
  final int clicks;
  final int views;
  final double? ctr;

  final String primaryMetricLabel;
  final String primaryMetricValue;
  final String secondaryLeftLabel;
  final String secondaryLeftValue;
  final String secondaryRightLabel;
  final String secondaryRightValue;

  /// `en` | `fr` — drives native string fallbacks when needed.
  final String localeCode;

  static WayoAdsWidgetSnapshot loggedOut({String localeCode = 'en'}) {
    final fr = localeCode.startsWith('fr');
    return WayoAdsWidgetSnapshot(
      updatedAt: DateTime.now().toUtc(),
      authState: WidgetAuthState.loggedOut,
      role: 'unknown',
      localeCode: localeCode,
      primaryMetricLabel: 'Wayo Ads',
      primaryMetricValue: '—',
      emptyHeadline: fr
          ? 'Connectez-vous pour voir votre tableau de bord'
          : 'Sign in to see your dashboard',
      emptyCta: fr ? 'Ouvrir Wayo →' : 'Open Wayo →',
      walletTitle: fr ? 'Portefeuille Wayo' : 'Wayo Wallet',
    );
  }

  static WayoAdsWidgetSnapshot tokenExpired({
    WayoAdsWidgetSnapshot? previous,
    String localeCode = 'en',
  }) {
    final base = previous ?? loggedOut(localeCode: localeCode);
    return WayoAdsWidgetSnapshot(
      updatedAt: base.updatedAt,
      authState: WidgetAuthState.tokenExpired,
      role: base.role,
      accountIdHash: base.accountIdHash,
      currency: base.currency,
      balance: base.balance,
      pendingBalance: base.pendingBalance,
      balanceFormatted: base.balanceFormatted,
      pendingFormatted: base.pendingFormatted,
      availableLabel: base.availableLabel,
      pendingLabel: base.pendingLabel,
      walletTitle: base.walletTitle,
      emptyHeadline: base.emptyHeadline,
      emptyCta: base.emptyCta,
      tertiaryLabel: base.tertiaryLabel,
      tertiaryValue: base.tertiaryValue,
      activeCampaigns: base.activeCampaigns,
      spend: base.spend,
      clicks: base.clicks,
      views: base.views,
      ctr: base.ctr,
      primaryMetricLabel: base.primaryMetricLabel,
      primaryMetricValue: base.primaryMetricValue,
      secondaryLeftLabel: base.secondaryLeftLabel,
      secondaryLeftValue: base.secondaryLeftValue,
      secondaryRightLabel: base.secondaryRightLabel,
      secondaryRightValue: base.secondaryRightValue,
      localeCode: base.localeCode,
    );
  }

  bool get isStale {
    final age = DateTime.now().toUtc().difference(updatedAt.toUtc());
    return age > const Duration(hours: 6);
  }

  String get staleHint {
    final age = DateTime.now().toUtc().difference(updatedAt.toUtc());
    final fr = localeCode.startsWith('fr');
    if (age.inMinutes < 1) {
      return fr ? 'Mis à jour à l’instant' : 'Updated just now';
    }
    if (age.inHours < 1) {
      return fr
          ? 'Mis à jour il y a ${age.inMinutes} min'
          : 'Updated ${age.inMinutes}m ago';
    }
    if (age.inDays < 1) {
      return fr
          ? 'Mis à jour il y a ${age.inHours} h'
          : 'Updated ${age.inHours}h ago';
    }
    return fr
        ? 'Mis à jour il y a ${age.inDays} j'
        : 'Updated ${age.inDays}d ago';
  }

  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'authState': authState.storageValue,
        'role': role,
        'accountIdHash': accountIdHash,
        'currency': currency,
        'balance': balance,
        'pendingBalance': pendingBalance,
        'balanceFormatted': balanceFormatted,
        'pendingFormatted': pendingFormatted,
        'availableLabel': availableLabel,
        'pendingLabel': pendingLabel,
        'walletTitle': walletTitle,
        'emptyHeadline': emptyHeadline,
        'emptyCta': emptyCta,
        'tertiaryLabel': tertiaryLabel,
        'tertiaryValue': tertiaryValue,
        'activeCampaigns': activeCampaigns,
        'spend': spend,
        'clicks': clicks,
        'views': views,
        'ctr': ctr,
        'primaryMetricLabel': primaryMetricLabel,
        'primaryMetricValue': primaryMetricValue,
        'secondaryLeftLabel': secondaryLeftLabel,
        'secondaryLeftValue': secondaryLeftValue,
        'secondaryRightLabel': secondaryRightLabel,
        'secondaryRightValue': secondaryRightValue,
        'localeCode': localeCode,
      };

  factory WayoAdsWidgetSnapshot.fromJson(Map<String, dynamic> json) {
    DateTime parseUpdated() {
      final raw = json['updatedAt'] ?? json['updated_at'];
      if (raw is String) {
        return DateTime.tryParse(raw)?.toUtc() ?? DateTime.now().toUtc();
      }
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
      }
      return DateTime.now().toUtc();
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return WayoAdsWidgetSnapshot(
      updatedAt: parseUpdated(),
      authState: WidgetAuthState.fromStorage(
        json['authState']?.toString() ?? json['auth_state']?.toString(),
      ),
      role: (json['role'] ?? 'unknown').toString(),
      accountIdHash: json['accountIdHash']?.toString(),
      currency: (json['currency'] ?? 'USD').toString(),
      balance: asDouble(json['balance']),
      pendingBalance:
          asDouble(json['pendingBalance'] ?? json['pending_balance']),
      balanceFormatted: (json['balanceFormatted'] ?? '').toString(),
      pendingFormatted: (json['pendingFormatted'] ?? '').toString(),
      availableLabel: (json['availableLabel'] ?? '').toString(),
      pendingLabel: (json['pendingLabel'] ?? '').toString(),
      walletTitle: (json['walletTitle'] ?? '').toString(),
      emptyHeadline: (json['emptyHeadline'] ?? '').toString(),
      emptyCta: (json['emptyCta'] ?? '').toString(),
      tertiaryLabel: (json['tertiaryLabel'] ?? '').toString(),
      tertiaryValue: (json['tertiaryValue'] ?? '').toString(),
      activeCampaigns: asInt(json['activeCampaigns'] ?? json['active_campaigns']),
      spend: asDouble(json['spend']),
      clicks: asInt(json['clicks']),
      views: asInt(json['views']),
      ctr: asDouble(json['ctr']),
      primaryMetricLabel: (json['primaryMetricLabel'] ?? '').toString(),
      primaryMetricValue: (json['primaryMetricValue'] ?? '—').toString(),
      secondaryLeftLabel: (json['secondaryLeftLabel'] ?? '').toString(),
      secondaryLeftValue: (json['secondaryLeftValue'] ?? '—').toString(),
      secondaryRightLabel: (json['secondaryRightLabel'] ?? '').toString(),
      secondaryRightValue: (json['secondaryRightValue'] ?? '—').toString(),
      localeCode: (json['localeCode'] ?? 'en').toString(),
    );
  }
}
