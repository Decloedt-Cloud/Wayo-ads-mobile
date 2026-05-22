import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/push/push_notifications_status_provider.dart';
import '../../../../i18n/strings.g.dart';
import 'app_settings_panel_content.dart';

/// Opens a premium **trailing** settings panel (not the default Material drawer).
///
/// Uses [showGeneralDialog] so we keep full control over motion, barrier, and
/// `AlignmentDirectional` (correct on RTL).
Future<void> showAppSettingsSidePanel(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final barrierLabel = MaterialLocalizations.of(
    context,
  ).modalBarrierDismissLabel;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.centerEnd,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox.expand(),
              ),
            ),
            Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              label: dialogContext.t.app_settings.open_semantics,
              child: _AnimatedPanel(
                child: AppSettingsPanelContent(
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final beginDx = isRtl ? -1.0 : 1.0;
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(beginDx, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  ).whenComplete(() {
    unawaited(
      container.read(pushNotificationsActiveProvider.notifier).refresh(),
    );
  });
}

class _AnimatedPanel extends StatelessWidget {
  const _AnimatedPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final panelW = (w * 0.88).clamp(300.0, 420.0);
    final panelH = mq.size.height - mq.padding.vertical - 20;
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: panelW,
          height: panelH.clamp(360.0, 900.0),
          child: child,
        ),
      ),
    );
  }
}
