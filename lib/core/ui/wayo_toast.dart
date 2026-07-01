import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/shell/widgets/wayo_bottom_nav.dart';
import 'root_scaffold_messenger_key.dart';

/// Visual intent of a [WayoToast].
enum WayoToastVariant { success, error, warning, info, neutral }

/// Centralized, brand-consistent toast/snackbar for the whole app.
///
/// International-app styling: floating card, rounded corners, leading icon badge,
/// optional title + message, optional action, swipe-to-dismiss. Adapts to
/// light/dark and RTL (Arabic) automatically.
///
/// Works without a local [Scaffold] by falling back to [rootScaffoldMessengerKey].
///
/// ```dart
/// WayoToast.success(context, t.dashboard.application_approved);
/// WayoToast.error(context, t.errors.network, title: 'Oops');
/// ```
abstract final class WayoToast {
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    SnackBarAction? action,
    double? bottomInset,
  }) =>
      show(
        context,
        message: message,
        title: title,
        variant: WayoToastVariant.success,
        duration: duration,
        action: action,
        bottomInset: bottomInset,
      );

  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    SnackBarAction? action,
    double? bottomInset,
  }) =>
      show(
        context,
        message: message,
        title: title,
        variant: WayoToastVariant.error,
        duration: duration,
        action: action,
        bottomInset: bottomInset,
      );

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    SnackBarAction? action,
    double? bottomInset,
  }) =>
      show(
        context,
        message: message,
        title: title,
        variant: WayoToastVariant.warning,
        duration: duration,
        action: action,
        bottomInset: bottomInset,
      );

  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    SnackBarAction? action,
    double? bottomInset,
  }) =>
      show(
        context,
        message: message,
        title: title,
        variant: WayoToastVariant.info,
        duration: duration,
        action: action,
        bottomInset: bottomInset,
      );

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    WayoToastVariant variant = WayoToastVariant.neutral,
    Duration? duration,
    SnackBarAction? action,
    IconData? icon,
    double? bottomInset,
  }) {
    // Always prefer the app-root messenger so nested Scaffolds (settings screens,
    // keyboard open) do not double-count viewInsets and push toasts to the top.
    final messenger = rootScaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final resolvedBottomInset =
        bottomInset ?? wayoToastBottomMargin(context);

    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(variant);
    final dur = duration ??
        (variant == WayoToastVariant.error ||
                variant == WayoToastVariant.warning
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 3200));

    HapticFeedback.lightImpact();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: dur,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(12, 0, 12, resolvedBottomInset),
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.horizontal,
        content: _WayoToastCard(
          title: title,
          message: message,
          accent: accent,
          icon: icon ?? _icon(variant),
          dark: dark,
          action: action,
          onClose: messenger.hideCurrentSnackBar,
        ),
      ),
    );
  }

  static Color _accent(WayoToastVariant v) => switch (v) {
        WayoToastVariant.success => const Color(0xFF22C55E),
        WayoToastVariant.error => const Color(0xFFEF4444),
        WayoToastVariant.warning => const Color(0xFFF59E0B),
        WayoToastVariant.info => const Color(0xFF3B82F6),
        WayoToastVariant.neutral => const Color(0xFFF47A1F),
      };

  static IconData _icon(WayoToastVariant v) => switch (v) {
        WayoToastVariant.success => Icons.check_circle_rounded,
        WayoToastVariant.error => Icons.error_rounded,
        WayoToastVariant.warning => Icons.warning_amber_rounded,
        WayoToastVariant.info => Icons.info_rounded,
        WayoToastVariant.neutral => Icons.notifications_rounded,
      };
}

class _WayoToastCard extends StatelessWidget {
  const _WayoToastCard({
    required this.title,
    required this.message,
    required this.accent,
    required this.icon,
    required this.dark,
    required this.onClose,
    this.action,
  });

  final String? title;
  final String message;
  final Color accent;
  final IconData icon;
  final bool dark;
  final VoidCallback onClose;
  final SnackBarAction? action;

  @override
  Widget build(BuildContext context) {
    final surface = dark ? const Color(0xFF17171F) : Colors.white;
    final titleColor = dark ? const Color(0xFFF5F5F7) : const Color(0xFF0F172A);
    final messageColor =
        dark ? const Color(0xFFB7B9C4) : const Color(0xFF475569);
    final hasTitle = title != null && title!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.45 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: dark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: accent, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasTitle) ...[
                              Text(
                                title!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: hasTitle ? 13 : 13.5,
                                fontWeight: hasTitle
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: hasTitle ? messageColor : titleColor,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (action != null)
                        TextButton(
                          onPressed: () {
                            onClose();
                            action!.onPressed();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            action!.label,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: onClose,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints.tightFor(width: 32, height: 32),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: messageColor.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
