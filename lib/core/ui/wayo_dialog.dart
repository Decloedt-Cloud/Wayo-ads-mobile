import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Visual intent for premium dialogs (icon tint + confirm button style).
enum WayoDialogTone { neutral, primary, destructive, warning }

/// Shared premium chrome for every app popup (replaces raw [AlertDialog]).
class WayoAlertDialog extends StatelessWidget {
  const WayoAlertDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.tone = WayoDialogTone.neutral,
    this.scrollable = false,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    this.actionsAlignment = MainAxisAlignment.end,
    this.actionsOverflowButtonSpacing,
    this.clipBehavior = Clip.antiAlias,
    this.backgroundColor,
    this.shape,
    this.contentPadding,
    this.titlePadding,
    this.actionsPadding,
    this.iconPadding,
  });

  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final WayoDialogTone tone;
  final bool scrollable;
  final EdgeInsets insetPadding;
  final MainAxisAlignment actionsAlignment;
  final double? actionsOverflowButtonSpacing;
  final Clip clipBehavior;

  /// Optional overrides (legacy call sites); premium defaults apply when null.
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? iconPadding;

  static Color surface(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF1C1816) : const Color(0xFFFFFBF8);
  }

  static Color _toneAccent(WayoDialogTone tone) {
    switch (tone) {
      case WayoDialogTone.destructive:
        return AppColors.error;
      case WayoDialogTone.warning:
        return const Color(0xFFF59E0B);
      case WayoDialogTone.primary:
        return AppColors.primary;
      case WayoDialogTone.neutral:
        return AppColors.primarySoft;
    }
  }

  static IconData defaultIconForTone(WayoDialogTone tone) {
    switch (tone) {
      case WayoDialogTone.destructive:
        return Icons.delete_outline_rounded;
      case WayoDialogTone.warning:
        return Icons.warning_amber_rounded;
      case WayoDialogTone.primary:
        return Icons.check_circle_outline_rounded;
      case WayoDialogTone.neutral:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = _toneAccent(tone);
    final titleStyle = GoogleFonts.sora(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.25,
      color: AppColors.textPrimaryOf(context),
    );
    final bodyStyle = GoogleFonts.dmSans(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: AppColors.textSecondaryOf(context),
    );

    Widget? resolvedIcon = icon;

    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondaryOf(context),
            textStyle: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: accent.withValues(alpha: 0.35),
            textStyle: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimaryOf(context),
            side: BorderSide(
              color: AppColors.borderOf(context).withValues(alpha: 0.9),
            ),
            textStyle: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      child: AlertDialog(
        backgroundColor: backgroundColor ?? surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 28,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.55 : 0.22),
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color:
                    (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              ),
            ),
        clipBehavior: clipBehavior,
        insetPadding: insetPadding,
        iconPadding: iconPadding ??
            (resolvedIcon == null
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(24, 26, 24, 0)),
        titlePadding: titlePadding ??
            EdgeInsets.fromLTRB(
              24,
              resolvedIcon == null ? 26 : 14,
              24,
              content == null ? 8 : 0,
            ),
        contentPadding:
            contentPadding ?? const EdgeInsets.fromLTRB(24, 12, 24, 8),
        actionsPadding:
            actionsPadding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
        buttonPadding: const EdgeInsets.symmetric(horizontal: 4),
        actionsAlignment: actionsAlignment,
        actionsOverflowButtonSpacing: actionsOverflowButtonSpacing ?? 8,
        icon: resolvedIcon == null
            ? null
            : _WayoDialogIconBadge(accent: accent, child: resolvedIcon),
        title: title == null
            ? null
            : DefaultTextStyle.merge(style: titleStyle, child: title!),
        content: content == null
            ? null
            : DefaultTextStyle.merge(style: bodyStyle, child: content!),
        scrollable: scrollable,
        actions: actions,
      ),
    );
  }
}

class _WayoDialogIconBadge extends StatelessWidget {
  const _WayoDialogIconBadge({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      alignment: Alignment.center,
      child: IconTheme(
        data: IconThemeData(color: accent, size: 26),
        child: child,
      ),
    );
  }
}

/// Premium dialog host — dimmed barrier + fade/scale feel via Material defaults.
Future<T?> showWayoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? const Color(0xCC0A0A0A),
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    builder: builder,
  );
}

/// Standard cancel / confirm popup used across the app.
Future<bool> showWayoConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelLabel,
  String? confirmLabel,
  WayoDialogTone tone = WayoDialogTone.neutral,
  IconData? icon,
  bool barrierDismissible = true,
}) async {
  final material = MaterialLocalizations.of(context);
  final cancel = cancelLabel ?? material.cancelButtonLabel;
  final confirm = confirmLabel ?? material.okButtonLabel;

  final result = await showWayoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => WayoAlertDialog(
      tone: tone,
      icon: Icon(icon ?? WayoAlertDialog.defaultIconForTone(tone)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancel),
        ),
        FilledButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(ctx).pop(true);
          },
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result == true;
}
