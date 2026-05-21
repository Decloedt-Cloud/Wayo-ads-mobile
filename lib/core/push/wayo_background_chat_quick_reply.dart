import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../features/chat/data/chat_repository.dart';
import '../config/auth_runtime_config.dart';
import '../network/auth_interceptor.dart';
import '../network/interceptors/certificate_pinning.dart';
import '../network/interceptors/retry_interceptor.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_token_storage.dart';
import 'wayo_push_intent.dart';

/// Sends a tray inline reply **without** bringing the Flutter activity to foreground.
///
/// Runs on the flutter_local_notifications **background dispatcher** isolate.
/// Uses the same Wayo-ads chat bootstrap + chat-service POST as [ChatRepository].
Future<bool> trySendWayoChatQuickReplySilently({
  required int conversationId,
  required String text,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  await recordInlineReplyEchoGuard(
    conversationId: '$conversationId',
    messageText: trimmed,
  );
  try {
    await AuthRuntimeConfig.ensureLoaded();
    final runtime = AuthRuntimeConfig.instance;

    final storage = SecureStorageService(SecureTokenStorage());
    final dio = Dio(
      BaseOptions(
        baseUrl: runtime.resolvedWayoAdsBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        followRedirects: true,
        maxRedirects: 3,
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Client': 'wayo-ads-go',
          'X-Client-Version': runtime.effectiveAppRelease,
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(storage: storage, dio: dio));
    dio.interceptors.add(buildWayoRetryInterceptor(dio));
    CertificatePinning.attach(
      dio,
      pinnedSha256Base64: runtime.mergedPinnedSha256Base64,
    );

    late final ChatRepository repo;
    repo = ChatRepository(
      dio,
      refreshChatCredentials: () => repo.fetchBootstrap(),
    );
    final creds = await repo.fetchBootstrap();
    await repo.sendTextMessage(
      creds,
      conversationId,
      trimmed,
      socketId: () => null,
    );
    return true;
  } catch (e, st) {
    await clearInlineReplyEchoGuard();
    developer.log(
      'Background tray reply send failed ($e)',
      name: 'wayo.push.bg_reply',
      error: e,
      stackTrace: st,
    );
    return false;
  }
}
