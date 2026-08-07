import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/wayo_ads_widget_snapshot.dart';
import '../home_widget_constants.dart';

/// Persists sanitized widget snapshots for native OS widgets.
///
/// Android: SharedPreferences (via home_widget).
/// iOS: App Group UserDefaults.
final class WidgetPreferencesRepository {
  const WidgetPreferencesRepository();

  Future<void> ensureConfigured() async {
    try {
      await HomeWidget.setAppGroupId(WayoAdsHomeWidgetConstants.appGroupId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeWidget] setAppGroupId failed: $e');
      }
    }
  }

  Future<WayoAdsWidgetSnapshot?> readSnapshot() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        WayoAdsHomeWidgetConstants.snapshotKey,
      );
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WayoAdsWidgetSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSnapshot(WayoAdsWidgetSnapshot snapshot) async {
    await ensureConfigured();
    final json = jsonEncode(snapshot.toJson());
    await HomeWidget.saveWidgetData<String>(
      WayoAdsHomeWidgetConstants.snapshotKey,
      json,
    );

    // Flat keys for lightweight native layouts.
    await Future.wait([
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.authState,
        snapshot.authState.storageValue,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.role,
        snapshot.role,
      ),
      HomeWidget.saveWidgetData<int>(
        WayoAdsHomeWidgetConstants.updatedAtMs,
        snapshot.updatedAt.toUtc().millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.currency,
        snapshot.currency,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.balance,
        snapshot.balance?.toStringAsFixed(2) ?? '',
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.pendingBalance,
        snapshot.pendingBalance?.toStringAsFixed(2) ?? '',
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.balanceFormatted,
        snapshot.balanceFormatted,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.pendingFormatted,
        snapshot.pendingFormatted,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.availableLabel,
        snapshot.availableLabel,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.pendingLabel,
        snapshot.pendingLabel,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.walletTitle,
        snapshot.walletTitle,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.emptyHeadline,
        snapshot.emptyHeadline,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.emptyCta,
        snapshot.emptyCta,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.tertiaryLabel,
        snapshot.tertiaryLabel,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.tertiaryValue,
        snapshot.tertiaryValue,
      ),
      HomeWidget.saveWidgetData<int>(
        WayoAdsHomeWidgetConstants.activeCampaigns,
        snapshot.activeCampaigns,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.spend,
        snapshot.spend?.toStringAsFixed(2) ?? '',
      ),
      HomeWidget.saveWidgetData<int>(
        WayoAdsHomeWidgetConstants.clicks,
        snapshot.clicks,
      ),
      HomeWidget.saveWidgetData<int>(
        WayoAdsHomeWidgetConstants.views,
        snapshot.views,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.ctr,
        snapshot.ctr == null ? '' : snapshot.ctr!.toStringAsFixed(2),
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.primaryMetricLabel,
        snapshot.primaryMetricLabel,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.primaryMetricValue,
        snapshot.primaryMetricValue,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.secondaryLeftLabel,
        snapshot.secondaryLeftLabel,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.secondaryLeftValue,
        snapshot.secondaryLeftValue,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.secondaryRightLabel,
        snapshot.secondaryRightLabel,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.secondaryRightValue,
        snapshot.secondaryRightValue,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.staleHint,
        snapshot.staleHint,
      ),
      HomeWidget.saveWidgetData<String>(
        WayoAdsHomeWidgetConstants.statusMessage,
        snapshot.authState.statusMessageForLocale(snapshot.localeCode),
      ),
    ]);
  }

  /// Clears all private presentation data (logout / account switch).
  Future<void> clearAll() async {
    await writeSnapshot(WayoAdsWidgetSnapshot.loggedOut());
  }
}
