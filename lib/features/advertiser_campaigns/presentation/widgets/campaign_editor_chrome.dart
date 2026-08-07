import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';

/// Premium visual language for advertiser campaign create / edit.
abstract final class CampaignEditorChrome {
  static bool dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static const amber = Color(0xFFF4A237);
  static const amberDeep = Color(0xFFE08B12);
  static const ink = Color(0xFF0B0B10);
  static const mist = Color(0xFF8B90A0);

  static BoxDecoration pageBackground(BuildContext c) {
    final isDark = dark(c);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF0B0B10),
                Color(0xFF14121A),
                Color(0xFF1A1208),
              ]
            : const [
                Color(0xFFFFFBF5),
                Color(0xFFF7F4EF),
                Color(0xFFFFF0DE),
              ],
        stops: const [0.0, 0.55, 1.0],
      ),
    );
  }

  static TextStyle display(BuildContext c) => GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.15,
        color: AppColors.textPrimaryOf(c),
      );

  static TextStyle section(BuildContext c) => GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimaryOf(c),
      );

  static TextStyle hint(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.textMutedOf(c),
      );

  static TextStyle label(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textMutedOf(c),
      );

  static InputDecoration fieldDecoration(
    BuildContext c, {
    required String label,
    String? hint,
    Widget? suffix,
    IconData? prefixIcon,
  }) {
    final isDark = dark(c);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AppColors.borderOf(c).withValues(alpha: isDark ? 0.45 : 0.8),
      ),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: amber),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.85),
      labelStyle: labelStyle(c),
      hintStyle: CampaignEditorChrome.hint(c),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: amber, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.8)),
      ),
    );
  }

  static TextStyle labelStyle(BuildContext c) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryOf(c),
      );

  /// High-UX error: haptic + premium toast + returns message for in-page banner.
  static void shoutError(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    HapticFeedback.heavyImpact();
    WayoToast.error(
      context,
      message,
      title: title ?? 'Something needs attention',
      duration: const Duration(seconds: 5),
    );
  }
}

/// Animated step rail — 3 stations with amber progress.
class CampaignEditorStepRail extends StatelessWidget {
  const CampaignEditorStepRail({
    super.key,
    required this.step,
    required this.total,
    required this.labels,
    required this.stepOfLabel,
  });

  final int step;
  final int total;
  final List<String> labels;
  final String stepOfLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = CampaignEditorChrome.dark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderOf(context).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stepOfLabel,
            style: CampaignEditorChrome.label(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: i <= step
                            ? const LinearGradient(
                                colors: [
                                  CampaignEditorChrome.amber,
                                  CampaignEditorChrome.amberDeep,
                                ],
                              )
                            : null,
                        color: i <= step
                            ? null
                            : AppColors.borderOf(context)
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                _StepDot(
                  index: i,
                  active: i == step,
                  done: i < step,
                  label: labels[i],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.active,
    required this.done,
    required this.label,
  });

  final int index;
  final bool active;
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = CampaignEditorChrome.amber;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: active ? 34 : 28,
          height: active ? 34 : 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active || done
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CampaignEditorChrome.amber,
                      CampaignEditorChrome.amberDeep,
                    ],
                  )
                : null,
            color: active || done
                ? null
                : AppColors.surfaceElevatedOf(context),
            border: active || done
                ? null
                : Border.all(
                    color: AppColors.borderOf(context),
                  ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: done && !active
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active || done
                        ? Colors.white
                        : AppColors.textMutedOf(context),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? CampaignEditorChrome.amber
                : AppColors.textMutedOf(context),
          ),
        ),
      ],
    );
  }
}

/// Glass error panel for in-wizard validation failures.
class CampaignEditorErrorPanel extends StatelessWidget {
  const CampaignEditorErrorPanel({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.error.withValues(alpha: 0.16),
            AppColors.error.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fix before continuing',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textMutedOf(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable campaign-type tile (Link / Video / Shorts).
class CampaignTypeTile extends StatelessWidget {
  const CampaignTypeTile({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = CampaignEditorChrome.dark(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CampaignEditorChrome.amber.withValues(alpha: 0.22),
                        CampaignEditorChrome.amberDeep.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: selected
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.7)),
              border: Border.all(
                color: selected
                    ? CampaignEditorChrome.amber
                    : AppColors.borderOf(context).withValues(alpha: 0.5),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: CampaignEditorChrome.amber.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? CampaignEditorChrome.amber
                      : AppColors.textMutedOf(context),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CampaignEditorChrome.hint(context).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft surface panel for sections / review.
class CampaignEditorPanel extends StatelessWidget {
  const CampaignEditorPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = CampaignEditorChrome.dark(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.78),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.4),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Wallet chip under the step rail.
class CampaignEditorWalletChip extends StatelessWidget {
  const CampaignEditorWalletChip({
    super.key,
    required this.label,
    required this.low,
  });

  final String label;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final color = low ? AppColors.error : CampaignEditorChrome.amber;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            low ? Icons.account_balance_wallet_outlined : Icons.wallet_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Review summary row inside a panel.
class CampaignReviewRow extends StatelessWidget {
  const CampaignReviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: CampaignEditorChrome.label(context)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
