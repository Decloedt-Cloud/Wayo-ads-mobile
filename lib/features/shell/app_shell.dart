import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/creator_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/app_prefs.dart';
import '../../i18n/strings.g.dart';
import '../account_deletion/presentation/providers/account_deletion_providers.dart';
import '../auth/domain/auth_notifier.dart';
import '../auth/domain/wayo_ads_account_role.dart';
import '../chat/presentation/providers/chat_providers.dart';
import '../dashboard/domain/entities/campaign_status.dart';
import '../account_deletion/presentation/widgets/pending_account_deletion_banner.dart';
import '../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../onboarding/presentation/shell_tutorial_controller.dart';
import 'presentation/widgets/shell_tutorial_replay_scope.dart';
import '../../core/ui/wayo_system_nav_bar.dart';
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

  /// Host for the coach-mark overlay — scoped to the shell body so the bottom
  /// nav stays outside the dimmed layer (width-independent tab highlighting).
  final GlobalKey _shellTutorialOverlayHostKey =
      GlobalKey(debugLabel: 'shell.tutorial.overlay');

  bool _tutorialTriggered = false;

  BuildContext get _shellTutorialOverlayContext =>
      _shellTutorialOverlayHostKey.currentContext ?? context;
  Future<void>? _tutorialLaunch;

  Future<void> _waitForCoachNavLayouts(
    Map<ShellTutorialTarget, GlobalKey> keys,
    int attempts,
  ) async {
    for (var i = 0;
        i < attempts && mounted && !shellCoachNavTabsReady(keys);
        i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _kickoffShellTutorialFirstRun({
    required AppPrefs prefs,
    required int userId,
    required WayoAdsAccountRole role,
    required Map<ShellTutorialTarget, GlobalKey> keys,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await _waitForCoachNavLayouts(keys, 24);
    if (!mounted) return;

    Future<bool> tryShow() {
      return ShellTutorialController.instance.maybeShow(
        context: _shellTutorialOverlayContext,
        prefs: prefs,
        userId: userId,
        role: role,
        keys: keys,
      );
    }

    var ok = await tryShow();
    if (!ok && mounted) {
      await _waitForCoachNavLayouts(keys, 8);
      if (mounted) ok = await tryShow();
    }

    if (!mounted) return;
    _tutorialTriggered = true;

    if (!ok) {
      debugPrint(
        '[AppShell] Shell onboarding tour did not anchor to bottom nav tabs',
      );
    }
  }

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

  Map<ShellTutorialTarget, GlobalKey> _tutorialKeys(bool includeInvoicesTab) {
    return {
      ShellTutorialTarget.dashboard: _dashboardKey,
      ShellTutorialTarget.campaigns: _campaignsKey,
      ShellTutorialTarget.wallet: _walletKey,
      if (includeInvoicesTab) ShellTutorialTarget.invoices: _invoicesKey,
      ShellTutorialTarget.chat: _chatKey,
    };
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

    if (_tutorialLaunch != null) return;

    final keys = _tutorialKeys(
      role == WayoAdsAccountRole.advertiser ||
          role == WayoAdsAccountRole.creator,
    );

    final Future<void> kickoff = _kickoffShellTutorialFirstRun(
      prefs: prefs,
      userId: auth.user.id,
      role: role,
      keys: keys,
    );
    _tutorialLaunch = kickoff;
    kickoff.whenComplete(() {
      if (identical(_tutorialLaunch, kickoff)) {
        _tutorialLaunch = null;
      }
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
    final keys = _tutorialKeys(
      role == WayoAdsAccountRole.advertiser ||
          role == WayoAdsAccountRole.creator,
    );
    await ShellTutorialController.instance.reset(
      prefs: prefs,
      userId: auth.user.id,
      role: role,
    );
    if (!mounted) return;

    await _waitForCoachNavLayouts(keys, 24);
    if (!mounted) return;

    var ok = await ShellTutorialController.instance.show(
      context: _shellTutorialOverlayContext,
      prefs: prefs,
      userId: auth.user.id,
      role: role,
      keys: keys,
    );
    if (!ok && mounted) {
      await _waitForCoachNavLayouts(keys, 8);
      if (!mounted) return;
      await ShellTutorialController.instance.show(
        context: _shellTutorialOverlayContext,
        prefs: prefs,
        userId: auth.user.id,
        role: role,
        keys: keys,
      );
    }
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
    final chatUnread = ref.watch(chatUnreadCountProvider);
    final campaignsAttentionCount = ref.watch(
      dashboardStreamProvider.select(
        (async) =>
            async.valueOrNull?.campaigns
                .where((c) => c.status == CampaignStatus.draft)
                .length ??
            0,
      ),
    );

    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final showInvoicesTab = authState is AuthAuthenticated &&
        (authState.user.wayoAdsRole == WayoAdsAccountRole.advertiser ||
            authState.user.wayoAdsRole == WayoAdsAccountRole.creator);

    final invoicesNavLabel = authState is AuthAuthenticated &&
            authState.user.wayoAdsRole == WayoAdsAccountRole.creator
        ? context.t.nav.invoices_creator
        : context.t.nav.invoices;

    final navBarBg = wayoSystemNavBarColor(context);
    final systemNav = wayoSystemNavBarOverlay(context);

    final keyboardOpen = wayoShellKeyboardOpen(context);
    final shellCoachAccent = authState is AuthAuthenticated &&
            authState.user.wayoAdsRole == WayoAdsAccountRole.creator
        ? CreatorColors.primaryOf(context)
        : AppColors.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemNav,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PendingAccountDeletionBanner(),
            Expanded(
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) {
                      return KeyedSubtree(
                        key: _shellTutorialOverlayHostKey,
                        child: ShellTutorialReplayScope(
                          replay: _replayShellTutorial,
                          child: widget.navigationShell,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : Material(
                color: navBarBg,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                child: WayoBottomNav(
                  navigationShell: widget.navigationShell,
                  notificationUnread: notificationUnread,
                  chatUnread: chatUnread,
                  campaignsAttentionCount: campaignsAttentionCount,
                  showInvoicesTab: showInvoicesTab,
                  invoicesNavLabel: invoicesNavLabel,
                  coachAccentColor: shellCoachAccent,
                  dashboardTabKey: _dashboardKey,
                  campaignsTabKey: _campaignsKey,
                  walletTabKey: _walletKey,
                  invoicesTabKey: showInvoicesTab ? _invoicesKey : null,
                  chatTabKey: _chatKey,
                ),
              ),
      ),
    );
  }
}
