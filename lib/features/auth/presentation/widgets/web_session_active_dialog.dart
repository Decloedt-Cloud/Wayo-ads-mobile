import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

/// Dialog shown when Auth returns [WEB_SESSION_ACTIVE] — mirrors Wayo-ads web sign-in
/// error card + "switch account" (federated logout).
Future<WebSessionActiveDialogResult?> showWebSessionActiveDialog({
  required BuildContext context,
  required Translations t,
  String? logoutUrl,
}) {
  return showDialog<WebSessionActiveDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _WebSessionActiveDialog(
      t: t,
      logoutUrl: logoutUrl,
    ),
  );
}

enum WebSessionActiveDialogResult { disconnectAndContinue, openBrowser, cancel }

class _WebSessionActiveDialog extends StatelessWidget {
  const _WebSessionActiveDialog({required this.t, this.logoutUrl});

  final Translations t;
  final String? logoutUrl;

  @override
  Widget build(BuildContext context) {
    final canOpenBrowser = logoutUrl != null && logoutUrl!.trim().isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        t.login.web_session_title,
        style: AppTextStyles.headlineMedium(context).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        t.login.web_session_body,
        style: AppTextStyles.bodyLarge(context).copyWith(
          color: AppColors.textSecondaryOf(context),
          height: 1.45,
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            WebSessionActiveDialogResult.cancel,
          ),
          child: Text(t.login.web_session_cancel),
        ),
        if (canOpenBrowser)
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(logoutUrl!.trim());
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) {
                Navigator.of(context).pop(
                  WebSessionActiveDialogResult.openBrowser,
                );
              }
            },
            child: Text(t.login.web_session_open_browser),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(
            WebSessionActiveDialogResult.disconnectAndContinue,
          ),
          child: Text(t.login.web_session_disconnect),
        ),
      ],
    );
  }
}
