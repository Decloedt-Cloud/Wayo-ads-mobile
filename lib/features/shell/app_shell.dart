import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../account_deletion/presentation/providers/account_deletion_providers.dart';
import '../auth/domain/auth_notifier.dart';
import '../auth/domain/wayo_ads_account_role.dart';
import '../chat/presentation/providers/chat_providers.dart';
import '../dashboard/domain/entities/campaign_status.dart';
import '../account_deletion/presentation/widgets/pending_account_deletion_banner.dart';
import '../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../onboarding/presentation/shell_tutorial_controller.dart';
import 'presentation/widgets/shell_tutorial_replay_scope.dart';
import 'widgets/wayo_bottom_nav.dart';

/// Main shell with bottom navigation (Dashboard, Campaigns, Wallet, Invoices, Chat).
///
/// Owns the [GlobalKey]s used by the first-login coach-mark tour so both the
/// navigation bar and the tour anchor to the same widget tree. The tour runs
/// **at most once per (user, role)** via [ShellTutorialController].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  // One GlobalKey per bottom-nav branch. They identify the tab pills for the
  // coach-mark tour; recreating them here (not inside the bottom nav) keeps
  // a stable identity across bottom-nav rebuilds.
  final GlobalKey _dashboardKey = GlobalKey(debugLabel: 'shell.tab.dashboard');
  final GlobalKey _campaignsKey = GlobalKey(debugLabel: 'shell.tab.campaigns');
  final GlobalKey _walletKey = GlobalKey(debugLabel: 'shell.tab.wallet');
  final GlobalKey _invoicesKey = GlobalKey(debugLabel: 'shell.tab.invoices');
  final GlobalKey _chatKey = GlobalKey(debugLabel: 'shell.tab.chat');

  bool _tutorialTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTutorial();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authNotifierProvider).valueOrNull;
      if (auth is AuthAuthenticated) {
        ref.read(accountDeletionScheduledAtProvider.notifier).syncFromRemote();
      }
    }
  }

  /// Runs the shell coach-mark tour once per (user, role).
  ///
  /// We trigger from `postFrameCallback` (first paint) **and** re-check on
  /// role changes — covers the case where the user signs in with the wrong
  /// role first and the auth bounces through a loading state before the
  /// final role is known.
  void _maybeShowTutorial() {
    if (!mounted || _tutorialTriggered) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    final role = auth.user.wayoAdsRole;
    if (role == WayoAdsAccountRole.unknown) return;

    final prefs = ref.read(appPrefsProvider);
    if (ShellTutorialController.instance.hasSeen(
      prefs: prefs,
      userId: auth.user.id,
      role: role,
    )) {
      _tutorialTriggered = true;
      return;
    }

    _tutorialTriggered = true;
    // One more frame so the bottom nav has a rendered context — the coach
    // mark package relies on `GlobalKey.currentContext` to locate targets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShellTutorialController.instance.maybeShow(
        context: context,
        prefs: prefs,
        userId: auth.user.id,
        role: role,
        keys: {
          ShellTutorialTarget.dashboard: _dashboardKey,
          ShellTutorialTarget.campaigns: _campaignsKey,
          ShellTutorialTarget.wallet: _walletKey,
          ShellTutorialTarget.chat: _chatKey,
        },
      );
    });
  }

  /// Lets the dashboard (and similar) reopen the coach-mark shell tour on demand.
  Future<void> _replayShellTutorial() async {
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    final role = auth.user.wayoAdsRole;
    if (role == WayoAdsAccountRole.unknown) return;

    final prefs = ref.read(appPrefsProvider);
    await ShellTutorialController.instance.reset(
      prefs: prefs,
      userId: auth.user.id,
      role: role,
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShellTutorialController.instance.show(
        context: context,
        prefs: prefs,
        userId: auth.user.id,
        role: role,
        keys: {
          ShellTutorialTarget.dashboard: _dashboardKey,
          ShellTutorialTarget.campaigns: _campaignsKey,
          ShellTutorialTarget.wallet: _walletKey,
          ShellTutorialTarget.chat: _chatKey,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // React to role / auth transitions so the tour triggers after the role
    // is resolved, even if the user landed on `/dashboard` before it was.
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenData((s) {
        if (s is AuthAuthenticated &&
            s.user.wayoAdsRole != WayoAdsAccountRole.unknown) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _maybeShowTutorial(),
          );
        }
      });
    });

    final notificationUnread = ref.watch(
      dashboardStreamProvider.select(
        (async) => async.valueOrNull?.unreadCount ?? 0,
      ),
    );
    final chatUnread = ref
        .watch(chatConversationsProvider)
        .maybeWhen(
          data: (list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount),
          orElse: () => 0,
        );
    final campaignsAttentionCount = ref.watch(
      dashboardStreamProvider.select(
        (async) =>
            async.valueOrNull?.campaigns
                .where((c) => c.status == CampaignStatus.draft)
                .length ??
            0,
      ),
    );

    return Scaffold(
      extendBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PendingAccountDeletionBanner(),
          Expanded(
            child: ShellTutorialReplayScope(
              replay: _replayShellTutorial,
              child: widget.navigationShell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: WayoBottomNav(
        navigationShell: widget.navigationShell,
        notificationUnread: notificationUnread,
        chatUnread: chatUnread,
        campaignsAttentionCount: campaignsAttentionCount,
        dashboardTabKey: _dashboardKey,
        campaignsTabKey: _campaignsKey,
        walletTabKey: _walletKey,
        invoicesTabKey: _invoicesKey,
        chatTabKey: _chatKey,
      ),
    );
  }
}
