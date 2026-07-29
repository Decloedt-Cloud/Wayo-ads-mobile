import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../data/known_devices_remote.dart';

final knownDevicesRemoteProvider = Provider<KnownDevicesRemote>((ref) {
  return KnownDevicesRemote(ref.watch(wayoAdsDioProvider));
});

final knownDevicesProvider =
    FutureProvider.autoDispose<List<KnownDevice>>((ref) async {
      return ref.watch(knownDevicesRemoteProvider).fetchDevices();
    });
