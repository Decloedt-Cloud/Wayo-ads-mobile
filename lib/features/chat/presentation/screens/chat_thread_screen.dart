import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/push/wayo_push_intent.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_message_media.dart';
import '../../data/chat_share_intent.dart';
import '../../data/chat_phone_validation.dart';
import '../../data/chat_realtime_service.dart';
import '../../data/chat_messages_page.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_send_spam_guard.dart';
import '../cinematic/cinematic_chat_colors.dart';
import '../cinematic/cinematic_chat_header.dart';
import '../cinematic/cinematic_composer_bar.dart';
import '../cinematic/cinematic_date_pill.dart';
import '../cinematic/cinematic_mesh_background.dart';
import '../cinematic/cinematic_message_bubble.dart';
import '../cinematic/cinematic_send_burst.dart';
import '../cinematic/cinematic_typing_dots.dart';
import '../formatting/chat_message_plain_body.dart';
import '../formatting/chat_unread_badge_label.dart';
import '../providers/chat_pending_share_provider.dart';
import '../providers/chat_providers.dart';

/// Flat layout rows for [ChatThreadScreen] — lets [SliverChildBuilderDelegate]
/// build only visible bubbles instead of materializing the whole thread upfront.
sealed class _ThreadSegment {
  const _ThreadSegment();
}

final class _ThreadDateSegment extends _ThreadSegment {
  const _ThreadDateSegment(this.day);
  final DateTime day;
}

final class _ThreadMessageSegment extends _ThreadSegment {
  const _ThreadMessageSegment(this.messageIndex);
  final int messageIndex;
}

List<_ThreadSegment> _flattenMessagesToSegments(List<ChatMessage> msgs) {
  if (msgs.isEmpty) return const [];
  final out = <_ThreadSegment>[];
  DateTime? lastDay;
  for (var i = 0; i < msgs.length; i++) {
    final m = msgs[i];
    final parsed = DateTime.tryParse(m.createdAt)?.toLocal();
    if (parsed != null) {
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      if (lastDay == null || day != lastDay) {
        out.add(_ThreadDateSegment(day));
        lastDay = day;
      }
    }
    out.add(_ThreadMessageSegment(i));
  }
  return out;
}

