import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/interceptors/certificate_pinning.dart';
import '../../../core/network/interceptors/logging_interceptor.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_credentials.dart';
import '../domain/chat_directory_user.dart';
import '../domain/chat_message.dart';
import 'chat_avatar_enrichment.dart';
import 'chat_media_utils.dart';
import 'chat_message_media.dart';
import 'chat_message_text.dart';
import 'chat_messages_page.dart';
import '../domain/chat_user_preview.dart';

/// Reverb/Pusher clients expect a bare hostname, not `https://host`.
String _normalizePusherWsHost(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  if (s.contains('://')) {
    final u = Uri.tryParse(s);
    if (u != null && u.hasAuthority) {
      return u.host;
    }
  }
  final seg = s.split('/').first;
  if (seg.startsWith('[')) {
    return seg;
  }
  final colon = seg.indexOf(':');
  if (colon > 0) {
    return seg.substring(0, colon);
  }
  return seg;
}

/// Wayo-ads often returns `http://localhost:…` / `127.0.0.1` for [CHAT_SERVICE_API_URL].
/// On **Android emulator**, that points at the emulator itself, not the dev machine — use `10.0.2.2`.
String _rewriteChatApiBaseForAndroidEmulator(String url) {
  if (kIsWeb || !kDebugMode) return url;
  try {
    if (!Platform.isAndroid) return url;
    final uri = Uri.parse(url.trim());
    if (uri.host != 'localhost' && uri.host != '127.0.0.1') return url;
    return uri
        .replace(host: '10.0.2.2')
        .toString()
        .replaceAll(RegExp(r'/+$'), '');
  } catch (_) {
    return url;
  }
}

String _effectiveChatApiBaseUrl(String fromBootstrap) {
  final overlay = AuthRuntimeConfig.instance.chatServiceApiBaseUrl.trim();
  final raw = overlay.isNotEmpty ? overlay : fromBootstrap.trim();
  return _rewriteChatApiBaseForAndroidEmulator(
    raw.replaceAll(RegExp(r'/+$'), ''),
  );
}

String _rewriteReverbHostForAndroidEmulator(String host) {
  if (kIsWeb || !kDebugMode) return host;
  try {
    if (!Platform.isAndroid) return host;
    if (host == 'localhost' || host == '127.0.0.1') return '10.0.2.2';
    return host;
  } catch (_) {
    return host;
  }
}

/// Refetch Wayo-ads `GET /api/chat/token` and return fresh chat-service credentials.
/// Used on chat API 401 (expired short-lived token).
typedef ChatCredentialsRefresher = Future<ChatCredentials> Function();

final class ChatRepository {
  ChatRepository(
    this._wayoAdsDio, {
    required Future<ChatCredentials> Function() refreshChatCredentials,
  }) : _refreshChatCredentials = refreshChatCredentials;

  final Dio _wayoAdsDio;
  final Future<ChatCredentials> Function() _refreshChatCredentials;

