import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../i18n/strings.g.dart';

import 'cinematic_chat_colors.dart';

/// ━━━ [6] BARRE DE SAISIE — Premium glass composer ━━━
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
    this.editing = false,
    this.editingTitle,
    this.editingPreview,
    this.editingCancelLabel,
    this.onCancelEdit,
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

  /// Inline edit mode: when true, the composer shows a leading banner and the
  /// send button swaps to a confirm glyph.
  final bool editing;
  final String? editingTitle;
  final String? editingPreview;
  final String? editingCancelLabel;
  final VoidCallback? onCancelEdit;

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetCt.surface.withValues(alpha: 0.94),
                    border: Border(
                      top: BorderSide(
                        color: sheetCt.borderSoft.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: sheetCt.muted.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Text(
                        t.chat.pick_attachment,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: sheetCt.textPrimary,
                          letterSpacing: -0.2,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: ct.bg.withValues(alpha: isDark ? 0.72 : 0.78),
              border: Border(
                top: BorderSide(
                  color: ct.borderSoft.withValues(alpha: 0.4),
                  width: 0.6,
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: widget.editing
                      ? _EditingBanner(
                          title: widget.editingTitle ?? 'Editing message',
                          preview: widget.editingPreview ?? '',
                          cancelLabel: widget.editingCancelLabel ?? 'Cancel',
                          onCancel: widget.onCancelEdit,
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (widget.errorText != null && widget.errorText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: Colors.redAccent.shade200,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.errorText!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.redAccent.shade100,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _PremiumInputField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  focused: _focused,
                  hint: widget.hint,
                  hasText: _hasText,
                  editing: widget.editing,
                  onAttach: widget.onAttach == null
                      ? null
                      : () => _openAttachSheet(context),
                  onSubmit: widget.enabled && _hasText ? _submit : null,
                ),
              ],
            ),
          ),
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

/// Pill unifiée : [attach] | champ | [send]
/// — tout glassmorphisme, pas d'icône micro.
class _PremiumInputField extends StatelessWidget {
  const _PremiumInputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.focused,
    required this.hint,
    required this.hasText,
    required this.editing,
    required this.onAttach,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool focused;
  final String? hint;
  final bool hasText;
  final bool editing;
  final VoidCallback? onAttach;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = focused
        ? ct.amber.withValues(alpha: 0.9)
        : ct.borderSoft.withValues(alpha: isDark ? 0.7 : 0.55);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: isDark
            ? ct.surface.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: focused ? 1.4 : 0.8),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: ct.amber.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onAttach != null)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: _CircleIconButton(
                icon: Icons.add_rounded,
                tint: ct.textPrimary.withValues(alpha: 0.78),
                backgroundColor: ct.textPrimary.withValues(alpha: isDark ? 0.08 : 0.06),
                onTap: enabled ? onAttach : null,
                size: 40,
                iconSize: 22,
              ),
            )
          else
            const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.45,
                  color: ct.textPrimary,
                  letterSpacing: -0.1,
                ),
                cursorColor: ct.amber,
                cursorRadius: const Radius.circular(2),
                cursorWidth: 2,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(
                    color: ct.muted.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: _PremiumSendButton(
              active: enabled && hasText,
              editing: editing,
              onTap: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tint,
    required this.backgroundColor,
    required this.onTap,
    this.size = 44,
    this.iconSize = 24,
  });

  final IconData icon;
  final Color tint;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: tint, size: iconSize),
        ),
      ),
    );
  }
}

/// Bouton envoi premium : cercle gradient amber → coral avec highlight intérieur.
/// **Aucune icône micro** : désactivé → petite flèche atténuée, actif → flèche blanche
/// sur gradient lumineux, édition → check.
class _PremiumSendButton extends StatelessWidget {
  const _PremiumSendButton({
    required this.active,
    required this.editing,
    required this.onTap,
  });

  final bool active;
  final bool editing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icon = editing
        ? Icons.check_rounded
        : Icons.arrow_upward_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ct.amber, ct.amberDeep],
              )
            : null,
        color: active
            ? null
            : ct.textPrimary.withValues(alpha: isDark ? 0.08 : 0.06),
        boxShadow: active
            ? [
                BoxShadow(
                  color: ct.amber.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedScale(
            scale: active ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(
              icon,
              size: 22,
              color: active
                  ? Colors.white
                  : ct.muted.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ct.amber.withValues(alpha: isDark ? 0.16 : 0.12),
                ct.amber.withValues(alpha: isDark ? 0.06 : 0.04),
              ],
            ),
            border: Border.all(
              color: ct.amber.withValues(alpha: 0.24),
              width: 0.6,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ct.amber, ct.amberDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ct.amber.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: ct.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditingBanner extends StatelessWidget {
  const _EditingBanner({
    required this.title,
    required this.preview,
    required this.cancelLabel,
    this.onCancel,
  });

  final String title;
  final String preview;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ct = CinematicChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            ct.amber.withValues(alpha: isDark ? 0.22 : 0.16),
            ct.amber.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: ct.amber, width: 3.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ct.amber.withValues(alpha: 0.22),
            ),
            child: Icon(Icons.edit_rounded, size: 15, color: ct.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ct.amber,
                    letterSpacing: 0.1,
                  ),
                ),
                if (preview.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      preview.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ct.textPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            tooltip: cancelLabel,
            icon: Icon(Icons.close_rounded, size: 18, color: ct.muted),
          ),
        ],
      ),
    );
  }
}
