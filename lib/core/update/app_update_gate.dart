import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../ui/wayo_toast.dart';
import 'app_update_info.dart';
import 'app_update_service.dart';

/// Blocks or prompts when Remote Config reports a newer store build.
///
/// - [AppUpdateStatus.required]: non-dismissible full-screen gate
/// - [AppUpdateStatus.optional]: dialog with Later / Update (once per session)
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  AppUpdateInfo _info = AppUpdateInfo.none;
  bool _isUpdateDialogVisible = false;
  bool _optionalDismissedThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final result = await AppUpdateService.checkForUpdate();
    if (!mounted) return;
    setState(() => _info = result);
    if (result.isOptional &&
        !_optionalDismissedThisSession &&
        !_info.isRequired) {
      unawaited(_showOptionalDialogIfNeeded());
    }
  }

  Future<void> _showOptionalDialogIfNeeded() async {
    if (!mounted || _isUpdateDialogVisible || _optionalDismissedThisSession) {
      return;
    }
    if (!_info.isOptional) return;

    _isUpdateDialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _OptionalUpdateDialog(
          message: _info.message,
          onLater: () {
            _optionalDismissedThisSession = true;
            Navigator.of(ctx).pop();
          },
          onUpdate: () {
            unawaited(_openStore());
          },
        ),
      );
    } finally {
      _isUpdateDialogVisible = false;
    }
  }

  Future<void> _openStore() async {
    final url = _info.storeUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      WayoToast.error(context, t.force_update.action_update);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_info.isRequired) {
      return PopScope(
        canPop: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            const ModalBarrier(dismissible: false, color: Colors.black87),
            _ForcedUpdateScreen(
              message: _info.message,
              onUpdate: () => unawaited(_openStore()),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}

class _ForcedUpdateScreen extends StatelessWidget {
  const _ForcedUpdateScreen({
    required this.onUpdate,
    this.message,
  });

  final VoidCallback onUpdate;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = (message != null && message!.trim().isNotEmpty)
        ? message!.trim()
        : t.force_update.subtitle;

    return Material(
      color: AppColors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                t.force_update.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.force_update.body_required,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    unawaited(HapticFeedback.lightImpact());
                    onUpdate();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    t.force_update.action_update,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
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

class _OptionalUpdateDialog extends StatelessWidget {
  const _OptionalUpdateDialog({
    required this.onLater,
    required this.onUpdate,
    this.message,
  });

  final VoidCallback onLater;
  final VoidCallback onUpdate;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final body = (message != null && message!.trim().isNotEmpty)
        ? message!.trim()
        : t.force_update.optional_subtitle;

    return AlertDialog(
      icon: Icon(
        Icons.system_update_alt_rounded,
        color: AppColors.primary,
        size: 36,
      ),
      title: Text(t.force_update.optional_title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: onLater,
          child: Text(t.force_update.action_later),
        ),
        FilledButton(
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            onUpdate();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(t.force_update.action_update),
        ),
      ],
    );
  }
}