  static AuthException mapError(Object e) {
    if (e is AuthException) return e;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const NetworkException();
      }
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return ServerException(e.message ?? 'Unauthorized', code);
      }
      return ServerException(e.message ?? 'Request failed');
    }
    return ServerException('$e');
  }

  /// `GET /api/chat/token` on Wayo-ads (Bearer via interceptors).
  ///
  /// Retries up to 3 times on 401 to handle the Android FlutterSecureStorage
  /// propagation delay after a fresh login (token not yet visible to interceptors).
  Future<ChatCredentials> fetchBootstrap() async {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.chatToken,
    );
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final res = await _wayoAdsDio.get<Map<String, dynamic>>(path);
        final data = res.data;
        if (data == null || data['success'] != true) {
          final msg = data?['message'] is String
              ? data!['message'] as String
              : 'Chat bootstrap failed';
          throw ServerException(msg);
        }
        final inner = data['data'];
        if (inner is! Map<String, dynamic>) {
          throw const ServerException('Invalid chat bootstrap payload');
        }
        final token = (inner['token'] as String?)?.trim();
        final chatUserId = inner['chatUserId'];
        final appId = (inner['appId'] as String?)?.trim();
        final apiBaseUrl = (inner['apiBaseUrl'] as String?)?.trim();
        final rt = inner['realtime'];
        if (token == null ||
            token.isEmpty ||
            chatUserId == null ||
            appId == null ||
            appId.isEmpty ||
            apiBaseUrl == null ||
            apiBaseUrl.isEmpty ||
            rt is! Map<String, dynamic>) {
          throw const ServerException('Incomplete chat bootstrap payload');
        }
        final resolvedBase = _effectiveChatApiBaseUrl(apiBaseUrl);
        if (kDebugMode) {
          final ads = AuthRuntimeConfig.instance.resolvedWayoAdsBaseUrl;
          final localAds =
              ads.contains('10.0.2.2') ||
              ads.contains('127.0.0.1') ||
              ads.contains('localhost');
          if (localAds && resolvedBase.contains('wayochat')) {
            debugPrint(
              '[Chat] Wayo-ads is local but chat HTTP is $resolvedBase. '
              '401 on /conversations? Point CHAT_SERVICE_API_BASE_URL to the Laravel chat '
              'that signs this JWT (e.g. http://10.0.2.2:8000), not only production wayochat.',
            );
          }
        }
        final authEndpoint = '$resolvedBase/api/v1/broadcasting/auth';
        return ChatCredentials(
          token: token,
          chatUserId: (chatUserId as num).toInt(),
          appId: appId,
          apiBaseUrl: resolvedBase,
          realtime: ChatRealtimeConfig(
            key: '${rt['key'] ?? ''}',
            wsHost: _rewriteReverbHostForAndroidEmulator(
              _normalizePusherWsHost('${rt['wsHost'] ?? ''}'),
            ),
            wsPort: (rt['wsPort'] as num?)?.toInt() ?? 8080,
            wssPort: (rt['wssPort'] as num?)?.toInt() ?? 443,
            forceTLS: rt['forceTLS'] == true,
            authEndpoint: authEndpoint,
          ),
        );
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        final is401 = code == 401;
        final isTransientServer =
            code == 500 || code == 502 || code == 503 || code == 504;
        final isLastAttempt = attempt == maxAttempts - 1;
        if (is401 && !isLastAttempt) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
          continue;
        }
        if (isTransientServer && !isLastAttempt) {
          if (kDebugMode) {
            debugPrint(
              '[Chat] GET $path returned $code; retrying bootstrap '
              '(attempt ${attempt + 1}/$maxAttempts)…',
            );
          }
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (attempt + 1)),
          );
          continue;
        }
        rethrow;
      }
    }
    throw const ServerException('Chat bootstrap failed after retries');
  }

  /// Max JWT refresh attempts per failing request before surfacing 401 (stale/expired bootstrap).
  static const _kChat401RefreshAttempts = 'chat_service_401_refresh_attempts';

  void _addChatDioAuthRetry(Dio dio, {String? Function()? socketId}) {
    // Queued wrapper: async 401 recovery must complete [ErrorInterceptorHandler].
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          final sid = socketId?.call();
          if (sid != null && sid.isNotEmpty) {
            options.headers['X-Socket-ID'] = sid;
          }
          handler.next(options);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }
          final attempts =
              (e.requestOptions.extra[_kChat401RefreshAttempts] as int?) ?? 0;
          const maxJwtRefreshPasses = 3;
          if (attempts >= maxJwtRefreshPasses) {
            return handler.next(e);
          }
          e.requestOptions.extra[_kChat401RefreshAttempts] = attempts + 1;

          _refreshChatCredentials()
              .then((creds) {
                e.requestOptions.headers['Authorization'] =
                    'Bearer ${creds.token.trim()}';
                e.requestOptions.headers['X-Application-ID'] =
                    creds.appId.trim();
                return dio.fetch<dynamic>(e.requestOptions);
              })
              .then(handler.resolve)
              .catchError((Object _) => handler.next(e));
        },
      ),
    );
  }

  Dio _chatDio(ChatCredentials c, {String? Function()? socketId}) {
    final base = c.apiBaseUrl.endsWith('/') ? c.apiBaseUrl : '${c.apiBaseUrl}/';
    final dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${c.token.trim()}',
          'X-Application-ID': c.appId.trim(),
        },
      ),
    );

    // SECURITY: Attach certificate pinning in release builds.
    CertificatePinning.attach(
      dio,
      pinnedSha256Base64: AuthRuntimeConfig.instance.mergedPinnedSha256Base64,
    );

    _addChatDioAuthRetry(dio, socketId: socketId);
    if (kDebugMode) {
      dio.interceptors.add(WayoLoggingInterceptor());
    }
    return dio;
  }

  /// Same query as Wayo-ads `AdvertiserChatDialog` user search.
  ///
  /// Retries once after a forced credential refresh on HTTP 401 (in addition to
  /// the Dio 401 interceptor), to recover from stale [ChatCredentials] or JWT skew.
  Future<List<ChatDirectoryUser>> searchUsers(
    ChatCredentials c,
    String term, {
    int limit = 10,
    int offset = 0,
    String? Function()? socketId,
  }) async {
    final q = term.trim();
    if (q.isEmpty) return const [];
    ChatCredentials creds = c;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final dio = _chatDio(creds, socketId: socketId);
        final res = await dio.get<Map<String, dynamic>>(
          'api/v1/users',
          queryParameters: <String, dynamic>{
            'search': q,
            'limit': limit,
            'offset': offset,
          },
        );
        final data = res.data;
        if (data == null || data['success'] != true) {
          throw ServerException(
            data?['message'] as String? ?? 'User search failed',
          );
        }
        final list = data['data'];
        if (list is! List<dynamic>) {
          return const [];
        }
        return list
            .map((e) => ChatDirectoryUser.fromJson(e as Map<String, dynamic>))
            .toList();
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 && attempt < 3) {
          if (kDebugMode) {
            debugPrint(
              '[Chat] GET api/v1/users → 401; forcing chat bootstrap refresh '
              '(body: ${e.response?.data}).',
            );
          }
          creds = await _refreshChatCredentials();
          continue;
        }
        throw mapError(e);
      }
    }
    throw const ServerException('User search failed');
  }

  Future<ChatConversation> createDirectConversation(
    ChatCredentials c, {
    required int participantId,
    String? Function()? socketId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    final res = await dio.post<Map<String, dynamic>>(
      'api/v1/conversations',
      data: <String, dynamic>{
        'type': 'direct',
        'participant_ids': <int>[participantId],
      },
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw ServerException(
        data?['message'] as String? ?? 'Could not start conversation',
      );
    }
    final raw = data['data'];
    if (raw is! Map<String, dynamic>) {
      throw const ServerException('Invalid conversation response');
    }
    return _parseConversation(raw);
  }

  Future<List<ChatConversation>> fetchConversations(
    ChatCredentials c, {
    String? Function()? socketId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    final res = await dio.get<Map<String, dynamic>>('api/v1/conversations');
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw ServerException(
        data?['message'] as String? ?? 'Failed to load conversations',
      );
    }
    final list = data['data'];
    if (list is! List<dynamic>) {
      return const [];
    }
    return list
        .map((e) => _parseConversation(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatConversation>> fetchConversationsEnriched(
    ChatCredentials c, {
    String? Function()? socketId,
  }) async {
    final list = await fetchConversations(c, socketId: socketId);
    try {
      return await enrichChatConversationsWithMarketingAvatars(
        list,
        c.chatUserId,
        c.apiBaseUrl,
        (path) async {
          final res = await _wayoAdsDio.get<Map<String, dynamic>>(path);
          return res.data;
        },
      );
    } catch (_) {
      return list;
    }
  }

  Future<List<ChatMessage>> fetchMessages(
    ChatCredentials c,
    int conversationId, {
    String? Function()? socketId,
    int perPage = 100,
  }) async {
    final page = await fetchMessagesPage(
      c,
      conversationId,
      socketId: socketId,
      page: 1,
      perPage: perPage,
    );
    return page.messages;
  }

  /// Paginated messages (`page`, `per_page`). Laravel-style `data.data` + meta when present.
  Future<ChatMessagesPage> fetchMessagesPage(
    ChatCredentials c,
    int conversationId, {
    String? Function()? socketId,
    int page = 1,
    int perPage = 50,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    final res = await dio.get<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/messages',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': page,
      },
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw ServerException(
        data?['message'] as String? ?? 'Failed to load messages',
      );
    }
    final parsed = _parseMessagesEnvelope(data['data'], requestedPage: page);
    return ChatMessagesPage(
      messages: parsed.messages,
      hasMore: parsed.meta.hasMore,
      currentPage: parsed.meta.currentPage,
      lastPage: parsed.meta.lastPage,
    );
  }

  /// Parses `response.data` — either a Laravel paginator map (`data` list + meta)
  /// or a bare message list.
  ({
    List<ChatMessage> messages,
    ChatMessagesPageMeta meta,
  }) _parseMessagesEnvelope(
    dynamic inner, {
    required int requestedPage,
  }) {
    if (inner is Map<String, dynamic>) {
      final rowsRaw = inner['data'];
      final rows = rowsRaw is List<dynamic> ? rowsRaw : null;
      final meta = readChatMessagesPaginationMeta(inner, requestedPage);
      final messages = _sortedMessagesFromRows(rows);
      return (messages: messages, meta: meta);
    }
    if (inner is List<dynamic>) {
      return (
        messages: _sortedMessagesFromRows(inner),
        meta: ChatMessagesPageMeta.singlePage(requestedPage),
      );
    }
    return (
      messages: const [],
      meta: ChatMessagesPageMeta.singlePage(requestedPage),
    );
  }

  List<ChatMessage> _sortedMessagesFromRows(List<dynamic>? rows) {
    if (rows == null || rows.isEmpty) return const [];
    final messages = rows
        .map((e) => _parseMessage(e as Map<String, dynamic>))
        .toList();
    messages.sort(
      (a, b) =>
          DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
    );
    return messages;
  }

  Future<ChatMessage> sendTextMessage(
    ChatCredentials c,
    int conversationId,
    String content, {
    String? Function()? socketId,
    /// Laravel chat parity: binds message to parent row when API supports `reply_to_message_id`.
    int? replyToMessageId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    final replyId = switch (replyToMessageId) {
      final id? when id > 0 => id,
      _ => null,
    };

    /// Chat-service payloads vary (`reply_to`, `parent_id`, etc.) — duplicate keys hurt
    /// strict APIs less than missing the one Laravel validates.
    final body = <String, dynamic>{
      'content': content,
      'type': 'text',
    };
    if (replyId != null) {
      body['reply_to_message_id'] = replyId;
      body['reply_to_id'] = replyId;
      body['parent_id'] = replyId;
      body['parent_message_id'] = replyId;
      body['reply_to'] = replyId;
    }

    final res = await dio.post<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/messages',
      data: body,
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw ServerException(data?['message'] as String? ?? 'Send failed');
    }
    final msg = coerceChatMessagePayload(data['data']);
    if (msg == null) {
      throw const ServerException('Invalid send response');
    }
    return _parseMessage(msg);
  }

  Future<void> markRead(
    ChatCredentials c,
    int conversationId, {
    String? Function()? socketId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    await dio.post<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/read',
    );
  }

  /// `PUT /api/v1/conversations/{id}/messages/{messageId}` — owner edits text content.
  Future<ChatMessage> updateTextMessage(
    ChatCredentials c,
    int conversationId,
    int messageId, {
    required String content,
    String type = 'text',
    String? Function()? socketId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    final res = await dio.put<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/messages/$messageId',
      data: <String, dynamic>{'content': content, 'type': type},
    );
    final data = res.data;
    if (data == null || data['success'] != true) {
      throw ServerException(data?['message'] as String? ?? 'Update failed');
    }
    final msg = coerceChatMessagePayload(data['data']);
    if (msg == null) {
      throw const ServerException('Invalid update response');
    }
    return _parseMessage(msg);
  }

  /// Download bytes for message attachment (authenticated). Used when forwarding media.
  Future<Uint8List> fetchMessageAttachmentBytes(
    ChatCredentials c,
    ChatMessage m, {
    String? Function()? socketId,
  }) async {
    var path = (m.fileUrl ?? '').trim();
    if (path.isEmpty) {
      final body = plainBodyFromChatContent(m.content).trim();
      if (looksLikeRemoteMediaUrl(body)) {
        path = body;
      }
    }
    if (path.isEmpty) {
      throw const ServerException('Message has no attachment');
    }
    final dio = _chatDio(c, socketId: socketId);
    final url = resolveChatMediaUrl(path, c.apiBaseUrl).trim();
    if (url.isEmpty) {
      throw const ServerException('Invalid attachment URL');
    }
    if (!isAllowedChatMediaHost(url, c.apiBaseUrl)) {
      throw const ServerException('Attachment host not allowed');
    }

    final hdr = <String, dynamic>{
      ...dio.options.headers.map((k, v) => MapEntry(k, v)),
      'Accept': '*/*',
    };

    final res = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes, headers: hdr),
    );

    if (res.statusCode != 200 || res.data == null) {
      throw ServerException('Download failed (${res.statusCode})');
    }
    return Uint8List.fromList(res.data!);
  }

  /// `DELETE /api/v1/conversations/{id}/messages/{messageId}` — owner removes their message.
  Future<void> deleteMessage(
    ChatCredentials c,
    int conversationId,
    int messageId, {
    String? Function()? socketId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    await dio.delete<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/messages/$messageId',
    );
  }

  Future<void> sendTyping(
    ChatCredentials c,
    int conversationId,
    bool isTyping, {
    String? Function()? socketId,
  }) async {
    final dio = _chatDio(c, socketId: socketId);
    await dio.post<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/typing',
      data: <String, dynamic>{'is_typing': isTyping},
    );
  }

  /// Downloads a remote URL then uploads as attachment (never as plain text link).
  Future<ChatMessage> uploadMessageFromRemoteReference(
    ChatCredentials c,
    int conversationId, {
    required String reference,
    String caption = '',
    String? Function()? socketId,
  }) async {
    final url = reference.trim();
    final resolved = resolveChatMediaUrl(
      url.startsWith('http') ? url : null,
      c.apiBaseUrl,
    );
    final target = resolved.isNotEmpty ? resolved : url;
    if (!isAllowedChatMediaHost(target, c.apiBaseUrl)) {
      throw const ServerException('Attachment host not allowed');
    }
    final targetUri = Uri.tryParse(target);
    final baseUri = Uri.tryParse(c.apiBaseUrl.trim());
    final sameChatHost = targetUri != null &&
        baseUri != null &&
        targetUri.host.isNotEmpty &&
        targetUri.host.toLowerCase() == baseUri.host.toLowerCase();
    final client = sameChatHost
        ? _chatDio(c, socketId: socketId)
        : Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
              headers: <String, dynamic>{'Accept': '*/*'},
            ),
          );
    final res = await client.get<List<int>>(
      target,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = res.data;
    if (bytes == null || bytes.isEmpty) {
      throw const ServerException('Could not download attachment');
    }
    return uploadMessageAttachment(
      c,
      conversationId,
      filename: filenameFromMediaReference(target),
      bytes: bytes,
      caption: caption,
      socketId: socketId,
    );
  }

  /// Multipart upload — same contract as `AdvertiserChatDialog.tsx` (`file`, optional `content`).
  /// Uses bytes so it works on mobile and web (`withData: true` from file_picker).
  Future<ChatMessage> uploadMessageAttachment(
    ChatCredentials c,
    int conversationId, {
    required String filename,
    List<int>? bytes,
    String? filePath,
    String caption = '',
    String? Function()? socketId,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final safeCaption = sanitizeOutgoingAttachmentCaption(caption);
    final isPdf = isChatPdfExtension(extensionFromFilename(filename) ?? '');
    final contentType = _multipartContentTypeForFilename(filename);

    MultipartFile filePart;
    final path = filePath?.trim();
    if (!kIsWeb && path != null && path.isNotEmpty) {
      filePart = await MultipartFile.fromFile(
        path,
        filename: filename,
        contentType: contentType,
      );
    } else {
      final data = bytes;
      if (data == null || data.isEmpty) {
        throw const ServerException('Attachment bytes missing');
      }
      filePart = MultipartFile.fromBytes(
        data,
        filename: filename,
        contentType: contentType,
      );
    }

    final form = FormData.fromMap(<String, dynamic>{
      if (safeCaption.isNotEmpty) 'content': safeCaption,
      'type': isPdf ? 'file' : 'image',
      'file': filePart,
    });

    final dio = _chatDio(c, socketId: socketId);
    dio.options.connectTimeout = const Duration(seconds: 120);
    dio.options.receiveTimeout = const Duration(seconds: 120);
    dio.options.sendTimeout = const Duration(seconds: 120);

    final res = await dio.post<Map<String, dynamic>>(
      'api/v1/conversations/$conversationId/messages',
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Authorization': 'Bearer ${c.token.trim()}',
          'X-Application-ID': c.appId.trim(),
        },
      ),
      onSendProgress: onSendProgress,
    );

    final data = res.data;
    if (data == null || data['success'] != true) {
      throw ServerException(data?['message'] as String? ?? 'Upload failed');
    }
    final msg = coerceChatMessagePayload(data['data']);
    if (msg == null) {
      throw const ServerException('Invalid upload response');
    }
    return _parseMessage(msg);
  }

  ChatConversation _parseConversation(Map<String, dynamic> m) {
    final last = m['last_message'] ?? m['lastMessage'];
    return ChatConversation(
      id: (m['id'] as num).toInt(),
      type: '${m['type'] ?? 'direct'}',
      status: m['status'] as String?,
      displayName: m['display_name'] as String? ?? m['displayName'] as String?,
      displayAvatar:
          m['display_avatar'] as String? ?? m['displayAvatar'] as String?,
      unreadCount:
          (m['unread_count'] as num?)?.toInt() ??
          (m['unreadCount'] as num?)?.toInt() ??
          0,
      updatedAt: m['updated_at'] as String? ?? m['updatedAt'] as String?,
      lastMessage: last is Map<String, dynamic> ? _parseMessage(last) : null,
      participants: _parseParticipants(m['participants']),
    );
  }

  List<ChatParticipant>? _parseParticipants(dynamic raw) {
    if (raw is! List<dynamic>) return null;
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      final u = m['user'];
      return ChatParticipant(
        userId:
            (m['user_id'] as num?)?.toInt() ??
            (m['userId'] as num?)?.toInt() ??
            0,
        lastReadAt: m['last_read_at'] as String? ?? m['lastReadAt'] as String?,
        user: u is Map<String, dynamic>
            ? ChatUserPreview(
                id: (u['id'] as num).toInt(),
                name: u['name'] as String?,
                avatar: u['avatar'] as String?,
                email: u['email'] as String?,
                marketingUserId:
                    u['marketing_user_id'] as String? ??
                    u['marketingUserId'] as String?,
              )
            : null,
      );
    }).toList();
  }

  /// Used by realtime payloads (`message.sent`, `message.edited`).
  ChatMessage parseRemoteMessage(Map<String, dynamic> m) =>
      _parseMessage(coerceChatMessagePayload(m) ?? m);

  /// Normalizes Laravel / Pusher shapes (`message`, nested `data`, etc.).
  static Map<String, dynamic>? coerceChatMessagePayload(dynamic raw) {
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final map = asMap(raw);
    if (map == null) return null;

    for (final key in ['message', 'data', 'attributes', 'resource']) {
      final inner = asMap(map[key]);
      if (inner == null) continue;
      final coerced = coerceChatMessagePayload(inner);
      if (coerced != null &&
          (coerced.containsKey('id') || coerced.containsKey('content'))) {
        return coerced;
      }
    }

    if (map.containsKey('id') &&
        (map.containsKey('type') ||
            map.containsKey('content') ||
            map.containsKey('file_url') ||
            map.containsKey('fileUrl'))) {
      return map;
    }
    return map;
  }

  MediaType? _multipartContentTypeForFilename(String filename) {
    final ext = extensionFromFilename(filename);
    return switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      'bmp' => MediaType('image', 'bmp'),
      'pdf' => MediaType('application', 'pdf'),
      _ => null,
    };
  }

  ChatReplyRef? _parseReplyRef(Map<String, dynamic> m) {
    final raw =
        m['reply_to'] ??
            m['replyTo'] ??
            m['referenced_message'] ??
            m['referencedMessage'] ??
            m['quoted_message'] ??
            m['quotedMessage'] ??
            m['parent'];
    if (raw is! Map<String, dynamic>) return null;

    final idRaw = raw['id'] ?? raw['message_id'] ?? raw['messageId'];
    if (idRaw is! num) return null;
    final id = idRaw.toInt();

    final pv = raw['content'] ?? raw['body'] ?? raw['text'] ?? raw['preview'];
    var preview = pv == null ? '' : '$pv'.trim();
    if (preview.isEmpty) {
      final t = '${raw['type'] ?? ''}'.trim();
      if (t.isNotEmpty && t != 'text') {
        preview = t;
      }
    }

    String? senderName;
    final u = raw['user'] ?? raw['sender'];
    if (u is Map<String, dynamic>) {
      final n = u['name'] ?? u['display_name'];
      if (n is String && n.trim().isNotEmpty) {
        senderName = n.trim();
      }
    }

    return ChatReplyRef(
      messageId: id,
      preview: preview,
      senderName: senderName,
    );
  }

  ChatMessage _parseMessage(Map<String, dynamic> raw) {
    final m = coerceChatMessagePayload(raw) ?? raw;
    final replyTo = _parseReplyRef(m);
    final u = m['user'];
    final s = m['sender'];
    Map<String, dynamic>? userEnvelope;
    if (u is Map<String, dynamic>) {
      userEnvelope = u;
    } else if (s is Map<String, dynamic>) {
      userEnvelope = s;
    }
    return normalizeChatMessage(
      ChatMessage(
        id: (m['id'] as num).toInt(),
        conversationId:
            (m['conversation_id'] as num?)?.toInt() ??
            (m['conversationId'] as num?)?.toInt() ??
            0,
        userId:
            (m['user_id'] as num?)?.toInt() ??
            (m['userId'] as num?)?.toInt() ??
            0,
        content: '${m['content'] ?? ''}',
        type: '${m['type'] ?? 'text'}',
        createdAt: '${m['created_at'] ?? m['createdAt'] ?? ''}',
        updatedAt: m['updated_at'] as String? ?? m['updatedAt'] as String?,
        editedAt: m['edited_at'] as String? ?? m['editedAt'] as String?,
        isEdited: m['is_edited'] == true || m['isEdited'] == true,
        fileUrl: m['file_url'] as String? ?? m['fileUrl'] as String?,
        fileName: m['file_name'] as String? ?? m['fileName'] as String?,
        fileSize:
            (m['file_size'] as num?)?.toInt() ??
            (m['fileSize'] as num?)?.toInt(),
        user: userEnvelope != null
            ? ChatUserPreview(
                id: (userEnvelope['id'] as num).toInt(),
                name: userEnvelope['name'] as String?,
                avatar: userEnvelope['avatar'] as String?,
              )
            : null,
        replyTo: replyTo,
      ),
    );
  }
}
