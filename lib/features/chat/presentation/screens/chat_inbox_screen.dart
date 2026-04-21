import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_realtime_service.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_directory_user.dart';
import '../providers/chat_providers.dart';
import '../theme/liquid_neural_palette.dart';
import '../widgets/chat_user_search_bar.dart';
import '../widgets/liquid_neural_mesh_backdrop.dart';
import '../widgets/liquid_neural_organic_shapes.dart';
import '../widgets/liquid_neural_plasma_avatar.dart';
import '../widgets/liquid_neural_unread_badge.dart';
import '../widgets/signal_typing_indicator.dart';

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  StreamSubscription<ChatRealtimeEvent>? _rtSub;
  final Map<int, String> _typingUserByConv = {};
  final Map<int, Timer> _typingClearTimers = {};
  final Map<int, int> _pulseTokenByConv = {};
  final ScrollController _scroll = ScrollController();
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScrollThrottled);
  }

  void _onScrollThrottled() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 12), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scroll.removeListener(_onScrollThrottled);
    _scroll.dispose();
    for (final t in _typingClearTimers.values) {
      t.cancel();
    }
    _typingClearTimers.clear();
    _rtSub?.cancel();
    super.dispose();
  }

  void _scheduleTypingClear(int conversationId) {
    _typingClearTimers[conversationId]?.cancel();
    _typingClearTimers[conversationId] = Timer(const Duration(seconds: 4), () {
      _typingClearTimers.remove(conversationId);
      if (!mounted) return;
      if (_typingUserByConv.remove(conversationId) != null) {
        setState(() {});
      }
    });
  }

  void _bindRtListener() {
    _rtSub ??= ref.read(chatRealtimeServiceProvider).events.listen((event) {
      if (!mounted) return;
      if (event is ChatInboxRefreshEvent) {
        ref.invalidate(chatConversationsProvider);
        unawaited(_resyncConversationChannels());
        return;
      }
      if (event is ChatMessageSentEvent) {
        setState(() {
          _pulseTokenByConv[event.conversationId] = (_pulseTokenByConv[event.conversationId] ?? 0) + 1;
        });
        return;
      }
      if (event is ChatTypingEvent) {
        final id = event.conversationId;
        if (!event.isTyping) {
          _typingClearTimers.remove(id)?.cancel();
          if (_typingUserByConv.remove(id) != null) {
            setState(() {});
          }
          return;
        }
        final name = event.userName.trim();
        setState(() {
          _typingUserByConv[id] = name;
        });
        _scheduleTypingClear(id);
      }
    });
  }

  Future<void> _resyncConversationChannels() async {
    try {
      final list = await ref.read(chatConversationsProvider.future);
      final creds = await ref.read(chatBootstrapProvider.future);
      await ref.read(chatRealtimeServiceProvider).updateConversationSubscriptions(
            creds,
            list.map((e) => e.id).toList(),
          );
    } catch (_) {}
  }

  Future<void> _openChatWithUser(ChatCredentials creds, ChatDirectoryUser user) async {
    final t = context.t;
    final repo = ref.read(chatRepositoryProvider);
    final rt = ref.read(chatRealtimeServiceProvider);
    final candidates = <int>[
      user.id,
      if (user.externalUserId != null && user.externalUserId != user.id) user.externalUserId!,
    ];
    ChatConversation? conv;
    for (final pid in candidates) {
      try {
        conv = await repo.createDirectConversation(
          creds,
          participantId: pid,
          socketId: () => rt.socketId,
        );
        break;
      } catch (_) {}
    }
    if (conv == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.chat.conversation_open_failed)),
        );
      }
      return;
    }
    ref.invalidate(chatConversationsProvider);
    ref.invalidate(chatRealtimeBindingProvider);
    await _resyncConversationChannels();
    if (!mounted) return;
    context.push('/chat/thread/${conv.id}', extra: conv.title(t.chat.conversation_unknown));
  }

  double _gravityScale(int index, double listViewportHeight) {
    const itemH = 96.0;
    if (!_scroll.hasClients || listViewportHeight <= 0) return 1.0;
    final anchor = _scroll.offset + listViewportHeight * 0.48;
    final itemCenter = index * itemH + itemH * 0.5;
    final dist = (itemCenter - anchor).abs();
    return (1.03 - (dist / 260).clamp(0.0, 1.0) * 0.06).clamp(0.97, 1.03);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.watch(chatRealtimeBindingProvider);
    ref.watch(chatBootstrapProvider);
    _bindRtListener();

    final reduce = MediaQuery.disableAnimationsOf(context);
    final ln = LiquidNeuralTheme.of(context);
    final async = ref.watch(chatConversationsProvider);
    final myChatUserId = ref.watch(chatBootstrapProvider).value?.chatUserId;
    final rt = ref.watch(chatRealtimeServiceProvider);

    return Scaffold(
      backgroundColor: ln.canvas,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ln.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.chat.inbox_title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: ln.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            if (!reduce)
              Text(
                t.chat.inbox_subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ln.textSecondary,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            if (reduce)
              Text(
                t.chat.inbox_subtitle,
                style: AppTextStyles.caption(context).copyWith(color: ln.textSecondary),
              ),
          ],
        ),
      ),
      body: LiquidNeuralMeshBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: ref.watch(chatBootstrapProvider).when(
                      data: (creds) => ChatUserSearchBar(
                        creds: creds,
                        useLiquidNeuralStyle: true,
                        hiddenParticipantIds: _existingPartnerChatUserIds(
                          ref.watch(chatConversationsProvider).valueOrNull ?? const [],
                          creds.chatUserId,
                        ),
                        onUserSelected: (u) => _openChatWithUser(creds, u),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
              ),
              Expanded(
                child: async.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: ln.plasma),
                  ),
                  error: (e, _) => _ChatError(
                    message: t.chat.error_load_threads,
                    onRetry: () {
                      ref.invalidate(chatBootstrapProvider);
                      ref.invalidate(chatConversationsProvider);
                      ref.invalidate(chatRealtimeBindingProvider);
                    },
                  ),
                  data: (list) {
                    final creds = ref.watch(chatBootstrapProvider).valueOrNull;
                    if (list.isEmpty) {
                      return _ChatEmpty(message: t.chat.empty_threads_title, hint: t.chat.empty_threads_hint);
                    }
                    return ListenableBuilder(
                      listenable: rt.onlineChatUserIds,
                      builder: (context, _) {
                        final onlineIds = rt.onlineChatUserIds.value;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final vh = constraints.maxHeight;
                            return RefreshIndicator(
                              color: ln.plasma,
                              onRefresh: () async {
                                ref.invalidate(chatConversationsProvider);
                                await ref.read(chatConversationsProvider.future);
                                await _resyncConversationChannels();
                              },
                              child: ListView.builder(
                                controller: _scroll,
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final c = list[index];
                                  final title = c.title(t.chat.conversation_unknown);
                                  final last = _inboxLastPreview(c, t);
                                  final typingName = _typingUserByConv[c.id];
                                  final isTyping = typingName != null;
                                  final time = _sidebarTime(context, c.updatedAt ?? c.lastMessage?.createdAt);
                                  final unread = c.unreadCount > 0;
                                  final partnerId =
                                      myChatUserId == null ? null : c.partnerChatUserId(myChatUserId);
                                  final partnerOnline =
                                      partnerId != null && onlineIds.contains(partnerId);
                                  final letter = _firstLetter(title);
                                  final pulseTok = _pulseTokenByConv[c.id] ?? 0;
                                  final scale = reduce ? 1.0 : _gravityScale(index, vh);
                                  final rowAvatarPath = c.displayAvatar ??
                                      (myChatUserId != null ? c.partnerAvatarFromParticipants(myChatUserId) : null);
                                  final rowAvatarUrl = creds == null
                                      ? ''
                                      : resolveChatMediaUrl(rowAvatarPath, creds.apiBaseUrl);

                                  Widget inner = Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: LiquidNeuralPulseLayer(
                                      pulseToken: pulseTok,
                                      child: ClipPath(
                                        clipper: LiquidNeuralBlobClipper(seed: c.id),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                          child: Material(
                                            color: ln.textPrimary.withValues(alpha: 0.04),
                                            child: InkWell(
                                              splashColor: ln.plasma.withValues(alpha: 0.18),
                                              highlightColor: ln.textPrimary.withValues(alpha: 0.04),
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                context.push('/chat/thread/${c.id}', extra: title);
                                              },
                                              child: Ink(
                                                decoration: BoxDecoration(
                                                  gradient: ln.cardSheen,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                                                  child: Row(
                                                    children: [
                                                      LiquidNeuralPlasmaAvatar(
                                                        letter: letter,
                                                        unread: unread,
                                                        online: partnerOnline,
                                                        imageUrl: rowAvatarUrl,
                                                      ),
                                                      const SizedBox(width: 14),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    title,
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: GoogleFonts.spaceGrotesk(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w700,
                                                                      color: ln.textPrimary,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  time,
                                                                  style: GoogleFonts.spaceGrotesk(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: ln.textSecondary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 6),
                                                            isTyping
                                                                ? Row(
                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                    children: [
                                                                      const SignalTypingIndicator(
                                                                        useLiquidPalette: true,
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Expanded(
                                                                        child: Text(
                                                                          typingName.isNotEmpty
                                                                              ? '$typingName · ${t.chat.typing_status}'
                                                                              : t.chat.typing_status,
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: GoogleFonts.spaceGrotesk(
                                                                            fontSize: 13,
                                                                            fontWeight: FontWeight.w600,
                                                                            color: ln.plasma,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Text(
                                                                    last,
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: GoogleFonts.spaceGrotesk(
                                                                      fontSize: 13,
                                                                      fontWeight: FontWeight.w500,
                                                                      color: ln.textSecondary,
                                                                      height: 1.35,
                                                                    ),
                                                                  ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (unread) ...[
                                                        const SizedBox(width: 8),
                                                        LiquidNeuralUnreadBadge(count: c.unreadCount),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  inner = Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.center,
                                    child: inner,
                                  );

                                  if (!reduce) {
                                    inner = inner
                                        .animate(delay: (index * 80).ms)
                                        .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
                                        .slideX(begin: 0.14, duration: 420.ms, curve: Curves.easeOutCubic);
                                  }

                                  return Dismissible(
                                    key: ValueKey('conv_${c.id}'),
                                    confirmDismiss: (dir) async {
                                      if (dir == DismissDirection.endToStart ||
                                          dir == DismissDirection.startToEnd) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(t.chat.inbox_swipe_soon)),
                                          );
                                        }
                                      }
                                      return false;
                                    },
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 22),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(26),
                                        gradient: LinearGradient(
                                          colors: [
                                            ln.amberGlow.withValues(alpha: 0.35),
                                            ln.plasma.withValues(alpha: 0.12),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(Icons.push_pin_rounded, color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 22),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(26),
                                        color: AppColors.error.withValues(alpha: 0.45),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                    ),
                                    child: inner,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _inboxLastPreview(ChatConversation c, Translations t) {
    final m = c.lastMessage;
    if (m == null) return '—';
    switch (m.type) {
      case 'image':
        final cap = m.content.trim();
        return cap.isNotEmpty ? cap : t.chat.attachment_image;
      case 'file':
        final name = m.fileName?.trim();
        if (name != null && name.isNotEmpty) return name;
        final cap = m.content.trim();
        return cap.isNotEmpty ? cap : t.chat.attachment_pdf;
      default:
        final s = m.content.trim();
        return s.isEmpty ? '—' : s;
    }
  }

  String _sidebarTime(BuildContext context, String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final sameDay =
          d.year == now.year && d.month == now.month && d.day == now.day;
      if (sameDay) {
        return DateFormat.Hm().format(d);
      }
      return DateFormat.MMMd().format(d);
    } catch (_) {
      return '';
    }
  }
}

Set<int> _existingPartnerChatUserIds(List<ChatConversation> list, int me) {
  final out = <int>{};
  for (final c in list) {
    for (final p in c.participants ?? const <ChatParticipant>[]) {
      final uid = p.userId;
      if (uid != 0 && uid != me) out.add(uid);
      final nested = p.user?.id;
      if (nested != null && nested != 0 && nested != me) out.add(nested);
    }
  }
  return out;
}

String _firstLetter(String title) {
  final it = title.trim().runes.iterator;
  if (!it.moveNext()) return '?';
  return String.fromCharCode(it.current).toUpperCase();
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty({required this.message, required this.hint});

  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final ln = LiquidNeuralTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 52, color: ln.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ln.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ln.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ln = LiquidNeuralTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                color: ln.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ln.plasma,
                foregroundColor: Colors.black,
              ),
              child: Text(context.t.dashboard.errors.retry),
            ),
          ],
        ),
      ),
    );
  }
}
