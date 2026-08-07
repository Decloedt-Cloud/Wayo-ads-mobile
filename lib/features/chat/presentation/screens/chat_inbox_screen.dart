import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_share_intent.dart';
import '../../data/chat_realtime_service.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_directory_user.dart';
import '../formatting/chat_partner_role.dart';
import '../providers/chat_pending_share_provider.dart';
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

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen>
    with WidgetsBindingObserver {
  StreamSubscription<ChatRealtimeEvent>? _rtSub;
  final Map<int, String> _typingUserByConv = {};
  final Map<int, Timer> _typingClearTimers = {};
  final Map<int, int> _pulseTokenByConv = {};
  final ScrollController _scroll = ScrollController();

  /// Coalesce bursts of [ChatInboxRefreshEvent] from realtime (avoids hammering
  /// `/conversations` when many channels signal at once).
  Timer? _inboxRefreshDebounce;
  static const Duration _inboxRefreshDebounceDelay = Duration(
    milliseconds: 550,
  );

  /// Entry stagger uses flutter_animate — cap indices so long lists don't schedule
  /// hundreds of overlapping animations during scroll/recycle.
  static const int _maxStaggeredInboxIndices = 22;

  int _inboxAutoRetryCount = 0;
  Timer? _inboxAutoRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatShareIntent.bind((files) {
      ref.read(chatPendingShareProvider.notifier).state = files;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxAutoRetryTimer?.cancel();
    _inboxRefreshDebounce?.cancel();
    _scroll.dispose();
    for (final t in _typingClearTimers.values) {
      t.cancel();
    }
    _typingClearTimers.clear();
    _rtSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resyncAfterForeground());
    }
  }

  Future<void> _resyncAfterForeground() async {
    if (!mounted) return;
    ref.invalidate(chatConversationsProvider);
    await forceReconnectChatRealtime(ref);
    if (!mounted) return;
    await _resyncConversationChannels();
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
        _inboxRefreshDebounce?.cancel();
        _inboxRefreshDebounce = Timer(_inboxRefreshDebounceDelay, () {
          if (!mounted) return;
          ref.invalidate(chatConversationsProvider);
          unawaited(_resyncConversationChannels());
        });
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
    List<ChatConversation> conversations,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final t = context.t;
    final me = creds.chatUserId;
    for (final c in conversations) {
      if (c.partnerChatUserId(me) == user.id) {
        if (!mounted) return;
        context.push(
          '/chat/thread/${c.id}',
          extra: c.title(t.chat.conversation_unknown),
        );
        return;
      }
    }

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
        WayoToast.error(context, t.chat.conversation_open_failed);
      }
      return;
    }
    ref.invalidate(chatConversationsProvider);
    invalidateChatRealtimeBindingImmediate(
      () => ref.invalidate(chatRealtimeBindingProvider),
    );
    await _resyncConversationChannels();
    if (!mounted) return;
    context.push(
      '/chat/thread/${conv.id}',
      extra: conv.title(t.chat.conversation_unknown),
    );
  }

  void _scheduleInboxAutoRetry() {
    if (_inboxAutoRetryCount >= 3) return;
    _inboxAutoRetryTimer?.cancel();
    _inboxAutoRetryCount++;
    _inboxAutoRetryTimer = Timer(
      Duration(milliseconds: 900 + _inboxAutoRetryCount * 700),
      () {
        if (!mounted) return;
        ref.invalidate(chatBootstrapProvider);
        ref.invalidate(chatConversationsProvider);
        scheduleInvalidateChatRealtimeBinding(
          () => ref.invalidate(chatRealtimeBindingProvider),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.watch(chatRealtimeBindingProvider);
    ref.watch(chatBootstrapProvider);
    _bindRtListener();

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      final wasAuthed = prev?.valueOrNull is AuthAuthenticated;
      final isAuthed = next.valueOrNull is AuthAuthenticated;
      if (!wasAuthed && isAuthed) {
        _inboxAutoRetryCount = 0;
        ref.invalidate(chatBootstrapProvider);
        ref.invalidate(chatConversationsProvider);
      }
    });

    ref.listen(chatConversationsProvider, (prev, next) {
      if (next.hasError && (prev == null || !prev.hasError)) {
        _scheduleInboxAutoRetry();
      } else if (next.hasValue) {
        _inboxAutoRetryCount = 0;
      }
    });

    final reduce = MediaQuery.disableAnimationsOf(context);
    final ln = LiquidNeuralTheme.of(context);
    final p = PremiumChatTokens.of(context);
    final async = ref.watch(chatConversationsProvider);
    final readOverrides = ref.watch(chatReadConversationOverridesProvider);
    // Use valueOrNull to avoid throwing on error state (e.g. 404 from backend)
    final myChatUserId = ref
        .watch(chatBootstrapProvider)
        .valueOrNull
        ?.chatUserId;
    final rt = ref.watch(chatRealtimeServiceProvider);
    final role = ref.watch(currentWayoAdsAccountRoleProvider);

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
            // Shell already reserves space for the floating bottom nav — avoid
            // doubling [MediaQuery.padding.bottom] here (creates a dead zone and
            // clips the last conversation cards above the nav bar).
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PremiumInboxHeader(
                    title: t.chat.inbox_title,
                    subtitle: t.chat.inbox_subtitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _InboxFilterBar(
                      showArchived: ref.watch(chatInboxShowArchivedProvider),
                      onChanged: (archived) {
                        ref.read(chatInboxShowArchivedProvider.notifier).state =
                            archived;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ref
                        .watch(chatBootstrapProvider)
                        .when(
                          data: (creds) {
                            final convListSnapshot =
                                async.valueOrNull ?? const [];
                            final priorOnly =
                                role == WayoAdsAccountRole.creator;
                            final hiddenIds = priorOnly
                                ? const <int>{}
                                : _existingPartnerChatUserIds(
                                    convListSnapshot,
                                    creds.chatUserId,
                                  );
                            return ChatUserSearchBar(
                              creds: creds,
                              useLiquidNeuralStyle: true,
                              priorContactsOnly: priorOnly,
                              priorConversationList: convListSnapshot,
                              hiddenParticipantIds: hiddenIds,
                              onUserSelected: (u) =>
                                  _openChatWithUser(creds, u, convListSnapshot),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (error, stackTrace) => const SizedBox.shrink(),
                        ),
                  ),
                  Expanded(
                    child: async.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(color: ln.plasma),
                      ),
                      error: (e, _) => _inboxAutoRetryCount < 3
                          ? Center(
                              child: CircularProgressIndicator(color: ln.plasma),
                            )
                          : _ChatError(
                              message: t.chat.error_load_threads,
                              onRetry: () {
                                _inboxAutoRetryCount = 0;
                                ref.invalidate(chatBootstrapProvider);
                                ref.invalidate(chatConversationsProvider);
                                scheduleInvalidateChatRealtimeBinding(
                                  () => ref.invalidate(
                                    chatRealtimeBindingProvider,
                                  ),
                                );
                              },
                            ),
                      data: (list) {
                        final creds = ref
                            .watch(chatBootstrapProvider)
                            .valueOrNull;
                        if (list.isEmpty) {
                          final archived =
                              ref.watch(chatInboxShowArchivedProvider);
                          return _ChatEmpty(
                            message: archived
                                ? t.chat.empty_archived_title
                                : t.chat.empty_threads_title,
                            hint: archived
                                ? t.chat.empty_archived_hint
                                : t.chat.empty_threads_hint,
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
                                    // Slightly wider prefetch than default — smoother flick scroll on tall lists.
                                    cacheExtent: 360,
                                    addAutomaticKeepAlives: false,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      4,
                                      12,
                                      80,
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
                                          : resolveChatAvatarUrl(
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
                                          unreadCount: chatEffectiveUnreadCount(
                                            c,
                                            readOverrides,
                                          ),
                                          online: partnerOnline,
                                          pinned: c.isPinned,
                                          isArchived: c.isArchived,
                                          typing: isTyping,
                                          typingName: typingName,
                                          partnerRole: resolveChatPartnerRole(
                                            myRole: role,
                                            partnerAppRoles: myChatUserId == null
                                                ? null
                                                : c.partnerAppRoles(
                                                    myChatUserId,
                                                  ),
                                          ),
                                          onTap: () {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                            context.push(
                                              '/chat/thread/${c.id}',
                                              extra: title,
                                            );
                                          },
                                          onPin: () => _togglePin(
                                            context,
                                            conversation: c,
                                          ),
                                          onArchive: () => _toggleArchive(
                                            context,
                                            conversation: c,
                                          ),
                                          onDelete: () => _deleteConversation(
                                            context,
                                            conversation: c,
                                          ),
                                        ),
                                      );

                                      final allowEntryMotion =
                                          !reduce &&
                                          index < _maxStaggeredInboxIndices;
                                      if (allowEntryMotion) {
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

                                      return RepaintBoundary(
                                        child: Dismissible(
                                          key: ValueKey(
                                            'conv_${c.id}_${c.isPinned}_${c.isArchived}',
                                          ),
                                          confirmDismiss: (dir) =>
                                              _onInboxSwipe(
                                            context,
                                            conversation: c,
                                            direction: dir,
                                          ),
                                          background: Container(
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.only(
                                              left: 26,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
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
                                            child: Icon(
                                              c.isArchived
                                                  ? Icons.unarchive_rounded
                                                  : (c.isPinned
                                                      ? Icons
                                                          .push_pin_outlined
                                                      : Icons
                                                          .push_pin_rounded),
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
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    p.radiusXL,
                                                  ),
                                              color: (c.isArchived
                                                      ? p.accentWarm
                                                      : AppColors.error)
                                                  .withValues(alpha: 0.55),
                                            ),
                                            child: Icon(
                                              c.isArchived
                                                  ? Icons.unarchive_rounded
                                                  : Icons.archive_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                          child: inner,
                                        ),
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

  Future<bool> _onInboxSwipe(
    BuildContext context, {
    required ChatConversation conversation,
    required DismissDirection direction,
  }) async {
    final showArchived = ref.read(chatInboxShowArchivedProvider);

    if (showArchived || conversation.isArchived) {
      await _toggleArchive(context, conversation: conversation);
      return true;
    }

    if (direction == DismissDirection.startToEnd) {
      await _togglePin(context, conversation: conversation);
      return false;
    }

    if (direction == DismissDirection.endToStart) {
      await _toggleArchive(context, conversation: conversation);
      return true;
    }
    return false;
  }

  Future<void> _togglePin(
    BuildContext context, {
    required ChatConversation conversation,
  }) async {
    final t = context.t;
    final creds = ref.read(chatBootstrapProvider).valueOrNull;
    if (creds == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final rt = ref.read(chatRealtimeServiceProvider);

    try {
      if (conversation.isPinned) {
        await repo.unpinConversation(
          creds,
          conversation.id,
          socketId: () => rt.socketId,
        );
        if (context.mounted) {
          WayoToast.info(context, t.chat.inbox_unpinned);
        }
      } else {
        await repo.pinConversation(
          creds,
          conversation.id,
          socketId: () => rt.socketId,
        );
        if (context.mounted) {
          WayoToast.info(context, t.chat.inbox_pinned);
        }
      }
      ref.invalidate(chatConversationsProvider);
    } catch (e) {
      if (!context.mounted) return;
      final msg = '$e';
      if (msg.contains('disabled') || msg.contains('501')) {
        WayoToast.error(context, t.chat.inbox_pin_disabled);
      } else {
        WayoToast.error(context, t.chat.inbox_pin_failed);
      }
    }
  }

  Future<void> _toggleArchive(
    BuildContext context, {
    required ChatConversation conversation,
  }) async {
    final t = context.t;
    final creds = ref.read(chatBootstrapProvider).valueOrNull;
    if (creds == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final rt = ref.read(chatRealtimeServiceProvider);
    final showArchived = ref.read(chatInboxShowArchivedProvider);

    try {
      if (showArchived || conversation.isArchived) {
        await repo.unarchiveConversation(
          creds,
          conversation.id,
          socketId: () => rt.socketId,
        );
        if (context.mounted) {
          WayoToast.info(context, t.chat.inbox_unarchived);
        }
      } else {
        await repo.archiveConversation(
          creds,
          conversation.id,
          socketId: () => rt.socketId,
        );
        if (context.mounted) {
          WayoToast.info(context, t.chat.inbox_archived);
        }
      }
      ref.invalidate(chatConversationsProvider);
    } catch (e) {
      if (!context.mounted) return;
      WayoToast.error(context, t.chat.inbox_archive_failed);
    }
  }

  Future<void> _deleteConversation(
    BuildContext context, {
    required ChatConversation conversation,
  }) async {
    final t = context.t;
    final confirmed = await showWayoConfirmDialog(
      context: context,
      title: t.chat.delete_conversation_confirm_title,
      message: t.chat.delete_conversation_confirm_text,
      cancelLabel: t.chat.delete_confirm_cancel,
      confirmLabel: t.chat.delete_conversation_confirm_cta,
      tone: WayoDialogTone.destructive,
    );
    if (!confirmed || !context.mounted) return;

    final creds = ref.read(chatBootstrapProvider).valueOrNull;
    if (creds == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final rt = ref.read(chatRealtimeServiceProvider);
    try {
      await repo.deleteConversation(
        creds,
        conversation.id,
        socketId: () => rt.socketId,
      );
      invalidateChatRealtimeBindingImmediate(
        () => ref.invalidate(chatRealtimeBindingProvider),
      );
      ref.invalidate(chatConversationsProvider);
      if (context.mounted) {
        WayoToast.info(context, t.chat.delete_conversation_done);
      }
    } catch (_) {
      if (!context.mounted) return;
      WayoToast.error(context, t.chat.delete_conversation_failed);
    }
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

class _InboxFilterBar extends StatelessWidget {
  const _InboxFilterBar({
    required this.showArchived,
    required this.onChanged,
  });

  final bool showArchived;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          label: Text(t.chat.inbox_filter_active),
          icon: const Icon(Icons.inbox_rounded, size: 18),
        ),
        ButtonSegment(
          value: true,
          label: Text(t.chat.inbox_filter_archived),
          icon: const Icon(Icons.archive_rounded, size: 18),
        ),
      ],
      selected: {showArchived},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
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
