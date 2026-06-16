import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

/// Result of the active-session conflict sheet (web browser or another device).
enum WebSessionActiveDialogResult { disconnectAndContinue, cancel }

/// Shown when Auth returns [WEB_SESSION_ACTIVE] (409).
///
/// Lets the user disconnect the other session and retry login with
/// `force_web_logout: true`.
Future<WebSessionActiveDialogResult?> showWebSessionActiveDialog({
  required BuildContext context,
  required Translations t,
  String? email,
  required Future<void> Function() onDisconnect,
}) {
  return showDialog<WebSessionActiveDialogResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => _WebSessionActiveDialog(
      t: t,
      email: email,
      onDisconnect: onDisconnect,
    ),
  );
}

class _WebSessionActiveDialog extends StatefulWidget {
  const _WebSessionActiveDialog({
    required this.t,
    required this.onDisconnect,
    this.email,
  });

  final Translations t;
  final String? email;
  final Future<void> Function() onDisconnect;

  @override
  State<_WebSessionActiveDialog> createState() => _WebSessionActiveDialogState();
}

class _WebSessionActiveDialogState extends State<_WebSessionActiveDialog> {
  bool _disconnecting = false;

  Future<void> _disconnect() async {
    if (_disconnecting) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _disconnecting = true);
    try {
      await widget.onDisconnect();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(WebSessionActiveDialogResult.disconnectAndContinue);
    } catch (_) {
      if (mounted) {
        setState(() => _disconnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final email = widget.email?.trim();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.borderOf(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.14),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A1A0A)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.devices_other_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t.login.web_session_title,
                      style: AppTextStyles.labelLarge(context).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                t.login.web_session_body,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              if (email != null && email.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141414)
                        : AppColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderOf(context).withValues(
                        alpha: isDark ? 0.5 : 0.85,
                      ),
                    ),
                  ),
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _DisconnectButton(
                label: _disconnecting
                    ? t.login.web_session_disconnecting
                    : t.login.web_session_disconnect,
                busy: _disconnecting,
                onPressed: _disconnect,
              ),
              const SizedBox(height: 10),
              _CancelButton(
                label: t.login.web_session_cancel,
                enabled: !_disconnecting,
                onPressed: () => Navigator.of(context).pop(
                  WebSessionActiveDialogResult.cancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: busy
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.55),
                      AppColors.primaryDeep.withValues(alpha: 0.55),
                    ],
                  )
                : AppColors.primaryGradient,
            boxShadow: busy
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.38),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.15,
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

class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : AppColors.borderOf(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        foregroundColor: AppColors.textPrimaryOf(context),
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppColors.textPrimaryOf(context),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelLarge(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
