import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/domain/wayo_ads_account_role.dart';
import '../../features/onboarding/presentation/shell_tutorial_controller.dart';
import '../providers/app_providers.dart';
import 'app_review_service.dart';

/// Records authenticated shell sessions and may trigger native review prompts.
class AppReviewPromptHost extends ConsumerStatefulWidget {
  const AppReviewPromptHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppReviewPromptHost> createState() => _AppReviewPromptHostState();
}

class _AppReviewPromptHostState extends ConsumerState<AppReviewPromptHost> {
  int? _lastRecordedUserId;

  void _maybeRecordShellSession() {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    final role = auth.user.wayoAdsRole;
    if (role == WayoAdsAccountRole.unknown) return;

    final userId = auth.user.id;
    if (_lastRecordedUserId == userId) return;
    _lastRecordedUserId = userId;

    final prefs = ref.read(appPrefsProvider);
    final tutorialPending = !ShellTutorialController.instance.hasSeen(
      prefs: prefs,
      userId: userId,
      role: role,
    );

    unawaited(
      AppReviewService.instance.onShellEntered(
        prefs: prefs,
        userId: userId,
        shellTutorialPending: tutorialPending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenData((s) {
        if (s is AuthAuthenticated &&
            s.user.wayoAdsRole != WayoAdsAccountRole.unknown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeRecordShellSession();
          });
        } else {
          _lastRecordedUserId = null;
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeRecordShellSession();
    });

    return widget.child;
  }
}
