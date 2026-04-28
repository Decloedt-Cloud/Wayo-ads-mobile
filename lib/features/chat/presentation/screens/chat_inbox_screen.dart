import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_realtime_service.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_directory_user.dart';
import '../providers/chat_providers.dart';
import '../theme/liquid_neural_palette.dart';
import '../theme/premium_chat_tokens.dart';
import '../widgets/chat_user_search_bar.dart';
import '../widgets/liquid_neural_mesh_backdrop.dart';
import '../widgets/liquid_neural_organic_shapes.dart';
import '../widgets/premium_conversation_card.dart';
import '../widgets/premium_inbox_header.dart';

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
          _pulseTokenByConv[event.conversationId] =
              (_pulseTokenByConv[event.conversationId] ?? 0) + 1;
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
      await ref
          .read(chatRealtimeServiceProvider)
          .updateConversationSubscriptions(
            creds,
            list.map((e) => e.id).toList(),
          );
    } catch (_) {}
  }

  Future<void> _openChatWithUser(
    ChatCredentials creds,
    ChatDirectoryUser user,
  ) async {
    final t = context.t;
    final repo = ref.read(chatRepositoryProvider);
    final rt = ref.read(chatRealtimeServiceProvider);
    final candidates = <int>[
      user.id,
      if (user.externalUserId != null && user.externalUserId != user.id)
        user.externalUserId!,
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
    context.push(
      '/chat/thread/${conv.id}',
      extra: conv.title(t.chat.conversation_unknown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.watch(chatRealtimeBindingProvider);
    ref.watch(chatBootstrapProvider);
    _bindRtListener();

    final reduce = MediaQuery.disableAnimationsOf(context);
    final ln = LiquidNeuralTheme.of(context);
    final p = PremiumChatTokens.of(context);
    final async = ref.watch(chatConversationsProvider);
    final myChatUserId = ref.watch(chatBootstrapProvider).value?.chatUserId;
    final rt = ref.watch(chatRealtimeServiceProvider);

    return Scaffold(
      backgroundColor: p.surfaceBase,
      body: LiquidNeuralMeshBackdrop(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Warm ambient orbs for a luxurious depth layer ───
            Positioned(
              top: -120,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        p.ambientOrbWarm,
                        p.ambientOrbWarm.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -80,
              child: IgnorePointer(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        p.accentWarm.withValues(alpha: p.isDark ? 0.18 : 0.1),
                        p.accentWarm.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PremiumInboxHeader(
                    title: t.chat.inbox_title,
                    subtitle: t.chat.inbox_subtitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ref
                        .watch(chatBootstrapProvider)
                        .when(
                          data: (creds) => ChatUserSearchBar(
                            creds: creds,
                            useLiquidNeuralStyle: true,
                            hiddenParticipantIds: _existingPartnerChatUserIds(
                              ref
                                      .watch(chatConversationsProvider)
                                      .valueOrNull ??
                                  const [],
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
                        final creds = ref
                            .watch(chatBootstrapProvider)
                            .valueOrNull;
                        if (list.isEmpty) {
                          return _ChatEmpty(
                            message: t.chat.empty_threads_title,
                            hint: t.chat.empty_threads_hint,
                          );
                        }
                        return ListenableBuilder(
                          listenable: rt.onlineChatUserIds,
                          builder: (context, _) {
                            final onlineIds = rt.onlineChatUserIds.value;
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return RefreshIndicator(
                                  color: ln.plasma,
                                  onRefresh: () async {
                                    // Also refresh bootstrap to get fresh chat token if stale.
                                    ref.invalidate(chatBootstrapProvider);
                                    ref.invalidate(chatConversationsProvider);
                                    await ref.read(
                                      chatConversationsProvider.future,
                                    );
                                    await _resyncConversationChannels();
                                  },
                                  child: ListView.builder(
                                    controller: _scroll,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      4,
                                      12,
                                      28,
                                    ),
                                    itemCount: list.length,
                                    itemBuilder: (context, index) {
                                      final c = list[index];
                                      final title = c.title(
                                        t.chat.conversation_unknown,
                                      );
                                      final last = _inboxLastPreview(c, t);
                                      final typingName =
                                          _typingUserByConv[c.id];
                                      final isTyping = typingName != null;
                                      final time = _sidebarTime(
                                        context,
                                        c.updatedAt ?? c.lastMessage?.createdAt,
                                      );
                                      final partnerId = myChatUserId == null
                                          ? null
                                          : c.partnerChatUserId(myChatUserId);
                                      final partnerOnline =
                                          partnerId != null &&
                                          onlineIds.contains(partnerId);
                                      final letter = _firstLetter(title);
                                      final pulseTok =
                                          _pulseTokenByConv[c.id] ?? 0;
                                      final rowAvatarPath =
                                          c.displayAvatar ??
                                          (myChatUserId != null
                                              ? c.partnerAvatarFromParticipants(
                                                  myChatUserId,
                                                )
                                              : null);
                                      final rowAvatarUrl = creds == null
                                          ? ''
                                          : resolveChatMediaUrl(
                                              rowAvatarPath,
                                              creds.apiBaseUrl,
                                            );

                                      Widget inner = LiquidNeuralPulseLayer(
                                        pulseToken: pulseTok,
                                        child: PremiumConversationCard(
                                          title: title,
                                          preview: last,
                                          time: time,
                                          initial: letter,
                                          avatarUrl: rowAvatarUrl,
                                          unreadCount: c.unreadCount,
                                          online: partnerOnline,
                                          typing: isTyping,
                                          typingName: typingName,
                                          onTap: () {
                                            context.push(
                                              '/chat/thread/${c.id}',
                                              extra: title,
                                            );
                                          },
                                        ),
                                      );

                                      if (!reduce) {
                                        inner = inner
                                            .animate(delay: (index * 80).ms)
                                            .fadeIn(
                                              duration: 380.ms,
                                              curve: Curves.easeOutCubic,
                                            )
                                            .slideX(
                                              begin: 0.14,
                                              duration: 420.ms,
                                              curve: Curves.easeOutCubic,
                                            );
                                      }

                                      return Dismissible(
                                        key: ValueKey('conv_${c.id}'),
                                        confirmDismiss: (dir) async {
                                          if (dir ==
                                                  DismissDirection.endToStart ||
                                              dir ==
                                                  DismissDirection.startToEnd) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    t.chat.inbox_swipe_soon,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          return false;
                                        },
                                        background: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(
                                            left: 26,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              p.radiusXL,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                p.accentWarm.withValues(
                                                  alpha: 0.9,
                                                ),
                                                p.accentWarm.withValues(
                                                  alpha: 0.35,
                                                ),
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.push_pin_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                        secondaryBackground: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                            right: 26,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              p.radiusXL,
                                            ),
                                            color: AppColors.error.withValues(
                                              alpha: 0.55,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                          ),
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
          ],
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
    return PremiumStateCard(
      icon: Icons.forum_rounded,
      title: message,
      message: hint,
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = PremiumChatTokens.of(context);
    return PremiumStateCard(
      icon: Icons.error_outline_rounded,
      title: context.t.dashboard.errors.retry,
      message: message,
      action: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(p.radiusLG),
          gradient: p.accentGradient,
          boxShadow: p.warmGlow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(p.radiusLG),
          child: InkWell(
            borderRadius: BorderRadius.circular(p.radiusLG),
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Text(
                context.t.dashboard.errors.retry,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
