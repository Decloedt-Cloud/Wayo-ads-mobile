/// Shared keys / names for Wayo Ads Home Screen Widgets.
///
/// Never store tokens or secrets under these keys — presentation data only.
abstract final class WayoAdsHomeWidgetConstants {
  static const appGroupId = 'group.ma.wayo.wayoadsgo';
  static const scheme = 'wayoads';

  /// Full JSON snapshot key written to SharedPreferences / App Group.
  static const snapshotKey = 'wayo_ads_widget_snapshot_v1';

  /// Flat keys for native RemoteViews (Android) / Timeline (iOS).
  static const authState = 'auth_state';
  static const role = 'role';
  static const updatedAtMs = 'updated_at_ms';
  static const currency = 'currency';
  static const balance = 'balance';
  static const pendingBalance = 'pending_balance';
  static const balanceFormatted = 'balance_formatted';
  static const pendingFormatted = 'pending_formatted';
  static const availableLabel = 'available_label';
  static const pendingLabel = 'pending_label';
  static const walletTitle = 'wallet_title';
  static const emptyHeadline = 'empty_headline';
  static const emptyCta = 'empty_cta';
  static const tertiaryLabel = 'tertiary_label';
  static const tertiaryValue = 'tertiary_value';
  static const activeCampaigns = 'active_campaigns';
  static const spend = 'spend';
  static const clicks = 'clicks';
  static const views = 'views';
  static const ctr = 'ctr';
  static const primaryMetricLabel = 'primary_metric_label';
  static const primaryMetricValue = 'primary_metric_value';
  static const secondaryLeftLabel = 'secondary_left_label';
  static const secondaryLeftValue = 'secondary_left_value';
  static const secondaryRightLabel = 'secondary_right_label';
  static const secondaryRightValue = 'secondary_right_value';
  static const staleHint = 'stale_hint';
  static const statusMessage = 'status_message';

  /// Android AppWidgetProvider simple class names (must match Kotlin).
  static const androidPerformance = 'PerformanceWidgetProvider';
  static const androidWallet = 'WalletWidgetProvider';
  static const androidQuickActions = 'QuickActionsWidgetProvider';

  /// iOS WidgetKit kind names.
  static const iosPerformance = 'WayoAdsPerformanceWidget';
  static const iosWallet = 'WayoAdsWalletWidget';
  static const iosQuickActions = 'WayoAdsQuickActionsWidget';
}
