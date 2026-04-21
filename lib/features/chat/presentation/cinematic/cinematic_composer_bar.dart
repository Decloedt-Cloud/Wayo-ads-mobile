import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../i18n/strings.g.dart';

import 'cinematic_chat_colors.dart';

/// ━━━ [6] BARRE DE SAISIE — OBJET SCULPTURAL ━━━
class CinematicComposerBar extends StatefulWidget {
  const CinematicComposerBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.reduceMotion,
    this.hint,
    this.errorText,
    this.onDraftChanged,
    this.onAttach,
    this.onSendBurst,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool reduceMotion;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onDraftChanged;
  final VoidCallback? onAttach;
  final VoidCallback? onSendBurst;

  @override
  State<CinematicComposerBar> createState() => _CinematicComposerBarState();
}

class _CinematicComposerBarState extends State<CinematicComposerBar> {
  final _focus = FocusNode();
  bool _hasText = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  void _onText() {
    final v = widget.controller.text.trim().isNotEmpty;
    if (v != _hasText && mounted) setState(() => _hasText = v);
    widget.onDraftChanged?.call(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _openAttachSheet(BuildContext context) {
    if (widget.onAttach == null) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final t = ctx.t;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.42,
          minChildSize: 0.28,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            final sheetCt = CinematicChatTheme.of(context);
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: sheetCt.surface.withValues(alpha: 0.96),
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: sheetCt.muted.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Text(
                        t.chat.pick_attachment,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: sheetCt.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AttachTile(
                              icon: Icons.perm_media_outlined,
                              label: t.chat.attachment_image,
                              onTap: () {
                                Navigator.pop(ctx);
                                widget.onAttach!();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AttachTile(
                              icon: Icons.insert_drive_file_outlined,
                              label: t.chat.attachment_pdf,
                              onTap: () {
                                Navigator.pop(ctx);
                                widget.onAttach!();
                              },
                            ),
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

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.errorText != null && widget.errorText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  widget.errorText!,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent.shade100),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onAttach != null)
                    IconButton(
                      onPressed: widget.enabled ? () => _openAttachSheet(context) : null,
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: widget.enabled ? ct.muted : ct.muted.withValues(alpha: 0.5),
                      ),
                    ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      constraints: const BoxConstraints(minHeight: 56),
                      decoration: BoxDecoration(
                        color: ct.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: ct.amber.withValues(alpha: _focused ? 1 : 0.35),
                          width: 0.8,
                        ),
                        boxShadow: _focused
                            ? [
                                BoxShadow(
                                  color: ct.amber.withValues(alpha: 0.4),
                                  blurRadius: 0,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        enabled: widget.enabled,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => widget.enabled ? _submit() : null,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.45,
                          color: ct.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: GoogleFonts.inter(color: ct.muted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendMorphButton(
                    active: widget.enabled && _hasText,
                    reduceMotion: widget.reduceMotion,
                    onTap: widget.enabled && _hasText ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    widget.onSendBurst?.call();
    widget.onSend();
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    return Material(
      color: ct.textPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: ct.amber, size: 32),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.inter(color: ct.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendMorphButton extends StatelessWidget {
  const _SendMorphButton({
    required this.active,
    required this.reduceMotion,
    required this.onTap,
  });

  final bool active;
  final bool reduceMotion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      transitionBuilder: (child, anim) {
        return ScaleTransition(
          scale: anim,
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.042).animate(anim),
            child: child,
          ),
        );
      },
      child: Material(
        key: ValueKey(active),
        color: active ? ct.amber : ct.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(
              active ? Icons.arrow_upward_rounded : Icons.mic_none_rounded,
              color: active ? Colors.black : ct.muted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
