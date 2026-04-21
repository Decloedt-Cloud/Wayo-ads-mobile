import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../theme/liquid_neural_palette.dart';

class ChatComposerBar extends StatelessWidget {
  const ChatComposerBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.reduceMotion,
    this.hint,
    this.errorText,
    this.onDraftChanged,
    this.onAttach,
    this.liquidNeural = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool reduceMotion;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onDraftChanged;
  final VoidCallback? onAttach;
  final bool liquidNeural;

  @override
  Widget build(BuildContext context) {
    final ln = liquidNeural ? LiquidNeuralTheme.of(context) : null;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorText != null && errorText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  errorText!,
                  style: AppTextStyles.caption(context).copyWith(color: AppColors.error),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onAttach != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: IconButton.filledTonal(
                      onPressed: enabled ? onAttach : null,
                      style: IconButton.styleFrom(
                        backgroundColor: liquidNeural
                            ? ln!.ghostGlassStrong
                            : const Color(0xFF1E1E1E),
                        foregroundColor: liquidNeural
                            ? ln!.textSecondary
                            : AppColors.textSecondaryOf(context),
                      ),
                      icon: const Icon(Icons.attach_file_rounded, size: 22),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onChanged: onDraftChanged,
                    onSubmitted: (_) => enabled ? onSend() : null,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: liquidNeural
                          ? ln!.textPrimary
                          : AppColors.textPrimaryOf(context),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTextStyles.bodyLarge(context).copyWith(
                        color: liquidNeural
                            ? ln!.textSecondary
                            : AppColors.textMutedOf(context),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: liquidNeural
                          ? ln!.ghostGlassStrong
                          : const Color(0xFF141414),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: liquidNeural
                              ? ln!.plasmaStroke
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: liquidNeural
                              ? ln!.plasmaStroke
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: liquidNeural ? ln!.plasma : AppColors.primary,
                          width: liquidNeural ? 1.35 : 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SendFab(onTap: enabled ? onSend : null, liquidNeural: liquidNeural),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendFab extends StatelessWidget {
  const _SendFab({required this.onTap, this.liquidNeural = false});

  final VoidCallback? onTap;
  final bool liquidNeural;

  @override
  Widget build(BuildContext context) {
    final ln = liquidNeural ? LiquidNeuralTheme.of(context) : null;
    final active = onTap != null;
    final fill = active
        ? (liquidNeural ? ln!.plasma : AppColors.primary)
        : (liquidNeural ? ln!.ghostGlassStrong : const Color(0xFF2A2A2A));
    final child = Material(
      color: fill,
      shape: const CircleBorder(),
      shadowColor: liquidNeural && active ? ln!.plasma.withValues(alpha: 0.45) : null,
      elevation: liquidNeural && active ? 8 : 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            Icons.arrow_upward_rounded,
            color: active ? Colors.black : AppColors.textMuted,
            size: 22,
          ),
        ),
      ),
    );

    return child;
  }
}
