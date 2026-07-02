import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Opens the best available system screen for fixing network connectivity.
///
/// Android → Wi‑Fi / mobile network settings (native intent).
/// iOS → app settings (Apple does not expose public Wi‑Fi deep links).
Future<bool> openSystemNetworkSettings() async {
  if (Platform.isAndroid) {
    try {
      const channel = MethodChannel('ma.wayo.wayoadsgo/network_settings');
      final opened = await channel.invokeMethod<bool>('openWirelessSettings');
      if (opened == true) return true;
    } catch (_) {}
  }
  return openAppSettings();
}