/// ━━━ Fil de discussion — UI cinématique (fond vivant, slivers, bulles, composer) ━━━
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    this.autoFocusComposer = false,
  });

  final int conversationId;

  /// Opened from push “Répondre” — focus composer after load.
  final bool autoFocusComposer;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _scroll = ScrollController();
  final _draft = TextEditingController();
  final _fabVisible = ValueNotifier<bool>(false);
  final GlobalKey<CinematicSendBurstState> _burstKey =
      GlobalKey<CinematicSendBurstState>();
  StreamSubscription<ChatRealtimeEvent>? _sub;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  String? _typingName;
  Timer? _typingTimer;
  Timer? _typingQuietTimer;
  String? _phoneError;
  bool _uploading = false;
  DateTime? _peerReadAt;
  int? _selectedMessageId;
  int? _editingMessageId;
  String _editingOriginalContent = '';
  ChatMessage? _replyingTo;
  bool _pendingShareBound = false;
  final ChatSendSpamGuard _sendSpamGuard = ChatSendSpamGuard();
  Timer? _spamCooldownTicker;

  /// Laravel-style `page` / `per_page` for [/messages].
  static const int _messagesPageSize = 40;

  /// Near-top scroll threshold — fetch older messages (prepend).
  static const double _loadOlderScrollThresholdPx = 160;

  int _messagesLastPageLoaded = 1;
  bool _hasMoreOlderMessages = true;
  bool _loadingOlderMessages = false;
  bool _olderMessagesFetchInFlight = false;

  /// Show scroll-to-end FAB when farther than this from the list bottom.
  static const double _fabGapThreshold = 200;

  /// "At bottom" tolerance: at or below this gap we clear the off-screen counter.
  static const double _scrollBottomSlack = 80;

  /// Peer messages received while scrolled up (shown on the scroll-down FAB).
  int _offscreenPeerMessageCount = 0;

  /// After opening a conversation, keep jumping to max extent while the list lays out
  /// (slow images/fonts on mobile inflate [maxScrollExtent] after first frame).
  /// Cleared after ~6 seconds or any user-initiated scroll.
  bool _pinThreadToLatest = false;
  Timer? _pinThreadToLatestExpiry;
  /// Extra scroll-to-end pings while [_pinThreadToLatest] is true (fallback if some
  /// layout passes do not emit [ScrollMetricsNotification]).
  static const List<Duration> _bootstrapScrollRetries = [
    Duration(milliseconds: 100),
    Duration(milliseconds: 320),
    Duration(milliseconds: 700),
    Duration(milliseconds: 1400),
  ];

  /// Memo so [_flattenMessagesToSegments] is not recomputed unless [_messages] reference changes.
  List<_ThreadSegment>? _segmentsMemo;
  List<ChatMessage>? _segmentsMemoMessagesRef;

  List<_ThreadSegment> _segmentsForMessages() {
    if (identical(_segmentsMemoMessagesRef, _messages) &&
        _segmentsMemo != null) {
      return _segmentsMemo!;
    }
    final built = _flattenMessagesToSegments(_messages);
    _segmentsMemoMessagesRef = _messages;
    _segmentsMemo = built;
    return built;
  }

  /// Space below the last message only. Do **not** add [MediaQuery.padding.bottom]
  /// here — [CinematicComposerBar] already applies safe-area padding; duplicating it
  /// on the sliver created a large empty band above the composer.
  static const double _listBottomGap = 12;

  SystemUiOverlayStyle _threadSystemUi(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ct = CinematicChatTheme.of(context);
    return SystemUiOverlayStyle(
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: ct.bg,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  /// Back from push deep-link uses [GoRouter.go] (no stack) — [pop] would throw.
  void _onThreadBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chat');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _typingTimer?.cancel();
    _typingQuietTimer?.cancel();
    _spamCooldownTicker?.cancel();
    _pinThreadToLatestExpiry?.cancel();
    _scroll.dispose();
    _draft.dispose();
    _fabVisible.dispose();
    super.dispose();
  }

  void _syncSpamCooldownTicker() {
    if (!_sendSpamGuard.isCoolingDown) {
      _spamCooldownTicker?.cancel();
      _spamCooldownTicker = null;
      return;
    }
    _spamCooldownTicker ??= Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      if (_sendSpamGuard.remainingCooldown == null) {
        _spamCooldownTicker?.cancel();
        _spamCooldownTicker = null;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    _cancelPinThreadToLatest();
    setState(() {
      _loading = true;
      _error = null;
      _offscreenPeerMessageCount = 0;
      _messagesLastPageLoaded = 1;
      _hasMoreOlderMessages = true;
      _loadingOlderMessages = false;
      _olderMessagesFetchInFlight = false;
    });

    ref.read(chatRealtimeBindingProvider);
    final rt = ref.read(chatRealtimeServiceProvider);
    final repo = ref.read(chatRepositoryProvider);

    Object? lastError;
    ChatCredentials? validCreds;
    ChatMessagesPage? loadedPage;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final creds = await ref.read(chatBootstrapProvider.future);
        loadedPage = await repo.fetchMessagesPage(
          creds,
          widget.conversationId,
          socketId: () => rt.socketId,
          page: 1,
          perPage: _messagesPageSize,
        );
        validCreds = creds;
        break;
      } on DioException catch (e) {
        lastError = e;
        final is401 = e.response?.statusCode == 401;
        if (is401) {
          ref.invalidate(chatBootstrapProvider);
        }
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
        }
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 320 * (attempt + 1)),
          );
        }
      }
    }

    if (!mounted) return;

    if (loadedPage == null || validCreds == null) {
      setState(() {
        _loading = false;
        _error = ChatRepository.mapError(lastError!).toString();
      });
      return;
    }

    try {
      await repo.markRead(
        validCreds,
        widget.conversationId,
        socketId: () => rt.socketId,
      );
      ref.invalidate(chatConversationsProvider);
    } catch (_) {
      // Mark-read failure is non-fatal.
    }

    if (!mounted) return;

    // Wait for WS binding (chat-service `/broadcasting/auth` + subscriptions) then
    // ensure **this** thread is subscribed (list can lag briefly after invalidate).
    try {
      await ref.read(chatRealtimeBindingProvider.future);
      final conversations = ref.read(chatConversationsProvider).valueOrNull;
      final idSet = <int>{widget.conversationId};
      if (conversations != null) {
        idSet.addAll(conversations.map((c) => c.id));
      }
      await rt.updateConversationSubscriptions(validCreds, idSet.toList());
    } catch (_) {}

    if (!mounted) return;

    final page = loadedPage;
    setState(() {
      _messages = page.messages;
      _messagesLastPageLoaded = page.currentPage;
      _hasMoreOlderMessages = page.hasMore;
      _loading = false;
    });
    _seedPeerReadAtFromConversations(validCreds.chatUserId);
    _beginPinThreadToLatestAfterOpen();
    _scrollToLatestAfterUiSettles();
    _scheduleBootstrapScrollRetries();
    _listenRt(validCreds, repo, rt);
    _bindPendingShare(validCreds, repo, rt);
  }

  void _bindPendingShare(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) {
    if (_pendingShareBound) return;
    _pendingShareBound = true;

    ref.listen<List<SharedMediaFile>>(chatPendingShareProvider, (prev, next) {
      if (!mounted || next.isEmpty || _loading) return;
      unawaited(_consumePendingShare(next, creds, repo, rt));
    });

    final pending = ref.read(chatPendingShareProvider);
    if (pending.isNotEmpty) {
      unawaited(_consumePendingShare(pending, creds, repo, rt));
    }
  }

  Future<void> _consumePendingShare(
    List<SharedMediaFile> files,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    ref.read(chatPendingShareProvider.notifier).state = const [];
    await _uploadSharedFiles(files, creds, repo, rt);
    await ChatShareIntent.reset();
  }

  void _cancelPinThreadToLatest() {
    _pinThreadToLatestExpiry?.cancel();
    _pinThreadToLatestExpiry = null;
    _pinThreadToLatest = false;
  }

  void _beginPinThreadToLatestAfterOpen() {
    _pinThreadToLatestExpiry?.cancel();
    _pinThreadToLatest = _messages.isNotEmpty;
    if (!_pinThreadToLatest) return;
    _pinThreadToLatestExpiry = Timer(const Duration(seconds: 6), () {
      _pinThreadToLatestExpiry = null;
      if (!mounted) return;
      _pinThreadToLatest = false;
    });
  }

  void _scheduleBootstrapScrollRetries() {
    for (final d in _bootstrapScrollRetries) {
      Future<void>.delayed(d, () {
        if (!mounted || !_pinThreadToLatest) return;
        if (_messages.isEmpty || _loading || _error != null) return;
        _scrollToEnd(animated: false);
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_olderMessagesFetchInFlight ||
        !_hasMoreOlderMessages ||
        _loading ||
        _error != null) {
      return;
    }
    _olderMessagesFetchInFlight = true;
    if (mounted) {
      setState(() => _loadingOlderMessages = true);
    }

    final rt = ref.read(chatRealtimeServiceProvider);
    final repo = ref.read(chatRepositoryProvider);

    double? anchorPixels;
    double? anchorMaxExtent;
    if (_scroll.hasClients) {
      final p = _scroll.position;
      if (p.hasContentDimensions) {
        anchorPixels = p.pixels;
        anchorMaxExtent = p.maxScrollExtent;
      }
    }

    try {
      final creds = await ref.read(chatBootstrapProvider.future);
      final page = await repo.fetchMessagesPage(
        creds,
        widget.conversationId,
        socketId: () => rt.socketId,
        page: _messagesLastPageLoaded + 1,
        perPage: _messagesPageSize,
      );

      if (!mounted) return;

      final existingIds = _messages.map((m) => m.id).toSet();
      final olderOnly =
          page.messages.where((m) => !existingIds.contains(m.id)).toList();
      final merged = [...olderOnly, ..._messages];
      merged.sort(
        (a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

      setState(() {
        _messages = merged;
        _messagesLastPageLoaded = page.currentPage;
        _hasMoreOlderMessages = page.hasMore;
      });

      if (anchorPixels != null &&
          anchorMaxExtent != null &&
          mounted &&
          _scroll.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll.hasClients) return;
          final p = _scroll.position;
          if (!p.hasContentDimensions) return;
          final delta = p.maxScrollExtent - anchorMaxExtent!;
          final target = anchorPixels! + delta;
          _scroll.jumpTo(
            target.clamp(p.minScrollExtent, p.maxScrollExtent),
          );
          _syncScrollFabVisibility();
        });
      }
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(context.t.chat.load_older_failed)),
      );
    } finally {
      _olderMessagesFetchInFlight = false;
      if (mounted) {
        setState(() => _loadingOlderMessages = false);
      }
    }
  }

  void _seedPeerReadAtFromConversations(int myChatUserId) {
    final convList = ref.read(chatConversationsProvider).valueOrNull;
    final conv = _findConversation(convList);
    final parts = conv?.participants;
    if (parts == null) return;
    DateTime? best;
    for (final p in parts) {
      final uid = p.user?.id ?? p.userId;
      if (uid == myChatUserId) continue;
      final raw = p.lastReadAt;
      if (raw == null || raw.isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;
      if (best == null || parsed.isAfter(best)) best = parsed;
    }
    if (best != null && (_peerReadAt == null || best.isAfter(_peerReadAt!))) {
      if (mounted) setState(() => _peerReadAt = best);
    }
  }

  void _listenRt(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) {
    _sub?.cancel();
    _sub = rt.events.listen((event) {
      if (!mounted) return;
      if (event is ChatMessageSentEvent &&
          event.conversationId == widget.conversationId) {
        final m = repo.parseRemoteMessage(event.rawMessage);
        if (m.userId == creds.chatUserId) {
          return;
        }
        if (_messages.any((x) => x.id == m.id)) {
          return;
        }
        final gapBefore =
            _scroll.hasClients && _scroll.position.hasContentDimensions
            ? (_scroll.position.maxScrollExtent - _scroll.position.pixels)
            : 0.0;
        final scrolledUp = gapBefore > _scrollBottomSlack;
        HapticFeedback.lightImpact();
        setState(() {
          _messages = [..._messages, m];
          if (scrolledUp) {
            _offscreenPeerMessageCount++;
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncScrollFabVisibility();
        });
        return;
      }
      if (event is ChatTypingEvent &&
          event.conversationId == widget.conversationId) {
        _typingTimer?.cancel();
        if (!event.isTyping) {
          setState(() => _typingName = null);
          return;
        }
        setState(() => _typingName = event.userName);
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _typingName = null);
        });
        return;
      }
      if (event is ChatMessageDeletedEvent &&
          event.conversationId == widget.conversationId) {
        setState(() {
          _messages = _messages.where((m) => m.id != event.messageId).toList();
          if (_selectedMessageId == event.messageId) _selectedMessageId = null;
          if (_editingMessageId == event.messageId) {
            _editingMessageId = null;
            _editingOriginalContent = '';
            _draft.clear();
          }
        });
        return;
      }
      if (event is ChatMessageEditedEvent &&
          event.conversationId == widget.conversationId) {
        final m = repo.parseRemoteMessage(event.rawMessage);
        setState(() {
          _messages = _messages.map((x) => x.id == m.id ? m : x).toList();
        });
        return;
      }
      if (event is ChatMessageReadEvent &&
          event.conversationId == widget.conversationId) {
        if (event.readerId == creds.chatUserId) return;
        final parsed = DateTime.tryParse(event.readAt);
        if (parsed == null) return;
        if (_peerReadAt == null || parsed.isAfter(_peerReadAt!)) {
          setState(() => _peerReadAt = parsed);
        }
        return;
      }
    });
  }

  void _syncScrollFabVisibility() {
    if (!_scroll.hasClients) {
      return;
    }
    final m = _scroll.position;
    if (!m.hasContentDimensions) {
      return;
    }
    final gap = m.maxScrollExtent - m.pixels;
    final show = gap > _fabGapThreshold || _offscreenPeerMessageCount > 0;
    if (_fabVisible.value != show) {
      _fabVisible.value = show;
    }
  }

  /// After [_loading] becomes false the [CustomScrollView] often still reports
  /// `hasContentDimensions: false` for a frame — a single [_scrollToEnd] then
  /// no-ops and the thread opens at the top. Retry across frames until the list
  /// pins to the last message (or [maxAttempts] is reached).
  void _scrollToLatestAfterUiSettles({int attempt = 0}) {
    const maxAttempts = 28;
    if (!mounted || attempt >= maxAttempts) {
      _syncScrollFabVisibility();
      return;
    }
    if (_messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncScrollFabVisibility();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) {
        _scrollToLatestAfterUiSettles(attempt: attempt + 1);
        return;
      }
      final p = _scroll.position;
      final target = p.maxScrollExtent;
      if (!target.isFinite || target <= 0) {
        _scrollToLatestAfterUiSettles(attempt: attempt + 1);
        return;
      }
      _scroll.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final p2 = _scroll.position;
        if (!p2.hasContentDimensions) {
          _scrollToLatestAfterUiSettles(attempt: attempt + 1);
          return;
        }
        final gap = p2.maxScrollExtent - p2.pixels;
        if (gap > 6 && attempt + 1 < maxAttempts) {
          _scrollToLatestAfterUiSettles(attempt: attempt + 1);
        } else {
          _syncScrollFabVisibility();
        }
      });
    });
  }

  void _scrollToEnd({required bool animated}) {
    if (_offscreenPeerMessageCount > 0 && mounted) {
      setState(() => _offscreenPeerMessageCount = 0);
    }
    if (!_scroll.hasClients) {
      return;
    }
    final position = _scroll.position;
    if (!position.hasContentDimensions) {
      /// User tapped “scroll down” FAB — same race as cold open; chase layout.
      _scrollToLatestAfterUiSettles();
      return;
    }
    final target = position.maxScrollExtent;
    if (animated) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutExpo,
      );
    } else {
      _scroll.jumpTo(target);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncScrollFabVisibility();
    });
  }

  bool _onScroll(ScrollNotification n) {
    // User drag on the viewport (finger / stylus) → stop pinning to latest.
    if (_pinThreadToLatest &&
        n is ScrollStartNotification &&
        n.dragDetails != null) {
      _cancelPinThreadToLatest();
    }
    // Bubble / image intrinsic height settles after cold open → chase max extent once.
    if (_pinThreadToLatest &&
        !_loading &&
        _error == null &&
        !_loadingOlderMessages &&
        !_olderMessagesFetchInFlight &&
        _messages.isNotEmpty &&
        n is ScrollMetricsNotification) {
      if (_scroll.hasClients) {
        final p = _scroll.position;
        if (p.hasContentDimensions) {
          final max = p.maxScrollExtent;
          if (max.isFinite && max > 0) {
            final gap = max - p.pixels;
            if (gap > 2.0) {
              _scroll.jumpTo(max);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _syncScrollFabVisibility();
              });
            }
          }
        }
      }
    }

    if (n is! ScrollUpdateNotification && n is! ScrollMetricsNotification) {
      return false;
    }
    final m = _scroll.hasClients ? _scroll.position : null;
    if (m == null || !m.hasContentDimensions) {
      return false;
    }
    if (n is ScrollUpdateNotification &&
        !_loadingOlderMessages &&
        _hasMoreOlderMessages &&
        !_loading &&
        _error == null &&
        !_olderMessagesFetchInFlight &&
        m.pixels <= _loadOlderScrollThresholdPx) {
      unawaited(_loadOlderMessages());
    }

    final gap = m.maxScrollExtent - m.pixels;
    // Only clear when the user scrolls — not when layout grows (new messages).
    if (n is ScrollUpdateNotification &&
        gap <= _scrollBottomSlack &&
        _offscreenPeerMessageCount > 0) {
      setState(() => _offscreenPeerMessageCount = 0);
    }
    final show = gap > _fabGapThreshold || _offscreenPeerMessageCount > 0;
    if (_fabVisible.value != show) {
      _fabVisible.value = show;
    }
    return false;
  }

  String _dayLabel(DateTime day, Translations t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final y = today.subtract(const Duration(days: 1));
    if (day == today) return t.chat.date_today;
    if (day == y) return t.chat.date_yesterday;
    return DateFormat.yMMMd().format(day);
  }

  String _replySnippet(ChatMessage m) {
    final raw = m.content.trim();
    if (raw.isNotEmpty) {
      return raw.length > 120 ? '${raw.substring(0, 120)}…' : raw;
    }
    if (m.type == 'image') return '📷';
    if (m.type == 'file') {
      final n = m.fileName?.trim();
      return (n != null && n.isNotEmpty) ? n : 'PDF';
    }
    return m.type;
  }

  /// Banner title row (Reply to **Name**).
  String _replyBannerTitle(ChatMessage m, ChatCredentials creds) {
    if (m.userId == creds.chatUserId) {
      return context.t.chat.reply_composer_you;
    }
    final n = m.user?.name?.trim();
    return (n != null && n.isNotEmpty) ? n : '?';
  }

  void _beginReply(ChatMessage m) {
    setState(() {
      _replyingTo = m;
      _selectedMessageId = null;
      _editingMessageId = null;
      _editingOriginalContent = '';
    });
    HapticFeedback.selectionClick();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _onCopyMessage(ChatMessage m) {
    final plain = plainBodyFromChatContent(m.content);
    if (plain.isEmpty) return;
    Clipboard.setData(ClipboardData(text: plain));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.chat.bubble_copied)),
    );
  }

  void _onForwardMessage(
    ChatMessage m,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) {
    final t = context.t;
    final list = ref.read(chatConversationsProvider).valueOrNull;
    final others = (list ?? [])
        .where((c) => c.id != widget.conversationId)
        .toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.chat.forward_no_other_chats)),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    t.chat.forward_sheet_title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: others.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final conv = others[i];
                      final title = conv.title(t.chat.conversation_unknown);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.borderOf(context),
                          ),
                        ),
                        title: Text(title, maxLines: 1),
                        subtitle: conv.lastMessage != null
                            ? Text(
                                _replySnippet(conv.lastMessage!),
                                maxLines: 1,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          unawaited(
                            _forwardMessageToConversation(
                              m,
                              conv,
                              creds,
                              repo,
                              rt,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _forwardMessageToConversation(
    ChatMessage m,
    ChatConversation target,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    final t = context.t;
    if (!mounted) return;
    var messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(t.chat.forward_sending)));
    try {
      final plainCaption = plainBodyFromChatContent(m.content);

      final media = resolveChatMessageMedia(m, creds.apiBaseUrl);
      if (media.hasMedia) {
        final bytes = await repo.fetchMessageAttachmentBytes(
          creds,
          m,
          socketId: () => rt.socketId,
        );
        final rawName = (m.fileName ?? '').trim();
        final filename = rawName.isNotEmpty
            ? rawName
            : (media.isImage ? 'photo.jpg' : 'document.pdf');
        await repo.uploadMessageAttachment(
          creds,
          target.id,
          filename: filename,
          bytes: bytes,
          caption: plainCaption,
          socketId: () => rt.socketId,
        );
      } else {
        final outbound = plainBodyFromChatContent(m.content).trim();
        if (outbound.isEmpty) return;
        await repo.sendTextMessage(
          creds,
          target.id,
          outbound,
          socketId: () => rt.socketId,
        );
      }
      ref.invalidate(chatConversationsProvider);
      if (!mounted) return;
      messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.chat.forward_ok),
          action: SnackBarAction(
            label: t.chat.forward_view,
            onPressed: () {
              if (context.mounted) {
                context.push('/chat/thread/${target.id}');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(t.chat.forward_failed)),
      );
      debugPrint('[ChatThread] forward failed: $e');
    }
  }

  Future<void> _onSend(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    if (chatTextLooksLikePhoneNumber(text)) {
      setState(() => _phoneError = context.t.chat.error_phone);
      return;
    }
    setState(() => _phoneError = null);

    // Edit mode bypasses flood control (single intentional update).
    if (_editingMessageId == null) {
      final blocked = _sendSpamGuard.checkBeforeSend();
      if (blocked != null) {
        HapticFeedback.heavyImpact();
        setState(() {});
        _syncSpamCooldownTicker();
        return;
      }
    }

    if (await _tryUploadMediaReference(
      text,
      creds,
      repo,
      rt,
      replyTo: _replyingTo,
    )) {
      return;
    }

    // ── Edit mode: PUT /messages/{id}
    final editingId = _editingMessageId;
    if (editingId != null) {
      if (text == _editingOriginalContent) {
        setState(() {
          _editingMessageId = null;
          _editingOriginalContent = '';
          _draft.clear();
        });
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() => _sending = true);
      try {
        final updated = await repo.updateTextMessage(
          creds,
          widget.conversationId,
          editingId,
          content: text,
          socketId: () => rt.socketId,
        );
        if (!mounted) return;
        setState(() {
          _messages = _messages
              .map((m) => m.id == editingId ? updated : m)
              .toList();
          _editingMessageId = null;
          _editingOriginalContent = '';
          _draft.clear();
        });
        ref.invalidate(chatConversationsProvider);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.t.chat.edit_failed)));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

    HapticFeedback.mediumImpact();
    _sendSpamGuard.recordSend();
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final quote = _replyingTo;
    ChatReplyRef? optimisticReply;
    if (quote != null && quote.id > 0) {
      optimisticReply = ChatReplyRef(
        messageId: quote.id,
        preview: _replySnippet(quote),
        senderName: quote.user?.name?.trim().isNotEmpty == true
            ? quote.user!.name!.trim()
            : null,
      );
    }
    final optimistic = ChatMessage(
      id: tempId,
      conversationId: widget.conversationId,
      userId: creds.chatUserId,
      content: text,
      type: 'text',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      pending: true,
      replyTo: optimisticReply,
    );
    setState(() {
      _messages = [..._messages, optimistic];
      _sending = true;
      _draft.clear();
    });
    final replyTargetId = quote != null && quote.id > 0 ? quote.id : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToEnd(animated: true);
    });
    try {
      await recordInlineReplyEchoGuard(
        conversationId: '${widget.conversationId}',
        messageText: text.trim(),
      );
      final sent = await repo.sendTextMessage(
        creds,
        widget.conversationId,
        text,
        socketId: () => rt.socketId,
        replyToMessageId: replyTargetId,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages.map((m) => m.id == tempId ? sent : m).toList();
        _replyingTo = null;
      });
      ref.invalidate(chatConversationsProvider);
    } catch (_) {
      await clearInlineReplyEchoGuard();
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (m) =>
                  m.id == tempId ? m.copyWith(pending: false, failed: true) : m,
            )
            .toList();
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onEditMessage(ChatMessage m, int myChatUserId) {
    if (m.userId != myChatUserId || m.type != 'text') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.chat.edit_not_allowed)));
      return;
    }
    setState(() {
      _selectedMessageId = null;
      _replyingTo = null;
      _editingMessageId = m.id;
      _editingOriginalContent = m.content;
      _draft.text = m.content;
      _draft.selection = TextSelection.fromPosition(
        TextPosition(offset: _draft.text.length),
      );
      _phoneError = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _editingOriginalContent = '';
      _draft.clear();
      _phoneError = null;
    });
  }

  Future<void> _onDeleteMessage(
    ChatMessage m,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    final t = context.t;
    if (m.userId != creds.chatUserId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.chat.delete_not_allowed)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ct = CinematicChatTheme.of(ctx);
        return AlertDialog(
          backgroundColor: ct.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(t.chat.delete_confirm_title),
          content: Text(t.chat.delete_confirm_text),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.chat.delete_confirm_cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.chat.delete_confirm_cta),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final previous = _messages;
    setState(() {
      _messages = _messages.where((x) => x.id != m.id).toList();
      if (_selectedMessageId == m.id) _selectedMessageId = null;
      if (_editingMessageId == m.id) {
        _editingMessageId = null;
        _editingOriginalContent = '';
        _draft.clear();
      }
    });
    try {
      await repo.deleteMessage(
        creds,
        widget.conversationId,
        m.id,
        socketId: () => rt.socketId,
      );
      ref.invalidate(chatConversationsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.chat.delete_failed)));
    }
  }

  ChatConversation? _findConversation(List<ChatConversation>? list) {
    if (list == null) return null;
    for (final c in list) {
      if (c.id == widget.conversationId) return c;
    }
    return null;
  }

  /// Partner chat user id for presence; falls back to loaded messages when the
  /// conversation is not in [chatConversationsProvider] yet (e.g. push → thread).
  int? _partnerChatUserIdForPresence(int myChatUserId, ChatConversation? conv) {
    final fromConv = conv?.partnerChatUserId(myChatUserId);
    if (fromConv != null) return fromConv;
    for (final m in _messages) {
      final uid = m.userId != 0 ? m.userId : (m.user?.id ?? 0);
      if (uid != 0 && uid != myChatUserId) return uid;
    }
    return null;
  }

  String? _partnerAvatarFromMessages(int myChatUserId) {
    for (final m in _messages) {
      final uid = m.userId != 0 ? m.userId : (m.user?.id ?? 0);
      if (uid != 0 && uid != myChatUserId) {
        return m.user?.avatar;
      }
    }
    return null;
  }

  /// Uploads local paths, remote media URLs, or gallery markers — never plain link text.
  Future<bool> _tryUploadMediaReference(
    String reference,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt, {
    ChatMessage? replyTo,
  }) async {
    final trimmed = reference.trim();
    if (!chatComposerTextLooksLikeMediaReference(trimmed)) return false;

    if (looksLikeLocalMediaUri(trimmed)) {
      final local = await readLocalChatAttachment(trimmed);
      if (local == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.chat.upload_failed)),
          );
        }
        return true;
      }
      final ext = extensionFromFilename(local.filename) ?? '';
      if (!kChatAttachmentExtensions.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.chat.attachment_type_not_allowed)),
          );
        }
        return true;
      }
      await _uploadAttachmentBytes(
        creds,
        repo,
        rt,
        filename: local.filename,
        bytes: local.bytes,
        filePath: local.path,
        caption: _draft.text.trim(),
        replyTo: replyTo,
      );
      return true;
    }

    final remoteRef = trimmed.contains(kChatGalleryContentMarker)
        ? (firstUrlFromGalleryMarkerContent(trimmed) ?? trimmed)
        : trimmed;
    if (!looksLikeRemoteMediaUrl(remoteRef)) return false;

    final caption = sanitizeOutgoingAttachmentCaption(_draft.text.trim());
    setState(() => _uploading = true);
    _draft.clear();
    try {
      final sent = await repo.uploadMessageFromRemoteReference(
        creds,
        widget.conversationId,
        reference: remoteRef,
        caption: caption,
        socketId: () => rt.socketId,
      );
      if (!mounted) return true;
      setState(() {
        _messages = [..._messages, sent];
        _phoneError = null;
        _replyingTo = null;
      });
      ref.invalidate(chatConversationsProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToEnd(animated: true);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.chat.upload_failed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
    return true;
  }

  String _filenameForSharedFile(SharedMediaFile sf, String path) {
    var name =
        path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? 'attachment';
    if (!name.contains('.')) {
      final mime = (sf.mimeType ?? '').toLowerCase();
      if (mime.contains('pdf')) {
        name = '$name.pdf';
      } else if (mime.startsWith('image/')) {
        final sub = mime.split('/').last;
        name = sub.isNotEmpty ? '$name.$sub' : '$name.jpg';
      } else {
        name = '$name.jpg';
      }
    }
    return name;
  }

  bool _sharedPathLooksLikeUrl(SharedMediaFile sf, String path) {
    if (sf.type == SharedMediaType.url) return true;
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        looksLikeRemoteMediaUrl(path);
  }

  Future<bool> _uploadOneSharedFile(
    SharedMediaFile sf,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt, {
    required String caption,
  }) async {
    final path = sf.path.trim();
    if (path.isEmpty) return false;

    if (_sharedPathLooksLikeUrl(sf, path)) {
      setState(() => _uploading = true);
      try {
        final sent = await repo.uploadMessageFromRemoteReference(
          creds,
          widget.conversationId,
          reference: path,
          caption: caption,
          socketId: () => rt.socketId,
        );
        if (!mounted) return true;
        setState(() {
          _messages = [..._messages, sent];
          _phoneError = null;
          _replyingTo = null;
        });
        ref.invalidate(chatConversationsProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToEnd(animated: true);
        });
        return true;
      } catch (_) {
        return false;
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }

    if (looksLikeLocalMediaUri(path)) {
      final local = await readLocalChatAttachment(path);
      if (local != null) {
        final ext = extensionFromFilename(local.filename) ?? '';
        if (!kChatAttachmentExtensions.contains(ext)) return false;
        await _uploadAttachmentBytes(
          creds,
          repo,
          rt,
          filename: local.filename,
          bytes: local.bytes,
          filePath: local.path,
          caption: caption,
          replyTo: _replyingTo,
        );
        return true;
      }
    }

    if (!path.startsWith('http')) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final name = _filenameForSharedFile(sf, path);
          final ext = extensionFromFilename(name) ?? '';
          if (!kChatAttachmentExtensions.contains(ext)) return false;
          await _uploadAttachmentBytes(
            creds,
            repo,
            rt,
            filename: name,
            filePath: path,
            caption: caption,
            replyTo: _replyingTo,
          );
          return true;
        }
      } catch (_) {}
    }

    try {
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) return false;
      final name = _filenameForSharedFile(sf, path);
      final ext = extensionFromFilename(name) ?? '';
      if (!kChatAttachmentExtensions.contains(ext)) return false;
      await _uploadAttachmentBytes(
        creds,
        repo,
        rt,
        filename: name,
        bytes: bytes,
        filePath: path.startsWith('http') ? null : path,
        caption: caption,
        replyTo: _replyingTo,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _uploadSharedFiles(
    List<SharedMediaFile> files,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    if (_uploading || _sending) return;
    final captionBefore =
        sanitizeOutgoingAttachmentCaption(_draft.text.trim());
    for (final sf in files) {
      if (await _uploadOneSharedFile(
        sf,
        creds,
        repo,
        rt,
        caption: captionBefore,
      )) {
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.chat.upload_failed)),
      );
    }
  }

  Future<void> _uploadAttachmentBytes(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt, {
    required String filename,
    List<int>? bytes,
    String? filePath,
    required String caption,
    ChatMessage? replyTo,
  }) async {
    final lower = (extensionFromFilename(filename) ?? '').toLowerCase();
    final isPdf = isChatPdfExtension(lower);
    final maxBytes = isPdf ? 50 * 1024 * 1024 : 10 * 1024 * 1024;
    var size = bytes?.length ?? 0;
    if (size == 0 && filePath != null && filePath.trim().isNotEmpty) {
      try {
        size = await File(filePath).length();
      } catch (_) {}
    }
    if (size > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.chat.file_too_large)),
        );
      }
      return;
    }

    final safeCaption = sanitizeOutgoingAttachmentCaption(caption);
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId,
      conversationId: widget.conversationId,
      userId: creds.chatUserId,
      content: safeCaption,
      type: isPdf ? 'file' : 'image',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      fileName: filename,
      fileSize: size > 0 ? size : null,
      pending: true,
      replyTo: replyTo != null && replyTo.id > 0
          ? ChatReplyRef(
              messageId: replyTo.id,
              preview: _replySnippet(replyTo),
              senderName: replyTo.user?.name?.trim().isNotEmpty == true
                  ? replyTo.user!.name!.trim()
                  : null,
            )
          : null,
    );

    setState(() {
      _uploading = true;
      _messages = [..._messages, optimistic];
      _draft.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToEnd(animated: true);
    });

    try {
      final sent = await repo.uploadMessageAttachment(
        creds,
        widget.conversationId,
        filename: filename,
        bytes: bytes,
        filePath: filePath,
        caption: safeCaption,
        socketId: () => rt.socketId,
      );
      if (!mounted) return;
      final guardText = safeCaption.isNotEmpty
          ? safeCaption
          : chatMessageDisplayCaption(sent, creds.apiBaseUrl);
      if (guardText.isNotEmpty) {
        unawaited(
          recordInlineReplyEchoGuard(
            conversationId: '${widget.conversationId}',
            messageText: guardText,
          ),
        );
      }
      setState(() {
        _messages = _messages.map((m) => m.id == tempId ? sent : m).toList();
        _phoneError = null;
        _replyingTo = null;
      });
      ref.invalidate(chatConversationsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (m) => m.id == tempId
                  ? m.copyWith(pending: false, failed: true)
                  : m,
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.chat.upload_failed)),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickAndUpload(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    final t = context.t;
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: kChatAttachmentExtensions.toList(),
        withData: false,
        dialogTitle: t.chat.pick_attachment,
      );
    } on MissingPluginException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.chat.file_picker_restart_hint)),
        );
      }
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    var ext = (f.extension ?? '').toLowerCase();
    if (ext.isEmpty && f.name.contains('.')) {
      ext = f.name.split('.').last.toLowerCase();
    }
    if (!kChatAttachmentExtensions.contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.chat.attachment_type_not_allowed)),
        );
      }
      return;
    }
    var bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      final path = f.path;
      if (path != null && path.isNotEmpty) {
        try {
          bytes = await XFile(path).readAsBytes();
        } catch (_) {
          try {
            bytes = await File(path).readAsBytes();
          } catch (_) {}
        }
      }
    }
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.chat.upload_failed)));
      }
      return;
    }
    await _uploadAttachmentBytes(
      creds,
      repo,
      rt,
      filename: f.name,
      bytes: bytes,
      filePath: f.path,
      caption: sanitizeOutgoingAttachmentCaption(_draft.text.trim()),
      replyTo: _replyingTo,
    );
  }

  Future<void> _fireTyping(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
    bool typing,
  ) async {
    try {
      await repo.sendTyping(
        creds,
        widget.conversationId,
        typing,
        socketId: () => rt.socketId,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = GoRouterState.of(context);
    final peerFromQuery = state.uri.queryParameters['peer']?.trim();
    final extraTitle = state.extra is String
        ? (state.extra! as String).trim()
        : null;
    final convList = ref.watch(chatConversationsProvider).valueOrNull;
    final conv = _findConversation(convList);
    final convTitle = conv?.title('').trim() ?? '';
    final title = (extraTitle != null && extraTitle.isNotEmpty)
        ? extraTitle
        : (peerFromQuery != null && peerFromQuery.isNotEmpty)
        ? peerFromQuery
        : (convTitle.isNotEmpty ? convTitle : t.chat.thread_fallback_title);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final credsAsync = ref.watch(chatBootstrapProvider);
    final letter = title.trim().isEmpty
        ? '?'
        : String.fromCharCode(title.trim().runes.first).toUpperCase();

    final threadUi = _threadSystemUi(context);
    final chatTheme = CinematicChatTheme.of(context);

    return credsAsync.when(
      loading: () => AnnotatedRegion<SystemUiOverlayStyle>(
        value: threadUi,
        child: Scaffold(
          backgroundColor: chatTheme.bg,
          body: Center(
            child: CircularProgressIndicator(color: chatTheme.amber),
          ),
        ),
      ),
      error: (e, _) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: threadUi,
        child: Scaffold(
          backgroundColor: chatTheme.bg,
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text(e.toString())),
        ),
      ),
      data: (creds) {
        final repo = ref.read(chatRepositoryProvider);
        final rt = ref.read(chatRealtimeServiceProvider);
        final convList = ref.watch(chatConversationsProvider).valueOrNull;
        final conv = _findConversation(convList);
        final partnerId = _partnerChatUserIdForPresence(creds.chatUserId, conv);

        return ValueListenableBuilder<Set<int>>(
          valueListenable: rt.onlineChatUserIds,
          builder: (context, onlineSet, _) {
            final online = partnerId != null && onlineSet.contains(partnerId);
            final typing = _typingName != null && _typingName!.isNotEmpty;
            final statusLine = typing
                ? ''
                : partnerId == null
                ? ''
                : online
                ? t.chat.online
                : t.chat.offline;

            final partnerPhotoPath =
                conv?.displayAvatar ??
                conv?.partnerAvatarFromParticipants(creds.chatUserId) ??
                _partnerAvatarFromMessages(creds.chatUserId);
            final partnerAvatarResolved = resolveChatMediaUrl(
              partnerPhotoPath,
              creds.apiBaseUrl,
            );

            final segments = _segmentsForMessages();
            final replyTo = _replyingTo;
            final replyBnTitle = replyTo != null
                ? _replyBannerTitle(replyTo, creds)
                : '';
            final replyBnSub = replyTo != null ? _replySnippet(replyTo) : '';
            final listCount = segments.length + (_typingName != null ? 1 : 0);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: threadUi,
              child: Scaffold(
                backgroundColor: chatTheme.bg,
                body: ColoredBox(
                  color: chatTheme.bg,
                  child: CinematicMeshBackground(
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              NotificationListener<ScrollNotification>(
                                onNotification: _onScroll,
                                child: CustomScrollView(
                                  clipBehavior: Clip.none,
                                  controller: _scroll,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  slivers: [
                                    SliverPersistentHeader(
                                      pinned: true,
                                      delegate: CinematicChatHeaderDelegate(
                                        headerTitle: title,
                                        statusLine: statusLine,
                                        typing: typing,
                                        partnerOnline: online,
                                        titleLetter: letter,
                                        onBack: _onThreadBack,
                                        topSafeInset: MediaQuery.paddingOf(
                                          context,
                                        ).top,
                                        partnerAvatarUrl: partnerAvatarResolved,
                                      ),
                                    ),
                                    if (_loading)
                                      SliverPadding(
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          4,
                                          0,
                                          _listBottomGap,
                                        ),
                                        sliver: SliverFillRemaining(
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: chatTheme.amber,
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (_error != null)
                                      SliverPadding(
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          4,
                                          0,
                                          _listBottomGap,
                                        ),
                                        sliver: SliverFillRemaining(
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _error!,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  FilledButton(
                                                    onPressed: _bootstrap,
                                                    child: Text(
                                                      t.dashboard.errors.retry,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else ...[
                                      if (_loadingOlderMessages)
                                        SliverToBoxAdapter(
                                          child: Semantics(
                                            label:
                                                t.chat.loading_older_messages,
                                            child:
                                                const LinearProgressIndicator(
                                              minHeight: 2,
                                            ),
                                          ),
                                        ),
                                      SliverPadding(
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          4,
                                          0,
                                          _listBottomGap,
                                        ),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            index,
                                          ) {
                                            if (index < segments.length) {
                                              final seg = segments[index];
                                              switch (seg) {
                                                case _ThreadDateSegment(
                                                  :final day,
                                                ):
                                                  return CinematicDatePill(
                                                    label: _dayLabel(day, t),
                                                  );
                                                case _ThreadMessageSegment(
                                                  :final messageIndex,
                                                ):
                                                  final m =
                                                      _messages[messageIndex];
                                                  final next =
                                                      messageIndex + 1 <
                                                          _messages.length
                                                      ? _messages[messageIndex +
                                                            1]
                                                      : null;
                                                  return RepaintBoundary(
                                                    child: _buildMessageBubble(
                                                      context,
                                                      m: m,
                                                      next: next,
                                                      creds: creds,
                                                      repo: repo,
                                                      rt: rt,
                                                      reduce: reduce,
                                                      peerAvatarUrl:
                                                          partnerAvatarResolved,
                                                    ),
                                                  );
                                              }
                                            }
                                            return const Padding(
                                              padding: EdgeInsets.only(
                                                left: 12,
                                                bottom: 12,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: CinematicTypingDots(),
                                              ),
                                            );
                                          }, childCount: listCount),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: _fabVisible,
                                builder: (context, show, _) {
                                  if (!show || _loading || _error != null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Positioned(
                                    right: 18,
                                    bottom: 18,
                                    child: FloatingActionButton.small(
                                      tooltip: t.chat.scroll_to_latest,
                                      backgroundColor: chatTheme.amber,
                                      foregroundColor: Colors.black,
                                      elevation: 8,
                                      onPressed: () =>
                                          _scrollToEnd(animated: true),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                          ),
                                          if (_offscreenPeerMessageCount > 0)
                                            Positioned(
                                              right: -6,
                                              top: -6,
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error,
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.error
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  formatChatUnreadBadgeLabel(
                                                    _offscreenPeerMessageCount,
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomRight,
                          children: [
                            CinematicComposerBar(
                              controller: _draft,
                              enabled:
                                  !_sending &&
                                  !_uploading &&
                                  !_loading &&
                                  _error == null &&
                                  !_sendSpamGuard.isCoolingDown,
                              reduceMotion: reduce,
                              spamCooldownRemaining:
                                  _sendSpamGuard.remainingCooldown,
                              spamCooldownTotal:
                                  _sendSpamGuard.activeCooldownTotal,
                              hint: _editingMessageId != null
                                  ? t.chat.edit_mode_hint
                                  : replyTo != null
                                  ? t.chat.composer_reply_hint
                                  : t.chat.composer_hint,
                              errorText: _phoneError,
                              editing: _editingMessageId != null,
                              editingTitle: t.chat.edit_mode_title,
                              editingPreview: _editingOriginalContent,
                              editingCancelLabel: t.chat.edit_mode_cancel,
                              onCancelEdit: _cancelEdit,
                              replying:
                                  _editingMessageId == null && replyTo != null,
                              replyBannerTitle: replyBnTitle,
                              replyBannerSubtitle: replyBnSub,
                              replyCancelTooltip: MaterialLocalizations.of(
                                context,
                              ).cancelButtonLabel,
                              onCancelReply: _cancelReply,
                              onAttach: _editingMessageId != null
                                  ? null
                                  : () => _pickAndUpload(creds, repo, rt),
                              onSendBurst: () => _burstKey.currentState?.play(),
                              onDraftChanged: (s) {
                                setState(() {
                                  _phoneError =
                                      chatTextLooksLikePhoneNumber(s.trim())
                                      ? t.chat.error_phone
                                      : null;
                                });
                                if (_editingMessageId != null) return;
                                _typingQuietTimer?.cancel();
                                if (s.trim().isEmpty) {
                                  unawaited(
                                    _fireTyping(creds, repo, rt, false),
                                  );
                                  return;
                                }
                                unawaited(_fireTyping(creds, repo, rt, true));
                                _typingQuietTimer = Timer(
                                  const Duration(milliseconds: 1200),
                                  () {
                                    unawaited(
                                      _fireTyping(creds, repo, rt, false),
                                    );
                                  },
                                );
                              },
                              onSend: () => _onSend(creds, repo, rt),
                              autoFocusOnMount: widget.autoFocusComposer,
                            ),
                            Positioned(
                              right: 24,
                              bottom: 88,
                              child: CinematicSendBurst(key: _burstKey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required ChatMessage m,
    required ChatMessage? next,
    required ChatCredentials creds,
    required ChatRepository repo,
    required ChatRealtimeService rt,
    required bool reduce,
    required String peerAvatarUrl,
  }) {
    final t = context.t;
    final showGroupFooter = next == null || next.userId != m.userId;
    final isMine = m.userId == creds.chatUserId;
    final createdUtc = DateTime.tryParse(m.createdAt);
    final isReadByPeer =
        isMine &&
        !m.pending &&
        !m.failed &&
        _peerReadAt != null &&
        createdUtc != null &&
        !createdUtc.isAfter(_peerReadAt!);
    return CinematicMessageBubble(
      key: ValueKey('msg-${m.id}'),
      message: m,
      isMine: isMine,
      reduceMotion: reduce,
      apiBaseUrl: creds.apiBaseUrl,
      // Time for own bubbles is already inside the bubble; avoid duplicate + stray band.
      showTimestampFooter: !isMine && showGroupFooter,
      peerAvatarUrl: peerAvatarUrl,
      attachmentLabel: t.chat.attachment,
      openPdfLabel: t.chat.open_file,
      isReadByPeer: isReadByPeer,
      selected: _selectedMessageId == m.id,
      onSelect: () => setState(() => _selectedMessageId = m.id),
      onDismissSelection: () {
        if (_selectedMessageId == m.id) {
          setState(() => _selectedMessageId = null);
        }
      },
      onEditRequest: () => _onEditMessage(m, creds.chatUserId),
      onDeleteRequest: () => _onDeleteMessage(m, creds, repo, rt),
      onReplyRequest: () => _beginReply(m),
      onCopyRequest: () => _onCopyMessage(m),
      onForwardRequest: () => _onForwardMessage(m, creds, repo, rt),
      chatImageRequestHeaders: () {
        final media = resolveChatMessageMedia(m, creds.apiBaseUrl);
        if (!media.isImage || media.url.isEmpty) return null;
        return {
          'Authorization': 'Bearer ${creds.token.trim()}',
          'X-Application-ID': creds.appId.trim(),
        };
      }(),
    );
  }
}
