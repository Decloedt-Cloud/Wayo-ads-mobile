import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/wayo_ads_dio.dart';
import '../../data/active_sessions_remote.dart';

final activeSessionsRemoteProvider = Provider<ActiveSessionsRemote>((ref) {
  return ActiveSessionsRemote(ref.watch(wayoAdsDioProvider));
});

final activeSessionsProvider =
    FutureProvider.autoDispose<List<ActiveSession>>((ref) async {
      return ref.watch(activeSessionsRemoteProvider).fetchSessions();
    });
