import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'system_push_permission.dart';
import 'user_push_notifications_preference.dart';

/// `true` when in-app preference is on and OS notifications are allowed.
final pushNotificationsActiveProvider =
    StateNotifierProvider<PushNotificationsActiveNotifier, bool>(
  (ref) => PushNotificationsActiveNotifier(ref),
);

class PushNotificationsActiveNotifier extends StateNotifier<bool> {
  PushNotificationsActiveNotifier(this._ref) : super(true) {
    unawaited(refresh());
  }

  final Ref _ref;

  Future<void> refresh() async {
    final prefs = _ref.read(appPrefsProvider);
    if (!await isUserPushNotificationsEnabled(prefs)) {
      state = false;
      return;
    }
    state = await areSystemPushNotificationsGranted();
  }
}
