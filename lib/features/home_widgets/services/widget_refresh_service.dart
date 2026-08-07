import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../data/widget_preferences_repository.dart';
import '../domain/wayo_ads_widget_snapshot.dart';
import '../home_widget_constants.dart';
import 'widget_data_service.dart';

/// Orchestrates snapshot refresh + native widget update.
final class WidgetRefreshService {
  WidgetRefreshService(this._ref);

  final Ref _ref;
  bool _busy = false;
  DateTime? _lastRefreshUtc;

  WidgetPreferencesRepository get _prefs =>
      _ref.read(widgetPreferencesRepositoryProvider);

  WidgetDataService get _data => _ref.read(widgetDataServiceProvider);

  /// Minimum gap between network-backed refreshes.
  static const minInterval = Duration(seconds: 45);

  Future<void> refresh({bool force = false}) async {
    if (_busy) return;
    final now = DateTime.now().toUtc();
    if (!force &&
        _lastRefreshUtc != null &&
        now.difference(_lastRefreshUtc!) < minInterval) {
      return;
    }
    _busy = true;
    try {
      final snapshot = await _data.buildSnapshot();
      await _prefs.writeSnapshot(snapshot);
      await _updateNative();
      _lastRefreshUtc = now;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeWidget] refresh failed: $e');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> clearForLogout() async {
    try {
      await _prefs.clearAll();
      await _updateNative();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeWidget] clear failed: $e');
      }
    }
  }

  /// Drops previous account data when a different user signs in.
  Future<void> onAccountSwitch(String? newAccountIdHash) async {
    final previous = await _prefs.readSnapshot();
    if (previous?.accountIdHash != null &&
        newAccountIdHash != null &&
        previous!.accountIdHash != newAccountIdHash) {
      await clearForLogout();
    }
  }

  Future<void> writeLoggedOutShell() async {
    await _prefs.writeSnapshot(WayoAdsWidgetSnapshot.loggedOut());
    await _updateNative();
  }

  Future<void> _updateNative() async {
    try {
      await HomeWidget.updateWidget(
        name: WayoAdsHomeWidgetConstants.androidPerformance,
        androidName: WayoAdsHomeWidgetConstants.androidPerformance,
        qualifiedAndroidName:
            'ma.wayo.wayoadsgo.widgets.PerformanceWidgetProvider',
        iOSName: WayoAdsHomeWidgetConstants.iosPerformance,
      );
      await HomeWidget.updateWidget(
        name: WayoAdsHomeWidgetConstants.androidWallet,
        androidName: WayoAdsHomeWidgetConstants.androidWallet,
        qualifiedAndroidName: 'ma.wayo.wayoadsgo.widgets.WalletWidgetProvider',
        iOSName: WayoAdsHomeWidgetConstants.iosWallet,
      );
      await HomeWidget.updateWidget(
        name: WayoAdsHomeWidgetConstants.androidQuickActions,
        androidName: WayoAdsHomeWidgetConstants.androidQuickActions,
        qualifiedAndroidName:
            'ma.wayo.wayoadsgo.widgets.QuickActionsWidgetProvider',
        iOSName: WayoAdsHomeWidgetConstants.iosQuickActions,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeWidget] updateWidget failed: $e');
      }
    }
  }
}

final widgetRefreshServiceProvider = Provider<WidgetRefreshService>((ref) {
  return WidgetRefreshService(ref);
});
