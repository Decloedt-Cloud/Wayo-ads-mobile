import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../i18n/strings.g.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_phone_validation.dart';
import '../../data/chat_realtime_service.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_message.dart';
import '../cinematic/cinematic_chat_colors.dart';
import '../cinematic/cinematic_chat_header.dart';
import '../cinematic/cinematic_composer_bar.dart';
import '../cinematic/cinematic_date_pill.dart';
import '../cinematic/cinematic_mesh_background.dart';
import '../cinematic/cinematic_message_bubble.dart';
import '../cinematic/cinematic_send_burst.dart';
import '../cinematic/cinematic_typing_dots.dart';
import '../providers/chat_providers.dart';

/// ━━━ Fil de discussion — UI cinématique (fond vivant, slivers, bulles, composer) ━━━
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _scroll = ScrollController();
  final _draft = TextEditingController();
  final _header = CinematicHeaderController(title: '');
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

  @override
  void dispose() {
    _sub?.cancel();
    _typingTimer?.cancel();
    _typingQuietTimer?.cancel();
    _scroll.dispose();
    _draft.dispose();
    _header.dispose();
    _fabVisible.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ref.read(chatRealtimeBindingProvider);
      final creds = await ref.read(chatBootstrapProvider.future);
      final rt = ref.read(chatRealtimeServiceProvider);
      final repo = ref.read(chatRepositoryProvider);
      final rows = await repo.fetchMessages(
        creds,
        widget.conversationId,
        socketId: () => rt.socketId,
      );
      await repo.markRead(
        creds,
        widget.conversationId,
        socketId: () => rt.socketId,
      );
      ref.invalidate(chatConversationsProvider);
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _loading = false;
      });
      _seedPeerReadAtFromConversations(creds.chatUserId);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToEnd(animated: false),
      );
      _listenRt(creds, repo, rt);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ChatRepository.mapError(e).toString();
      });
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
        HapticFeedback.lightImpact();
        setState(() => _messages = [..._messages, m]);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToEnd(animated: true),
        );
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

  void _scrollToEnd({required bool animated}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;
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
  }

  bool _onScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification && n is! ScrollMetricsNotification) {
      return false;
    }
    final m = _scroll.hasClients ? _scroll.position : null;
    if (m == null || !m.hasContentDimensions) return false;
    final gap = m.maxScrollExtent - m.pixels;
    final show = gap > 200;
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
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ChatMessage(
      id: tempId,
      conversationId: widget.conversationId,
      userId: creds.chatUserId,
      content: text,
      type: 'text',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      pending: true,
    );
    setState(() {
      _messages = [..._messages, optimistic];
      _sending = true;
      _draft.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToEnd(animated: true),
    );
    try {
      final sent = await repo.sendTextMessage(
        creds,
        widget.conversationId,
        text,
        socketId: () => rt.socketId,
      );
      if (!mounted) return;
      setState(() {
        _messages = _messages.map((m) => m.id == tempId ? sent : m).toList();
      });
      ref.invalidate(chatConversationsProvider);
    } catch (_) {
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

  Future<void> _pickAndUpload(
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
  ) async {
    final t = context.t;
    const allowed = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'};
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
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
    if (!allowed.contains(ext)) {
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
          bytes = await File(path).readAsBytes();
        } catch (_) {}
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
    final lower = ext;
    final isPdf = lower == 'pdf';
    final maxBytes = isPdf ? 50 * 1024 * 1024 : 10 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.chat.file_too_large)));
      }
      return;
    }
    setState(() => _uploading = true);
    try {
      final sent = await repo.uploadMessageAttachment(
        creds,
        widget.conversationId,
        filename: f.name,
        bytes: bytes,
        caption: _draft.text.trim(),
        socketId: () => rt.socketId,
      );
      if (!mounted) return;
      _draft.clear();
      setState(() {
        _messages = [..._messages, sent];
        _phoneError = null;
      });
      ref.invalidate(chatConversationsProvider);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToEnd(animated: true),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.chat.upload_failed)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
    final title = GoRouterState.of(context).extra is String
        ? GoRouterState.of(context).extra! as String
        : t.chat.thread_fallback_title;
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
        final partnerId = conv?.partnerChatUserId(creds.chatUserId);

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
            _header.setPresence(
              title: title,
              statusLine: statusLine,
              typing: typing,
              partnerOnline: online,
            );

            final partnerPhotoPath =
                conv?.displayAvatar ??
                conv?.partnerAvatarFromParticipants(creds.chatUserId);
            final partnerAvatarResolved = resolveChatMediaUrl(
              partnerPhotoPath,
              creds.apiBaseUrl,
            );

            final messageTiles = _buildMessageWidgets(
              context,
              creds,
              repo,
              rt,
              reduce,
              peerAvatarUrl: partnerAvatarResolved,
            );
            final listCount =
                messageTiles.length + (_typingName != null ? 1 : 0);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: threadUi,
              child: Scaffold(
                backgroundColor: chatTheme.bg,
                body: CinematicMeshBackground(
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            NotificationListener<ScrollNotification>(
                              onNotification: _onScroll,
                              child: CustomScrollView(
                                controller: _scroll,
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                slivers: [
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: CinematicChatHeaderDelegate(
                                      controller: _header,
                                      titleLetter: letter,
                                      onBack: () => context.pop(),
                                      topSafeInset: MediaQuery.paddingOf(
                                        context,
                                      ).top,
                                      partnerAvatarUrl: partnerAvatarResolved,
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      0,
                                      4,
                                      0,
                                      8 + MediaQuery.paddingOf(context).bottom,
                                    ),
                                    sliver: _loading
                                        ? SliverFillRemaining(
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: chatTheme.amber,
                                              ),
                                            ),
                                          )
                                        : _error != null
                                        ? SliverFillRemaining(
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _error!,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    FilledButton(
                                                      onPressed: _bootstrap,
                                                      child: Text(
                                                        t
                                                            .dashboard
                                                            .errors
                                                            .retry,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : SliverList(
                                            delegate:
                                                SliverChildBuilderDelegate((
                                                  context,
                                                  index,
                                                ) {
                                                  if (index <
                                                      messageTiles.length) {
                                                    return messageTiles[index];
                                                  }
                                                  return const Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 12,
                                                      bottom: 12,
                                                    ),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child:
                                                          CinematicTypingDots(),
                                                    ),
                                                  );
                                                }, childCount: listCount),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: _fabVisible,
                              builder: (context, show, _) {
                                if (!show || _loading || _error != null)
                                  return const SizedBox.shrink();
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
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
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
                                _error == null,
                            reduceMotion: reduce,
                            hint: _editingMessageId != null
                                ? t.chat.edit_mode_hint
                                : t.chat.composer_hint,
                            errorText: _phoneError,
                            editing: _editingMessageId != null,
                            editingTitle: t.chat.edit_mode_title,
                            editingPreview: _editingOriginalContent,
                            editingCancelLabel: t.chat.edit_mode_cancel,
                            onCancelEdit: _cancelEdit,
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
                                unawaited(_fireTyping(creds, repo, rt, false));
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
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 24,
                              bottom: 88,
                            ),
                            child: CinematicSendBurst(key: _burstKey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildMessageWidgets(
    BuildContext context,
    ChatCredentials creds,
    ChatRepository repo,
    ChatRealtimeService rt,
    bool reduce, {
    required String peerAvatarUrl,
  }) {
    final t = context.t;
    final out = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final parsed = DateTime.tryParse(m.createdAt)?.toLocal();
      if (parsed != null) {
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (lastDay == null || day != lastDay) {
          out.add(CinematicDatePill(label: _dayLabel(day, t)));
          lastDay = day;
        }
      }
      final next = i + 1 < _messages.length ? _messages[i + 1] : null;
      final showFooter = next == null || next.userId != m.userId;
      final isMine = m.userId == creds.chatUserId;
      final createdUtc = DateTime.tryParse(m.createdAt);
      final isReadByPeer =
          isMine &&
          !m.pending &&
          !m.failed &&
          _peerReadAt != null &&
          createdUtc != null &&
          !createdUtc.isAfter(_peerReadAt!);
      out.add(
        CinematicMessageBubble(
          key: ValueKey('msg-${m.id}'),
          message: m,
          isMine: isMine,
          reduceMotion: reduce,
          apiBaseUrl: creds.apiBaseUrl,
          showTimestampFooter: showFooter,
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
        ),
      );
    }
    return out;
  }
}
