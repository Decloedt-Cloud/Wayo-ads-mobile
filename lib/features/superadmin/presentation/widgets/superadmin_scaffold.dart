import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/wayo_black_bottom_bar.dart';
import '../../../../core/layout/wayo_system_insets.dart';
import '../../../../core/theme/app_colors.dart';
import 'superadmin_chrome_actions.dart';

/// Shared chrome for full-screen superadmin routes (not the tab shell).
///
/// Always paints [WayoBlackBottomBar] so no form CTAs / list rows draw through
/// the Android system navigation bar under edge-to-edge.
class SuperadminScaffold extends StatelessWidget {
  const SuperadminScaffold({
    super.key,
    required this.body,
    this.title,
    this.appBar,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.showChromeActions = true,
    this.onRefresh,
  });

  final Widget body;
  final String? title;
  final PreferredSizeWidget? appBar;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final bool showChromeActions;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final resolvedActions = <Widget>[
      if (onRefresh != null)
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ...?actions,
      if (showChromeActions)
        const SuperadminChromeActions(trailingPadding: 8),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
        systemNavigationBarColor: WayoBlackBottomBar.barColor,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: true,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: appBar ??
            (title != null
                ? SuperadminAppBar(
                    title: title!,
                    leading: leading,
                    actions: resolvedActions,
                  )
                : null),
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: const WayoBlackBottomBar(),
      ),
    );
  }
}

/// Compact AppBar used across superadmin settings / ops screens.
class SuperadminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SuperadminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  static const double height = 48;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.textPrimaryOf(context);
    return AppBar(
      toolbarHeight: height,
      titleSpacing: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: fg,
        ),
      ),
      backgroundColor: AppColors.surfaceOf(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: fg,
      iconTheme: IconThemeData(color: fg, size: 20),
      actionsIconTheme: IconThemeData(color: fg, size: 20),
      actions: actions,
    );
  }
}

/// Standard page padding — clears content above the black system-nav fill.
EdgeInsets superadminPagePadding(BuildContext context, {double top = 8}) {
  return EdgeInsets.fromLTRB(16, top, 16, wayoScrollBottomReserve(context, gap: 20));
}

/// Elevated settings / section card.
class SuperadminSectionCard extends StatelessWidget {
  const SuperadminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.28),
        ),
      ),
      child: child,
    );
  }
}

/// Keyboard + system nav inset for modal sheets (Android edge-to-edge safe).
double superadminSheetBottomInset(BuildContext context) {
  return MediaQuery.viewInsetsOf(context).bottom +
      wayoSystemBottomInset(context);
}

/// Modal bottom sheet that never draws CTAs under the system navigation bar.
Future<T?> showSuperadminSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) {
      final keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
      final nav = wayoSystemBottomInset(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard + nav),
        child: builder(ctx),
      );
    },
  );
}
