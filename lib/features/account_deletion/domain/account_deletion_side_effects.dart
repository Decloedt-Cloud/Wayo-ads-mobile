import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/wayo_ads_dio.dart';
import '../../../core/push/wayo_push_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../app_settings/data/mobile_session_register.dart';

/// Runs after a successful mobile [POST /api/user/delete-account].
///
/// - Suppresses the server echo FCM / Reverb toast on this device.
/// - Keeps the current mobile session registered (visible in web settings).
Future<void> runAccountDeletionScheduledSideEffects(WidgetRef ref) async {
  await markAccountDeletionSelfInitiatedPushSuppress();

  unawaited(
    registerMobileWayoSession(
      wayoAdsDio: ref.read(wayoAdsDioProvider),
      storage: ref.read(secureStorageProvider),
    ).catchError((_) {}),
  );
}
