import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../theme/liquid_neural_palette.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/chat_media_utils.dart';
import '../../data/chat_prior_contacts.dart';
import '../../domain/chat_conversation.dart';
import '../../domain/chat_credentials.dart';
import '../../domain/chat_directory_user.dart';
import '../providers/chat_providers.dart';

/// User search bar: advertiser flow calls chat-service [`GET api/v1/users`]; creators
/// can restrict to **[priorContactsOnly]** (local filter on existing threads only).
class ChatUserSearchBar extends ConsumerStatefulWidget {
  const ChatUserSearchBar({
    super.key,
    required this.creds,
    required this.hiddenParticipantIds,
    required this.onUserSelected,
    this.useLiquidNeuralStyle = false,
    this.priorContactsOnly = false,
    this.priorConversationList = const [],
  });

  final ChatCredentials creds;
  final Set<int> hiddenParticipantIds;
  final Future<void> Function(ChatDirectoryUser user) onUserSelected;
  final bool useLiquidNeuralStyle;

  /// When true, never hits `api/v1/users` — searches only [`priorConversationList`].
  final bool priorContactsOnly;
  final List<ChatConversation> priorConversationList;

  @override
  ConsumerState<ChatUserSearchBar> createState() => _ChatUserSearchBarState();
}

class _ChatUserSearchBarState extends ConsumerState<ChatUserSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<ChatDirectoryUser> _results = const [];
  bool _loading = false;
  int? _busyUserId;
  String _lastQuery = '';

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String raw) async {
    final q = raw.trim();
    _lastQuery = q;

    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _results = const [];
          _loading = false;
        });
      }
      return;
    }

    if (widget.priorContactsOnly) {
      await _runPriorContactsSearch(q);
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      // Drop cached JWT so each search pulls a minted token via Wayo-ads (matches web).
      ref.invalidate(chatBootstrapProvider);
      final repo = ref.read(chatRepositoryProvider);
      final rt = ref.read(chatRealtimeServiceProvider);
      final creds = await ref.read(chatBootstrapProvider.future);

      final rows = await repo.searchUsers(
        creds,
        q,
        socketId: () => rt.socketId,
      );

      if (!mounted || _lastQuery != q) return;

      final me = creds.chatUserId;
      final hidden = widget.hiddenParticipantIds;

      setState(() {
        _results = rows
            .where((u) => u.id != me && !hidden.contains(u.id))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  /// Local search only — no chat-service directory API.
  Future<void> _runPriorContactsSearch(String q) async {
    final t = context.t;
    final me = widget.creds.chatUserId;
    final qLower = q.toLowerCase();
    final roster = chatDirectoryUsersFromPriorConversations(
      conversations: widget.priorConversationList,
      myChatUserId: me,
      fallbackName: t.chat.conversation_unknown,
    );
    final filtered = roster
        .where((u) => u.id != me && chatPriorContactMatchesQuery(u, qLower))
        .where((u) => !widget.hiddenParticipantIds.contains(u.id))
        .toList();

    if (!mounted || _lastQuery != q) return;
    setState(() {
      _results = filtered;
      _loading = false;
    });
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 380),
      () => _runSearch(value),
    );
  }

  Future<void> _onTapUser(ChatDirectoryUser u) async {
    setState(() => _busyUserId = u.id);
    try {
      await widget.onUserSelected(u);
      if (!mounted) return;

      _controller.clear();
      _focus.unfocus();

      setState(() {
        _results = const [];
        _lastQuery = '';
      });
    } finally {
      if (mounted) {
        setState(() => _busyUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;
    final ln = widget.useLiquidNeuralStyle
        ? LiquidNeuralTheme.of(context)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: widget.useLiquidNeuralStyle && ln != null
                ? ln.cardSheen
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
            border: Border.all(
              color: widget.useLiquidNeuralStyle && ln != null
                  ? ln.plasmaStroke.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (widget.useLiquidNeuralStyle && ln != null
                            ? ln.plasma
                            : AppColors.primary)
                        .withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.useLiquidNeuralStyle
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: _buildSearchField(context, t, scheme),
                  ),
                )
              : _buildSearchField(context, t, scheme),
        ),

        if (_controller.text.trim().length >= 2) ...[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _results.isEmpty && !_loading
                ? Padding(
                    key: const ValueKey('empty'),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      widget.priorContactsOnly
                          ? t.chat.search_prior_chats_no_results
                          : t.chat.search_users_no_results,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textMutedOf(context)),
                    ),
                  )
                : _results.isEmpty
                ? const SizedBox.shrink(key: ValueKey('loading'))
                : Material(
                    key: const ValueKey('list'),
                    color: widget.useLiquidNeuralStyle && ln != null
                        ? ln.avatarPhotoPlate
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _results.length,
                        separatorBuilder: (context, _) => Divider(
                          height: 1,
                          color: widget.useLiquidNeuralStyle && ln != null
                              ? ln.strokeSubtle
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (context, i) {
                          final u = _results[i];
                          final avatarUrl = resolveChatMediaUrl(
                            u.avatar,
                            widget.creds.apiBaseUrl,
                          );
                          final busy = _busyUserId == u.id;

                          return ListTile(
                            onTap: busy ? null : () => _onTapUser(u),
                            leading: SizedBox(
                              width: 44,
                              height: 44,
                              child: ClipOval(
                                child: avatarUrl.isEmpty
                                    ? ColoredBox(
                                        color:
                                            widget.useLiquidNeuralStyle &&
                                                ln != null
                                            ? ln.ghostGlassStrong
                                            : Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                        child: Center(
                                          child: Text(
                                            _initialLetter(u.name),
                                            style: AppTextStyles.labelLarge(
                                              context,
                                            ),
                                          ),
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: avatarUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            ColoredBox(
                                              color:
                                                  widget.useLiquidNeuralStyle &&
                                                      ln != null
                                                  ? ln.ghostGlass
                                                  : Colors.white.withValues(
                                                      alpha: 0.06,
                                                    ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            ColoredBox(
                                              color:
                                                  widget.useLiquidNeuralStyle &&
                                                      ln != null
                                                  ? ln.ghostGlassStrong
                                                  : Colors.white.withValues(
                                                      alpha: 0.08,
                                                    ),
                                              child: Center(
                                                child: Text(
                                                  _initialLetter(u.name),
                                                  style:
                                                      AppTextStyles.labelLarge(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ),
                                      ),
                              ),
                            ),
                            title: Text(
                              u.name?.trim().isNotEmpty == true
                                  ? u.name!.trim()
                                  : t.chat.conversation_unknown,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge(
                                context,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle:
                                u.email != null && u.email!.trim().isNotEmpty
                                ? Text(
                                    u.email!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          color: AppColors.textSecondaryOf(
                                            context,
                                          ),
                                        ),
                                  )
                                : null,
                            trailing: busy
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          widget.useLiquidNeuralStyle &&
                                              ln != null
                                          ? ln.textSecondary
                                          : AppColors.textMutedOf(context),
                                    ),
                                  )
                                : Icon(
                                    Icons.chat_bubble_outline,
                                    color:
                                        widget.useLiquidNeuralStyle &&
                                            ln != null
                                        ? ln.textSecondary
                                        : AppColors.textMutedOf(context),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ] else if (_focus.hasFocus) ...[
          const SizedBox(height: 6),
          Text(
            widget.priorContactsOnly
                ? t.chat.search_prior_chats_min_hint
                : t.chat.search_users_min_hint,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textMutedOf(context)),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    Translations t,
    ColorScheme scheme,
  ) {
    final ln = widget.useLiquidNeuralStyle
        ? LiquidNeuralTheme.of(context)
        : null;

    final accent = widget.useLiquidNeuralStyle && ln != null
        ? ln.textSecondary
        : AppColors.textMutedOf(context);

    return TextField(
      controller: _controller,
      focusNode: _focus,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: AppTextStyles.bodyLarge(context).copyWith(
        color: widget.useLiquidNeuralStyle && ln != null
            ? ln.textPrimary
            : null,
      ),
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: widget.priorContactsOnly
            ? t.chat.search_prior_chats_hint
            : t.chat.search_users_hint,
        hintStyle: AppTextStyles.bodyLarge(context).copyWith(
          color: widget.useLiquidNeuralStyle && ln != null
              ? ln.textSecondary
              : AppColors.textMutedOf(context),
        ),
        prefixIcon: Icon(Icons.search_rounded, color: accent),
        suffixIcon: !widget.priorContactsOnly && _loading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                ),
              )
            : _controller.text.isNotEmpty
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                onPressed: () {
                  _controller.clear();
                  _debounce?.cancel();
                  setState(() {
                    _results = const [];
                    _lastQuery = '';
                    _loading = false;
                  });
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMutedOf(context),
                ),
              )
            : null,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
      onChanged: (v) {
        setState(() {});
        _scheduleSearch(v);
      },
    );
  }
}

String _initialLetter(String? name) {
  final it = (name ?? '').trim().runes.iterator;
  if (!it.moveNext()) return '?';
  return String.fromCharCode(it.current).toUpperCase();
}
